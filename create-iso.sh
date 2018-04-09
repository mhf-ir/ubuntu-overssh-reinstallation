#!/bin/bash

# logo
echo -e "Ubuntu Overssh Reinstallation: Create iso file"

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

source $CONFIGFILE

ISO_FILE=$PROJECTPATH/mini.iso

if [ ! -f $ISO_FILE ]; then
  echo "File mini.iso not found. Download it $DEFAULT_ISO_URL"
  exit 1
fi

# copy iso
umount /mnt/ubuntu-overssh-iso 2> /dev/null
mkdir -p /mnt/ubuntu-overssh-iso
mount -o loop $ISO_FILE /mnt/ubuntu-overssh-iso 2> /dev/null
rm -rf $PROJECTPATH/ubuntu-overssh-iso
mkdir $PROJECTPATH/ubuntu-overssh-iso
cp -rT /mnt/ubuntu-overssh-iso $PROJECTPATH/ubuntu-overssh-iso

# create preseed
cp $PROJECTPATH/preseed.cfg.template $PROJECTPATH/ubuntu-overssh-iso/preseed.cfg

# replace vairables
sed -i 's/timeout 0/timeout 30/g' $PROJECTPATH/ubuntu-overssh-iso/prompt.cfg
sed -i 's/timeout 0/timeout 30/g' $PROJECTPATH/ubuntu-overssh-iso/isolinux.cfg

sed -i "s/INTERFACE_DEV/$INTERFACE_DEV/g" $PROJECTPATH/ubuntu-overssh-iso/preseed.cfg
sed -i "s/INTERFACE_IP/$INTERFACE_IP/g" $PROJECTPATH/ubuntu-overssh-iso/preseed.cfg
sed -i "s/INTERFACE_NAMESERVERS/$INTERFACE_NAMESERVERS/g" $PROJECTPATH/ubuntu-overssh-iso/preseed.cfg
sed -i "s/INTERFACE_NETMASK/$INTERFACE_NETMASK/g" $PROJECTPATH/ubuntu-overssh-iso/preseed.cfg
sed -i "s/INTERFACE_GATEWAY/$INTERFACE_GATEWAY/g" $PROJECTPATH/ubuntu-overssh-iso/preseed.cfg
sed -i "s/COUNTRY_LOWER/$COUNTRY_LOWER/g" $PROJECTPATH/ubuntu-overssh-iso/preseed.cfg
sed -i "s/COUNTRY/$COUNTRY/g" $PROJECTPATH/ubuntu-overssh-iso/preseed.cfg
sed -i "s/HOSTNAME/$HOSTNAME/g" $PROJECTPATH/ubuntu-overssh-iso/preseed.cfg
sed -i "s/DOMAIN/$DOMAIN/g" $PROJECTPATH/ubuntu-overssh-iso/preseed.cfg
sed -i "s/PASSWORD/$PASSWORD/g" $PROJECTPATH/ubuntu-overssh-iso/preseed.cfg

sed -i "s#append #append priority=critical auto=true preseed/url=$PRESEED_URL netcfg/hostname=$HOSTNAME netcfg/domain=$DOMAIN interface=$INTERFACE_DEV netcfg/disable_dhcp=true netcfg/get_ipaddress=$INTERFACE_IP netcfg/get_netmask=$INTERFACE_NETMASK netcfg/get_gateway=$INTERFACE_GATEWAY netcfg/get_nameservers=$INTERFACE_NAMESERVERS #g" $PROJECTPATH/ubuntu-overssh-iso/txt.cfg

cp $PROJECTPATH/ubuntu-overssh-iso/preseed.cfg $PROJECTPATH/preseed.cfg

mkisofs -D -r -V UBUNTU_SERVER -cache-inodes -J -l -b isolinux.bin -c boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -o $PROJECTPATH/ubuntu-overssh-reinstall.iso $PROJECTPATH/ubuntu-overssh-iso

echo "Your network iso is ready '$PROJECTPATH/ubuntu-overssh-reinstall.iso'"
