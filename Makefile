#
# SPDX-License-Identifier:     BSD-3-Clause
#
# Copyright 2021 NXP
#

CFLAGS = -g -mcpu=cortex-m7 -mthumb -mlittle-endian -fomit-frame-pointer -Wall -Iinclude

BUILD := build
LINKER_FILE := $(BUILD)/project.ld
LDFLAGS := -pie -Bstatic  --no-dynamic-linker -T $(LINKER_FILE)

CC := $(CROSS_COMPILE)gcc
LD := $(CROSS_COMPILE)ld
OBJCOPY:= $(CROSS_COMPILE)objcopy
OBJDUMP:= $(CROSS_COMPILE)objdump

SOURCE := $(wildcard src/*.c)
SOURCE += $(wildcard src/*.S)
OBJ := $(filter %.o,$(patsubst src/%.c,$(BUILD)/%.o,$(SOURCE)) \
	+       $(patsubst src/%.S,$(BUILD)/%.o,$(SOURCE)))
ELF := $(BUILD)/m7.elf
ELF_MAP := $(patsubst %.elf,%.map, $(ELF))
ELF_BIN := $(patsubst %.elf,%.bin, $(ELF))
ELF_DUMP := $(patsubst %.elf,%.dump, $(ELF))

ifeq (,$(findstring clean,$(MAKECMDGOALS))$(findstring compile,$(MAKECMDGOALS)))
ifeq ("$(wildcard $(A53_BOOTLOADER))","")
$(error "Please specify the bootloader binary using A53_BOOTLOADER argument.\
	E.g.: make A53_BOOTLOADER=u-boot.s32")
endif

CFLAGS += -DCUSTOM_START_ADDR=$(shell $(CURDIR)/append_m7.sh -e -i $(A53_BOOTLOADER))
A53_BOOTLOADER_OUT := $(A53_BOOTLOADER).m7
endif

ifdef DISABLE_A53_LOCKSTEP
CFLAGS += -DDISABLE_A53_LOCKSTEP
endif

ASFLAGS := $(CFLAGS)

.PHONY: all compile $(A53_BOOTLOADER_OUT)

all: $(BUILD) $(A53_BOOTLOADER_OUT)

compile: $(BUILD) $(ELF)

$(A53_BOOTLOADER_OUT): $(A53_BOOTLOADER) $(ELF)
	@printf "  [APP]\t$@ <- $<\n"
	@$(CURDIR)/append_m7.sh -i $< -b $(ELF_BIN) -m $(ELF_MAP)

$(BUILD)/%.ld: %.ld.S
	@printf "  [CC]\t$@ <- $<\n"
	@$(CC) -E -P $(CFLAGS) -o $@ $<

$(BUILD)/%.o: src/%.S
	@printf "  [CC]\t$@ <- $<\n"
	@$(CC) $(ASFLAGS) -c -o $@ $<

$(BUILD)/%.o: src/%.c
	@printf "  [CC]\t$@ <- $<\n"
	@$(CC) $(CFLAGS) -c -o $@ $<

$(ELF): $(OBJ) $(LINKER_FILE)
	@printf "  [LD]\t$@ <- $<\n"
	@$(LD) $(LDFLAGS) -Map=$(ELF_MAP) -o $@ $(OBJ)
	@$(OBJCOPY) -j .vtable -j .data -j .text -O binary $@ $(ELF_BIN)
	@$(OBJDUMP) -D $@ > $(ELF_DUMP)

$(BUILD):
	@printf "  [MK]\t$(BUILD)\n"
	@mkdir -p $(BUILD)

clean:
	@printf "  [RM]\t$(BUILD)\n"
	@rm -rf $(BUILD)


