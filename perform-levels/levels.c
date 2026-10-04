/* SPDX-License-Identifier: GPL-2.0-or-later
 * Copyright (C) 2026 Toon Stegen */
/* perform-levels: track levels survive leaving PERFORM KIT mode on a
 * Digitakt II (OS 1.17).
 *
 * Stock, turning PERFORM KIT on copies the pattern's kit into a spare kit,
 * slot 0x80, and plays that one; every tweak goes there. Turning it off
 * selects the pattern's own kit again, so every tweak is gone. With this
 * mod the 16 track levels are copied from the perform kit into the
 * pattern's kit first: the levels you left with stay, as if you had set
 * them outside PERFORM KIT, and every other parameter goes back as stock.
 *
 * The kits: the collection's vtable +0x30 gives a slot's kit (its table
 * + slot * 0x5574), and +0x5c(kits, slot, 0) is what the firmware calls
 * after it writes a kit (0x40035e12, 0x40035eb4). A kit's track levels
 * are 16 words at +0x14, the value in the high byte (track 1 first).
 */

#define PERFORM_KIT 0x80
#define LEVELS      0x14
#define TRACKS      16

typedef char *(*kit_at_fn)(void *kits, int slot);
typedef void (*kit_changed_fn)(void *kits, int slot, int arg);

#define VT(kits, off) (*(void **)(*(char **)(kits) + (off)))

void pl_keep(void *kits, int slot)
{
    kit_at_fn kit_at = (kit_at_fn)VT(kits, 0x30);
    unsigned short *from, *to;
    char *perform, *kit;
    int t, changed = 0;

    if (slot < 0 || slot >= PERFORM_KIT)
        return;
    perform = kit_at(kits, PERFORM_KIT);
    kit = kit_at(kits, slot);
    if (!perform || !kit)
        return;
    from = (unsigned short *)(perform + LEVELS);
    to = (unsigned short *)(kit + LEVELS);
    for (t = 0; t < TRACKS; t++)
        if (to[t] != from[t]) {
            to[t] = from[t];
            changed = 1;
        }
    if (changed)
        ((kit_changed_fn)VT(kits, 0x5c))(kits, slot, 0);
}
