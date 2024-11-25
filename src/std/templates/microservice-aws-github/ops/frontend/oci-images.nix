let
  inherit (inputs) std;
in {
  my-srv-a = std.lib.ops.mkStandardOCI {
    name = "ghcr.io/myorg/myrepo/my-srv-a";
    operable = cell.operables.my-srv-a;
    meta.description = "Minimal OCI Image for my-srv-a";
  };
}
