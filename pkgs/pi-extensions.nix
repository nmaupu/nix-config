# Official example extensions of the pi coding agent (plan-mode, subagent,
# agents and prompts). pi itself is installed with npm in ~/.npm-global.
# Keep the version in sync with the installed pi (pi --version).
{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "pi-extensions";
  version = "1.2.0";

  src = fetchFromGitHub {
    owner = "earendil-works";
    repo = "pi";
    tag = "v${finalAttrs.version}";
    hash = "sha256-IjNJvVxjzRur2foQDWPA5iM9sa3ThBoZU1/LT5pU6jc=";
  };

  dontBuild = true;

  installPhase = ''
    runHook preInstall
    ex=packages/coding-agent/examples/extensions
    mkdir -p $out/share/pi/extensions/subagent
    cp -r $ex/plan-mode $out/share/pi/extensions/plan-mode
    cp $ex/subagent/index.ts $ex/subagent/agents.ts $out/share/pi/extensions/subagent/
    cp -r $ex/subagent/agents $out/share/pi/agents
    cp -r $ex/subagent/prompts $out/share/pi/prompts
    runHook postInstall
  '';

  meta = {
    description = "Plan mode and subagent extensions for the pi coding agent";
    homepage = "https://github.com/earendil-works/pi";
    license = lib.licenses.mit;
  };
})
