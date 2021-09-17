/*
 * SPDX-License-Identifier:     BSD-3-Clause
 *
 * Copyright 2021 NXP
 */

OUTPUT_FORMAT("elf32-littlearm", "elf32-littlearm", "elf32-littlearm")
OUTPUT_ARCH(arm)
ENTRY(_start)

SECTIONS
{
 . = 0x3408E000;
 . = ALIGN(128); /* VTOR must be aligned to 128 bytes */
 .vtable :
 {
  *vector.o (.vtable*)
  *(.vtable*)
 }
.data :
 {
  *(.data*)
 }
 .text :
 {
  *start.o (.text*)
  *(.text*)
 }

 _stack_end = 0x3408F000;
 _stack_start = 0x34090000;

 /DISCARD/ : { *(.dynsym) }
 /DISCARD/ : { *(.dynstr*) }
 /DISCARD/ : { *(.dynamic*) }
 /DISCARD/ : { *(.plt*) }
 /DISCARD/ : { *(.interp*) }
 /DISCARD/ : { *(.gnu*) }
}
