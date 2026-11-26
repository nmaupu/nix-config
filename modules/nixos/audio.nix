# PipeWire (Guix ran pipewire/wireplumber as home shepherd services; on NixOS
# they are systemd user services started with the session).
{ pkgs, ... }:

{
  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };

  services.pulseaudio.enable = false;

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };
  services.blueman.enable = true;

  environment.systemPackages = with pkgs; [
    alsa-utils
    pavucontrol
    pwvucontrol
    pasystray
  ];
}
