#!/bin/bash

install_settings() {
    echo
    echo "*** Copying setting files ..."
    echo
    sudo cp etc/vim/vimrc.local /etc/vim/ -avf
    sudo mkdir -p /etc/profile.d
    sudo cp etc/profile.d/* /etc/profile.d/ -avf
    sudo cp etc/zsh/* /etc/zsh/ -avf
    sudo chown root:root /etc/vim/vimrc.local /etc/profile.d/* /etc/zsh/*

    echo
    echo "*** Installling user settings ..."
    sudo usermod -s /bin/zsh `whoami`
    test -f ~/.vimrc || cp -av home/.vimrc* ~/
    test -f ~/.zshrc || cp -av home/.zshrc ~/
}

install_grub() {
    echo
    echo "*** Updating Grub default OS ..."
    echo
    sudo cp -avf etc/default/grub /etc/default/grub
    sudo chmod -x /etc/grub.d/20_memtest86+
    sudo update-grub
}

install_timezone() {
    echo
    echo "*** Setting BIOS clock to local time for Windows compatibility ..."
    echo
    timedatectl set-local-rtc 1 --adjust-system-clock
}

install_packages() {
    echo
    echo "*** Installing standard software ..."
    echo
    sudo apt install vim zsh screen ksshaskpass blender audacity vlc kdenlive gimp inkscape kdevelop clang clang-tidy cppcheck cmake cmake-gui git gitk kdiff3
    sudo apt install python3-pip python3-serial python3-numpy python3-scipy python3-opencv python3-tk python3-pil.imagetk python3-venv
}

install_onedrive() {
    echo
    echo "*** Removing old nedrive installation ..."
    echo
    sudo apt remove onedrive
    sudo add-apt-repository --remove ppa:yann1ck/onedrive
    sudo rm -f /etc/systemd/user/default.target.wants/onedrive.service
    echo
    echo "*** Installing new onedrive application ..."
    echo
    wget -qO - https://download.opensuse.org/repositories/home:/npreining:/debian-ubuntu-onedrive/xUbuntu_24.04/Release.key | gpg --dearmor | sudo tee /usr/share/keyrings/obs-onedrive.gpg > /dev/null
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/obs-onedrive.gpg] https://download.opensuse.org/repositories/home:/npreining:/debian-ubuntu-onedrive/xUbuntu_24.04/ ./" | sudo tee /etc/apt/sources.list.d/onedrive.list
    sudo apt update
    sudo apt install --no-install-recommends --no-install-suggests onedrive
    echo
    echo "*** Starting onedrive service ..."
    echo
    systemctl --user enable onedrive
    systemctl --user start onedrive
}

install_vscode() {
    echo
    echo "*** Adding VSCode repository ..."
    echo
    sudo apt-get install wget gpg
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
    sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
    echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" |sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
    rm -f packages.microsoft.gpg

    echo
    echo "*** Installing VSCode ..."
    echo
    sudo apt install apt-transport-https
    sudo apt update
    sudo apt install code
}

help() {
    echo "Usage: ./install.sh [all|grub|onedrive]"
    exit 0
}

if [ -z $1 ]; then
    install_packages
    install_settings
    install_timezone
    exit 0
fi

case $1 in
    -h|--help)
	help
	;;
    all)
	install_packages
	install_settings
	install_timezone
	install_grub
	install_vscode
	install_onedrive
	;;
    grub)
	install_grub
	;;
    onedrive)
	install_onedrive
	;;
    code)
	install_vscode
	;;
    *)
	echo "Invalid option: $1"
	exit 1
esac
