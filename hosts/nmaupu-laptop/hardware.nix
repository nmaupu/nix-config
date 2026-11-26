# ThinkPad X1 Carbon Gen 13 (21NSCTO1WW), Intel Core Ultra 7 258V (Lunar Lake),
# Arc 140V iGPU, Intel BE200 Wi-Fi 7, 32GB RAM, 1TB NVMe.
#
# Filesystems, LUKS and LVM are declared in ./disko.nix (single source of
# truth for the disk layout); disko generates fileSystems / swapDevices /
# boot.initrd.luks from it.
{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot = {
    # Guix was on a 7.x kernel; Lunar Lake graphics/wifi want something recent.
    kernelPackages = pkgs.linuxPackages_latest;

    initrd = {
      availableKernelModules = [
        "xhci_pci"
        "thunderbolt"
        "nvme"
        "usb_storage"
        "sd_mod"
      ];
      kernelModules = [ "dm-snapshot" ];
      # LVM on top of LUKS: activate the VG in the initrd
      services.lvm.enable = true;
    };

    kernelModules = [ "kvm-intel" ];
    extraModulePackages = [ ];

    # boot.resumeDevice (hibernation) is set by disko from the swap LV (/dev/nixos/swap)

    loader = {
      # systemd-boot with the ESP on /boot. Guix used GRUB with /boot on the
      # encrypted root (which is why the LUKS header was pbkdf2 for GRUB).
      # With the kernels on the ESP, LUKS2 can use argon2id and we only unlock once.
      systemd-boot = {
        enable = true;
        configurationLimit = 8;
      };
      efi.canTouchEfiVariables = true;
    };
  };

  hardware = {
    cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    enableRedistributableFirmware = true; # linux-firmware, sof-firmware, ...

    graphics = {
      enable = true;
      extraPackages = with pkgs; [
        intel-media-driver # VA-API (iHD) for Arc 140V
        vpl-gpu-rt # Intel oneVPL (QSV)
      ];
    };
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
