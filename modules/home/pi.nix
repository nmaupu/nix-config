# pi coding agent: installed with npm (~/.npm-global, see base.nix .npmrc),
# extensions/agents/prompts/skills linked one by one so ~/.pi/agent stays
# writable (settings, sessions, auth).
{
  pkgs,
  lib,
  config,
  ...
}:

let
  share = p: "${pkgs.pi-extensions}/share/pi/${p}";

  # What `pi install <source>` would add. Merged into ~/.pi/agent/settings.json
  # (which pi also writes to, so it cannot be a read-only link); pi installs
  # missing packages on next startup. Entries are matched by identity (version
  # / git ref ignored), so bumping a version replaces the previous one.
  # Removing an entry does not remove it from settings.json: `pi remove <source>`.
  piPackages = [
    "npm:pi-ollama-cloud@0.13.0"
    "npm:@aliou/pi-guardrails@0.19.0"
    "npm:@juicesharp/rpiv-ask-user-question@2.13.8"
    "npm:@juicesharp/rpiv-todo@2.13.8"
    "npm:pi-lens@4.4.3" # native tools (ast-grep) run thanks to programs.nix-ld
    "git:github.com/obra/superpowers@v7.0.0"
  ];

  jqFilter = ''
    def id: (if type == "string" then . else .source end) | sub("@[^@/:]+$"; "");
    ($pkgs | map(id)) as $ids
    | .packages = ([(.packages // [])[] | select(id as $i | $ids | index($i) | not)] + $pkgs)
  '';
in
{
  home.file = {
    ".pi/agent/mcp.json".source = ../../files/pi/mcp.json;
    ".pi/agent/extensions/plan-mode".source = share "extensions/plan-mode";
    ".pi/agent/extensions/subagent".source = share "extensions/subagent";
    ".pi/agent/skills/frontend-design".source = "${pkgs.anthropic-skills}/skills/frontend-design";
  }
  // lib.listToAttrs (
    map (f: lib.nameValuePair ".pi/agent/agents/${f}" { source = share "agents/${f}"; }) [
      "planner.md"
      "reviewer.md"
      "scout.md"
      "worker.md"
    ]
  )
  // lib.listToAttrs (
    map (f: lib.nameValuePair ".pi/agent/prompts/${f}" { source = share "prompts/${f}"; }) [
      "implement.md"
      "implement-and-review.md"
      "scout-and-plan.md"
    ]
  );

  home.activation.piPackages = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    dir="${config.home.homeDirectory}/.pi/agent"
    file="$dir/settings.json"
    if [ -n "''${DRY_RUN:-}" ]; then
      verboseEcho "Would merge pi packages into $file"
    else
      mkdir -p "$dir"
      [ -f "$file" ] || echo '{}' > "$file"
      tmp="$file.hm-tmp"
      ${pkgs.jq}/bin/jq --argjson pkgs '${builtins.toJSON piPackages}' \
        '${jqFilter}' "$file" > "$tmp" && mv "$tmp" "$file"
    fi
  '';
}
