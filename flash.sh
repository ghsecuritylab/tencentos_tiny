#!/bin/bash

#================================================================
#   Copyright (C) 2019年08月09日 肖飞 All rights reserved
#   
#   文件名称：flash.sh
#   创 建 者：肖飞
#   创建日期：2019年08月09日 星期五 10时59分21秒
#   修改日期：2019年09月23日 星期一 12时52分57秒
#   描    述：
#
#================================================================
opt_string="b:a:ed"

bin_file="build/tencentos_tiny.hex"
load_address="0x8000000"
erase_flash=0
debug=0
jlink_script="jlink.script"

function process_parameter() {
	local arguments="$1"
	local optarg="$2"
	
	#echo -e "[$0-$FUNCNAME:$LINENO]arguments:$arguments, optarg:$optarg"
	case $arguments in
		a)
			load_address="$optarg"
			echo "load_address:$load_address"
			;;
		b)
			bin_file="$optarg"
			echo "bin_file:$bin_file"
			;;
		e)
			erase_flash=1
			echo "bin_file:$bin_file"
			;;
		d)
			debug=1
			echo "bin_file:$bin_file"
			;;
		*)
			;;
	esac
}

function opt_parse() {
	local args=( "$@" )
	local ret=0
	local current_opt_index=1

	OPTIND=1
	OPTERR=0

	while getopts $opt_string arguments 2>/dev/null; do

		#echo "[$0-$FUNCNAME:$LINENO]\${#args[@]} is ${#args[@]}, \$OPTIND is $OPTIND, \$OPTERR is $OPTERR, \$arguments is $arguments, \$OPTARG is $OPTARG"
		OPTERR=0

		case $arguments in
			"?")
				ret=1
				break
				;;
			*)
				current_opt_index=$OPTIND
				process_parameter "$arguments" "$OPTARG"
				;;
		esac
	done

	#echo "[$0-$FUNCNAME:$LINENO]\${#args[@]} is ${#args[@]}, \$OPTIND is $OPTIND, \$OPTERR is $OPTERR, \$arguments is $arguments, \$OPTARG is $OPTARG"

	if test ${#args[@]} -gt $((current_opt_index - 1)); then
		ret=1
		echo -ne "[$0-$FUNCNAME:$LINENO]Usage:$FUNCNAME \"$opt_string\"\n\t"
		for((index = $current_opt_index - 1; index < ${#args[@]}; index++)); do
			echo -ne " ${args[$index]}"
		done
		echo
	fi

	return $ret
}

function gen_jlink_script_erase() {
	cat > "$jlink_script" << EOF
power on
Sleep 10
rx 10
unlock kinetis
erase
unlock kinetis
power off
q
EOF
}

function gen_jlink_script_flash() {
	cat > "$jlink_script" << EOF
power on
Sleep 10
rx 10
loadbin $bin_file $load_address
rx 10
power off
q
EOF
}

function gen_jlink_script_bootloader() {
	cat > "$jlink_script" << EOF
rx 10
r0
r1
q
EOF
}

function main() {
	opt_parse $@

	if [ $? -ne 0 ];then
		return
	fi

	if [ $erase_flash -eq 1 ];then
		gen_jlink_script_erase
		JLinkExe -Device "STM32F207VE" -IF "JTAG" -JTAGConf "-1,-1" -Speed "4000" -CommanderScript "$jlink_script"
	fi

	gen_jlink_script_flash
	JLinkExe -Device "STM32F207VE" -IF "JTAG" -JTAGConf "-1,-1" -Speed "4000" -CommanderScript "$jlink_script"

	rm "$jlink_script"

	if [ $debug -eq 1 ];then
		JLinkGDBServer -select USB -device STM32F207VE -endian little -if JTAG -speed 4000 -noir -noLocalhostOnly
	fi
}

main $@
