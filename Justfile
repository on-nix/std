# Autogenerated! DO NOT EDIT!
# This justfile is autogenerated via https://std.divnix.com/reference/std/nixago/just.html
# It can be used without Nix by running a locally installed  `just` binary.
# NOTE: Without Nix, you are responsible for having all task dependencies
# available locally!

# Formats all changed source files
fmt:
    treefmt $(git diff --name-only --cached)
