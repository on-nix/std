let
  inherit (inputs.nixpkgs) lib;
  inherit (inputs.std.lib) dev;

  template = (import ./action/template.nix) lib;
in {
  inherit template;
  ci = dev.mkNixago {
    output = ".github/workflows/ci-cd.yaml";
    format = "yaml";
    hook.mode = "copy";
    data = template {
      default_branch = "main";
      platform = "aws"; # gc, azure, digitalocean
      # set up with nixbuild.net to speed up builds
      withNixbuild = false;
      # use with persistent discovery; needs to be setup separately
      withPersistentDiscovery = false;
    };
  };
}
