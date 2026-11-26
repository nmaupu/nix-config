# Anthropic's Agent Skills collection; only selected skills are linked into
# ~/.pi/agent/skills (modules/home/pi.nix).
{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
}:

stdenvNoCC.mkDerivation {
  pname = "anthropic-skills";
  version = "0-unstable-2025-11";

  src = fetchFromGitHub {
    owner = "anthropics";
    repo = "skills";
    rev = "dbd4588f9e1033efb41dad4bef2f7947c8993d44";
    hash = "sha256-+UIqBnzyeIOvJSKYaDaE3GYPEpLw7qQqyUw5S971AfU=";
  };

  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -r . $out/
    runHook postInstall
  '';

  meta = {
    description = "Anthropic Agent Skills";
    homepage = "https://github.com/anthropics/skills";
    license = lib.licenses.asl20;
  };
}
