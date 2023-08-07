#!/bin/bash
#
# SPDX-License-Identifier:     BSD-3-Clause
#
# Copyright 2021-2022 NXP
#
# This script create a bootable binary image containing both TF-A and M7
# bootloader with the boot target being M7. The following steps are performed:
# - take a standard fip.s32 image
# - modify IVT header to set boot_target = M7
# - modify IVT header to set the start address
# - modify IVT header to set the new length
# - add the M7 binary to the configured offset
# With these settings, both TF-A binary and M7 bootloader binary  are copied
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

get_u32_val () {
	local file="$1"
	local offset="$2"
	printf "0x%s" $(od --address-radix=n --format=x4 --skip-bytes="$offset" --read-bytes=4 "$file")
}

get_ivt_offset () {
	local file="$1"
	local ivt_token="0x600001d1"
	local qspi_offset="0x0"
	local sd_offset="0x1000"
	local qspi_ivt_token="$(get_u32_val "$file" "$qspi_offset")"
	local sd_ivt_token="$(get_u32_val "$file" "$sd_offset")"

	if [ "$qspi_ivt_token" = "$ivt_token" ]
	then
		echo "$qspi_offset"
		return
	fi

	if [ "$sd_ivt_token" = "$ivt_token" ]
	then
		echo "$sd_offset"
		return
	fi

	>&2 echo "Failed to detect IVT offset"
}

# M7 VTABLE must be aligned to 128 bytes
VTABLE_ALIGN=128

# IVT header offsets
app_boot_header_off=0x20
boot_cfg_off=0x28

# Application Boot header offsets
app_start_off=0x4
app_entry_off=0x8
app_size_off=0xC
app_code_off=0x40

# Size needed for M7: code + stack.
m7_bin_size=0x2000

show_usage ()
{
	echo -e "\n Usage: "
	echo -e "  ${BASH_SOURCE[0]} [parameters]"
	echo "Parameters:"
	echo "    -i input IVT file, e.g. fip.s32"
	echo "    -b m7 binary file, e.g. m7.bin"
	echo "    -m m7 map file, e.g. m7.map"
	echo "    -o output file (optional), If skip is used <input file>.m7"
	echo "    -e show expected M7 entry point (optional). -b and -m are optional when using -e"
	echo "    -h show this help"

	echo "Example"
	echo "./append_m7.sh -i fip.s32 -b build/m7.bin -m build/m7.map"
}


unset input m7_file m7_map output show_expected_ep
while getopts ":hi:b:m:o:e" input_params
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
		e) show_expected_ep="true"
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

ivt_header_off=$(get_ivt_offset "${input}")
if [ -z "$ivt_header_off" ]
then
	exit 1
fi

# offsets for QSPI and SD/eMMC
boot_target_off=$((ivt_header_off + boot_cfg_off))

app_header_off=$(get_u32_val "${input}" $((ivt_header_off + app_boot_header_off)))
fip_off=$((app_header_off + app_code_off))

# M7 binary offset in the IVT binary
# M7 binary replaces the fip.bin binary in IVT, while fip.bin is shifted with
# the M7 size
m7_bin_off=$fip_off
fip_off_new=$((fip_off + m7_bin_size))

ram_start_orig=$(get_u32_val "${input}" $((app_header_off + app_start_off)))

ram_start=$((ram_start_orig - m7_bin_size))
# Align to VTABLE_ALIGN
expected_ep=$(roundup $ram_start $VTABLE_ALIGN)
m7_bin_padding=$((expected_ep - ram_start))
m7_bin_off=$((m7_bin_off + m7_bin_padding))

if test "${show_expected_ep}"; then
	printf "0x%x\n" "${expected_ep}"
	exit 0
fi

check_file "${m7_file}"
check_file "${m7_map}"

if [ -z "${output}" ]; then
	output="${input}.m7"
fi

tmpfile="$(mktemp ./tmp.XXXXXX)"
trap 'rm -f "$tmpfile"' EXIT

# Read M7 entry point from the map file. This is the start of VTABLE
m7_bootloader_entry=$( get_symbol_addr "VTABLE" "${m7_map}" ) || on_exit

rm -f "${output}"
# write from input file until fip_off
dd of="${output}" if="${input}" conv=notrunc seek=0 skip=0 count=$(hex2dec $fip_off) status=none iflag=count_bytes

# update boot target. M7 boot_target -> 0x0
printf \\x00 | dd of="${output}" conv=notrunc seek=$(hex2dec $boot_target_off) status=none oflag=seek_bytes


if [ "$(printf "%d" $m7_bootloader_entry)" -eq "$(printf "%d"  $expected_ep)" ]; then
	printf "Checking M7 entry point versus IVT memory layout: OK\n"
else
	printf "Error: \tM7 entry point is not correctly set to work with IVT %s\n" "${input}"
	printf "\tCurrent M7 entry point is 0x%x, while expected is 0x%x\n" ${m7_bootloader_entry} ${expected_ep}
	exit 1
fi

# save the original entry point (A53 entry point)
dd of="${tmpfile}" if="${output}" count=4 skip=$(hex2dec $((app_header_off + app_entry_off))) status=none iflag=skip_bytes,count_bytes

# update entry point
int2bin $m7_bootloader_entry | dd of="${output}" bs=1 conv=notrunc seek=$(hex2dec $((app_header_off + app_entry_off))) status=none

# update Ram start
int2bin $ram_start | dd of="${output}" bs=1 conv=notrunc seek=$(hex2dec $((app_header_off + app_start_off))) status=none

# read the original app code size from IVT header
blob_size=$(get_u32_val "${output}" $((app_header_off + app_size_off)))
# update the size adding the newly added M7 binary size
# Note: the size should not be computed based on binary (fip.bin) size.
blob_size=$((blob_size + m7_bin_size))
int2bin $blob_size | dd of="${output}" bs=1 conv=notrunc seek=$(hex2dec $((app_header_off + app_size_off))) status=none

# write M7 bootloader
dd of="${output}" if="${m7_file}" conv=notrunc seek=$(hex2dec $m7_bin_off) status=none oflag=seek_bytes

# restore the original A53 entry point into the M7 binary
# The A53 entry point is located in .data section in symbol a53_entry_point
# Its address is read from the m7 map file to compute the offset in binary file
# where the A53 entry point should be overwritten
a53_entry_point_addr=$( get_symbol_addr "a53_entry_point" "${m7_map}" ) || on_exit
a53_entry_point_offset=$((a53_entry_point_addr - m7_bootloader_entry))

dd of="${output}" if="${tmpfile}" count=4 conv=notrunc seek=$(hex2dec $((m7_bin_off + a53_entry_point_offset))) status=none oflag=seek_bytes

# write FIP from original file to the new offset
dd of="${output}" if="${input}" conv=notrunc seek=$(hex2dec $fip_off_new) skip=$(hex2dec $fip_off) status=none oflag=seek_bytes iflag=skip_bytes


printf 'M7 Entry point   = 0x%x\n' $m7_bootloader_entry
printf 'A53 entry offset = 0x%x\n' $a53_entry_point_offset
printf 'RAM start        = 0x%x\n' $ram_start
printf 'App code size    = 0x%x\n' $blob_size

# How to update FIP into the generated image:
# - write fip.bin at new offset
echo
echo "If you need to update fip.bin on the resulting image ("${output}")"
echo "run the following command:"
echo
echo dd of="${output}" if=\<fip.bin\> conv=notrunc seek=$(hex2dec $fip_off_new) oflag=seek_bytes
echo

