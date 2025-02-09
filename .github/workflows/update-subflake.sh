# create the store path of
nix store add-path --name source .

# update the subflake lockfile to the (now existing) store path
(cd ./src/local && nix flake lock --update-input std && git add -f flake.lock)
(cd ./src/tests && nix flake lock --update-input std && git add -f flake.lock)
# continue normally ...
