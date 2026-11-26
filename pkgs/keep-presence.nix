# Keep the computer awake by simulating user input
{
  lib,
  python3Packages,
  fetchFromGitHub,
}:

python3Packages.buildPythonApplication rec {
  pname = "keep-presence";
  version = "1.0.7";
  format = "other";

  src = fetchFromGitHub {
    owner = "carrot69";
    repo = "keep-presence";
    tag = "v${version}";
    hash = "sha256-dXq5ru5fHWj1uJqz+GKFJ3TVus7jXsdwoFN/6yZZyPA=";
  };

  propagatedBuildInputs = with python3Packages; [ pynput ];

  dontBuild = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 src/keep-presence.py $out/bin/keep-presence
    runHook postInstall
  '';

  meta = {
    description = "Keep the computer awake by simulating user input";
    homepage = "https://github.com/carrot69/keep-presence";
    license = lib.licenses.cc0;
    mainProgram = "keep-presence";
  };
}
