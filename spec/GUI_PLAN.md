# GUI Plan - NaN/0S Windowed Shell

## Goal

Replace the text-mode menu with a true GUI: a desktop, windows, a title bar,
keyboard focus, and programs that run inside a window instead of taking over
the whole screen. Every window and every program carries a `NaN/0S` header.

## Display

- VGA mode 13h, 320x200x8, linear A0000.
- 5x7 font in 6x9 cells for labels, 8x8 or 8x12 for window chrome later.
- Palette: black desktop, gray window bodies, cyan focus border, white text,
  yellow `NaN/0S` title.
- Double buffer in guest RAM; `FBCOPY` presents.

## Window manager

```
desktop
  top bar: NaN/0S  clock  focus  hint
  windows[]: id, x, y, w, h, title, flags, owner, console
  focus: id
  z-order: array
```

Operations:

- `wm_open(title, w, h) -> id`
- `wm_close(id)`
- `wm_focus(id)`
- `wm_move(id, x, y)`
- `wm_resize(id, w, h)`
- `wm_draw()` composites desktop + windows + focus.
- `wm_key(key)` routes to the focused window.
- `wm_mouse(x, y, buttons)` later.

## Virtual console ABI

A window owns a virtual console:

```
vcon: cols=80, rows=25, cells[] (char, attr)
      cursor x, y, scroll_top, scroll_bottom
      putc, puts, cls, scroll, set_attr
```

The existing `V_PUTS`, `V_HEX`, `V_DEC`, `V_CLS`, `V_SCROLL` vectors are
redirected to the focused window's vcon when a program is running in a window.
The text-mode cartridges keep working; their 80x25 output is clipped and
rendered inside the window. A program that needs pixels uses a `pixel window`
instead of a vcon.

## Window chrome

- 1px cyan focus border; gray inactive border.
- Title bar: `NaN/0S  <program title>`.
- Close box `[x]`, minimize `[-]`, zoom `[+]` later.
- Footer: `ESC shell`, scroll hints, line counter.
- Every program screen starts with `NaN/0S` in the title bar, and the desktop
  top bar always shows `NaN/0S`.

## Programs in windows

Phase 1: text cartridges run in a vcon window. The shell captures their
80x25 output, clips it, and scrolls inside the window. Keys are routed to the
focused cartridge. `ESC` closes the window, not the machine.

Phase 2: pixel cartridges (Sierpinski, Paradox, future Doom/Quake) get a
pixel window. The shell gives them a framebuffer rectangle and an origin; the
framebuffer driver clips to the rectangle.

Phase 3: multiple windows. A launcher window, a museum window, a Trust window,
a Boole window. Tiling and overlapping. Keyboard focus with Tab / arrows.

Phase 4: mouse. PS/2 mouse IRQ, cursor, click-to-focus, drag, resize.

## Text readability

- 5x7 glyphs in 6x9 cells for dense text.
- 8x8/8x12 glyphs for window chrome and titles.
- 1px horizontal gap and 2px vertical gap.
- Optional 2x scaling for the focused window.
- UTF-8 decoder with a curated Unicode table (arrows, math, punctuation).
- Every page and program prints `NaN/0S` at the top.

## Implementation order

1. Window manager structs and drawing primitives in NaN16 (`src/lib/wm.nas`).
2. Virtual console buffer and renderer (`src/lib/vcon.nas`).
3. GUI shell launcher and desktop (`src/exhibits/gui_shell.nas`).
4. Redirect V_PUTS/V_CLS/V_SCROLL to the focused vcon.
5. Run Boole/About/Trust/Patriot in windows.
6. Pixel window for Sierpinski/Paradox.
7. Multiple windows and focus.
8. Mouse.
9. AArch64 framebuffer backend.

## Gates

- Desktop renders with `NaN/0S` header and clock.
- Open/close/focus a window without corrupting the desktop.
- A text cartridge runs inside a window and scrolls.
- A pixel cartridge renders inside its rectangle.
- Two windows overlap; the focused one is on top.
- ESC closes the focused window and returns focus to the shell.
- Every window title starts with `NaN/0S`.
- Screenshot: `screencaps/gui.png`.

## Native boundary

The window manager, compositor, vcon, and launcher are NaN16. The native core
only provides memory, port I/O, timer, keyboard, and framebuffer ops. No GUI
code is native.


## Status r24
Implemented: steps 1 (wm.nas), 3 (gui cart launcher/desktop), 6 partly (pixel window with occlusion skip), 7 (multiple overlapping windows, focus).
Step 2 (vcon) exists inside the Terminal app (`vc_putc`, `vc_puts`, `vc_cell`); it is not yet the shared V_PUTS target.
Not yet: 4, 5 (text carts in windows), 8 (mouse), 9 (AArch64). See TODO r24.
