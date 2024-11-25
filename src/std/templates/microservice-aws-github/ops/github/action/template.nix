lib: {
  default_branch,
  platform,
  withNixbuild,
  withPersistentDiscovery,
}: let
  aws = import ./aws.nix;
  installNixAction = {uses = "blaggacao/nix-quick-install-action@detect-nix-flakes-config";};
  useNixbuildAction = {
    uses = "nixbuild/nixbuild-action@v17";
    "with" = {
      nixbuild_ssh_key = "\${{ secrets.SSH_KEY }}";
      generate_summary_for = "job";
    };
  };
  discoverAction = {
    uses = "divnix/std-action/discover@main";
    id = "discovery";
  };
  runAction = {uses = "divnix/std-action/run@main";};
  # Jobs
  discover = {
    outputs.hits = "\${{ steps.discovery.outputs.hits }}";
    runs-on = "ubuntu-latest";
    steps =
      []
      # account is part of ecr url, thus part of `hits` output and needs to pass so we can't mask it
      ++ lib.optionals (platform == "aws") [(lib.recursiveUpdate aws.credentials {mask-aws-account-id = false;})]
      ++ lib.optionals (platform == "aws") [aws.ecr]
      ++ lib.optionals (!withPersistentDiscovery) [installNixAction]
      ++ lib.optionals withNixbuild [useNixbuildAction]
      ++ [discoverAction];
  };
  worker = {
    block,
    action,
    needs ? [],
    steps ? [],
  }: {
    needs = ["discover"] ++ needs;
    name = "\${{ matrix.target.jobName }}";
    "if" = "fromJSON(needs.discover.outputs.hits).${block}.${action} != '{}'";
    strategy = {
      fail-fast = false;
      matrix.target = "\${{ fromJSON(needs.discover.outputs.hits).${block}.${action} }}";
    };
    steps =
      []
      ++ [installNixAction]
      ++ lib.optionals withNixbuild [useNixbuildAction]
      ++ [runAction];
  };
in {
  name = "CI/CD";
  on = {
    pull_request.branches = [default_branch];
    push.branches = [default_branch];
  };
  permissions = {
    id-token = "write";
    contents = "read";
  };
  concurrency = {
    group = ''std-''${{ github.workflow }}-''${{ runner.os }}-''${{ github.ref }}'';
    "cancel-in-progress" = true;
  };
  jobs = {
    inherit discover;
    build = worker {
      block = "packages";
      action = "build";
    };
    images = worker {
      block = "images";
      action = "publish";
      needs = ["build"];
      steps =
        lib.optionals (platform == "aws") [aws.credentials]
        lib.optionals (platform == "aws") [aws.ecr];
    };
    deploy = worker {
      block = "deployments";
      action = "apply";
      needs = ["images"];
      steps =
        lib.optionals (platform == "aws") [aws.credentials];
    };
  };
}
