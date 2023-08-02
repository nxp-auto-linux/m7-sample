# Introduction

This project is a basic example of M7 bootloader.
IVT is set to make this M7 bootloader as boot target. Then M7 bootloader
enables A53 lockstep and start the A53 core0.

# How to build

Building sources
```shell
make CROSS_COMPILE=<armv7-cross-compiler-> compile
```

## How to Build example:
From the project's root folder, and having cross-compile binaries on path:

### ARM Trusted Firmware
```shell
make CROSS_COMPILE=arm-none-eabi- A53_BOOTLOADER=fip.s32
```
Above commands will generate `fip.s32.m7` file which has to be placed on SDCard instead of
usual `fip.s32`.

>**Note**
> Don't forget to leave some space for this bootloader when compiling A-TF. This is usually done
> using **FIP_OFFSET_DELTA=0x2000** compilation parameter.

## Other build options

By default, M7 boots with A53 lockstep enabled.
To disable A53 lockstep, the flag DISABLE_A53_LOCKSTEP should be added to `make` command.
```shell
make DISABLE_A53_LOCKSTEP=1
```
