# System services: network, printing, power, misc daemons.
{ pkgs, ... }:

{
  networking = {
    networkmanager = {
      enable = true;
      plugins = [ pkgs.networkmanager-openvpn ];
    };
    firewall = {
      enable = true;
      # tailscale
      trustedInterfaces = [ "tailscale0" ];
      allowedUDPPorts = [ 41641 ];
    };
  };

  programs.nm-applet.enable = true;

  services = {
    openssh.enable = true;
    tailscale.enable = true;

    # mDNS: resolve .local names (Guix: %mdns-host-lookup-nss)
    avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };

    # Printing / scanning
    printing = {
      enable = true;
      webInterface = true;
      drivers = with pkgs; [
        brlaser
        cups-filters
      ];
    };

    # Desktop plumbing (udisks, upower, ...)
    udisks2.enable = true;
    upower.enable = true;
    accounts-daemon.enable = true;
    colord.enable = true;
    geoclue2.enable = true;
    gvfs.enable = true;
    dbus.enable = true;

    # udev rules: brightnessctl (video group), MTP devices
    udev.packages = with pkgs; [
      brightnessctl
      libmtp
    ];

    # Power & thermal
    thermald.enable = true;
    tlp = {
      enable = true;
      settings = {
        CPU_BOOST_ON_AC = 1;
        WIFI_PWR_ON_BAT = "on";
      };
    };
    power-profiles-daemon.enable = false; # conflicts with tlp

    # Firmware updates (ThinkPad)
    fwupd.enable = true;

    syncthing = {
      enable = true;
      user = "nmaupu";
      dataDir = "/home/nmaupu";
    };
  };

  hardware = {
    sane.enable = true;
    usb-modeswitch.enable = true;
  };

  security.polkit.enable = true;
}
