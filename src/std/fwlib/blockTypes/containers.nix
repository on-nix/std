{
  trivial,
  root,
  super,
}:
/*
Use the Containers Blocktype for OCI-images built with nix2container.

Available actions:
  - print-image
  - publish
  - load
*/
let
  inherit (root) mkCommand actions;
  inherit (super) addSelectorFunctor;
  inherit (builtins) readFile toFile;
in
  name: {
    __functor = addSelectorFunctor;
    inherit name;
    type = "containers";
    actions = {
      currentSystem,
      fragment,
      fragmentRelPath,
      target,
      inputs,
    }: let
      inherit (inputs.n2c.packages.${currentSystem}) skopeo-nix2container;
      triv = trivial.${currentSystem};
      proviso = ./containers-proviso.sh;

      tags' =
        builtins.toFile "${target.name}-tags.json" (builtins.concatStringsSep "\n" target.image.tags);
      copyFn = ''
        copy() {
          local uri prev_tag
          uri=$1
          shift

          for tag in $(<${tags'}); do
            if ! [[ -v prev_tag ]]; then
              skopeo --insecure-policy copy nix:${target} "$uri:$tag" "$@"
            else
              # speedup: copy from the previous tag to avoid superflous network bandwidth
              skopeo --insecure-policy copy "$uri:$prev_tag" "$uri:$tag" "$@"
            fi
            echo "Done: $uri:$tag"

            prev_tag="$tag"
          done
        }
      '';
    in [
      (actions.build currentSystem target)
      (mkCommand currentSystem "print-image" "print out the image.repo with all tags" [] ''
        echo
        for tag in $(<${tags'}); do
          echo "${target.image.repo}:$tag"
        done
      '' {})
      (mkCommand currentSystem "publish" "copy the image to its remote registry" [skopeo-nix2container] ''
          ${copyFn}
          copy docker://${target.image.repo}

          # Get the digest of the published image
          DIGEST=$(skopeo inspect --raw docker://${target.image.repo}:${builtins.head target.image.tags} | jq -r '.config.digest')

          echo "$DIGEST"
          echo "$GITHUB_OUTPUT"

          # Conditionally output the name and digest for GitHub Actions
          if [ -n "$GITHUB_OUTPUT" ]; then
            echo 'out={"name": "${target.image.repo}", "digest": "'"$DIGEST"'"}' >> "$GITHUB_OUTPUT"
          fi
        '' {
          meta.image = target.image.name;
          inherit proviso;
        })
      (mkCommand currentSystem "load" "load image to the local docker daemon" [skopeo-nix2container] ''
        ${copyFn}
        if command -v podman &> /dev/null; then
           echo "Podman detected: copy to local podman"
           copy containers-storage:${target.image.repo} "$@"
        fi
        if command -v docker &> /dev/null; then
           echo "Docker detected: copy to local docker"
           copy docker-daemon:${target.image.repo} "$@"
        fi
      '' {})
    ];
  }
