#!/bin/bash

set -ouex pipefail

### Fedora par défaut :
# zram en lzo-rle (on veut zstd)
# compression btrfs zstd niveau 1 dans /etc/fstab, mais n'est pas utilisé par le système
# relatime (mieux que noatime)
# gamemode : installé par défaut.
# fstrim.timer : déjà activé et actif (hebdomadaire)
# discard=async : déjà présent sur tous les montages btrfs et à travers LUKS
# ne pas utiliser earlyoom
# tip : on peut overrider les fichiers de /usr/lib/ en placant un fichier du même nom dans le dossier correspondant dans /etc/

### ntsync : chargement au boot
echo "ntsync" > /usr/lib/modules-load.d/ntsync.conf

### VMMC : https://fedoraproject.org/wiki/Changes/IncreaseVmMaxMapCount
### utilisé par Bazzite
cat > /usr/lib/sysctl.d/99-vmmc.conf << 'EOF'
vm.max_map_count=1048576
EOF

### swappiness agressif comme Bazzitepour favoriser ZRAM avant le swap disque
cat > /usr/lib/sysctl.d/99-swappiness.conf << 'EOF'
vm.swappiness = 180
EOF

### ZRAM : zstd, 100% de la RAM (au lieu du défaut lzo-rle plafonné à 8 Go)
cat > /etc/systemd/zram-generator.conf << 'EOF'
[zram0]
compression-algorithm=zstd
swap-priority=100
zram-size=100 / 100 * ram
EOF

### Kernel arg : compression btrfs forcée en zstd:3
### https://github.com/ublue-os/bazzite/issues/3602
### https://discussion.fedoraproject.org/t/talk-mount-options-are-ignored-in-fedora-atomic-desktops-42/148874/22
### https://gitlab.com/fedora/ostree/sig/-/work_items/72
### les options kargs ne remplacent pas les existantes, mais s'y ajoutent sans fusion
### Cela fait un doublon de kargs qui est sans conséquence compress-force=zstd:3
### est bien actif (test sur fichier avant et apres l'ajout des kaargs
### https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/10/html/using_image_mode_for_rhel_to_build_deploy_and_manage_operating_systems/managing-kernel-arguments-in-bootc-systems#how-to-inject-kernel-arguments-in-the-containerfile
mkdir -p /usr/lib/bootc/kargs.d
cat > /usr/lib/bootc/kargs.d/10-btrfs-compress.toml << 'EOF'
kargs = ["rootflags=subvol=root,compress-force=zstd:3"]
EOF

### https://github.com/JasonN3/fedora_workstation/blob/main/Containerfile.gnome
### Disable non-functional services
### RUN rm /usr/etc/systemd/system/systemd-remount-fs.service
### inclure dans les services à desactiver, pour ne plus avoir les erreus au démarrage

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
