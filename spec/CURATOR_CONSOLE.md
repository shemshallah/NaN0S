# Curator Console

## Purpose

A secret, always-available raw view of the running machine. It is not a normal
menu item. It is the curator's door: the person who maintains the museum can
look at the actual NaN words, not a curated screen.

## Secret key

The first key is `~` (Shift + backtick). It is safe on a phone keyboard and on
a PC keyboard. The planned PC chord is Ctrl + Shift + 0. The kernel will track
Ctrl in the keyboard IRQ so the chord can be recognized without stealing a
normal printable key.

## Screen

80x25 text mode, attribute 0x0F00 on black:

```
row 0   CURATOR CONSOLE - RAW GUEST MEMORY - word 0000
row 1   blank
rows 2..24   one word per line? no: four words per row
        AAAA  NNNN_PPPPPPPP_FFFF  NNNN_PPPPPPPP_FFFF  ...
```

A row is:

- 4 hex digits of word address
- two spaces
- four words, each printed as `NNNN_PPPPPPPP_FFFF`
- optional ASCII gutter for the low byte of each payload

At 80 columns, four 21-character words plus address is 88 characters, too wide.
Use two words per row with the full double-face format and an ASCII gutter, or
four words with the compact `PPPPPPPP` payload only. The Curator Console defaults
to four payloads plus address, and `S` toggles the full double-face format.

## Controls

- Up/Down: scroll one row (four words).
- Left/Right: page by 96 words (24 rows).
- `g`: prompt for a hex address, jump there.
- `s`: toggle compact/full word format.
- `f`: follow the current program counter.
- `d`: dump the current 24 rows to the serial port as text.
- ESC: return to the shell.

## Implementation

The console lives in the shell, not in a cartridge. It must work even when a
cartridge is broken. It reads guest memory with `LD`, formats with `V_HEX`, and
draws with `V_PUTS`. It does not allocate. It does not call any exhibit.

The shell key loop checks for `~` before it maps a digit to a cartridge. The
console saves the shell state (r10..r14, current screen), runs, and returns with
`ESC`.

TOC relocation: the TOC currently starts at word 1024. The console needs room
between the shell code and the TOC. The TOC moves to word 1280, and the builder
uses the same base. Strings stay at 2048. The console code lives at 1024..1279.

## Safety

The console is read-only in its first version. A later `W` mode will require a
confirmation word and a seal. The first version cannot corrupt a cartridge by
accident. It can only show what is there.

## Test gates

- `~` from the menu opens the console at word 0 and shows the boot vector.
- Down/Up scroll by four words; Left/Right by 96.
- `g 2000` jumps to word 0x2000.
- ESC returns to the menu with the same TOC state.
- The console works when the selected cartridge has a bad seal.
- A screenshot of the console is stored as `screencaps/curator.png`.
