# Disk layout, same scheme as the Guix install (see README):
#
#   /dev/nvme0n1p1  512M  vfat   /boot (ESP)
#   /dev/nvme0n1p2  rest  LUKS2  -> crypt-root -> LVM VG "sys"
#     sys-root    20G    ext4  /               (Guix: 12G; /var/lib/libvirt and /tmp live here)
#     sys-nix     200G   ext4  /nix            (replaces gnustore 140G + nixstore 50G)
#     sys-docker  100G   xfs   /var/lib/docker
#     sys-log     10G    xfs   /var/log
#     sys-swap    32G    swap  (+ hibernation)
#     sys-home    350G   xfs   /home
#     ~240G left unallocated in the VG, like on Guix (lvextend later if needed)
#
# !!! `disko --mode destroy,format,mount` WIPES THE DISK. Never run it on an
# !!! installed system. For a fresh install only (see README).
#
# Besides partitioning, this module makes NixOS mount these filesystems
# (fileSystems.*, swapDevices, boot.initrd.luks.devices) so hardware.nix
# does not have to repeat them.
{
  disko.devices = {
    disk.main = {
      type = "disk";
      device = "/dev/nvme0n1";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            size = "512M";
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
              name = "crypt-root";
              settings.allowDiscards = true;
              # Interactive passphrase prompt at install time
              askPassword = true;
              content = {
                type = "lvm_pv";
                vg = "sys";
              };
            };
          };
        };
      };
    };

    lvm_vg.sys = {
      type = "lvm_vg";
      lvs = {
        root = {
          size = "20G";
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
            format = "xfs";
            mountpoint = "/var/lib/docker";
          };
        };
        log = {
          size = "10G";
          content = {
            type = "filesystem";
            format = "xfs";
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
            format = "xfs";
            mountpoint = "/home";
          };
        };
      };
    };
  };
}
