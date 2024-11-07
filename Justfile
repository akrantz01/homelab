# Show all the tasks
list:
  @just --list --unsorted

# Build the NixOS configuration
build host="krantz":
  nix build '.#nixosConfigurations.{{host}}.config.system.build.toplevel'

# Enter a REPL for the NixOS configuration
repl host="krantz":
  nix repl '.#nixosConfigurations.{{host}}'

# Compute the diff between two NixOS configurations
diff from to="HEAD" host="krantz":
  #!/usr/bin/env bash
  set -euxo pipefail
  
  just build '{{host}}'
  to_drv=$(readlink -f "result")
  rev=$(git rev-parse --abbrev-ref HEAD)

  git checkout '{{from}}'
  just build '{{host}}'
  from_drv=$(readlink -f "result")

  git checkout "$rev"

  nix-diff --color always "$from_drv" "$to_drv" | less -R
