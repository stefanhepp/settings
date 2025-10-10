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
    mkdir -p ~/Apps/Icons
    cp -avf home/Apps/Icons/* ~/Apps/Icons
    mkdir -p ~/.ssh
    mkdir -p ~/tmp
    test -f ~/.ssh/config || cp -av home/.ssh/config ~/.ssh/
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
    sudo apt install -y vim zsh screen ksshaskpass audacity vlc kdenlive gimp inkscape kdevelop clang clang-tidy cppcheck cmake cmake-gui git gitk kdiff3 net-tools curl
    sudo apt install -y krusader krename arj rar unrar smb4k kde-config-flatpak
    sudo apt install -y python3-pip python3-serial python3-numpy python3-scipy python3-opencv python3-tk python3-pil.imagetk python3-venv
}

install_mozilla_flatpak() {
    echo
    echo "*** Replacing Mozilla snaps with flatpak ..."
    echo

    # Remove Ubuntu snap
    sudo snap remove firefox
    sudo rm -f /etc/apparmor.d/usr.bin.firefox
    sudo rm -f /etc/apparmor.d/local/usr.bin.firefox
    sudo systemctl stop var-snap-firefox-common-host\\x2dhunspell.mount
    sudo systemctl disable var-snap-firefox-common-host\\x2dhunspell.mount
    sudo snap remove firefox
    sudo snap remove thunderbird

    # Install flatpak
    sudo flatpak install -y \
        org.mozilla.firefox \
        org.mozilla.Thunderbird

    flatpak override --user org.mozilla.firefox --talk-name=org.freedesktop.ScreenSaver
}

install_kicad() {
    echo
    echo "*** Installing KiCAD ..."
    echo
    sudo add-apt-repository --yes ppa:kicad/kicad-9.0-releases
    sudo apt update
    sudo apt install --install-recommends kicad
}

install_apps() {
    echo
    echo "*** Installing snaps and flatpaks ..."
    echo
    sudo apt install -y flatpak
    sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

    sudo flatpak install -y \
        org.freecad.FreeCAD \
        com.xnview.XnViewMP \
        com.jgraph.drawio.desktop \
	com.jetbrains.PyCharm-Professional \
        com.prusa3d.PrusaSlicer \
        com.valvesoftware.Steam \
        com.valvesoftware.SteamLink \
	com.usebottles.bottles \
        com.obsproject.Studio \
        org.jdownloader.JDownloader \
	org.blender.Blender \
	com.github.tchx84.Flatseal \
	io.github.Omniaevo.mqtt5-explorer	

    # Install supporting packages
    sudo apt install -y steam-devices

    # Setup permissions
    flatpak override --user com.usebottles.bottles --filesystem=~/.var/app/com.valvesoftware.Steam/data/Steam
    flatpak override --user com.usebottles.bottles --talk-name=org.freedesktop.Flatpak 

    # Temporary workaround for jdownloader
    sudo flatpak update -y --commit=0ae5cd879a0a113a53806fd1651ef873871c4fbeec3782496fec37dd2c4dc09b org.jdownloader.JDownloader
    flatpak run org.jdownloader.JDownloader
    flatpak update -y org.jdownloader.JDownloader
}

install_doublecommander() {
    echo 'deb http://download.opensuse.org/repositories/home:/Alexx2000/xUbuntu_24.04/ /' | sudo tee /etc/apt/sources.list.d/home:Alexx2000.list
    curl -fsSL https://download.opensuse.org/repositories/home:Alexx2000/xUbuntu_24.04/Release.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/home_Alexx2000.gpg > /dev/null
    sudo apt update
    sudo apt install -y doublecmd-qt6
}

upgrade_curl() {
    echo
    echo "*** Installing curl to 8.14.1 in /usr/local ..."
    echo 
    sudo apt install -y nghttp2 libnghttp2-dev libssl-dev libpsl-dev build-essential wget
    tmp=`mktemp -d`
    cd $tmp
    wget https://curl.se/download/curl-8.14.1.tar.xz
    tar -xvf curl-8.14.1.tar.xz
    rm -f curl-8.14.1.tar.xz
    cd curl-8.14.1
    ./configure --prefix=/usr/local --with-ssl --with-nghttp2 --enable-versioned-symbols
    make
    sudo make install
    sudo ldconfig
    cd ~
    rm -rf $tmp
    /usr/local/bin/curl --version
}


install_onedrive() {
    echo
    echo "*** Removing old onedrive installation ..."
    echo
    sudo apt remove onedrive
    sudo add-apt-repository --remove ppa:yann1ck/onedrive
    sudo rm -f /etc/systemd/user/default.target.wants/onedrive.service

    upgrade_curl

    echo
    echo "*** Installing new onedrive application ..."
    echo
    release=`lsb_release -rs`
    wget -qO - https://download.opensuse.org/repositories/home:/npreining:/debian-ubuntu-onedrive/xUbuntu_$release/Release.key | gpg --dearmor | sudo tee /usr/share/keyrings/obs-onedrive.gpg > /dev/null
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/obs-onedrive.gpg] https://download.opensuse.org/repositories/home:/npreining:/debian-ubuntu-onedrive/xUbuntu_$release/ ./" | sudo tee /etc/apt/sources.list.d/onedrive.list
    sudo apt update
    sudo apt install --no-install-recommends --no-install-suggests -y onedrive

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
	install_kicad
	install_apps
	install_mozilla_flatpak
	;;
    apps)
	install_apps
	;;
    grub)
	install_grub
	;;
    mozilla)
	install_mozilla_flatpak
	;;
    onedrive)
	install_onedrive
	;;
    kicad)
	install_kicad
	;;
    doublecommander)
	install_doublecommander
	;;
    code)
	install_vscode
	;;
    *)
	echo "Invalid option: $1"
	exit 1
esac
