# Custom Fedora Silverblue Image

Build bootc OCI and ISO image from Fedora Silverblue, with tweaks and additionals softwares. The original image is modified only by integrating what would have required rpm-ostree layering. Nothing is removed, to keep the base guaranteed by Fedora. All other things that don't involve changing the immutable part of the OS (settings in /etc, data provisioned in /var) can easily be done on the running system, as intended.

This repository builds a custom bootc image on GitHub Actions.

| Setting | Value |
|---------|-------|
| Repository | `binnotkari-wq/silverblue_bootc` |
| Base Image | `Fedora Silverblue` |
| Base Image URI | `quay.io/fedora-ostree-desktops/silverblue:44` |
| Published Image | `ghcr.io/binnotkari-wq/silverblue_bootc:latest` |
| Build Method | `Containerfile` |

## Managed By Atomic Image Builder

This repo is managed by `atomic-image-builder`. `.atomic-image-builder.json` is the saved settings file and source of truth for future updates.

If you hand-edit this repo after `atomic-image-builder` creates or manages it, stop using `atomic-image-builder` for this repo.

Later tool-driven updates rewrite managed files and can overwrite manual changes, especially `README.md` and `build_files/build.sh`.

## Requested Packages

These are the package names requested by this repo's generated build script.
Selected packages are what this repo will attempt to add, even if some are already present in the chosen base image.

- `aria2`
- `bat`
- `btop`
- `createrepo_c`
- `dialog`
- `distrobox`
- `duf`
- `fd-find`
- `fzf`
- `gamescope`
- `glow`
- `isomd5sum`
- `just`
- `kiwix-tools`
- `libva-utils`
- `lm_sensors`
- `mc`
- `msedit`
- `powertop`
- `s-tui`
- `ShellCheck`
- `smartmontools`
- `stress-ng`
- `tldr`
- `tmux`
- `yt-dlp`
- `zenity`
- `zoxide`

## Tweaks

- setting BTRFS compression in kargs, because mounting options for / are not applied in ComposeFS. See : [gitlab.com/fedora/ostree/sig — work item #72](https://gitlab.com/fedora/ostree/sig/-/work_items/72).
- enabling graphical boot on Radeon Vega integrated GPU : amdgpu driver included in initramfs, and requires 'UseSimpledrm=1' in '/etc/plymouth/plymouthd.conf' (upstream behavior change : "Don't use simpledrm together with LUKS")  to return to the bgrt display at the LUKS prompt.

## COPR Repositories

- None.

## Enabled Services

- None.

## Removed Base Packages

- None.

## Disabled Services

- None.

## Using The Image

After the first successful GitHub Actions build finishes, switch to it with:

```bash
sudo bootc switch ghcr.io/binnotkari-wq/silverblue_bootc:latest
systemctl reboot
```
