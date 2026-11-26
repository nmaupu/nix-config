# Migrating from the Guix laptop to NixOS on a second disk

Scenario: the new NVMe is plugged on a USB adapter into the running Guix
laptop. From there: partition + format it, copy `/home`, install NixOS, then
swap the disks.

Names on the new disk never clash with the running system (`crypt-nixos` /
VG `nixos` vs Guix's `crypt-root` / `sys`), so both can be plugged at once.

Everything below is run from the Guix laptop. `$NC` is this repo
(`~/work/perso/nix-config`), `$DISK` the adapter disk.

## 0. Identify the disk

```bash
lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT,MODEL,TRAN
```

The USB stick with the Guix ISO is `sda`; the new NVMe will show up as
`sdb` (or similar) with `TRAN=usb` and the right size. **Double check**:

```bash
export DISK=/dev/sdb
lsblk $DISK
```

## 1. Partition, LUKS, LVM, format, mount

### Option A: disko (recommended, same file the flake uses)

```bash
cd $NC
sudo env NIX_CONFIG="experimental-features = nix-command flakes" \
  /run/current-system/profile/bin/nix run github:nix-community/disko/latest -- \
  --mode destroy,format,mount --argstr device $DISK ./hosts/nmaupu-laptop/disko.nix
```

It asks for the new LUKS passphrase, then mounts everything under `/mnt`
(`/mnt`, `/mnt/boot`, `/mnt/nix`, `/mnt/home`, `/mnt/var/log`,
`/mnt/var/lib/docker`). Check with `lsblk $DISK` and `findmnt -R /mnt`.

### Option B: by hand (what disko does, so the config matches)

```bash
# GPT, partition labels are what the NixOS config looks up at boot
sudo sgdisk --zap-all $DISK
sudo sgdisk -n1:0:+1G -t1:ef00 -c1:disk-main-ESP \
            -n2:0:0     -t2:8309 -c2:disk-main-luks $DISK
sudo partprobe $DISK

# LUKS2 (default argon2id is fine, no GRUB involved)
sudo cryptsetup luksFormat --type luks2 --label disk-main-luks /dev/disk/by-partlabel/disk-main-luks
sudo cryptsetup open --allow-discards /dev/disk/by-partlabel/disk-main-luks crypt-nixos

# LVM
sudo pvcreate /dev/mapper/crypt-nixos
sudo vgcreate nixos /dev/mapper/crypt-nixos
sudo lvcreate -L20G  -n root   nixos
sudo lvcreate -L200G -n nix    nixos
sudo lvcreate -L100G -n docker nixos
sudo lvcreate -L10G  -n log    nixos
sudo lvcreate -L32G  -n swap   nixos
sudo lvcreate -L350G -n home   nixos

# Filesystems
sudo mkfs.vfat -F32 -n ESP /dev/disk/by-partlabel/disk-main-ESP
sudo mkfs.ext4 -L root /dev/nixos/root
sudo mkfs.ext4 -L nix  /dev/nixos/nix
sudo mkfs.xfs  -L docker /dev/nixos/docker
sudo mkfs.xfs  -L log  /dev/nixos/log
sudo mkfs.xfs  -L home /dev/nixos/home
sudo mkswap    -L swap /dev/nixos/swap

# Mount
sudo mount /dev/nixos/root /mnt
sudo mkdir -p /mnt/{boot,nix,home,var/log,var/lib/docker}
sudo mount -o umask=0077 /dev/disk/by-partlabel/disk-main-ESP /mnt/boot
sudo mount -o noatime /dev/nixos/nix /mnt/nix
sudo mount /dev/nixos/home /mnt/home
sudo mount /dev/nixos/log /mnt/var/log
sudo mount /dev/nixos/docker /mnt/var/lib/docker
```

(Re-mounting later, e.g. from the ISO: `cryptsetup open ... crypt-nixos`,
`vgchange -ay nixos`, then the `mount` block; or
`disko --mode mount --argstr device $DISK ./hosts/nmaupu-laptop/disko.nix`.)

## 2. Copy /home

```bash
sudo mkdir -p /mnt/home/nmaupu
sudo $NC/migration/sync-home.sh /mnt/home/nmaupu        # dry run, prints the exclude list
sudo $NC/migration/sync-home.sh --go /mnt/home/nmaupu   # ~150 GB
```

What is left out (`migration/home-rsync-exclude.txt`):

| excluded | why |
|---|---|
| `.guix-home`, `.guix-profile`, `.guix-extra-profiles`, `.config/guix`, `.cache/guix`, `.config/shepherd`, `.local/var/log`, `.bin`, `.config/alsa`, `.dotfiles` | Guix only (`.dotfiles` is on GitHub) |
| `.local/share/guix-sandbox-home` (5.6G) | nonguix Android Studio sandbox; on NixOS it uses the real `~/.config` |
| every symlink into `/gnu/store` or `~/.guix-*` (`.zshenv`, `.xsession`, `.config/xmonad/xmonad.hs`, `.gitconfig`, ...) | home-manager recreates them |
| `.npm-global`, `.local/goenv`, `.tmux/plugins/tpm`, `.pi/agent/{mcp.json,extensions,agents,prompts,skills}`, `.pi-lens` | reinstalled / linked by home-manager |
| `.var`, `.local/share/flatpak` (4G) | flatpak is not part of the NixOS config (pwvucontrol comes from nixpkgs) |
| `.cache` (117G, 102G of bazel), `.npm`, `.xsession.{log,err}` (1.8G), `.local/share/Trash` (2.2G), `go/pkg/mod/cache` | regenerable |

Kept on purpose, large, drop them from the command line with `--exclude` if
you don't want them: `.virt` (75G of VM images: debian, nixos-test, windows),
`go/1.25.1` (12G), `.config/emacs` (doom, run `doom sync` after first start),
`.local/goenv-data` and `.local/tfenv-data` (prebuilt go/terraform, run fine
thanks to nix-ld), `.local/bin/*` (bazel, gh, uv, kubeseal, ... prebuilt
binaries, idem).

Kept and needed: `.ssh`, `.gnupg`, `.kube`, `.docker`, `.config/gcloud`,
`.gitconfig-pro`, `.zshrc.d`, `.config/nix/netrc`, `.zsh_history`, `.mozilla`,
`.config/{google-chrome,Slack,Cursor,Postman,1Password}`, `.pi` (sessions,
settings, auth), `.claude`.

Ownership is rewritten to `1000:100` (NixOS `users` gid is 100, Guix's is 997).

## 3. Install

### From the NixOS ISO (recommended)

Most reliable: the installer environment is what `nixos-install` is tested
with. Write the minimal ISO to a USB stick, boot it with the new disk still on
the adapter (or already swapped in, see step 4), then:

```bash
sudo -i
nix-shell -p git
git clone https://github.com/nmaupu/nix-config /tmp/nc && cd /tmp/nc
# mount only (already formatted in step 1): DISK is whatever the disk is now
nix run github:nix-community/disko/latest -- --mode mount --argstr device /dev/sdX ./hosts/nmaupu-laptop/disko.nix
nixos-install --flake .#nmaupu-laptop --no-root-passwd
nixos-enter --root /mnt -c 'passwd nmaupu'
reboot
```

### From the Guix laptop (works, less beaten path)

Needs ~15-20 GB free in `/nix/store` (`df -h /nix/store`; `nix-collect-garbage`
if needed). As root, with the target still mounted under `/mnt`:

```bash
sudo env NIX_CONFIG="experimental-features = nix-command flakes" \
  /run/current-system/profile/bin/nix shell nixpkgs#nixos-install-tools -c \
  nixos-install --root /mnt --flake $NC#nmaupu-laptop --no-root-passwd
sudo env NIX_CONFIG="experimental-features = nix-command flakes" \
  /run/current-system/profile/bin/nix shell nixpkgs#nixos-install-tools -c \
  nixos-enter --root /mnt -c 'passwd nmaupu'
```

Notes:

- `nixos-install` builds the system into `/mnt/nix/store` directly (no
  daemon). If a build fails with sandbox errors on the Guix kernel, add
  `--option sandbox false`.
- The bootloader step (`bootctl install`) writes an EFI NVRAM entry on this
  laptop. That is wanted: the new disk goes into the same laptop. It also
  installs the fallback `EFI/BOOT/BOOTX64.EFI`, so the disk boots even without
  the entry. Until the swap, the Guix GRUB entry is untouched; if the adapter
  is still plugged at next reboot the firmware may boot NixOS from USB first
  (a free test run).
- If it gets in the way, fall back to the ISO: nothing on the new disk is
  lost, just re-mount and run `nixos-install` from there.

## 4. Swap the disks and first boot

1. `sudo umount -R /mnt && sudo vgchange -an nixos && sudo cryptsetup close crypt-nixos`.
2. Swap the NVMe drives (keep the Guix one, it's your rollback).
3. Boot: LUKS passphrase prompt, SDDM, session `home-manager` (default).
4. Then, as `nmaupu`:

   ```bash
   git clone git@github.com:nmaupu/nix-config.git ~/work/perso/nix-config   # if not copied with home
   npm install -g @earendil-works/pi-coding-agent   # pi (~/.npmrc prefix is set by HM)
   doom-emacs                                        # or `doom sync` if .config/emacs was copied
   # tmux: prefix + I  (tpm plugins)
   # kubectl krew: plugins in ~/.krew were copied, nothing to do
   sudo tailscale up
   ```

5. Later, to pull anything forgotten from the old disk on the adapter:

   ```bash
   sudo cryptsetup open /dev/sdX2 crypt-root && sudo vgchange -ay sys
   sudo mount /dev/sys/home /mnt
   ```
