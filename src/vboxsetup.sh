#!/usr/bin/env bash

_help(){
	>&2 echo "usage: vboxsetup <vmname> <iso-path> [-DomscpP]"
	>&2 echo "    -D <dir>   sets a vbox dir"
	>&2 echo "    -P <str>   sets vnc password (default: \$VMNAME)"
	>&2 echo "    -c <num>   sets vm cpu count"
	>&2 echo "    -m <num>   sets vm ram size in bytes"
	>&2 echo "    -o <type>  sets vm os type"
	>&2 echo "    -p <port>  sets and enables vnc port"
	>&2 echo "    -s <num>   sets vm storage disk size in bytes"
	exit 2
}

while getopts ":hD:m:s:c:p:P:" opt; do
    case "$opt" in
		D) VBOXDIR="$OPTARG" ;;
		m) MEMORY="$OPTARG" ;;
		o) OSTYPE="$OPTARG" ;;
		s) STORAGE="$OPTARG" ;;
		c) CPUS="$OPTARG" ;;
		p) VNCPORT="$OPTARG" ;;
		P) VNCPASSWORD="$OPTARG" ;;
		h) _help ;;
    esac
done

shift $((OPTIND -1))

ISO=${ISO:-"$2"}
VMNAME=${VMNAME:-"$1"}
VBOXDIR="${VBOXDIR:-"$HOME/hdd0-linux/virtualbox"}"
OSTYPE="${OSTYPE:-"Linux_64"}"
MEMORY="${MEMORY:-"2048"}"
STORAGE="${STORAGE:-"20480"}"
CPUS="${CPUS:-"2"}"
VNCPORT="${VNCPORT}"
VNCPASSWORD="${VNCPASSWORD:-$VMNAME}"

if [ -z "$VMNAME" ]; then
	>&2 echo "$(basename $0): fatal error: must specify VMNAME"
	exit 1
fi

if [ ! -e "$ISO" ]; then
	>&2 echo "$(basename $0): $ISO: no such file or directory"
	exit 1
fi


VBoxManage createvm --name "$VMNAME" --ostype "$OSTYPE" --basefolder "$VBOXDIR" --default
VBoxManage registervm "$VBOXDIR/$VMNAME/$VMNAME.vbox"

VBoxManage modifyvm "$VMNAME" --cpus $CPUS
VBoxManage modifyvm "$VMNAME" --memory $MEMORY
VBoxManage modifyvm "$VMNAME" --audio none

VBoxManage createmedium disk --filename "$VBOXDIR/$VMNAME/$VMNAME.vdi" --format VDI --size "$STORAGE"

VBoxManage storagectl "$VMNAME" --name SCSI --add scsi --portcount 16 --bootable on
VBoxManage storageattach "$VMNAME" --storagectl SCSI --type hdd --port 0 --device 0 --medium "$VBOXDIR/$VMNAME/$VMNAME.vdi"

VBoxManage storagectl "$VMNAME" --name SATA --add sata --portcount 16 --bootable on
VBoxManage storageattach "$VMNAME" --storagectl SATA --type dvddrive --port 0 --device 0 --medium "$ISO"

#VBoxManage hostonlyif create
#VBoxManage dhcpserver add --interface vboxnet0 --ip 192.168.56.1 --netmask 255.255.255.0 --lowerip 192.168.56.100 --upperip 192.168.56.200
#VBoxManage dhcpserver modify --interface vboxnet0 --enable
VBoxManage modifyvm "$VMNAME" --nic1 nat
VBoxManage modifyvm "$VMNAME" --nic2 hostonly --hostonlyadapter2 vboxnet0

if [ -b "$VNCPORT" ]; then
	VBoxManage setproperty vrdeextpack VNC
	VBoxManage modifyvm "$VMNAME" --vrde on
	VBoxManage modifyvm "$VMNAME" --vrdeport 
	VBoxManage modifyvm "$VMNAME" --vrdeproperty VNCPassword=$VNCPASSWORD
fi

