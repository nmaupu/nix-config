# goenv needs to live in a directory named "goenv" (no version in the path),
# hence linked to ~/.local/goenv by home-manager (modules/home/dev.nix).
{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  coreutils,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "goenv";
  version = "2.2.29";

  src = fetchFromGitHub {
    owner = "go-nv";
    repo = "goenv";
    tag = finalAttrs.version;
    hash = "sha256-3Jf0VYz7tDuPgF1MEDJ7GDt8oJlDOvIJ44h0bRdlgxw=";
  };

  dontBuild = true;

  postPatch = ''
    substituteInPlace libexec/goenv-version-name libexec/goenv-which \
      --replace-fail "/bin/ls" "${coreutils}/bin/ls"
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -r . $out/
    runHook postInstall
  '';

  meta = {
    description = "Go version management (pyenv/rbenv style)";
    homepage = "https://github.com/go-nv/goenv";
    license = lib.licenses.mit;
    mainProgram = "goenv";
  };
})
