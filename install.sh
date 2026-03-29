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
    mkdir -p ~/Applications/Icons
    cp -avf home/Applications/Icons/* ~/Applications/Icons
    mkdir -p ~/.ssh
    mkdir -p ~/tmp
    test -f ~/.ssh/config || cp -av home/.ssh/config ~/.ssh/
    mkdir -p ~/.local/bin
    cp -avf home/.local/bin/* ~/.local/bin
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
    sudo apt install -y vim zsh screen progress powertop ksshaskpass openssh-server
    sudo apt install -y clang clang-tidy cppcheck cmake cmake-gui git gitk kdiff3 net-tools curl scons
    sudo apt install -y krusader krename arj rar unrar smb4k vlc qimgv
    sudo apt install -y pipx python3-pip python3-serial python3-numpy python3-scipy python3-opencv python3-tk python3-pil.imagetk python3-venv python3-build
}

install_repos() {
    echo
    echo "*** Adding multiverse ..."
    echo
    sudo apt-add-repository -y multiverse

    echo
    echo "*** Installing flatpak repositories ..."
    echo

    sudo apt install -y flatpak
    sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

    sudo apt install -y kde-config-flatpak plasma-discover-backend-flatpak

    sudo flatpak install -y \
	com.github.tchx84.Flatseal

    echo
    echo "*** Install AppImageLauncher ..."
    echo
    
    package=appimagelauncher_3.0.0-beta-2-gha287.96cb937_amd64.deb

    wget https://github.com/TheAssassin/AppImageLauncher/releases/download/v3.0.0-beta-3/$package -P /tmp
    sudo apt install /tmp/$package
    rm /tmp/$package
}

install_xtradebs() {
    echo
    echo "*** Installing xtraDeb packages ..."
    echo

    if [ ! -f /etc/apt/sources.list.d/xtradeb-ubuntu.sources ]; then
        wget https://launchpad.net/~xtradeb/+archive/ubuntu/apps/+files/xtradeb-apt-source_0.4_all.deb -P /tmp
	sudo apt install /tmp/xtradeb-apt-source_0.4_all.deb
	rm /tmp/xtradeb-apt-source_0.4_all.deb 
	sudo apt update
    fi

    sudo apt install -y openra
    sudo apt install -y openrct2 openttd
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
    sudo apt remove -y firefox thunderbird

    # remove snap completely and block it being installed
    sudo apt autoremove --purge snapd
    sudo apt-mark hold snapd

    # Install flatpak
    sudo flatpak install -y \
        org.mozilla.firefox \
        org.mozilla.Thunderbird

    flatpak override --user org.mozilla.firefox --talk-name=org.freedesktop.ScreenSaver
}

install_touchscreen() {
    echo
    echo "*** Installing virtual keyboard ..."
    echo
    #sudo apt install -y qt6-base-dev-tools qt6-base-dev qt6-declarative-dev qt6-virtualkeyboard-dev extra-cmake-modules libecm-dev
    
    sudo apt install -y maliit-keyboard
}

install_lenovo() {
    echo
    echo "*** Installing apps for Lenovo Yoga laptop ..."
    echo

    sudo apt install -y thinkfan
}

install_apps() {
    echo
    echo "*** Installing flatpaks ..."
    echo

    sudo flatpak install -y \
        com.xnview.XnViewMP \
	net.epson.epsonscan2 \
        com.jgraph.drawio.desktop \
        org.jdownloader.JDownloader
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
    echo "*** Installing Onedrive client ..."
    echo

    release=`lsb_release -rs 2>/dev/null`
    repo="https://download.opensuse.org/repositories/home:/npreining:/debian-ubuntu-onedrive/xUbuntu_$release"

    grep "$repo" /etc/apt/sources.list.d/onedrive.list >/dev/null 2>&1
    if [ $? == 0 ]; then
	echo "Onedrive already installed, skipping!"
	echo
    else
	echo "* Removing old onedrive installations ..."
	sudo apt remove -y onedrive
	sudo add-apt-repository --remove ppa:yann1ck/onedrive
	sudo rm -f /etc/systemd/user/default.target.wants/onedrive.service

	if [ "$release" == "24.04" ]; then
	    echo
	    echo "* Installing newer version of curl ..."
	    echo
	    upgrade_curl
	fi

	echo
	echo "* Installing new onedrive application ..."
	echo
	wget -qO - $repo/Release.key | gpg --dearmor | sudo tee /usr/share/keyrings/obs-onedrive.gpg > /dev/null
	echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/obs-onedrive.gpg] $repo/ ./" | sudo tee /etc/apt/sources.list.d/onedrive.list
	sudo apt update
	sudo apt install --no-install-recommends --no-install-suggests -y onedrive

	echo
	echo "* Starting onedrive service ..."
	echo
	systemctl --user enable onedrive
	systemctl --user start onedrive
    fi
}

install_vscode() {
    echo
    echo "*** Adding VSCode repository ..."
    echo
    if [ ! -f /etc/apt/sources.list.d/vscode.sources ]; then
	sudo apt-get install wget gpg
	wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
	sudo install -D -o root -g root -m 644 microsoft.gpg /etc/apt/keyrings/microsoft.gpg
	rm -f microsoft.gpg
	sudo tee /etc/apt/sources.list.d/vscode.sources > /dev/null << EOL
Types: deb
URIs: https://packages.microsoft.com/repos/code
Suites: stable
Components: main
Architectures: amd64,arm64,armhf
Signed-By: /etc/apt/keyrings/microsoft.gpg
EOL
    fi

    echo
    echo "*** Installing VSCode ..."
    echo
    sudo apt install apt-transport-https
    sudo apt update
    sudo apt install code
}

install_kvm() {
    echo
    echo "*** Installing KVM virtualization ..."
    echo
    
    if [ `egrep -c "(vmx|svm)" /proc/cpuinfo` -gt 0 ]; then
	echo "KVM capable CPU found .."
	sudo apt install -y qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils
    else
	echo "CPU does not support KVM!"
    fi
}

install_dev() {
    echo
    echo "*** Installing Development IDEs ..."
    echo

    sudo apt install -y kdevelop clang clang-tidy cppcheck cmake cmake-gui git gitk kdiff3 scons

    sudo flatpak install -y \
	com.jetbrains.PyCharm-Professional \
	com.google.AndroidStudio \
	io.github.Omniaevo.mqtt5-explorer
}

install_rust() {
    echo
    echo "*** Installing rust ..."
    echo

    sudo apt remove -y rustc
    sudo apt autoremove

    # Install rustup
    if [ ! -f ~/.cargo/bin/rustc ]; then
	curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
    fi

}

install_media() {
    echo
    echo "*** Installing Media applications ..."
    echo

    # OBS Studia PPA is not up-to-date with latest Ubuntu version, Flatpak pulls in old dependencies; Install older version from Kubuntu instead
    #sudo add-apt-repository --yes ppa:obsproject/obs-studio
    #sudo apt update

    sudo apt install -y obs-studio

    sudo apt install -y kdenlive gimp inkscape scons avidemux-qt
    sudo apt install -y ardour audacity lmms midisnoop

    sudo flatpak install -y \
	org.musescore.MuseScore \
	net.sourceforge.GrandOrgue \
	com.bitwig.BitwigStudio
}

install_kicad() {
    echo
    echo "*** Installing KiCAD ..."
    echo
    sudo add-apt-repository --yes ppa:kicad/kicad-9.0-releases
    sudo apt update
    sudo apt install -y --install-recommends kicad
}

install_cad() {
    echo
    echo "*** Installing CAD applications ..."
    echo

    sudo flatpak install -y \
        org.freecad.FreeCAD \
        com.prusa3d.PrusaSlicer \
	org.blender.Blender
}

install_games() {
    echo
    echo "*** Installing Games and Launchers ..."
    echo

    sudo flatpak install -y \
        com.valvesoftware.SteamLink \
	com.heroicgameslauncher.hgl \
	org.DolphinEmu.dolphin-emu \
	info.cemu.Cemu \

    # No need:
    # com.usebottles.bottles
    # io.github.dosbox-staging

    # Install Steam, Epic, Gog clients and supporting packages
    sudo apt install -y steam steam-devices lutris

    # Install emulators
    sudo apt install -y dosbox

    # Setup permissions
    flatpak override --user com.heroicgameslauncher.hgl --talk-name=org.freedesktop.Flatpak
    #flatpak override --user com.usebottles.bottles --filesystem=~/.var/app/com.valvesoftware.Steam/data/Steam
    #flatpak override --user com.usebottles.bottles --talk-name=org.freedesktop.Flatpak 
}

install_vr() {
    echo
    echo "*** Installing VR support ..."
    echo

    # Install dependencies for Envision VR app
    sudo apt install -y libboost-all-dev libbz2-dev libeigen3-dev libfmt-dev libfmt-dev git-lfs \
                        libglew-dev libglew-dev glslang-tools glslc libgtest-dev libbsd-dev libclang-19-dev \
			libdrm-dev libepoxy-dev libgl1-mesa-dev libudev-dev libusb-1.0-0 libusb-1.0-0-dev \
			libx11-xcb-dev libxcb-randr0-dev libxcb-glx0-dev libxrandr-dev liblz4-dev \
			mesa-common-dev ninja-build libonnxruntime-dev libopencv-dev libopenxr-dev \
			libsdl2-dev libtbb-dev libvulkan-dev libwayland-dev wayland-protocols
    
    # Set SteamVR capabilities if SteamVR is nagging about incomplete setup
    # Run after every update of SteamVR
    #sudo setcap CAP_SYS_NICE=eip ~/.steam/steam/steamapps/common/SteamVR/bin/linux64/vrcompositor-launcher

    # Install WiVRn
    sudo flatpak install -y io.github.wivrn.wivrn
    sudo apt install -y adb

    # Install WayVR
    # wget https://github.com/wlx-team/wayvr/releases/download/v26.2.1/WayVR-v26.2.1-x86_64.AppImage

    # Install BS-Manager
    if [ ! -f /etc/apt/sources.list.d/bs-manager.list ]; then
        curl -fsSL https://raw.githubusercontent.com/silentrald/bs-manager-deb/refs/heads/main/KEY.gpg | sudo gpg --dearmor -o /usr/share/keyrings/bs-manager.gpg
	echo "deb [signed-by=/usr/share/keyrings/bs-manager.gpg] https://raw.githubusercontent.com/silentrald/bs-manager-deb/refs/heads/main ./" | sudo tee /etc/apt/sources.list.d/bs-manager.list
        sudo apt update
    fi

    sudo apt install bs-manager

}

install_flightsim() {
    echo
    echo "*** Installing Flightsims ..."
    echo

    sudo flatpak install -y \
	org.flightgear.FlightGear
}

help() {
    echo "Usage: ./install.sh [all|grub|onedrive]"
    exit 0
}

install() {
    case $1 in
	system)
	    install_timezone
	    install_settings
	    install_grub
	    ;;
	base)
	    install system
	    install apps
	    ;;
	all)
	    install base

	    install dev
	    install cad
	    install media
	    install games
	    ;;

	# Application categories
	apps)
	    install_repos
	    install_packages
	    install_mozilla_flatpak
	    install_onedrive
	    install_apps
	    ;; 
	dev)
	    install_vscode
	    install_kvm
	    install_dev
	    install_rust
	    ;;
	cad)
	    install_cad
	    install_kicad
	    ;;
	media)
	    install_media
	    ;;
	games)
	    install_games
	    ;;

	# Additional targets
	touch)
	    install_touchscreen
	    ;;
	lenovo)
	    install_touchscreen
	    install_lenovo
	    ;;
	flightsim)
	    install_flightsim
	    ;;
	vr)
	    install_rust
	    install_vr
	    ;;
	xtradebs)
	    install_xtradebs
	    ;;

	# Individual installers
	settings)
	    install_settings
	    ;;
	grub)
	    install_grub
	    ;;
	repos)
	    install_repos
	    ;;
	mozilla)
	    install_mozilla_flatpak
	    ;;
	onedrive)
	    install_onedrive
	    ;;
	code)
	    install_vscode
	    ;;
	kicad)
	    install_kicad
	    ;;
	*)
	    echo "Invalid option: $1"
	    exit 1
    esac

}

if [ -z $1 ]; then
    install base
    exit 0
fi

case $1 in
    -h|--help)
	help
	;;
    *)
	install $1
	;;
esac
