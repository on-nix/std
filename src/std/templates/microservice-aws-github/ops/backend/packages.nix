let
  inherit (inputs) nixpkgs std self;

  src = std.incl self [
    "folder"
    "my.file"
  ];
in {
  my-srv-a = {
    meta.description = "my-srv-a binary executable";
  };
}
