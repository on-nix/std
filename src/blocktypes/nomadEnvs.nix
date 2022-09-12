{nixpkgs}: let
  l = nixpkgs.lib // builtins;
  /*
  Use the `nomadEnvs` Blocktype for rendering job descriptions for the Nomad Cluster scheduler
  where each attribute in the block is a description of a complete Nomad namespace. Each named
  attribtute-set under the namespace contains a valid Nomad job description, written in Nix.

  i.e: `nomadEnvs.<namespace>.<job-name>.<valid-job-description>`.

  The `render` action will take this Nix job descrition, convert it to JSON and validate it,
  after which it can be run or planned with the Nomad cli.
  */
  functions = name: {
    inherit name;
    type = "nomadEnvs";

    actions = {
      system,
      flake,
      fragment,
      fragmentRelPath,
    }: [
      {
        name = "render";
        description = "build the JSON job files for this Nomad Namespace";
        command = let
          nomad = "${nixpkgs.legacyPackages.${system}.nomad}/bin";
          nixExpr = ''
            x: let
              job = builtins.mapAttrs (_: v: v // {meta = v.meta or {} // {rev = "\"$(git rev-parse --short HEAD)\"";};}) x.job;
            in
              builtins.toFile \"$job.json\" (builtins.unsafeDiscardStringContext (builtins.toJSON {inherit job;}))
          '';
        in
          # bash
          ''
            set -e
            # act from the top-level
            REPO_DIR="$(git rev-parse --show-toplevel)"
            cd "$REPO_DIR"

            if ! git check-ignore jobs --quiet; then
              printf "%s\n" "# Nomad Jobs" "jobs" >> .gitignore
              git add .gitignore
              echo >&2 "Please commit staged gitignore changes before continuing"
              # Don't exit here, as dirty check below will fail and report for us
            fi

            # use Nomad bin in path if it exists, and only fallback on nixpkgs if it doesn't
            PATH="$PATH:${nomad}"

            # use `.` instead of ${flake} to capture dirty state
            if ! jobs=$(nix eval --no-allow-dirty --raw .\#${fragment} --apply "x: toString (builtins.attrNames x)" 2>/dev/null); then
              >&2 echo "error: Will not render jobs from a dirty tree, otherwise we cannot keep good track of deployment history."
              exit 1
            fi

            for job in ''${jobs}; do
              (
                job_path="jobs/${baseNameOf fragmentRelPath}.$job.json"
                echo "Rendering to $job_path..."

                out="$(nix eval --raw .\#${fragment}."$job" --apply "${nixExpr}")"

                nix build "$out" --out-link "$job_path" 2>/dev/null

                if status=$(nomad validate "$job_path"); then
                  echo "$status for $job_path"
                fi
              )&
            done
            wait
          '';
      }
    ];
  };
in
  functions
