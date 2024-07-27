# Show all the tasks
list:
  @just --list --unsorted

# Build the NixOS configuration
build host="krantz":
  nix build '.#nixosConfigurations.{{host}}.config.system.build.toplevel'

# Enter a REPL for the NixOS configuration
repl host="krantz":
  nix repl '.#nixosConfigurations.{{host}}'
