/*
 * SPDX-License-Identifier:     BSD-3-Clause
 *
 * Copyright 2021 NXP
 */

.set VTOR_ADDR, 0xE000ED08
.align 2
.thumb

.section ".text", "ax"

.type _start,#function
.type _reset_handler,#function
.type _nmi,#function
.type _hard_fault,#function
.type _mem_manage,#function
.type _bus_fault,#function
.type _usage_fault,#function
.type _svc_call,#function
.type _debug_monitor,#function
.type _pend_sv,#function
.type _sys_tick,#function
.type _ext_int,#function

.globl	_start
.globl	_reset_handler
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


_reset_handler:
_start:
	mov   r0, #0
	mov   r1, #0
	mov   r2, #0
	mov   r3, #0
	mov   r4, #0
	mov   r5, #0
	mov   r6, #0
	mov   r7, #0
	mov   r8, r0
	mov   r9, r0
	mov   r10, r0
	mov   r11, r0
	mov   r12, r0
	mov   r14, r0

	/* Set vector table address in RAM */
	ldr  r0, =VTOR_ADDR
	ldr  r1, =VTABLE
	ldr  r2, =(1 << 29)
	orr  r1, r2
	str  r1,[r0]

	/* Set stack pointer */
	ldr  r0, =_stack_start
	msr MSP, r0

	/* Disable Watchdog SWT_0: Cortex-M7 - core 0 */
	ldr  r0, =0x40100010
	ldr  r1, =0xC520
	str  r1, [r0]
	ldr  r1, =0xD928
	str  r1, [r0]
	ldr  r0, =0x40100000
	ldr  r1, =0xFF000040
	str  r1, [r0]

	bl main

_end:
	wfi
	b _end

_nmi:
	b _nmi
_hard_fault:
	b _hard_fault
_mem_manage:
	b _mem_manage
_bus_fault:
	b _bus_fault
_usage_fault:
	b _usage_fault
_svc_call:
	b _svc_call
_debug_monitor:
	b _debug_monitor
_pend_sv:
	b _pend_sv
_sys_tick:
	b _sys_tick
_ext_int:
	b _ext_int
