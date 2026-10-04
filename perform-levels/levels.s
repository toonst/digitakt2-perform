| SPDX-License-Identifier: GPL-2.0-or-later
| Copyright (C) 2026 Toon Stegen
| perform-levels: the hook on leaving PERFORM KIT mode (Digitakt II, OS 1.17).
| ColdFire V4 (MCF5441x); assemble with -mcpu=54455.
|
| The PERFORM toggle (0x40064aec) turns the mode off at 0x40064ba6:
|     move.l 0x98(%a2),-(%sp) ; jsr (%a3)     | a3 = 0x40041d24: kits = arg + 0xf4
|     clr.l -(%sp) ; clr.l -(%sp) ; move.l %d2,-(%sp) ; movea.l %d6,%a0
|     move.l %d0,-(%sp) ; jsr (%a0)           | 0x40036cba(kits, d2, 0, 0): select kit d2
| with d2 the pattern's kit (0-127). The site's jsr comes here in place of
| the first two instructions: it does their work (the argument stays on
| the stack, d0 = kits), and before that lets pl_keep copy the perform
| kit's levels into kit d2, so the select that follows loads them.

        .section .run, "ax"
        .globl  pl_off
pl_off:
        move.l  0x98(%a2), -(%sp)
        jsr     (%a3)                   | d0 = kits, as the site's own call
        addq.l  #4, %sp
        lea     -12(%sp), %sp
        movem.l %d0-%d1/%a1, (%sp)
        move.l  %d2, -(%sp)             | the pattern's kit
        move.l  %d0, -(%sp)             | kits
        jsr     pl_keep
        addq.l  #8, %sp
        movem.l (%sp), %d0-%d1/%a1
        lea     12(%sp), %sp
        movea.l (%sp), %a0              | back to the site, with the argument
        move.l  0x98(%a2), (%sp)        | it pushed in place of our return address
        jmp     (%a0)                   | (a0 is loaded again before it is read)
