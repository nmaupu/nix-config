# Disk layout, same scheme as the Guix install (see README):
#
#   p1  1G    vfat   /boot (ESP, holds kernels+initrds for systemd-boot)  partlabel disk-main-ESP
#   p2  rest  LUKS2  -> crypt-nixos      partlabel disk-main-luks
#                    -> LVM VG "nixos"   (named differently from the Guix "sys"
#                       VG / "crypt-root" so both disks can coexist on one machine)
#     nixos-root    20G    ext4  /               (Guix: 12G; /var/lib/libvirt and /tmp live here)
#     nixos-nix     200G   ext4  /nix            (replaces gnustore 140G + nixstore 50G)
#     nixos-docker  100G   ext4  /var/lib/docker
#     nixos-log     10G    ext4  /var/log
#     nixos-swap    32G    swap  (+ hibernation)
#     nixos-home    350G   ext4  /home
#     ~240G left unallocated in the VG, like on Guix (lvextend later if needed)
#
# !!! `disko --mode destroy,format,mount` WIPES THE DISK. Never run it on an
# !!! installed system. For a fresh install only (see docs/MIGRATION.md).
#
# The target disk is a parameter so the same file serves the USB-adapter case:
#   disko --mode destroy,format,mount --argstr device /dev/sdX ./hosts/nmaupu-laptop/disko.nix
# At boot nothing depends on the device name: disko refers to partitions by
# partlabel and LVs by VG/LV name.
#
# Besides partitioning, this module makes NixOS mount these filesystems
# (fileSystems.*, swapDevices, boot.initrd.luks.devices) so hardware.nix
# does not have to repeat them.
{
  device ? "/dev/nvme0n1",
  ...
}:
{
  disko.devices = {
    disk.main = {
      type = "disk";
      inherit device;
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            size = "1G"; # ~8 generations of kernel+initrd
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [ "umask=0077" ];
            };
          };
          luks = {
            size = "100%";
            content = {
              type = "luks";
              name = "crypt-nixos";
              settings.allowDiscards = true;
              # Interactive passphrase prompt at install time
              askPassword = true;
              content = {
                type = "lvm_pv";
                vg = "nixos";
              };
            };
          };
        };
      };
    };

    lvm_vg.nixos = {
      type = "lvm_vg";
      lvs = {
        root = {
          size = "30G";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
          };
        };
        nix = {
          size = "200G";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/nix";
            mountOptions = [ "noatime" ];
          };
        };
        docker = {
          size = "100G";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/var/lib/docker";
          };
        };
        log = {
          size = "10G";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/var/log";
          };
        };
        swap = {
          size = "32G";
          content = {
            type = "swap";
            resumeDevice = true;
          };
        };
        home = {
          size = "350G";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/home";
          };
        };
      };
    };
  };
}
