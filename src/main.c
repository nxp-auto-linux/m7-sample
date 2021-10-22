/*
 * SPDX-License-Identifier:     BSD-3-Clause
 *
 * Copyright 2021 NXP
 */

#include <registers_defs.h>
#include <types.h>

#define A53_CORE0	0
#define A53_PARTITION	1

#define writel(addr, val)	((*(volatile u32*)(addr)) = (u32)(val))
#define readl(addr)		(*(volatile u32*)(addr))

u32 a53_entry_point = 0x340a0000UL;

static void enable_partition(u8 partition)
{
	u32 reg_value = 0;

#ifndef DISABLE_A53_LOCKSTEP
	writel(A53_CLUSTER_GPR06,
	       (readl(A53_CLUSTER_GPR06) | A53_CLUSTER_CA53_LOCKSTEP_ENABLE));
#endif

	/* enable clock partition */
	writel (MC_ME_PRTN_N_PCONF(partition), MC_ME_PARTITION_CLOCK_ENABLE);

	/* trigger hardware process for enabling clocks */
	writel (MC_ME_PRTN_N_PUPD(partition), MC_ME_TRIGGER_PROCESS);

	/* write the valid key sequence */
	writel (MC_ME_CTL_KEY_ADDR, MC_ME_CTL_KEY_VALUE);
	writel (MC_ME_CTL_KEY_ADDR, MC_ME_CTL_KEY_INVERTED_VALUE);

	/* wait for partition clock status bit */
	while ((readl(MC_ME_PRTN_N_STAT(partition)) &
		MC_ME_PARTITION_CLOCK_ENABLE) != 1)
		;

	/* unlock software reset domain control register */
	reg_value = readl(RDC_RD1_CTRL_REGISTER) | RDC_RD1_CTRL_UNLOCK_ENABLE;
	writel(RDC_RD1_CTRL_REGISTER, reg_value);

	/* enable the interconnect interface of software reset domain */
	reg_value = readl(RDC_RD1_CTRL_REGISTER) &
	    RDC_RD1_XBAR_INTERFACE_DISABLE;
	writel(RDC_RD1_CTRL_REGISTER, reg_value);

	/* wait for software reset domain status register
	   to acknowledge interconnect interface not disabled */
	while (((readl(RDC_RD1_STAT_REGISTER)) &
		RDC_RD1_XBAR_INTERFACE_STAT) != 0)
		;

	/* cluster reset */
	reg_value = readl(RGM_PRST(partition)) & RGM_PRST_CLUSTER;
	writel (RGM_PRST(partition), reg_value);

	reg_value = readl(MC_ME_PRTN_N_PCONF(partition)) &
	    MC_ME_OUTPUT_PARTITION;
	writel (MC_ME_PRTN_N_PCONF(partition), reg_value);

	reg_value = readl(MC_ME_PRTN_N_PUPD(partition)) |
	    MC_ME_OUTPUT_STATUS;
	writel (MC_ME_PRTN_N_PUPD(partition), reg_value);

	/* write the valid key sequence */
	writel (MC_ME_CTL_KEY_ADDR, MC_ME_CTL_KEY_VALUE);
	writel (MC_ME_CTL_KEY_ADDR, MC_ME_CTL_KEY_INVERTED_VALUE);

	/* wait until cluster is not in reset */
	while ((readl(RGM_PSTAT(partition)) &
		RGM_PSTAT_RESET_STATE) != 0)
		;

	while ((readl(MC_ME_PRTN_N_STAT(partition)) &
		MC_ME_OUTPUT_STATUS) != 0x0)
		;

	/* lock the reset domain controller */
	reg_value = readl(RDC_RD1_CTRL_REGISTER) &
	    RDC_RD1_CTRL_UNLOCK_DISABLE;
	writel(RDC_RD1_CTRL_REGISTER, reg_value);
}

static void enable_a53(void)
{
	u32 core_entry = a53_entry_point & 0xfffffffc;
	u32 reg_value;
	u8 core_id = A53_CORE0;
	u8 partition = A53_PARTITION;

	/* Set the A53 entrypoint address before enabling the partition */
	writel (MC_ME_PRTN_N_CORE_M_ADDR(partition, core_id), core_entry);

	enable_partition(partition);

	/* enable core clock */
	writel (MC_ME_PRTN_N_CORE_M_PCONF(partition, core_id), 1);

	/* Partition peripherals are always enabled in partition 0 */
	writel (MC_ME_PRTN_N_PCONF(partition), 1);

	/* trigger hardware process */
	writel (MC_ME_PRTN_N_CORE_M_PUPD(partition, core_id), 1);

	/* write key sequence */
	writel (MC_ME_CTL_KEY_ADDR, MC_ME_CTL_KEY_VALUE);
	writel (MC_ME_CTL_KEY_ADDR, MC_ME_CTL_KEY_INVERTED_VALUE);

	/* wait for clock to be enabled */
	while ((readl(MC_ME_PRTN_N_CORE_M_STAT(partition, core_id)) &
		MC_ME_CORE_CLOCK_STAT_MASK) != 1)
		;

	while ((readl(MC_ME_PRTN_N_STAT(partition)) &
		MC_ME_CLOCK_ACTIVE) != 1)
		;

	/* pull the core out of reset and wait for it */
	reg_value = readl(RGM_PRST(partition)) &
	    RGM_PRST_RESET_CORE(partition, core_id);
	writel (RGM_PRST(partition), reg_value);

	while ((readl(RGM_PSTAT(partition)) &
		RGM_PRST_STATUS_CORE(partition, core_id)) != 0)
		;
}

int main(void)
{
	enable_a53();
	return 1;
}
