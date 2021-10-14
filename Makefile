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

ifdef START_ADDR
CFLAGS += -DCUSTOM_START_ADDR=$(START_ADDR)
endif

ASFLAGS := $(CFLAGS)

$(BUILD)/%.ld: %.ld.S
	$(CC) -E -P $(CFLAGS) -o $@ $<

$(BUILD)/%.o: src/%.S
	$(CC) $(ASFLAGS) -c -o $@ $<

$(BUILD)/%.o: src/%.c
	$(CC) $(CFLAGS) -c -o $@ $<

.PHONY: all

all: builddir $(BUILD)/m7.elf

$(BUILD)/m7.elf: $(OBJ) $(LINKER_FILE)
	$(LD) $(LDFLAGS) -Map=$(BUILD)/m7.map -o $@ $(OBJ)
	$(OBJCOPY) -j .vtable -j .data -j .text -O binary $(BUILD)/m7.elf $(BUILD)/m7.bin
	$(OBJDUMP) -D $(BUILD)/m7.elf > $(BUILD)/m7.dump

clean:
	rm -rf $(BUILD)

builddir:
	mkdir -p $(BUILD)
