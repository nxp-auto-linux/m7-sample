#!/bin/bash
#
# SPDX-License-Identifier:     BSD-3-Clause
#
# Copyright 2021 NXP
#
# This script create a bootable binary image containing both U-Boot and M7
# bootloader with the boot target being M7. The following steps are performed:
# - take a standard u-boot.s32 image
# - modify IVT header to set boot_target = M7
# - modify IVT header to set the start address
# - modify IVT header to set the new length
# - add the M7 binary to the configured offset
# With these settings, both U-Boot binary and M7 bootloader binary  are copied
# to SRAM, and M7 is the boot target.
#

hex2dec () {
	printf "%d" $1
}

int2bin () {
	local a=$1
	# write binary as little endian
	printf -v f '\\x%02x\\x%02x\\x%02x\\x%02x' $((a & 255)) $((a >> 8 & 255)) $((a >> 16 & 255)) $((a >> 24 & 255))
	printf "$f"
}

roundup () {
	local a=$1
	local b=$2
	printf "0x%x" $(( (a + b - 1) & ~(b - 1) ))
}

get_symbol_addr () {
	local symbol=$1
	local map=$2
	local tmp

	if ! grep -q -w "${symbol}" "${map}"; then
		exit 1
	fi
	tmp=$(grep -w "${symbol}" "${map}")
	printf "0x%x" $(echo ${tmp} | cut -d ' ' -f1)
}

on_exit () {
	echo Fail to read symbol from map file
	exit 1
}

check_file () {
	local file=$1

	if [ -z "${file}" ]; then
		echo "Error: Empty file"
		exit 1
	fi

	if [ ! -f "${file}" ]; then
		echo "Error: File \"$file\" does not exist"
		exit 1
	fi
}



# offsets for QSPI and SD/eMMC
boot_target_off1=0x28
boot_target_off2=0x1028

# this is the value read from offset 0x20/0x1020
# for Linux BSP it is always used 0x3200. Use this hard-coded.
app_header_off=0x3200

# offsets relative to IVT's Application Boot header
app_start_off=0x4
app_entry_off=0x8
app_size_off=0xC
app_code_off=0x40

uboot_off=$(roundup  $((app_header_off + app_code_off)) 512)

show_usage ()
{
	echo -e "\n Usage: "
	echo -e "  ${BASH_SOURCE[0]} [parameters]"
	echo "Parameters:"
	echo "    -i input IVT file, e.g. u-boot.s32 or fip.s32"
	echo "    -b m7 binary file, e.g. m7.bin"
	echo "    -m m7 map file, e.g. m7.map"
	echo "    -o output file (optional), If skip is used <input file>.m7"
	echo "    -h show this help"

	echo "Example"
	echo "./append_m7.sh -i u-boot.s32 -b build/m7.bin -m build/m7.map"
}


unset input m7_file m7_map output
while getopts ":hi:b:m:o:" input_params
do
	case $input_params in
		i) input="$OPTARG"
			;;
		b) m7_file="$OPTARG"
			;;
		m) m7_map="$OPTARG"
			;;
		o) output="$OPTARG"
			;;
		h)
			show_usage
			exit 1
			;;
		?)
			echo Invalid option
			show_usage
			exit 1
	esac
done

check_file "${input}"
check_file "${m7_file}"
check_file "${m7_map}"

if [ -z "${output}" ]; then
	output="${input}.m7"
fi

tmpfile="$(mktemp ./tmp.XXXXXX)"

# Read M7 entry point from the map file. This is the start of VTABLE
m7_bootloader_entry=$( get_symbol_addr "VTABLE" "${m7_map}" ) || on_exit

# Size needed for M7: code + stack.
m7_bin_size=0x2000


# M7 binary offset in the IVT binary
# M7 binary replaces the U-Boot binary in IVT, while U-Boot is shifted with
# the M7 size
m7_bin_off=$uboot_off
uboot_off_new=$((uboot_off + m7_bin_size))

padding=$(( m7_bin_off - app_header_off - app_code_off ))
ram_start=$((m7_bootloader_entry - padding))


rm -f "${output}"
# write from input file until uboot_off
dd of="${output}" if="${input}" bs=1 conv=notrunc seek=0 skip=0 count=$(hex2dec $uboot_off) status=none

# update boot target. M7 boot_target -> 0x0
printf \\x00 | dd of="${output}" bs=1 conv=notrunc seek=$(hex2dec $boot_target_off1) status=none
printf \\x00 | dd of="${output}" bs=1 conv=notrunc seek=$(hex2dec $boot_target_off2) status=none

# save the original entry point (A53 entry point)
dd of="${tmpfile}" if="${output}" bs=1 count=4 skip=$(hex2dec $((app_header_off + app_entry_off))) status=none

# update entry point
int2bin $m7_bootloader_entry | dd of="${output}" bs=1 conv=notrunc seek=$(hex2dec $((app_header_off + app_entry_off))) status=none

# update Ram start
int2bin $ram_start | dd of="${output}" bs=1 conv=notrunc seek=$(hex2dec $((app_header_off + app_start_off))) status=none

# read the original app code size from IVT header
blob_size=0x$(hexdump -n 4 -e '"%02X"' -s $((app_header_off + app_size_off)) ${output})
# update the size adding the newly added M7 binary size
# Note: the size should not be computed based on binary (u-boot.bin or fip.bin) size. This works for
# U-Boot, but not for fip.bin where only BL2 size is counted in IVT header
blob_size=$((blob_size + m7_bin_size))
int2bin $blob_size | dd of="${output}" bs=1 conv=notrunc seek=$(hex2dec $((app_header_off + app_size_off))) status=none

# write M7 bootloader
dd of="${output}" if="${m7_file}" bs=1 conv=notrunc seek=$(hex2dec $m7_bin_off) status=none

# restore the original A53 entry point into the M7 binary
# The A53 entry point is located in .data section in symbol a53_entry_point
# Its address is read from the m7 map file to compute the offset in binary file
# where the A53 entry point should be overwritten
a53_entry_point_addr=$( get_symbol_addr "a53_entry_point" "${m7_map}" ) || on_exit
a53_entry_point_offset=$((a53_entry_point_addr - m7_bootloader_entry))

dd of="${output}" if="${tmpfile}" bs=1 count=4 conv=notrunc seek=$(hex2dec $((m7_bin_off + a53_entry_point_offset))) status=none
rm "${tmpfile}"

# write u-boot from original file to the new offset
dd of="${output}" if="${input}" bs=1 conv=notrunc seek=$(hex2dec $uboot_off_new) skip=$(hex2dec $uboot_off) status=none


printf 'M7 Entry point   = 0x%x\n' $m7_bootloader_entry
printf 'A53 entry offset = 0x%x\n' $a53_entry_point_offset
printf 'RAM start        = 0x%x\n' $ram_start
printf 'App code size    = 0x%x\n' $blob_size

# How to update u-boot into the generated image:
# - write u-boot.bin at new offset
echo
echo "If you need to update u-boot.bin on the resulting image ("${output}")"
echo "run the following command:"
echo
echo dd of="${output}" if=\<u-boot or fip\>.bin bs=1 conv=notrunc seek=$(hex2dec $uboot_off_new)
echo

