{
  description = "wt - a wrapper around creating and tearing down git worktrees";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems =
        f:
        nixpkgs.lib.genAttrs systems (
          system:
          f {
            inherit system;
            pkgs = nixpkgs.legacyPackages.${system};
          }
        );
    in
    {
      packages = forAllSystems (
        { pkgs, system }:
        let
          wt = pkgs.stdenvNoCC.mkDerivation {
            pname = "wt";
            version = "0.1.0";
            src = ./.;

            nativeBuildInputs = [ pkgs.makeWrapper ];

            dontConfigure = true;
            dontBuild = true;

            installPhase = ''
              runHook preInstall

              install -Dm755 wt                  "$out/bin/wt"
              install -Dm644 completions/_wt     "$out/share/zsh/site-functions/_wt"
              install -Dm644 completions/wt.bash "$out/share/bash-completion/completions/wt"

              runHook postInstall
            '';

            # The `#!/usr/bin/env bash` shebang is rewritten to a concrete bash by
            # the default patchShebangs fixup. We additionally make the tools the
            # script shells out to available. --suffix (not --prefix) so a user's
            # own git/coreutils still win -- important because `wt` execs an
            # interactive $SHELL that inherits this PATH -- while still guaranteeing
            # the tools exist when invoked from a bare environment.
            postFixup = ''
              wrapProgram "$out/bin/wt" \
                --suffix PATH : ${
                  pkgs.lib.makeBinPath [
                    pkgs.git
                    pkgs.gawk
                    pkgs.coreutils
                  ]
                }
            '';

            meta = {
              description = "Wrapper around creating and tearing down git worktrees";
              mainProgram = "wt";
              platforms = pkgs.lib.platforms.unix;
            };
          };
        in
        {
          inherit wt;
          default = wt;
        }
      );

      apps = forAllSystems (
        { system, ... }:
        let
          program = nixpkgs.lib.getExe self.packages.${system}.wt;
        in
        {
          wt = {
            type = "app";
            inherit program;
          };
          default = self.apps.${system}.wt;
        }
      );
    };
}
