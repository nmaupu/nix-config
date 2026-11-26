# tmux plugin manager, linked to ~/.tmux/plugins/tpm. Plugins themselves are
# installed by tpm (prefix + I) into the writable ~/.tmux/plugins.
{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "tmux-tpm";
  version = "3.1.0";

  src = fetchFromGitHub {
    owner = "tmux-plugins";
    repo = "tpm";
    tag = "v${finalAttrs.version}";
    hash = "sha256-CeI9Wq6tHqV68woE11lIY4cLoNY8XWyXyMHTDmFKJKI=";
  };

  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -r . $out/
    runHook postInstall
  '';

  meta = {
    description = "Tmux Plugin Manager";
    homepage = "https://github.com/tmux-plugins/tpm";
    license = lib.licenses.mit;
  };
})
