let
  inherit (inputs.std) dmerge;
  inherit (inputs.std.inputs) haumea;
  inherit (inputs.std.lib.ops) readYAML;

  loadYaml = _: _: readYAML;
  baseline = with haumea.lib;
    load {
      src = ./deployments;
      loader = [(matchers.regex ''^.+\.(yaml|yml)'' loadYaml)];
    };
in {
  my-srv-a = dmerge baseline.my-srv-a {
    meta.description = "Development Environment for my-srv-a";
    deployment = {
      spec.template.spec.containers = dmerge.updateOn "name" [
        {
          name = "my-srv-a";
          image = cell.oci-images.my-srv-a.image.name;
        }
      ];
    };
  };
}
