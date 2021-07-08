#!/bin/bash

#first step: get the product type so the rest of the script knows the correct settings. This pulls the product descriptor that was applied to the node during the hardware initialization stage
product=$(sum -c GetDmiInfo| grep BBPD | awk {'print $4'} | tr -d '"')

#get config based on node type. Sensors are different between different models and are listed as such below
if ["$product" = "sn3000"];
	source /networkshare/configs/sn3000_configuration
	mobo_serial=$(dmidecode -s baseboard-serial-number)
	serial_num=$(dmidecode -s chassis-serial-number)
	cpu_temp=$(ipmitool -I open sdr | grep CPU | awk {'print $4'})
	system_temp=$(ipmitool -I open sdr | grep "PCH Temp" | awk {'print $4'})
	fan3_rpm=$(ipmitool -I open sdr | grep "FAN3" | awk {'print $3'})
	fana_rpm=$(ipmitool -I open sdr | grep "FANA" | awk {'print $3'})
	fanb_rpm=$(ipmitool -I open sdr | grep "FANB" | awk {'print $3'})
	declare -A tests
	fi
	
if ["$product" = "sn7000"];
	source /networkshare/configs/sn7000_configuration
	mobo_serial=$(dmidecode -s baseboard-serial-number)
	serial_num=$(dmidecode -s chassis-serial-number)
	cpu_temp=$(ipmitool -I open sdr | grep CPU | awk {'print $4'})
	system_temp=$(ipmitool -I open sdr | grep "System Temp" | awk {'print $4'})
	fan1_rpm=$(ipmitool -I open sdr | grep "FAN1" | awk {'print $3'})
	fan2_rpm=$(ipmitool -I open sdr | grep "FAN2" | awk {'print $3'})
	fan3_rpm=$(ipmitool -I open sdr | grep "FAN3" | awk {'print $3'})	
	fan4_rpm=$(ipmitool -I open sdr | grep "FAN4" | awk {'print $3'})
	fana_rpm=$(ipmitool -I open sdr | grep "FANA" | awk {'print $3'})
	fanb_rpm=$(ipmitool -I open sdr | grep "FANB" | awk {'print $3'})
	declare -A tests
	fi






#run nic firmware update for sn3000
if ["$product" = "sn3000"];
	wget -r -nH --cut-dirs=4 --no-parent http://10.16.0.2:8080/share/automation/sn3000/nic_update/
	chmod +x FWUpdate.sh nvmupdate64e
	tests[nicfirmware]=👍
	nicversion=$(ethtool -i eno7 | grep firmware-version)
	correctfirmware="firmware-version: 4.11 0x80002044 1.2527.0"
	if [ "$nicversion" = "$correctfirmware" ];
	then
		echo "👍: NIC Firmware Check Passed: Firmware is up-to-date"
		
	else
		tests[nicfirmware]=🤬
		echo "🤬: NIC Firmware Check Failed: Beginning NIC Firmware Update"
		./FWUpdate.sh
		echo "Rebooting system NOW"
		reboot		
	fi
	fi

#update RAID card firmware for SN7000. Could be reused for any system with a Megaraid Card, or modified if a configuration other than JBOD was desired
if [ "$product" = "sn7000" ];
then
	tests[megaraidfirmware]=👍
	raidversion=$(storcli64 /c0 show all| grep 'Firmware Version' | awk {'print $4'})

	correctfirmware="5.170.00-3513"
	echo "Installed firmware version is: $raidversion"
	echo "Latest firmare is: $correctfirmware"

	if [ "$raidversion" = "$correctfirmware" ];
	then
		echo "👍: Megaraid 9460-16i firmware is up-to-date"

	else
		tests[megaraidfirmware]=🤬
		echo "🤬: Megaraid 9460-16i Firmware is NOT up-to-date: Beginning Firmware Update Process"
		echo "Copying firmware to local system..."
		cp /networkshare/megaraid/9460-16i_nopad.rom /
		echo "Flashing firmware ROM to card..."
		storcli64 /c0 download file=9460-16i_nopad.rom resetnow
		echo "Megaraid firmware update complete!"

		fi
	#update megaraid card configuration to use JBOD mode
	#delete existing config on controller 0. Must be done prior to applying new one
	storcli64 /c0 delete config
	
	#set controller 0 to jbod mode
	storcli64 /c0 set autoconfig=jbod
	
	#set all drives in the quad bay enclosuers to JBOD
	storcli64 /c0/eall/sall set jbod
	
	#set all drives direct attached to controller to JBOD (rear dual bay(s))
	storcli64 /c0/sall set jbod
	fi





exec > >(tee -ia /networkshare/hardwarelogs/"$serial_num")

echo "=====================Begin Testing: $(date) =============================="


if ["$product" = "sn3000"];
	echo "++++++++++++++++System Information+++++++++++++++++"
	echo "Chassis Serial Number: $serial_num"
	echo "Motherboard Serial Number: $mobo_serial"
	echo "Starting CPU temperature: $cpu_temp"
	echo "Starting System temperature: $system_temp"
	echo "Starting FAN3 rpms: $fan3_rpm"
	echo "Starting FANA rpms: $fana_rpm"
	echo "Starting FANB rpms: $fanb_rpm"
	echo ""
	echo "++++++++++++++++Tests+++++++++++++++++++++++++++"
	fi
	
if ["$product" = "sn7000"];
	echo "++++++++ Ending Temperatures ++++++++++++++"
	cpu_temp=$(ipmitool -I open sdr | grep CPU | awk {'print $4'})
	system_temp=$(ipmitool -I open sdr | grep "System Temp" | awk {'print $4'})
	fan1_rpm=$(ipmitool -I open sdr | grep "FAN1" | awk {'print $3'})
	fan2_rpm=$(ipmitool -I open sdr | grep "FAN2" | awk {'print $3'})
	fan3_rpm=$(ipmitool -I open sdr | grep "FAN3" | awk {'print $3'})	
	fan4_rpm=$(ipmitool -I open sdr | grep "FAN4" | awk {'print $3'})
	fana_rpm=$(ipmitool -I open sdr | grep "FANA" | awk {'print $3'})
	fanb_rpm=$(ipmitool -I open sdr | grep "FANB" | awk {'print $3'})
	
	echo "++++++++++++++++Ending System Information+++++++++++++++++"
	echo "Starting CPU temperature: $cpu_temp"
	echo "Starting System temperature: $system_temp"
	echo "Starting FAN1 rpms: $fan1_rpm"
	echo "Starting FAN2 rpms: $fan2_rpm"
	echo "Starting FAN3 rpms: $fan3_rpm"
	echo "Starting FAN4 rpms: $fan4_rpm"
	echo "Starting FANA rpms: $fana_rpm"
	echo "Starting FANB rpms: $fanb_rpm"
	echo ""
	echo "++++++++++++++++Tests+++++++++++++++++++++++++++"
	fi


SomethingFailed=false


echo "++++++++Ensure fans are connected and working+++++++++++++"

tests[fans]=👍

for i in ${fans[@]};
do
        echo "Checking for fan $i"
        ipmitool -I open sdr | grep $i | awk {'print $3'} | grep -q no
        if [ $? = 0 ];
        then
                echo "🤬: Fan check failed: Fan $i missing"
                SomethingFailed=true
                tests[fans]=🤬
        else
                echo "👍: Fan Check Passed: Fan $i present"
        fi
done

echo "+++++++++++Starting temperatures below 80 celsius++++++++++++"
tests[starting_temps]=👍

for i in "${temp_sensors[@]}";
do
        echo "Checking for sensor $i"
        temp=$(ipmitool -I open sdr | grep "$i" | awk {'print $4'})
        if [ $temp -gt 80 ];
        then
                echo "🤬: Starting temperatures failed on sensor: $i"
                SomethingFailed=true
                tests[starting_temps]=🤬
        else
                echo "👍: Starting temperatures passed on sensor: $i temp: $temp"
        fi
done


echo "+++++++Check for the correct amount of memory++++++++"

if [ $(free -g | grep Mem  | awk {'print $2'}) -ne $expected_memory ];
then
        echo "🤬: Failed memory check"
        SomethingFailed=true
        tests[memory]=🤬
else
        echo "👍: passed memory check"
        tests[memory]=👍
fi


echo "+++++++Check to make sure all disks are present++++++++"

tests[disks]=👍

for i in ${disks[@]};
do
        echo "Checking for disk $i"
        lsscsi | grep -q $i
        if [ $? = 1 ];
        then
                echo "🤬: Failed disk check: Disk $i missing"
                DiskFailed=true
                SomethingFailed=true
                tests[disks]=🤬
        else
                echo "👍: Passed disk check: Disk $i present"
        fi
done


echo "+++++++++++Check to make sure Virtualization has been enabled++++++++++++"

tests[virtualization]=👍

#There is a separate section for the SN7000 because AMD systems report virtualization extensions as 'svm' while intel systems like the SN3000 report 'vmx'
if ["$product" = "sn3000"];
	egrep -wo 'vmx' /proc/cpuinfo  | sort | uniq | grep -q vmx
	if [ $? = 1 ];
	then
		echo "🤬: Failed virtualization processor check.  Please enable virtualization in the BIOS"
		SomethingFailed=true
		tests[virtualization]=🤬
	else
		echo "👍: Passed Virtualization Check"
	fi
	fi

if ["$product" = "sn7000"];
	egrep -wo 'svm' /proc/cpuinfo  | sort | uniq | grep -q vmx
	if [ $? = 1 ];
	then
		echo "🤬: Failed virtualization processor check.  Please enable virtualization in the BIOS"
		SomethingFailed=true
		tests[virtualization]=🤬
	else
		echo "👍: Passed Virtualization Check"
	fi
	fi



echo "+++++++++++Check to make sure SR-IOV has been enabled++++++++++++"

tests[sriov]=👍
lspci -vvv -s $pciaddress | grep -q SR-IOV
if [ $? = 1 ];
then
        echo "🤬 : Failed SR-IOV check.  Please enable SR-IOV in the BIOS"
        SomethingFailed=true
        tests[sriov]=🤬
else
        echo "👍: Passed sriov Check"
fi

echo "++++++++++Starting disk wipe++++++++++"

./wipe.sh $product &

echo "+++++++Running Prime95 for $prime95_duration and getting temperatures++++++++"

timeout $prime95_duration mprime -t > /dev/null 2>&1

echo "+++++++++++Checking temperatures again, ensuring below 80c++++++++++++"

tests[ending_temps]=👍

for i in "${temp_sensors[@]}";
do
        echo "Checking for sensor $i"
        temp=$(ipmitool -I open sdr | grep "$i" | awk {'print $4'})
        if [ $temp -gt 80 ];
        then
                echo "🤬: Ending temperatures failed on sensor: $i"
                SomethingFailed=true
                tests[ending_temps]=🤬
        else
                echo "👍: Ending temperatures passed on sensor: $i  temp: $temp"
        fi
done

if ["$product" = "sn3000"];
	echo "++++++++ Ending Temperatures ++++++++++++++"
	cpu_temp=$(ipmitool -I open sdr | grep CPU | awk {'print $4'})
	system_temp=$(ipmitool -I open sdr | grep "PCH Temp" | awk {'print $4'})
	fan3_rpm=$(ipmitool -I open sdr | grep "FAN3" | awk {'print $3'})
	fana_rpm=$(ipmitool -I open sdr | grep "FANA" | awk {'print $3'})
	fanb_rpm=$(ipmitool -I open sdr | grep "FANB" | awk {'print $3'})
	
	echo "++++++++++++++++Ending System Information+++++++++++++++++"
	echo "Final CPU temperature: $cpu_temp"
	echo "Final System temperature: $system_temp"
	echo "Final FAN3 rpms: $fan3_rpm"
	echo "Final FANA rpms: $fana_rpm"
	echo "Final FANB rpms: $fanb_rpm"
	echo ""
	echo "++++++++++++++++Tests+++++++++++++++++++++++++++"
	fi
	
if ["$product" = "sn7000"];
	echo "++++++++ Ending Temperatures ++++++++++++++"
	cpu_temp=$(ipmitool -I open sdr | grep CPU | awk {'print $4'})
	system_temp=$(ipmitool -I open sdr | grep "System Temp" | awk {'print $4'})
	fan1_rpm=$(ipmitool -I open sdr | grep "FAN1" | awk {'print $3'})
	fan2_rpm=$(ipmitool -I open sdr | grep "FAN2" | awk {'print $3'})
	fan3_rpm=$(ipmitool -I open sdr | grep "FAN3" | awk {'print $3'})	
	fan4_rpm=$(ipmitool -I open sdr | grep "FAN4" | awk {'print $3'})
	fana_rpm=$(ipmitool -I open sdr | grep "FANA" | awk {'print $3'})
	fanb_rpm=$(ipmitool -I open sdr | grep "FANB" | awk {'print $3'})
	
	echo "++++++++++++++++Ending System Information+++++++++++++++++"
	echo "Final CPU temperature: $cpu_temp"
	echo "Final System temperature: $system_temp"
	echo "Final FAN1 rpms: $fan1_rpm"
	echo "Final FAN2 rpms: $fan2_rpm"
	echo "Final FAN3 rpms: $fan3_rpm"
	echo "Final FAN4 rpms: $fan4_rpm"
	echo "Final FANA rpms: $fana_rpm"
	echo "Final FANB rpms: $fanb_rpm"
	echo ""
	echo "++++++++++++++++Tests+++++++++++++++++++++++++++"
	fi


echo "+++Final results!!!!!!+++"
echo "++++Test Summary+++"
for i in ${!tests[@]};
do
        echo "Test: $i passed?:  ${tests[$i]}"
done

if [ "$SomethingFailed" = true ];
then
        echo "🤮 🤮 🤮 🤮 🤮 🤮 🤮 🤮  One or more tests failed  🤮 🤮 🤮 🤮 🤮 🤮 🤮"
else
        echo "😎 😎 😎 😎 😎 😎 😎 😎  All tests passed  😎 😎 😎 😎 😎 😎 😎"
	ipmitool  raw 0x30 0x0d
fi

