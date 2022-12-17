deSystemize: nixpkgs': let
  /*
  Use the Devshells Blocktype for devShells.

  Available actions:
    - build
    - enter
  */
  devshells = name: {
    __functor = import ./__functor.nix;
    inherit name;
    type = "devshells";
    actions = {
      system,
      fragment,
      fragmentRelPath,
    }: let
      l = nixpkgs.lib // builtins;
      nixpkgs = deSystemize system nixpkgs'.legacyPackages;
    in [
      (import ./actions/build.nix nixpkgs.writeShellScriptWithPrjRoot fragment)
      {
        name = "enter";
        description = "enter this devshell";
        command = nixpkgs.writeShellScriptWithPrjRoot "enter" ''
          std_layout_dir=$PRJ_ROOT/.std
          profile_path="$std_layout_dir/${fragmentRelPath}"
          mkdir -p "$profile_path"
          nix_args=(
            "$PRJ_ROOT#${fragment}"
            "--no-update-lock-file"
            "--no-write-lock-file"
            "--no-warn-dirty"
            "--accept-flake-config"
            "--no-link"
            "--build-poll-interval" "0"
            "--builders-use-substitutes"
          )
          nix build "''${nix_args[@]}" --profile "$profile_path/shell-profile"
          bash -c "source $profile_path/shell-profile/env.bash; SHLVL=$SHLVL; __devshell-motd; exec $SHELL -i"
        '';
      }
    ];
  };
in
  devshells
