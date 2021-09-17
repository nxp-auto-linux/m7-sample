/*
 * SPDX-License-Identifier:     BSD-3-Clause
 *
 * Copyright 2021 NXP
 */

#ifndef __REGISTERS_DEFS_H
#define __REGISTERS_DEFS_H

/* The RDC_RD1_STAT_REGISTER offset from the RDC base address */
#define RDC_RD1_STAT_REGISTER_OFFSET (0x84)


/* A53 CLUSTER GPR registers */
#define A53_CLUSTER_GPR_BASE_ADDR           (0x4007C400UL)
#define A53_CLUSTER_GPR06                   (A53_CLUSTER_GPR_BASE_ADDR + 0x18)
#define A53_CLUSTER_CA53_LOCKSTEP_ENABLE    (0x00000001U)

#define MC_ME_BASE_ADDR             (0x40088000UL)
#define MC_ME_CORE_CLOCK_STAT_MASK  0x1

/* MC_ME registers. */
#define MC_ME_CTL_KEY_ADDR              (MC_ME_BASE_ADDR)
#define MC_ME_CTL_KEY_VALUE             (0x00005AF0)
#define MC_ME_CTL_KEY_INVERTED_VALUE    (0x0000A50F)
#define MC_ME_PARTITION_CLOCK_ENABLE    (0x00000001U)
#define MC_ME_TRIGGER_PROCESS           (0x00000001U)
#define MC_ME_OUTPUT_PARTITION          (0xFFFFFFFD)
#define MC_ME_OUTPUT_STATUS             (0x4)
#define MC_ME_CLOCK_ACTIVE              (0x1)
#define MC_ME_MODE_STAT                 (MC_ME_BASE_ADDR + 0xC)
#define MC_ME_MODE_STAT_PREVMODE        (0x00000001)

/* MC_ME partition definitions */
#define MC_ME_PRTN_N(n)             (MC_ME_BASE_ADDR + 0x100 + (n) * 0x200)
#define MC_ME_PRTN_N_PCONF(n)       (MC_ME_PRTN_N(n))
#define MC_ME_PRTN_N_PUPD(n)        (MC_ME_PRTN_N(n) + 0x4)
#define MC_ME_PRTN_N_STAT(n)        (MC_ME_PRTN_N(n) + 0x8)
#define MC_ME_PRTN_N_CLK_STATUS(n)  (MC_ME_PRTN_N(n) + 0x10)
#define MC_ME_PRTN_N_CLK_ENABLE(n)  (MC_ME_PRTN_N(n) + 0x30)

/* MC_ME partition n core m definitions. */
#define MC_ME_PRTN_N_CORE_M(n, m)   (MC_ME_BASE_ADDR + 0x140 + \
                                    (n) * 0x200 + (m) * 0x20)
#define MC_ME_PRTN_N_CORE_M_PCONF(n, m) (MC_ME_PRTN_N_CORE_M(n, m))
#define MC_ME_PRTN_N_CORE_M_PUPD(n, m)  (MC_ME_PRTN_N_CORE_M(n, m) + 0x4)
#define MC_ME_PRTN_N_CORE_M_STAT(n, m)  (MC_ME_PRTN_N_CORE_M(n, m) + 0x8)
#define MC_ME_PRTN_N_CORE_M_ADDR(n, m)  (MC_ME_PRTN_N_CORE_M(n, m) + 0xC)

/* MC_RGM registers */
#define MC_RGM_BASE_ADDR (0x40078000UL)

#define RGM_DES             (MC_RGM_BASE_ADDR + 0x0)
#define RGM_DES_POR         (0x00000001)

#define RGM_FES             (MC_RGM_BASE_ADDR + 0x8)
#define RGM_FES_EXT         (0x00000001)

#define RGM_PRST(per)       (MC_RGM_BASE_ADDR + 0x40 + (per) * 0x8)
#define RGM_PSTAT(per)      (MC_RGM_BASE_ADDR + 0x140 + (per) * 0x8)

#define RGM_PRST_CLUSTER           (0xFFFFFFFE)
#define RGM_PSTAT_RESET_STATE      (0x1)
#define RGM_PRST_RESET_CORE(n, m)  (~(1 << (m + n)))
#define RGM_PRST_STATUS_CORE(n, m) ((1 << (m + n)))


/* RDC registers */
#define RDC_BASE_ADDR (0x40080000UL)

#define RDC_RD1_CTRL_REGISTER  (RDC_BASE_ADDR + 0x4)
#define RDC_RD1_STAT_REGISTER  (RDC_BASE_ADDR + RDC_RD1_STAT_REGISTER_OFFSET)

#define RDC_RD1_CTRL_UNLOCK_ENABLE (0x80000000)
#define RDC_RD1_CTRL_UNLOCK_DISABLE (~(0x80000000))
#define RDC_RD1_XBAR_INTERFACE_DISABLE (~(0x8))
#define RDC_RD1_XBAR_INTERFACE_STAT   (0x10U)

/* MSCM registers */
#define MSCM_BASEADDRESS             (0x40198000UL)
#define MSCM_CPXNUM_REG              (MSCM_BASEADDRESS + 0x04UL)
#define MSCM_IRCP4ISR1               (MSCM_BASEADDRESS + 0x288UL)

/*STM registers*/
#define STM_0_BASEADDR               ((uint32)0x4011C000UL)
#define STM_0_CNT                    (STM_0_BASEADDR + 0x04UL)
#define STM_0_CHANNEL0_IF            (STM_0_BASEADDR + 0x14UL)

#endif
