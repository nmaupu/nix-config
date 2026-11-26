# Docker (data on the dedicated /var/lib/docker LV) and libvirt/qemu.
{ pkgs, ... }:

{
  virtualisation = {
    docker = {
      enable = true;
      # Guix pinned the runc path because its runtime name changed on every
      # upgrade; nixpkgs' docker registers "runc" by name so no daemon.json needed.
      autoPrune = {
        enable = true;
        dates = "weekly";
      };
    };

    libvirtd = {
      enable = true;
      qemu = {
        package = pkgs.qemu_kvm;
        runAsRoot = false;
        swtpm.enable = true;
      };
    };
    spiceUSBRedirection.enable = true;
  };

  programs.virt-manager.enable = true;

  environment.systemPackages = with pkgs; [
    docker-compose
    qemu
  ];
}
