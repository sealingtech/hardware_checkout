#!/bin/bash
source /mnt/networkshare/configs/configuration
mobo_serial=$(dmidecode -s baseboard-serial-number)
cpu_temp=$(ipmitool -I open sdr | grep CPU | awk {'print $4'})
system_temp=$(ipmitool -I open sdr | grep "PCH Temp" | awk {'print $4'})
fan3_rpm=$(ipmitool -I open sdr | grep "FAN3" | awk {'print $3'})
fana_rpm=$(ipmitool -I open sdr | grep "FANA" | awk {'print $3'})
fanb_rpm=$(ipmitool -I open sdr | grep "FANB" | awk {'print $3'})
exec > >(tee -ia /hardwarelogs/"$mobo_serial-$(date)")

echo "=====================Begin Testing: $(date) =============================="

echo "++++++++++++++++System Information+++++++++++++++++"
echo "Motherboard Serial Number: $mobo_serial"
echo "Starting CPU temperature: $cpu_temp"
echo "Starting System temperature: $system_temp"
echo "Starting FAN3 rpms: $fan3_rpm"
echo "Starting FANA rpms: $fana_rpm"
echo "Starting FANB rpms: $fanb_rpm"
echo ""
echo "++++++++++++++++Tests+++++++++++++++++++++++++++"

declare -A tests

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
egrep -wo 'vmx' /proc/cpuinfo  | sort | uniq | grep -q vmx
if [ $? = 1 ];
then
	echo "🤬: Failed virtualization processor check.  Please enable virtualization in the BIOS"
	SomethingFailed=true
	tests[virtualization]=🤬
else
	echo "👍: Passed Virtualization Check"
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


echo "++++++++ Ending Temperatures ++++++++++++++"
cpu_temp=$(ipmitool -I open sdr | grep CPU | awk {'print $4'})
system_temp=$(ipmitool -I open sdr | grep "PCH Temp" | awk {'print $4'})
fan3_rpm=$(ipmitool -I open sdr | grep "FAN3" | awk {'print $3'})
fana_rpm=$(ipmitool -I open sdr | grep "FANA" | awk {'print $3'})
fanb_rpm=$(ipmitool -I open sdr | grep "FANB" | awk {'print $3'})

echo "++++++++++++++++Ending System Information+++++++++++++++++"
echo "Starting CPU temperature: $cpu_temp"
echo "Starting System temperature: $system_temp"
echo "Starting FAN3 rpms: $fan3_rpm"
echo "Starting FANA rpms: $fana_rpm"
echo "Starting FANB rpms: $fanb_rpm"
echo ""
echo "++++++++++++++++Tests+++++++++++++++++++++++++++"



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
fi

serial_num=$(dmidecode -s baseboard-serial-number)
#echo "Enter chassis serial number"
#read serial_num
#echo "Chassis serial number $serial_num"

#echo "Enter the name of who built the system"
#read builder_name
#echo "Builder name: $builder_name"


#echo "Enter the name of the tester:"
#read tester_name
#echo "Tester name: $tester_name"

#make sure it doesn't quit until user presses enter
echo "Press enter to quit"
read ready

