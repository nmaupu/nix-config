# Icon fonts shipped by adi1090x/polybar-themes (used by the polybar themes)
{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
}:

stdenvNoCC.mkDerivation {
  pname = "polybar-themes-fonts";
  version = "0-unstable-2024";

  src = fetchFromGitHub {
    owner = "adi1090x";
    repo = "polybar-themes";
    rev = "396a4c3649c2ad15c4724dd541c433b249bb0b9a";
    hash = "sha256-YjWT6akJibw2ANLM1L/YOibPysunfI14czASyk8y8QI=";
  };

  dontBuild = true;

  installPhase = ''
    runHook preInstall
    find fonts -type f \( -iname '*.ttf' -o -iname '*.otf' -o -iname '*.ttc' -o -iname '*.otc' \) \
      -exec install -Dm444 -t $out/share/fonts/truetype/polybar-themes {} +
    runHook postInstall
  '';

  meta = {
    description = "Fonts bundled with adi1090x/polybar-themes";
    homepage = "https://github.com/adi1090x/polybar-themes";
    license = lib.licenses.mit;
  };
}
