#!/bin/bash

set -ouex pipefail

if [ -d /ctx/system_files ]; then
    cp -avf /ctx/system_files/. /
fi

# Remove packages from the base image when they are installed
packages_to_remove=()
for pkg in \
    gnome-tour \
    gnome-software \
    gnome-software-rpm-ostree \
    qt5-qtbase \
    qt6-qtbase \
    orca \
    speech-dispatcher \
    speech-dispatcher-espeak-ng \
    speech-dispatcher-libs \
    speech-dispatcher-utils \
    espeak-ng \
    gnome-classic-session \
    gnome-shell-extension-apps-menu \
    gnome-shell-extension-launch-new-instance \
    gnome-shell-extension-places-menu \
    gnome-shell-extension-window-list \
    gnome-shell-extension-background-logo \
    fedora-flathub-remote
do
    if rpm -q --quiet "$pkg"; then
        packages_to_remove+=("$pkg")
    else
        echo "Skipping removal of $pkg because it is not installed in the base image."
    fi
done
if ((${#packages_to_remove[@]})); then
    dnf5 remove -y "${packages_to_remove[@]}"
fi

# Install packages
dnf5 install -y \
    aria2 \
    bat \
    btop \
    createrepo_c \
    dialog \
    distrobox \
    duf \
    fd-find \
    fzf \
    gamescope \
    glow \
    gnome-shell-extension-dash-to-panel \
    isomd5sum \
    just \
    kiwix-tools \
    libva-utils \
    msedit \
    powertop \
    s-tui \
    stress-ng \
    tldr \
    tmux \
    yt-dlp \
    zenity \
    zoxide \
    ShellCheck

### améliorations des performances
/ctx/tweaks.sh

# Clean dnf metadata before the final image is committed
dnf5 autoremove -y
dnf5 clean all

### Nettoyage des résidus runtime-only (/run, /tmp) et /var non déclaré (lint bootc)
rm -rf /run/dnf /run/selinux-policy /tmp/*
rm -rf /var/lib/dnf/*

### Régénération finale de l'initramfs (doit être la toute dernière étape)
### Fix : Plymouth non affiché sur hardware réel (AMD Vega notamment) sans cette étape explicite
### Référence : https://github.com/ublue-os/bazzite/blob/main/build_files/build-initramfs
# make root's home (sinon il y a une petite erreur dracut à cause du lien symbolique qui n'est pas encore établi dans le container)
mkdir -p /var/roothome
echo 'force_drivers+=" amdgpu "' > /etc/dracut.conf.d/amdgpu-early.conf
QUALIFIED_KERNEL="$(dnf5 repoquery --installed --queryformat='%{evr}.%{arch}' kernel)"
/usr/bin/dracut --no-hostonly --kver "$QUALIFIED_KERNEL" --reproducible --zstd -v --add ostree -f "/usr/lib/modules/$QUALIFIED_KERNEL/initramfs.img"
chmod 0600 /usr/lib/modules/"$QUALIFIED_KERNEL"/initramfs.img
