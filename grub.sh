#!/bin/bash

# logo
echo -e "Ubuntu Overssh Reinstallation: Update grub"

# check for root user
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

# default iso url
DEFAULT_ISO_URL='http://archive.ubuntu.com/ubuntu/dists/xenial/main/installer-amd64/current/images/netboot/mini.iso'

# check dependencies
echo "Checking dependencies...".
REQUIRE_COMMAND[0]='realpath'
REQUIRE_COMMAND[1]='mkisofs'
REQUIRE_COMMAND[2]='dirname'
REQUIRE_COMMAND[3]='awk'
REQUIRE_COMMAND[4]='cut'
REQUIRE_COMMAND[5]='head'
REQUIRE_COMMAND[6]='grep'
REQUIRE_COMMAND[7]='apt-get'
REQUIRE_COMMAND[8]='update-grub'
for command in "${REQUIRE_COMMAND[@]}"
do
  if ! type ${command} > /dev/null 2>&1; then
    echo "Please install '${command}' for continue installation"
    exit 1
  fi
done
echo "Done"

SCRIPT=`realpath $0`
PROJECTPATH=`dirname $SCRIPT`
CONFIGFILE=$PROJECTPATH/config
if [ ! -f $CONFIGFILE ]; then
  echo "Please create config file config"
  exit 1
fi

UBUNTUOVERSSHISO_FILE=$PROJECTPATH/ubuntu-overssh-reinstall.iso

if [ ! -f $UBUNTUOVERSSHISO_FILE ]; then
  echo "Please create image first."
  exit 1
fi

source $CONFIGFILE

apt-get install -y -qq grub-imageboot

if [ ! -f /etc/default/grub ]; then
  echo "Seems be grub dosnt install or not matched version"
  exit 1
fi

rm /boot/images -rf
mkdir -p /boot/images/
cp $UBUNTUOVERSSHISO_FILE /boot/images/iso.iso

update-grub

BOOTABLEGRUBNAME=`cat /boot/grub/grub.cfg | grep iso | head -n 1 | cut -d \" -f2`

if [ -z "$BOOTABLEGRUBNAME" ]; then
  echo "Seems be grub imageboot not work as expected. try manual"
  exit 1
fi

GRUBBACKUPFILE=$PROJECTPATH/grub.backup
if [ ! -f $GRUBBACKUPFILE ]; then
  cp /etc/default/grub $GRUBBACKUPFILE
fi

sed -i "s/GRUB_DEFAULT=0/GRUB_DEFAULT='$BOOTABLEGRUBNAME'/g" /etc/default/grub

update-grub

echo "1. Upload 'preseed.cfg' file for $PRESEED_URL"
echo " ==================================== "
cat $PROJECTPATH/preseed.cfg
echo " ==================================== "
echo "2. Reboot current machine and wait to init to ssh installer"
echo "3. Connect using ssh client ssh installer@$INTERFACE_IP"
echo "4. Your password is $PASSWORD"
