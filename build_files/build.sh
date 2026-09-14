#!/bin/bash

set -ouex pipefail

if [ -d /ctx/system_files ]; then
    cp -avf /ctx/system_files/. /
fi

# Install packages
# Extraction de la liste JSON sous forme de tableau Bash
mapfile -t PAQUETS < <(jq -r '.[]' "/ctx/rpm_install_list.json")
dnf5 install -y --setopt=install_weak_deps=False "${PAQUETS[@]}"

# Clean dnf metadata before the final image is committed
dnf5 autoremove -y
dnf5 clean all

# Karg : compression btrfs zstd:1 (Les options de montage de / dans /etc/fstab étant ignorée par composefs - valade pour toutes les Fedora Atomic et autres dérivés bootc)
mkdir -p /usr/lib/bootc/kargs.d
cat > /usr/lib/bootc/kargs.d/10-btrfs-compress.toml << 'EOF'
kargs = ["compress=zstd:1"]
EOF

# Corrige un bug apparu sur les GPU AMD intégrés de la famille Vega : Plymouth ne s'affiche 
# plus au prompt LUKS. https://github.com/ublue-os/bazzite/blob/main/build_files/build-initramfs
echo 'force_drivers+=" amdgpu "' > /etc/dracut.conf.d/amdgpu-early.conf
cat <<'EOF' | tee "/etc/plymouth/plymouthd.conf" >/dev/null
[Daemon]
Theme=bgrt
UseSimpledrm=1
EOF

# make root's home (sinon il y a une petite erreur dracut à cause du lien symbolique qui n'est pas encore établi dans le container)
mkdir -p /var/roothome

# Nettoyage des résidus runtime-only (/run, /tmp) et /var non déclaré (lint bootc)
rm -rf /run/dnf /run/selinux-policy /tmp/*
rm -rf /var/lib/dnf/*

# Régénération finale de l'initramfs (pour inclure kargs, pilote amd, config pluymouth)
QUALIFIED_KERNEL="$(dnf5 repoquery --installed --queryformat='%{evr}.%{arch}' kernel)"
/usr/bin/dracut --no-hostonly --kver "$QUALIFIED_KERNEL" --reproducible --zstd -v --add ostree -f "/usr/lib/modules/$QUALIFIED_KERNEL/initramfs.img"
chmod 0600 /usr/lib/modules/"$QUALIFIED_KERNEL"/initramfs.img
