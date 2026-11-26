# nmaupu's fork of adi1090x/polybar-themes, "simple" flavour only
# (linked to ~/.config/polybar; xmonad runs ~/.config/polybar/launch.sh --forest)
{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
}:

stdenvNoCC.mkDerivation {
  pname = "polybar-themes";
  version = "0-unstable-2025-05-14";

  src = fetchFromGitHub {
    owner = "nmaupu";
    repo = "polybar-themes";
    rev = "5f022cf05147e0a609140391aef71665f8658b2b";
    hash = "sha256-3OVC+TwGCmKvZ2ScLDRGaH4u1noOxG4rK/GG53L+VSU=";
  };

  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -r simple/. $out/
    runHook postInstall
  '';

  meta = {
    description = "Polybar themes (simple flavour), nmaupu fork";
    homepage = "https://github.com/nmaupu/polybar-themes";
    license = lib.licenses.gpl3Only;
  };
}
