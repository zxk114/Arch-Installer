#!/bin/bash

# 该死的颜色
color(){
    case $1 in
        red)
            echo -e "\033[31m$2\033[0m"
        ;;
        green)
            echo -e "\033[32m$2\033[0m"
        ;;
    esac
}

partition(){
    if (echo $1 | grep '/' > /dev/null 2>&1);then
        other=$1
    else
        other=/$1
    fi

    fdisk -l
    color green "Input the partition (/dev/sdaX"
    read OTHER
    color green "Format it ? y)yes ENTER)no"
    read tmp

    if [ "$tmp" == y ];then
        umount $OTHER > /dev/null 2>&1
        color green "Input the filesystem's num to format it"
        select type in 'ext2' "ext3" "ext4" "btrfs" "xfs" "jfs" "fat" "swap";do
            case $type in
                "ext2")
                    mkfs.ext2 $OTHER
                    break
                ;;
                "ext3")
                    mkfs.ext3 $OTHER
                    break
                ;;
                "ext4")
                    mkfs.ext4 $OTHER
                    break
                ;;
                "btrfs")
                    mkfs.btrfs $OTHER -f
                    break
                ;;
                "xfs")
                    mkfs.xfs $OTHER -f
                    break
                ;;
                "jfs")
                    mkfs.jfs $OTHER
                    break
                ;;
                "fat")
                    mkfs.fat -F32 $OTHER
                    break
                ;;
                "swap")
                    swapoff $OTHER > /dev/null 2>&1
                    mkswap $OTHER -f
                    break
                ;;
                *)
                    color red "Error ! Please input the num again"
                ;;
            esac
        done
    fi

    if [ "$other" == "/swap" ];then
        swapon $OTHER
    else
        umount $OTHER > /dev/null 2>&1
        mkdir /mnt$other
        mount $OTHER /mnt$other
    fi
}

prepare(){
    fdisk -l
    color green "Do you want to adjust the partition ? y)yes ENTER)no"
    read tmp
    if [ "$tmp" == y ];then
        color green "Input the disk (/dev/sdX"
        read TMP
        cfdisk $TMP
    fi
    color green "Input the ROOT(/) mount point:"
    read ROOT
    color green "Format it ? y)yes ENTER)no"
    read tmp
    if [ "$tmp" == y ];then
        umount $ROOT > /dev/null 2>&1
        color green "Input the filesystem's num to format it"
        select type in "ext4" "btrfs" "xfs" "jfs";do
            umount $ROOT > /dev/null 2>&1
            if [ "$type" == "btrfs" ];then
                mkfs.$type $ROOT -f
            elif [ "$type" == "xfs" ];then
                mkfs.$type $ROOT -f
            else
                mkfs.$type $ROOT
            fi
            break
        done
    fi
    mount $ROOT /mnt
    color green "Do you have another mount point ? if so please input it, such as : /boot /home and swap or just ENTER to skip"
    read other
    while [ "$other" != '' ];do
        partition $other
        color green "Still have another mount point ? input it or just ENTER"
        read other
    done
}

install(){
    echo "setopt no_nomatch" >> ~/.zshrc
    source ~/.zshrc
    mv /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
    wget -O /etc/pacman.d/mirrorlist.bak https://www.archlinux.org/mirrorlist/?country=CN
    sed -i 's/#Server/Server/g' /etc/pacman.d/mirrorlist.bak
    rankmirrors -n 6 /etc/pacman.d/mirrorlist.bak > /etc/pacman.d/mirrorlist
    echo -e "[archlinuxcn]\nServer = https://mirrors.ustc.edu.cn/archlinuxcn/\$arch" >> /etc/pacman.conf
    sed -i 's/^SigLevel.*$/SigLevel = Never/g' /etc/pacman.conf
    pacman -Syy
    pacstrap /mnt base base-devel --force
    genfstab -U -p /mnt > /mnt/etc/fstab
}

config(){
    wget https://raw.githubusercontent.com/zxk114/Arch-Installer/master/config.sh -O /mnt/root/config.sh
    chmod +x /mnt/root/config.sh
    arch-chroot /mnt /root/config.sh
}

if [ "$1" != '' ];then
    case $1 in
        "--prepare")
            prepare
        ;;
        "--install")
            install
        ;;
        "--chroot")
            config
        ;;
        "--help")
            color red "--prepare :  prepare disk and partition\n--install :  install the base system\n--chroot :  chroot into the system to install other software"
        ;;
        *)
            color red "Error !\n--prepare :  prepare disk and partition\n--install :  install the base system\n--chroot :  chroot into the system to install other software"
        ;;
    esac
else
    prepare
    install
    config
fi
