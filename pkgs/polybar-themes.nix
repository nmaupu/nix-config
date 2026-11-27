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
    rev = "058cfb5d2ee3f5be54410bff5648eba65d615cf9";
    hash = "sha256-PhqWVflkZlv7I5VLynNGKDQOWZ1tZ5InLLZbLUzf5E0=";
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
