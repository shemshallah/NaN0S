package org.nan0s.vm

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Rect
import android.graphics.Typeface
import android.text.InputType
import android.view.KeyEvent
import android.view.View
import android.view.inputmethod.BaseInputConnection
import android.view.inputmethod.EditorInfo
import android.view.inputmethod.InputConnection

/** Draws the guest display: 80x25 text from the cell buffer (colours through the guest's DAC) or the 8-bit framebuffer as a scaled bitmap. */
class NanView(context: Context, private val vm: NanVm, private val onInput: () -> Unit) : View(context) {
    private val cells = IntArray(2000)
    private val pal = IntArray(16)
    private val bg = Paint()
    private val fg = Paint(Paint.ANTI_ALIAS_FLAG).apply { typeface = Typeface.MONOSPACE }
    private val blit = Paint().apply { isFilterBitmap = false }
    private var px = IntArray(0)
    private var bmp: Bitmap? = null
    private val src = Rect()
    private val dst = Rect()
    private var fitW = -1f
    var integerScale = false

    init { isFocusable = true; isFocusableInTouchMode = true }

    override fun onDraw(canvas: Canvas) {
        canvas.drawColor(Color.BLACK)
        if (vm.graphics()) drawGfx(canvas) else drawText(canvas)
    }

    private fun drawText(c: Canvas) {
        if (!vm.snapshotText(cells, pal)) return
        val cw = width / 80f
        val ch = height / 25f
        fg.textSize = ch * 0.82f
        if (fitW < 0f || fitW != cw) { fitW = cw; fg.textScaleX = 1f; val m = fg.measureText("M"); if (m > 0f) fg.textScaleX = cw / m }
        val base = ch * 0.78f
        for (y in 0 until 25) {
            for (x in 0 until 80) {
                val cell = cells[y * 80 + x]
                val attr = cell shr 8 and 255
                val bi = attr shr 4 and 7
                if (bi != 0) { bg.color = pal[bi]; c.drawRect(x * cw, y * ch, (x + 1) * cw + 1f, (y + 1) * ch + 1f, bg) }
                val code = cell and 255
                if (code == 0 || code == 32) continue
                fg.color = pal[attr and 15]
                c.drawText(Cp437.map[code], x * cw, y * ch + base, fg)
            }
        }
    }

    private fun drawGfx(c: Canvas) {
        val w = vm.width(); val h = vm.height()
        if (w <= 0 || h <= 0 || w * h > 4_000_000) return
        if (px.size < w * h) px = IntArray(w * h)
        var b = bmp
        if (b == null || b.width != w || b.height != h) { b = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888); bmp = b }
        if (!vm.snapshotGfx(px)) return
        b!!.setPixels(px, 0, w, 0, 0, w, h)
        var s = minOf(width.toFloat() / w, height.toFloat() / h)
        if (integerScale && s >= 1f) s = s.toInt().toFloat()
        val dw = (w * s).toInt(); val dh = (h * s).toInt()
        val l = (width - dw) / 2; val t = (height - dh) / 2
        src.set(0, 0, w, h); dst.set(l, t, l + dw, t + dh)
        c.drawBitmap(b, src, dst, blit)
    }

    // ---- input: hardware and soft keyboards arrive as KeyEvents (soft keyboard with TYPE_NULL) ----
    override fun onCheckIsTextEditor(): Boolean = true
    override fun onCreateInputConnection(outAttrs: EditorInfo): InputConnection {
        outAttrs.inputType = InputType.TYPE_NULL
        outAttrs.imeOptions = EditorInfo.IME_FLAG_NO_EXTRACT_UI or EditorInfo.IME_FLAG_NO_FULLSCREEN
        return BaseInputConnection(this, false)
    }
    override fun onKeyDown(keyCode: Int, event: KeyEvent): Boolean = key(keyCode, event, true) || super.onKeyDown(keyCode, event)
    override fun onKeyUp(keyCode: Int, event: KeyEvent): Boolean = key(keyCode, event, false) || super.onKeyUp(keyCode, event)

    private fun key(code: Int, e: KeyEvent, down: Boolean): Boolean {
        if (vm.rawKeyboard()) {
            val sc = KeyMap.scancode(code)
            if (sc < 0) return false
            vm.keyEvent(sc, down); onInput(); return true
        }
        if (!down) return KeyMap.special(code) >= 0 || e.unicodeChar in 1..127
        val sp = KeyMap.special(code)
        if (sp >= 0) { vm.keyChar(sp); onInput(); return true }
        val u = e.unicodeChar
        if (u in 1..127) { vm.keyChar(u); onInput(); return true }
        return false
    }
}
