/*
 * SPDX-License-Identifier:     BSD-3-Clause
 *
 * Copyright 2021 NXP
 */

.thumb
.section ".vtable", "ax"

.globl VTABLE
.globl _stack_start
.globl _reset_handler
.globl _nmi
.globl _hard_fault
.globl _mem_manage
.globl _bus_fault
.globl _usage_fault
.globl _svc_call
.globl _debug_monitor
.globl _pend_sv
.globl _sys_tick
.globl _ext_int

VTABLE:
.long _stack_start
.long _reset_handler
.long _nmi
.long _hard_fault
.long _mem_manage
.long _bus_fault
.long _usage_fault
.long 0 /* 7-10 reserved*/
.long 0
.long 0
.long 0
.long _svc_call
.long _debug_monitor
.long 0 /* 13 reserved */
.long _pend_sv
.long _sys_tick

/* Vector table must be aligned to a power of two with a minimum alignment
 * of 128 bytes. For alignment, 16 unused external interrupts are added.
 */
.long _ext_int
.long _ext_int
.long _ext_int
.long _ext_int
.long _ext_int
.long _ext_int
.long _ext_int
.long _ext_int
.long _ext_int
.long _ext_int
.long _ext_int
.long _ext_int
.long _ext_int
.long _ext_int
.long _ext_int
.long _ext_int

.size VTABLE, . - VTABLE
