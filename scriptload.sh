#!/bin/sh
wget http://10.11.0.51:8080/share/scripts/hardware_checkout.sh
chmod +x hardware_checkout.sh

wget http://10.11.0.51:8080/share/scripts/wipe.sh
chmod +x wipe.sh

./hardware_checkout.sh
