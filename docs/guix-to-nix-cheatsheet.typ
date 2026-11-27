// Guix -> Nix day-to-day cheatsheet.
// Build (from repo root):
//   nix shell nixpkgs#typst -c typst compile \
//     --font-path "$(nix build --no-link --print-out-paths nixpkgs#nerd-fonts.iosevka)" \
//     docs/guix-to-nix-cheatsheet.typ

#let guix-c = rgb("#b8860b")
#let nix-c = rgb("#5277c3")
#let ink = rgb("#1d2430")
#let muted = rgb("#6b7280")
#let rule-c = rgb("#e3e7ee")

#set document(title: "Guix → Nix cheatsheet", author: "nmaupu")
#set page(
  paper: "a4",
  flipped: true,
  margin: (x: 9mm, top: 13mm, bottom: 8mm),
  columns: 3,
  header: context [
    #set text(size: 7pt, fill: muted)
    #text(weight: "bold", fill: ink, size: 10pt)[Guix #text(fill: nix-c)[→] Nix]
    #h(6pt) day-to-day commands · NixOS + standalone Home Manager · flakes
    #h(1fr) repo: `~/work/perso/nix-config` · host `nmaupu-laptop` · #counter(page).display("1/1", both: true)
  ],
)
#set columns(gutter: 7mm)
#set text(font: "DejaVu Sans", size: 6.9pt, fill: ink)
#set par(leading: 0.42em, spacing: 0.5em)
#show raw: set text(
  font: ("Iosevka Nerd Font", "DejaVu Sans Mono"),
  size: 7.6pt,
)

// guix command (muted, above) -> nix command (bold, below) + optional note
#let g(s) = text(fill: guix-c, raw(s))
#let n(s) = text(fill: nix-c, weight: "bold", raw(s))

#let section(title, body) = block(
  breakable: false,
  above: 7pt,
  below: 0pt,
  width: 100%,
)[
  #block(
    width: 100%,
    inset: (x: 4pt, y: 2.5pt),
    fill: ink,
    radius: (top: 2pt),
    below: 0pt,
    text(fill: white, weight: "bold", size: 7.6pt, title),
  )
  #body
]

// rows: array of (guix, nix, note) ; guix or note may be none / ""
#let rows(..items) = {
  let cells = ()
  for (i, it) in items.pos().enumerate() {
    let (gx, nx, note) = if it.len() == 3 { it } else {
      (it.at(0), it.at(1), none)
    }
    cells.push(table.cell(fill: if calc.odd(i) { rgb("#f6f8fb") } else {
      white
    })[
      #if gx != none and gx != "" [#g(gx) \ ]
      #if type(nx) == str { n(nx) } else { nx }
      #if note != none and note != "" [ \ #text(fill: muted, size: 6.3pt, note)]
    ])
  }
  table(
    columns: 1fr,
    stroke: (x: none, top: none, bottom: 0.4pt + rule-c),
    inset: (x: 4pt, y: 2.6pt),
    ..cells,
  )
}

#let box-note(color, title, body) = block(
  breakable: false,
  width: 100%,
  above: 7pt,
  inset: 5pt,
  radius: 2pt,
  stroke: (left: 2pt + color),
  fill: color.lighten(90%),
)[#text(weight: "bold", fill: color, title) \ #body]

// ---------------------------------------------------------------- legend
#block(below: 2pt)[
  #set text(size: 6.4pt, fill: muted)
  #g("guix …") Guix you know #h(4pt) #n("nix …") what to type now #h(4pt)
  `nixpkgs#foo` = attribute `foo` of nixpkgs (pinned to your flake.lock, see gotchas)
]

#section[Find packages & files][
  #rows(
    (
      "guix search foo",
      "nix search nixpkgs foo",
      [Regex, several terms are ANDed, `^foo$` for exact. 1st run slow, then cached. Faster to browse: #link("https://search.nixos.org/packages")[search.nixos.org].],
    ),
    (
      "guix show foo",
      "nix search nixpkgs '^foo$'",
      [Full meta: `nix eval --json nixpkgs#foo.meta | jq`],
    ),
    ("guix package -A '^foo$'", "nix eval --raw nixpkgs#foo.version"),
    (
      "guix locate foo",
      "nix-locate bin/foo",
      [Exact match: `nix-locate -w --top-level /bin/foo`. Also libs/headers: `nix-locate libssl.so`, `nix-locate include/zlib.h`. DB is prebuilt weekly (nix-index-database).],
    ),
    (
      "",
      ", foo args",
      [Comma: run `foo` from whichever package ships it, without installing. Typing an unknown command in zsh also prints the providing packages.],
    ),
    (
      "guix edit foo",
      "nix edit nixpkgs#foo",
      [Opens the package source in `$EDITOR` (read-only store copy).],
    ),
    (
      "guix system search svc",
      "man configuration.nix",
      [Or #link("https://search.nixos.org/options")[search.nixos.org/options]. Home: `man home-configuration.nix`, `home-manager option programs.git`.],
    ),
  )
]

#section[Ad-hoc shells (guix shell / environment)][
  #rows(
    (
      "guix shell foo bar\nguix environment --ad-hoc foo bar",
      "nix shell nixpkgs#foo nixpkgs#bar",
      [Shorter, same pinned nixpkgs: `nix-shell -p foo bar`. Brace trick: `nix shell nixpkgs#{foo,bar}`],
    ),
    ("guix shell foo -- cmd args", "nix shell nixpkgs#foo -c cmd args"),
    (
      "",
      "nix run nixpkgs#foo -- args",
      [Runs the package's main program (`meta.mainProgram`).],
    ),
    (
      "guix shell --pure foo",
      "nix shell -i nixpkgs#foo",
      [`-i` = `--ignore-env`, keep vars with `-k VAR`. Legacy: `nix-shell --pure -p foo`. No `-C` container equivalent.],
    ),
    (
      "guix shell -D foo\nguix environment foo",
      "nix develop nixpkgs#foo",
      [Build env of `foo`. Inside: `genericBuild` or a single phase, e.g. `runPhase unpackPhase`.],
    ),
    (
      "guix shell python python-requests",
      "nix-shell -p 'python3.withPackages (p: [ p.requests ])'",
      [Python libs must be wrapped in the interpreter, not listed side by side.],
    ),
    (
      "guix shell -m manifest.scm",
      "nix develop",
      [Reads `devShells.default` of `./flake.nix` (legacy: `nix-shell` reads `shell.nix`).],
    ),
  )
]

#section[Other channels: -L / nonguix][
  #rows(
    (
      "guix shell -L ~/…/nonguix foo",
      "NIXPKGS_ALLOW_UNFREE=1 nix shell --impure nixpkgs#foo",
      [No nonguix: unfree stuff (firmware, chrome, slack, …) lives in nixpkgs. Your configs already allow unfree; only ad-hoc shells need this. Alias it: `alias nsu='NIXPKGS_ALLOW_UNFREE=1 nix shell --impure'`.],
    ),
    (
      "guix shell -L ~/my-channel pkg",
      "nix shell ~/work/perso/nix-config#keep-presence",
      [Any local flake: path must start with `/`, `./` or `~`.],
    ),
    (
      "channel from git",
      "nix shell github:owner/repo#pkg",
      [Also `github:o/r/<branch-or-rev>#pkg`, `git+https://host/r.git?ref=main#pkg`.],
    ),
    ("what does this channel provide?", "nix flake show github:owner/repo"),
  )
]

#section[Updating (guix pull)][
  #rows(
    (
      "guix pull",
      "update-nix",
      [Runs `nix flake update`. Bumps `flake.lock` only, applies nothing. Commit the lock file.],
    ),
    ("guix pull (one channel)", "nix flake update nixpkgs"),
    (
      "guix pull && guix upgrade\n+ reconfigure",
      "update-nix && update-system --home",
    ),
    (
      "guix describe",
      "nix flake metadata",
      [Running system: `nixos-version --json`],
    ),
    ("guix pull -l", "git log -p flake.lock"),
    (
      "guix pull --roll-back",
      "git checkout HEAD~ -- flake.lock",
      [Then rebuild. The lock file is your channel history.],
    ),
    (
      "guix time-machine --commit=X -- shell foo",
      "nix shell github:NixOS/nixpkgs/X#foo",
    ),
  )
]


#section[Imperative profile (guix install) — prefer home.packages][
  #rows(
    ("guix install foo", "nix profile add nixpkgs#foo"),
    ("guix remove foo", "nix profile remove foo"),
    (
      "guix package -I",
      "nix profile list",
      [Contains `home-manager-path`: leave it, it is your home.],
    ),
    ("guix upgrade", "nix profile upgrade --all"),
    (
      "guix package -l / --roll-back",
      "nix profile history / nix profile rollback",
    ),
  )
]

#section[Services (herd → systemd)][
  #rows(
    (
      "sudo herd status",
      "systemctl list-units --type=service",
      [`systemctl --failed` for the broken ones.],
    ),
    (
      "sudo herd status|restart|stop foo",
      "sudo systemctl status|restart|stop foo",
    ),
    ("herd restart foo (home service)", "systemctl --user restart foo"),
    (
      "tail /var/log/messages",
      "journalctl -f -u foo",
      [`journalctl -b -p err` errors this boot, `--user` for user units.],
    ),
  )
]


#section[System (guix system)][
  #rows(
    (
      "sudo guix system reconfigure config.scm",
      "update-system",
      [Runs `sudo nixos-rebuild switch --flake .#nmaupu-laptop`, then shows the package diff. Extra args pass through (`--show-trace`).],
    ),
    (
      "guix system build config.scm",
      "update-system --dry",
      [Runs `nixos-rebuild build --flake .#nmaupu-laptop` (→ `./result`)],
    ),
    (
      "",
      "sudo nixos-rebuild boot --flake .#nmaupu-laptop",
      [Default at next boot only (kernel, initrd, risky changes).],
    ),
    (
      "",
      "sudo nixos-rebuild test --flake .#nmaupu-laptop",
      [Activate now, not added to the boot menu: a reboot reverts.],
    ),
    (
      "guix system vm config.scm",
      "nixos-rebuild build-vm --flake .#nmaupu-laptop",
      [Then `./result/bin/run-nmaupu-laptop-vm`],
    ),
    ("guix system list-generations", "nixos-rebuild list-generations"),
    (
      "sudo guix system roll-back",
      "sudo nixos-rebuild switch --rollback",
      [Or pick an older entry in the systemd-boot menu.],
    ),
    (
      "sudo guix system switch-generation N",
      "sudo nix-env -p /nix/var/nix/profiles/system --switch-generation N\nsudo /nix/var/nix/profiles/system/bin/switch-to-configuration switch",
    ),
    (
      "sudo guix system delete-generations 2m",
      "sudo nix-collect-garbage --delete-older-than 60d",
      [Boot menu is cleaned at the next switch/boot.],
    ),
    (
      "",
      "nix store diff-closures /run/booted-system /run/current-system",
      [What changed since boot.],
    ),
  )
]

#section[Home (guix home)][
  #rows(
    (
      "guix home reconfigure home.scm",
      "update-home",
      [Runs `home-manager switch --flake .#nmaupu@nmaupu-laptop`. 1st time, existing dotfiles: add `-b bak`.],
    ),
    (
      "guix home build home.scm",
      "update-home --dry",
      [Runs `home-manager build --flake …`],
    ),
    ("guix home list-generations", "home-manager generations"),
    (
      "guix home roll-back\nguix home switch-generation N",
      "/nix/store/…-home-manager-generation/activate",
      [Copy the path from `home-manager generations` and run its `activate`.],
    ),
    (
      "guix home delete-generations 2m",
      "home-manager expire-generations '-60 days'",
    ),
    ("guix home describe / package -I", "home-manager packages"),
  )
]

#section[Store & garbage collection (guix gc)][
  #rows(
    (
      "guix gc",
      "nix-collect-garbage",
      [Also runs daily at 05:00 (`--delete-older-than 60d`, see `modules/nixos/base.nix`).],
    ),
    (
      "guix gc -d 2m",
      "sudo nix-collect-garbage --delete-older-than 60d",
      [`sudo` to also expire system generations; without, only your profiles.],
    ),
    ("guix gc -F 50G", "nix store gc --max 50G", [Stops after freeing 50G.]),
    (
      "guix gc --optimize",
      "nix store optimise",
      [Already automatic (`auto-optimise-store`).],
    ),
    (
      "guix gc --verify=contents,repair",
      "sudo nix-store --verify --check-contents --repair",
    ),
    (
      "guix gc --list-roots",
      "nix-store --gc --print-roots",
      [`result` symlinks are roots too: `rm result` before GC.],
    ),
    ("guix gc --references p", "nix-store -q --references p"),
    ("guix gc --referrers p", "nix-store -q --referrers p"),
    ("guix gc -R p", "nix path-info -r p"),
    (
      "guix size p",
      "nix path-info -rSh p | sort -k2 -h",
      [Interactive: `, nix-tree`],
    ),
    (
      "guix graph --path a b",
      "nix why-depends /run/current-system nixpkgs#openssl",
    ),
    ("guix archive --export", "nix copy --to ssh://host /nix/store/…"),
  )
]

#section[Build & hack on packages][
  #rows(
    (
      "guix build foo",
      "nix build nixpkgs#foo",
      [Output link `./result`; `--no-link --print-out-paths` to just print.],
    ),
    (
      "guix build -L . my-pkg",
      "nix build .#polybar-themes",
      [Your overlay (`pkgs/`), exposed as `packages.x86_64-linux.*`.],
    ),
    (
      "guix build -f foo.scm",
      "nix build --impure --expr 'with import <nixpkgs> {}; callPackage ./foo.nix {}'",
    ),
    ("guix build -S foo", "nix build nixpkgs#foo.src"),
    ("guix build -d foo", "nix derivation show nixpkgs#foo"),
    ("guix build --check foo", "nix build --rebuild nixpkgs#foo"),
    (
      "guix build -K foo",
      "nix build --keep-failed nixpkgs#foo",
      [Then `cd /tmp/nix-build-…`],
    ),
    ("guix build --log-file foo", "nix log nixpkgs#foo"),
    (
      "guix repl",
      "nix repl",
      [`:lf .` loads this flake, `:l <nixpkgs>` puts all packages in scope, `:b expr` builds.],
    ),
    (
      "guix download url / guix hash -rx .",
      "nix store prefetch-file url / nix hash path .",
      [Git sources: `, nurl https://github.com/o/r <rev>` prints a ready `fetchFromGitHub`. Or use `lib.fakeHash`, build, copy the hash from the error.],
    ),
    ("guix import …", ", nix-init", [Generates a package from a URL.]),
    ("guix lint / guix style", "nix flake check / nix fmt"),
  )
]

#colbreak()

#section[Where things live][
  #set text(size: 6.4pt)
  #table(
    columns: (auto, 1fr),
    stroke: (x: none, top: none, bottom: 0.4pt + rule-c),
    inset: (x: 4pt, y: 2pt),
    g("/gnu/store"), n("/nix/store"),
    g("channels.scm"), [#n("flake.nix") inputs + #n("flake.lock")],
    g("/etc/config.scm"), [#n("hosts/") + #n("modules/nixos/")],
    g("home.scm"), n("modules/home/"),
    g("~/.guix-home"), n("~/.local/state/nix/profiles/home-manager"),
    g("~/.guix-profile"), n("~/.nix-profile"),
    g("/var/guix/profiles/system"), n("/nix/var/nix/profiles/system"),
    g("guix-daemon"), n("nix-daemon"),
  )
]

#box-note(rgb("#c2410c"), "Gotchas")[
  #set par(spacing: 0.45em)
  - *Flakes only see git-tracked files*: `git add` new files before `update-*` (no commit needed).
  - `nixpkgs#…` comes from the *system registry*, pinned to your `flake.lock` as of the last `update-system`: no download, same versions as the system. Newer: `github:NixOS/nixpkgs/nixos-unstable#foo`.
  - `nix-shell` (dash, legacy, `<nixpkgs>`) vs `nix shell` (flakes). Both are pinned the same way, use whichever is shorter.
  - Names differ: `python-foo` → `python3Packages.foo`, `emacs-foo` → `emacsPackages.foo`, `ghc-foo` → `haskellPackages.foo`, `gcc-toolchain` → `gcc`. Search when in doubt.
  - Eval errors are cryptic: add `--show-trace`.
  - Prebuilt binaries just run (nix-ld): no more `LD_LIBRARY_PATH` wrappers.
]
