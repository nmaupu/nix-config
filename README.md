# nix-config

NixOS + Home Manager configuration (flake), ported from the Guix setup in
[guix-config](https://github.com/nmaupu/guix-config).

```
flake.nix                 inputs (nixpkgs unstable, home-manager, disko, nixos-hardware), hosts
hosts/nmaupu-laptop/      host: hardware, disk layout (disko), home-manager wiring
modules/nixos/            system: base, desktop (X11/SDDM/xmonad), audio, services, virtualisation, 1password
modules/home/             user: base, shells, git, tmux, wm, emacs, dev, k8s, pi, work (toggle)
pkgs/                     packages missing from nixpkgs (overlay)
files/                    dotfiles linked by home-manager
```

## Day to day

```bash
# system + home in one go (replaces update-system / update-home)
sudo nixos-rebuild switch --flake ~/work/perso/nix-config#nmaupu-laptop

# update inputs (replaces update-channels)
nix flake update ~/work/perso/nix-config

# check without switching
nix flake check ~/work/perso/nix-config
nixos-rebuild build --flake ~/work/perso/nix-config#nmaupu-laptop
```

Work tools are enabled per host with `nmaupu.work.enable = true` in
`hosts/<host>/default.nix`.

## Fresh install

Disk layout (same as Guix, minus the Guix store):

```
/dev/nvme0n1p1  512M  vfat   /boot  (ESP)
/dev/nvme0n1p2  rest  LUKS2  crypt-root -> LVM VG "sys"
  sys-root    20G    ext4  /
  sys-nix     200G   ext4  /nix
  sys-docker  100G   xfs   /var/lib/docker
  sys-log     10G    xfs   /var/log
  sys-swap    32G    swap  (hibernation)
  sys-home    350G   xfs   /home
  (rest of the VG left unallocated, as on Guix)
```

Differences with Guix, on purpose:

- bootloader is systemd-boot with the ESP on `/boot` (Guix: GRUB, ESP on
  `/boot/efi`, `/boot` on the encrypted root). LUKS is only unlocked once, in
  the initrd, and LUKS2 can use its default argon2id (Guix needed `--pbkdf
  pbkdf2` for GRUB).
- `/nix` is one LV (Guix had `/gnu/store` + `/nix/store`).

1. Boot the NixOS minimal ISO, get network (`sudo systemctl start wpa_supplicant`
   + `wpa_cli`, or ethernet).
2. Get the config:

   ```bash
   sudo -i
   nix-shell -p git
   git clone https://github.com/nmaupu/nix-config /tmp/nix-config
   cd /tmp/nix-config
   ```

3. Partition, format and mount with disko. **This wipes `/dev/nvme0n1`.**

   ```bash
   nix --experimental-features "nix-command flakes" run github:nix-community/disko/latest -- \
     --mode destroy,format,mount --flake .#nmaupu-laptop
   ```

   disko asks for the LUKS passphrase. Everything ends up mounted under `/mnt`.

   If you prefer partitioning by hand (cfdisk/cryptsetup/lvcreate like the Guix
   README), keep the device names above (`crypt-root`, VG `sys`, LV names) and
   use `disko --mode mount --flake .#nmaupu-laptop` to mount, or mount manually
   under `/mnt`, `/mnt/boot`, `/mnt/nix`, ...

4. Install:

   ```bash
   nixos-install --flake .#nmaupu-laptop --no-root-passwd
   nixos-enter --root /mnt -c 'passwd nmaupu'
   reboot
   ```

5. After first login (SDDM session "home-manager"):

   ```bash
   git clone git@github.com:nmaupu/nix-config.git ~/work/perso/nix-config
   # pi is an npm install (prefix ~/.npm-global is set by ~/.npmrc)
   npm install -g @earendil-works/pi-coding-agent
   # first run clones doom + config, ~5 min
   doom-emacs
   # tmux plugins: prefix + I
   # krew plugins: ~/.krew (manual, as before)
   # private files not managed here: ~/.gitconfig-pro, ~/.zshrc.d/*, ~/.kube/conf.d/*, ~/.config/nix/netrc
   ```

## Notes

- `programs.nix-ld` is enabled: prebuilt binaries (goenv's go toolchains,
  tfenv's terraform, npm native modules such as pi-lens' ast-grep, ...) run
  without the `LD_LIBRARY_PATH` wrappers Guix needed.
- `nmaupu` is a nix trusted user, so `~/.config/nix/nix.conf` can add work
  substituters / `netrc-file`.
- xmonad is provided by the NixOS module (ghc + xmonad-contrib on PATH), so
  `mod+q` recompiles `~/.config/xmonad/xmonad.hs` as before. The file is a
  read-only link to this repo: edit it here, then `nixos-rebuild switch`.
- `~/.pi/agent/settings.json` gets the pi package list merged in at activation
  (`modules/home/pi.nix`), pi installs them on next startup.
