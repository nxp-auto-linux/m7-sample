# Introduction

This project is a basic example of M7 bootloader.
IVT is set to make this M7 bootloader as boot target. Then M7 bootloader
enables A53 lockstep and start the A53 core0.

# How to build

Building sources
```shell
make CROSS_COMPILE=<armv7-cross-compiler->
```

Appending M7 binary over an existing binary with IVT header (e.g. u-boot.s32)
```shell
append_m7.sh -i <IVT binary> -b <m7 binary from this project> -m <m7 map file from this project>
```
m7 binary and m7 map from this project are generated after make command described above
For complete parameters list and description, use help option:
```shell
append_m7.sh -h
```

## How to Build example:
From the project's root folder, and having cross-compile binaries on path:

```shell
make CROSS_COMPILE=arm-none-eabi-
./append_m7.sh -i u-boot.s32 -b build/m7.bin -m build/m7.map
```

## Other build options

By default, M7 boots with A53 lockstep enabled.
To disable A53 lockstep, the flag DISABLE_A53_LOCKSTEP should be defined, by appending
```shell
-DDISABLE_A53_LOCKSTEP
```
to CFLAGS variable
