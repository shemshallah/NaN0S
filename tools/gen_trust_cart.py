#!/usr/bin/env python3
# SCAFFOLD: emit the Thompson Trust exhibit cartridge from spec/TRUST_PAPER.md.
# Runtime is NaN16 only. The preface is authored here; the body is the paper,
# wrapped to 78 columns and sanitized for the .str format.
import os, textwrap, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gen_about_carts as about

PREFACE = [
" NaN/0S - THE TRUST EXHIBIT",
" KEN THOMPSON AND THE QUESTION OF TRUST",
"",
" THE MAN",
" Ken Thompson was born 4 February 1943 in New Orleans, Louisiana.",
" Status: LIVING. He joined Bell Labs in 1966. With Dennis Ritchie he",
" created Unix. He created the B language, co-created Plan 9 and Inferno,",
" co-created UTF-8 with Rob Pike, and co-created Go with Rob Pike and",
" Robert Griesemer. He received the Turing Award in 1983. In 1984 he gave",
" the Turing Award lecture 'Reflections on Trusting Trust'.",
"",
" THE QUESTION",
" To what extent should one trust a statement that a program is free of",
" Trojan horses? Perhaps it is more important to trust the people who",
" wrote the software. Thompson showed a compiler that inserts a backdoor",
" into login, then re-inserts the backdoor into itself when it compiles",
" its own source. The source looks clean. The binary is infected. Source",
" review alone cannot answer the question.",
"",
" THE ANSWER THIS MUSEUM BUILDS",
" A named trust base. A self-hosting fixed point. An independent builder.",
" A dual-face seal. A published log. And an honest list of limits. The",
" paper below is the whole argument. UP/DOWN scrolls one line. LEFT/RIGHT",
" moves ten lines. ESC returns to the museum.",
"",
" ------------------------------------------------------------------",
"",
]

def clean(line):
    line = line.rstrip('\n').replace('\t', '    ')
    line = line.replace(';', ',')
    line = line.replace('"', "'")
    return line

def main():
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    paper = os.path.join(root, 'spec', 'TRUST_PAPER.md')
    lines = list(PREFACE)
    for raw in open(paper, encoding='utf-8'):
        s = clean(raw)
        if not s.strip():
            lines.append('')
            continue
        # preserve Markdown headings and code fences, wrap prose to 78 cols
        width = 78
        if s.startswith('```') or s.startswith('    '):
            lines.append(s[:width])
            continue
        wrapped = textwrap.wrap(s, width=width, replace_whitespace=False,
                                drop_whitespace=True, break_long_words=True,
                                break_on_hyphens=False)
        if not wrapped:
            lines.append('')
        else:
            lines.extend(wrapped)
    # collapse runs of blank lines to one
    out = []
    for s in lines:
        if s == '' and out and out[-1] == '':
            continue
        out.append(s)
    about.emit(os.path.join(root, 'src', 'exhibits', 'trust_cart.nas'), out)
    print('trust exhibit lines:', len(out))

if __name__ == '__main__':
    main()
