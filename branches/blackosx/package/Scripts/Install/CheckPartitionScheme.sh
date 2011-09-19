#!/bin/bash

echo "==============================================="
echo "Check the Partition Scheme: GPT, GPT/MBR or MBR?"
echo "************************************************"

# Receives passed value for the Target Disk
# for example: /dev/disk0s2
# Then looks for the following:
# First 8 bytes of the GPTdiskGPTHeader to identify a GUID partition table.
# Byte number 450 of the GPTdiskProtectiveMBR to identify ID of 'EE' to identify a GPT partition.
# Byte numbers 466, 482 & 498 of the GPTdiskProtectiveMBR to identify further partitions.
#
# Exit with value 1 for GPT, 2 for GPT/MBR and 3 for MBR. 
# Exit with value 0 if nothing is found - this shouldn't happen.?

if [ "$#" -eq 1 ]; then
	targetDisk="$1"
	echo "DEBUG: passed argument = $targetDisk"
else
	echo "Error - wrong number of values passed"
	exit 9
fi


partitiontable=$( dd 2>/dev/null if="$targetDisk" count=1 skip=1 | dd 2>/dev/null count=8 bs=1 | perl -ne '@a=split"";for(@a){printf"%02x",ord}' )
if [ "${partitiontable:0:16}" == "4546492050415254" ]; then	
	partitiontable=$( dd 2>/dev/null if="$targetDisk" count=1 | dd 2>/dev/null count=64 bs=1 skip=446 | perl -ne '@a=split"";for(@a){printf"%02x",ord}' )
	if [ "${partitiontable:8:2}" == "ee" ]; then
		echo "Found System ID 'EE' to identify GPT Partition"
		if [ "${partitiontable:40:2}" == "00" ] && [ "${partitiontable:72:2}" == "00" ] && [ "${partitiontable:104:2}" == "00" ]; then
			echo "Found System ID '00' for each remaining possible partition"
			partitiontable="GPT"
			echo "${partitiontable} found."
			echo "-----------------------------------------------"
			echo ""
			exit 1
	 	else
			partitiontable="GPT/MBR"
			echo "${partitiontable} found."
			echo "-----------------------------------------------"
			echo ""
			exit 2
		fi
	fi
else
	partitiontable="MBR"
	echo "${partitiontable} found."
	echo "-----------------------------------------------"
	echo ""
	exit 3
fi

echo "No partition table found."
echo "-----------------------------------------------"
echo ""
exit 0