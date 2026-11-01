package org.nan0s.vm

import android.app.Activity
import android.app.AlertDialog
import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.os.Bundle
import android.os.ParcelFileDescriptor
import android.util.Log
import android.view.View
import android.view.WindowManager
import android.view.inputmethod.InputMethodManager
import android.widget.Button
import android.widget.HorizontalScrollView
import android.widget.LinearLayout
import android.widget.Toast
import java.io.File

/** Thin shell: one NanVm, one run thread, the display view, a key row and a few buttons. Everything NaN16 lives in the C core. */
class MainActivity : Activity(), NanLoop.Listener {
    private lateinit var vm: NanVm
    private lateinit var view: NanView
    private lateinit var loop: NanLoop
    private lateinit var beeper: Beeper
    private val log = StringBuilder()
    private val reqImage = 1
    private val reqDisk = 2
    private val autosave get() = File(filesDir, "autosave.nan1")
    private val diskFile get() = File(filesDir, "disk.nanfs")
    private var diskPfd: ParcelFileDescriptor? = null

    private fun asset(): ByteArray = assets.open("nan0s.img").use { it.readBytes() }

    /** Asset -> filesDir (once). The guest needs a real, writable file behind the ATA fd. */
    private fun seedDisk() {
        try { assets.open("disk.nanfs").use { i -> diskFile.outputStream().use { o -> i.copyTo(o) } } }
        catch (e: Exception) { Log.w("nan0s", "no bundled disk.nanfs", e) }
    }

    /**
     * Attach the bundled NaNFS volume so the guest can use it over ATA PIO (the C core exposes
     * it as a file descriptor; guest writes land in app storage). SAF "Disk" replaces it with
     * any volume the user opens from Android storage. We keep the PFD and pass its borrowed fd:
     * the C core never closes descriptors, so Java owns the lifetime.
     */
    private fun attachDisk(pfd: ParcelFileDescriptor, size: Long) {
        try { diskPfd?.close() } catch (e: Exception) { }
        diskPfd = pfd
        vm.attachDiskFd(pfd.fd, size)
    }

    private fun attachDefaultDisk() {
        if (!diskFile.exists()) seedDisk()
        if (!diskFile.exists()) return
        try {
            attachDisk(ParcelFileDescriptor.open(diskFile, ParcelFileDescriptor.MODE_READ_WRITE), diskFile.length())
        } catch (e: Exception) { Log.w("nan0s", "disk attach failed", e) }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        vm = NanVm()
        var restored = false
        if (autosave.exists()) restored = try { vm.restoreState(autosave.readBytes()) } catch (e: Exception) { false }
        if (!restored) vm.load(asset())
        attachDefaultDisk()
        loop = NanLoop(vm, this)
        view = NanView(this, vm) { loop.poke() }
        beeper = Beeper { vm.speakerHz() }

        val root = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL; setBackgroundColor(Color.BLACK) }
        root.addView(view, LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, 0, 1f))
        root.addView(keyRow(), LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))
        root.addView(toolRow(), LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))
        setContentView(root)
        view.requestFocus()
        loop.start(); beeper.start()
    }

    private fun btn(label: String, action: () -> Unit): Button = Button(this).apply {
        text = label; isAllCaps = false; minWidth = 0; minimumWidth = 0
        setOnClickListener { action() }
    }
    private fun send(c: Int) { vm.keyChar(c); loop.poke(); view.requestFocus() }

    private fun keyRow(): View {
        val row = LinearLayout(this).apply { orientation = LinearLayout.HORIZONTAL }
        val keys = listOf("Esc" to 27, "Tab" to 9, "\u2190" to NanVm.LEFT, "\u2191" to NanVm.UP, "\u2193" to NanVm.DOWN, "\u2192" to NanVm.RIGHT,
            "~" to '~'.code, "Enter" to 13, "Bksp" to 8, "Home" to NanVm.HOME, "End" to NanVm.END, "PgUp" to NanVm.PGUP, "PgDn" to NanVm.PGDN)
        for ((label, code) in keys) row.addView(btn(label) { send(code) })
        return HorizontalScrollView(this).apply { addView(row) }
    }

    private fun toolRow(): View {
        val row = LinearLayout(this).apply { orientation = LinearLayout.HORIZONTAL }
        row.addView(btn("Kbd") {
            view.requestFocus()
            (getSystemService(Context.INPUT_METHOD_SERVICE) as InputMethodManager).showSoftInput(view, 0)
        })
        row.addView(btn("Open") { pick(reqImage) })
        row.addView(btn("Disk") { pick(reqDisk) })
        row.addView(btn("Reset") {
            autosave.delete(); vm.detachDisk()
            diskFile.delete(); seedDisk(); vm.load(asset()); attachDefaultDisk(); loop.rearm()
        })
        row.addView(btn("Scale") { view.integerScale = !view.integerScale; view.invalidate() })
        row.addView(btn("Fit") { view.resetZoom() })
        row.addView(btn("Log") { showLog() })
        return HorizontalScrollView(this).apply { addView(row) }
    }

    private fun pick(req: Int) {
        val i = Intent(Intent.ACTION_OPEN_DOCUMENT).apply { addCategory(Intent.CATEGORY_OPENABLE); type = "*/*" }
        startActivityForResult(i, req)
    }

    @Deprecated("kept to avoid an androidx dependency")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        val uri = data?.data ?: return
        if (resultCode != RESULT_OK) return
        Thread {
            try {
                if (requestCode == reqImage) {
                    val bytes = contentResolver.openInputStream(uri)!!.use { it.readBytes() }
                    val kind = vm.load(bytes)
                    runOnUiThread { Toast.makeText(this, if (kind != null) "loaded: $kind" else "not a NaN16 program", Toast.LENGTH_SHORT).show() }
                    loop.rearm()
                } else {
                    val pfd = contentResolver.openFileDescriptor(uri, "rw")!!
                    val size = pfd.statSize
                    attachDisk(pfd, size)
                    runOnUiThread { Toast.makeText(this, "disk attached ($size bytes)", Toast.LENGTH_SHORT).show() }
                }
            } catch (e: Exception) {
                runOnUiThread { Toast.makeText(this, "failed: ${e.message}", Toast.LENGTH_LONG).show() }
            }
        }.start()
    }

    private fun showLog() {
        val text = synchronized(log) { log.toString() }
        AlertDialog.Builder(this).setTitle("COM1 / serial log").setMessage(if (text.isEmpty()) "(empty)" else text)
            .setPositiveButton("Close", null)
            .setNeutralButton("Copy") { _, _ ->
                (getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager).setPrimaryClip(ClipData.newPlainText("nan0s log", text))
            }.show()
    }

    // ---- NanLoop.Listener (called on the run thread) ----
    override fun onFrame() { view.postInvalidate() }
    override fun onSerial(bytes: ByteArray) {
        synchronized(log) { log.append(String(bytes, Charsets.ISO_8859_1)); if (log.length > 65536) log.delete(0, log.length - 49152) }
    }
    override fun onHalt(trap: String) {
        runOnUiThread { Toast.makeText(this, if (trap.isEmpty()) "guest halted" else "guest halted: $trap", Toast.LENGTH_SHORT).show() }
    }

    override fun onPause() {
        super.onPause()
        loop.paused = true; beeper.muted = true
        vm.saveState()?.let { try { autosave.writeBytes(it) } catch (e: Exception) { } }
    }
    override fun onResume() {
        super.onResume()
        loop.paused = false; beeper.muted = false; loop.poke(); view.invalidate()
    }
    override fun onDestroy() {
        super.onDestroy()
        loop.shutdown(); beeper.shutdown()
        try { loop.join(1000) } catch (e: InterruptedException) { }
        vm.detachDisk()
        try { diskPfd?.close() } catch (e: Exception) { }
        vm.close()
    }
}
