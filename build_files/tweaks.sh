#!/bin/bash

set -ouex pipefail

### ntsync : chargement au boot
echo "ntsync" > /usr/lib/modules-load.d/ntsync.conf

### https://wiki.archlinux.org/title/Zram#Optimizing_swap_on_zram
### swappiness agressif comme Bazzitepour favoriser ZRAM avant le swap disque
### VMMC : https://fedoraproject.org/wiki/Changes/IncreaseVmMaxMapCount
### utilisé par Bazzite
cat > /usr/lib/sysctl.d/99-vm-zram-parameters.conf << 'EOF'
vm.swappiness = 180
vm.watermark_boost_factor = 0
vm.watermark_scale_factor = 125
vm.page-cluster = 0
vm.max_map_count=1048576
EOF

### ZRAM : zstd, 100% de la RAM (au lieu du défaut lzo-rle plafonné à 8 Go)
cat > /etc/systemd/zram-generator.conf << 'EOF'
[zram0]
compression-algorithm=zstd
swap-priority=100
zram-size=100 / 100 * ram
EOF

### Kernel arg : compression btrfs forcée en zstd:3
### Les options de montage de / dans /etc/fstab étant ignorée par composefs
mkdir -p /usr/lib/bootc/kargs.d
cat > /usr/lib/bootc/kargs.d/10-btrfs-compress.toml << 'EOF'
kargs = ["compress=zstd:1"]
EOF

### Services système : désactivation classique
systemctl disable \
  NetworkManager-wait-online.service \
  ModemManager.service

### Services système : masquage (statique ou activation par socket/dbus)
systemctl mask \
  geoclue.service \
  gssproxy.service \
  sssd-kcm.service sssd-kcm.socket \
  pcscd.service pcscd.socket

### Services utilisateur (--global : pas de session active pendant le build)
systemctl --global mask \
  evolution-addressbook-factory.service \
  evolution-calendar-factory.service \
  evolution-alarm-notify.service \
  evolution-source-registry.service \
  evolution-user-prompter.service \
  org.gnome.SettingsDaemon.Smartcard.service \
  org.gnome.SettingsDaemon.Smartcard.target \
  org.gnome.SettingsDaemon.Wwan.service \
  org.gnome.SettingsDaemon.Wwan.target
