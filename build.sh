#!/bin/sh
# SPDX-License-Identifier: GPL-2.0-or-later
# Build both mods (and, while elekloader has not released it, the Digitakt II
# core) into dist/, lint them together, and print each file's sha256.
#
#   ELEKLOADER=~/code/elekloader ./build.sh Digitakt_II_OS1.17.syx
#
# ELEKLOADER is an elekloader checkout with mods/core-dt2. Its SDK needs m68k
# binutils and gcc: with Homebrew's m68k-elf-*, ELEKLOADER_CROSS=m68k-elf-.
set -eu
STOCK=${1:?usage: ELEKLOADER=<elekloader checkout> $0 <Digitakt II stock .syx>}
ELEKLOADER=${ELEKLOADER:?set ELEKLOADER to an elekloader checkout}
HERE=$(cd "$(dirname "$0")" && pwd)
export PYTHONPATH="$ELEKLOADER${PYTHONPATH:+:$PYTHONPATH}"
export ELEKLOADER_CROSS=${ELEKLOADER_CROSS:-m68k-elf-}
PY=${PYTHON:-python3}

mkdir -p "$HERE/dist"
"$PY" -m elekloader.sdk.build "$ELEKLOADER/mods/core-dt2" --stock "$STOCK" --out "$HERE/dist"
for m in perform-direct perform-levels; do
    "$PY" -m elekloader.sdk.build "$HERE/$m" --stock "$STOCK" --out "$HERE/dist"
done
"$PY" -m elekloader.lint "$HERE"/dist/perform-direct-*.elemod --stock "$STOCK" \
    --with "$HERE"/dist/core-*.elemod --with "$HERE"/dist/perform-levels-*.elemod
cd "$HERE/dist" && shasum -a 256 *.elemod
