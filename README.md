# Ubuntu Overssh Reinstallation

If your ISP/Datacenter dosn't provide standard or trusted iso for your server. Get ugly server from it with installed version of Ubuntu server.

I have same situation installed ubuntu has bad partition table or huge list of stupid package installed. Datacenter network is my primary concern or it's really cheap price but administrators dosn't care. What should i do? That's my way to solve this issue easily.

Ask them to install ubuntu server what ever is it. re install it over ssh.

Create your own netiso and reinstall it over ssh. You can partion yor server as you desire. And set more configuration using [ubuntu preseed](https://help.ubuntu.com/lts/installation-guide/armhf/apbs02.html) just over ssh; no kvm/ipmi/vnc required.

### Requirement

1. Installed ubuntu version on server via ssh access
2. Clone this repo to your server
3. Copy `config.sample` to `config` file and edit field by field exactly:
    ```
    # country
    COUNTRY='IR'

    # network: check network before create iso file
    INTERFACE_DEV='eth0'
    INTERFACE_IP='10.1.1.100'
    INTERFACE_NETMASK='255.255.255.0'
    INTERFACE_GATEWAY='10.1.1.1'
    INTERFACE_NAMESERVERS='4.2.2.4'

    # preseed file: upload created preseed.cfg to your own host before reboot system
    PRESEED_URL="http://yourserver.tld/preseed.cfg"

    # ssh installer password
    PASSWORD="tHISiSpASSWORD"

    # hostname and domain
    HOSTNAME="${INTERFACE_IP//\./\-}"
    DOMAIN="servers.domain.org"

    # lowercase of country code dont change it
    COUNTRY_LOWER="${COUNTRY,,}"
    ```
4. Upload your `preseed.cfg` file to your own host.

#### Find Predictable Network Interface Names

If your current installation of ubuntu not using **Predictable Network Interface Names** you can find out the name by using this command for example for `eth0`:

```
udevadm test /sys/class/net/eth0 2>/dev/null | grep ID_NET_NAME_
ID_NET_NAME_MAC=enxd4bed95f24db
ID_NET_NAME_PATH=enp7s0
```
You can use `enp7s0` as predictable network interface name.

#### Clone repository
```
cd /tmp
git clone https://github.com/mhf-ir/ubuntu-overssh-reinstallation.git
cd ubuntu-overssh-reinstallation
```
#### Config
See `config.sample` and change it.
⚠ Carefull about your network settings. It's can hold your server until get new kvm/ipmi/vnc to restore the ssh again.
```
cp config.sample config
vim config
```
#### Download network mini iso from ubuntu website
```
wget http://archive.ubuntu.com/ubuntu/dists/xenial/main/installer-amd64/current/images/netboot/mini.iso
```
#### Build iso
Remember you must do as root user
```
./create-iso.sh
...
Your network iso is ready '/tmp/ubuntu-overssh-reinstallation/ubuntu-overssh-reinstall.iso'
```
#### Update grub imageboot
Remember you must do as root user also
```
./grub.sh
...
Your password is tHISiSpASSWORD
```
#### Upload your preseed file
Upload your preseed.cfg file to configured location `PRESEED_URL`.

You can test it. We must get 200 response as we expected
```
curl -o /dev/null --silent --head --write-out '%{http_code}\n' http://yourserver.tld/preseed.cfg
200
```
⚠ If your webserver not reachable you must reboot your server to get preseed file. so test it before reboot your server.

#### Reboot
```
reboot
```
#### Get ssh
Wait it until boot to iso complete and install require packages then
```
ssh installer@10.1.1.100
```
#### Continue installation of ubuntu
---
✅ This script test on Ubuntu Server 16.04 and 18.04.
