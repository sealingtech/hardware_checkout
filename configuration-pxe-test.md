# Setting up Mock for the first time
Mock is used to build the live image for booting into the test environment.  This process needs to be done on a Fedora 30 machine

```
sudo -s
dnf install mock livecd-iso-to-mediums
usermod -a -G mock admin
```

Next, we need to build the mock environment that will be used for Fedora-30.
```
mock -r fedora-30-x86_64 --init
mock -r fedora-30-x86_64 --install lorax-lmc-novirt vim-minimal pykickstart wget

Edit the configuration
vi /etc/mock/site-defaults.cfg

config_opts['rpmbuild_networking']. < set to True

sudo setenforce 0

```


# Building the image
Each time there is a change made to the image, enter into the mock Fedora-30 environment and cd to /builddir
```
sudo -s
mock -r fedora-30-x86_64 --shell --old-chroot
cd /builddir
```

Download the lastest kickstart file for the live environment.
```
wget https://raw.githubusercontent.com/sealingtech/hardware_checkout/master/flat-ks-live.ks
```

Open this file and modify the following section with the appropriate DNS server:
```
cat > /etc/resolv.conf << EOF
search st.lab
nameserver 172.16.100.1
EOF
```

This will ensure that the live environment builder is able to perform DNS lookups.

Make sure that /var/lmc is cleaned up if we are building a second time.  The livemedia-creator step will fail if this hasn't been done.
```
rm -rf /var/lmc
```

Run the livemedia-creator script to build out the ISO.
```
livemedia-creator --ks flat-ks-live.ks --no-virt --resultdir /var/lmc --project Fedora-test-Live --make-iso --volid Fedora-test-30 --iso-only --iso-name Fedora-test-30-x86_64.iso --releasever 30 --title Fedora-test-live --keep-image --kernel-args nopersistenthome
```



Once this process is complete, break out of the session with ctrl-a+d (that is ctrl a, then while still holding ctrl but not a, hit d).  Take the ISO image and build it into a PXE boot environment.  Copy this to the local TFTPboot server.

```
rm -rf tftpboot/
livecd-iso-to-pxeboot /var/lib/mock/fedora-30-x86_64/root/var/lmc/Fedora-test-30-x86_64.iso
\cp -f tftpboot/initrd.img /var/lib/tftpboot/fedora-live/
\cp -f tftpboot/vmlinuz /var/lib/tftpboot/fedora-live/
\cp -f tftpboot/pxelinux.0 /var/lib/tftpboot/
```

# Troubleshooting

This process is very susceptible to human errors in the scripting process.  Some troubleshooting tips.

## Complains about .pid errors

When you run the livemedia-creator command you see errors regarding anaconda.pid.  This occurs when a prior livemedia-creator finished unsuccessfully.  

```
08:50:33,652 INF main: /usr/sbin/anaconda 30.25.6-3.fc30
08:50:33,718 ERR main: Unable to create /var/run/anaconda.pid, exiting
```

To fix this issue, simply delete /var/run/anaconda.pid

```
/var/run/anaconda.pid
```

## Log files

Anaconda creates a number of log files during the build process and outputs these to /builddir/anaconda.  The can be a great start to troubleshooting.

## Log files complain about not being able to find Google.com

During the build process the kickstart currently does an nslookup of google.com.  For some reason, the config networking option doesn't properly set the DNS resolver.  
```
echo "ping google"
ping -c 1 google.com
echo "ping 8.8.8.8"
ping -c 1 8.8.8.8

ip a

nslookup google.com
```


## If all else fails:

To delete the mock chroot environment:

```
mock --clean fedora-30-x86_64
```

From there, start the entire process over from the beginning.
