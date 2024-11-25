let
  inherit (inputs) std;
  inherit (inputs.nixpkgs) lib;
in {
  my-srv-a = std.lib.ops.mkOperable {
    package = cell.packages.my-srv-a;
    runtimeScript = lib.getExe cell.packages.my-srv-a;
    meta.description = "A thin warpper around my-srv-a binary executable";
  };
}
