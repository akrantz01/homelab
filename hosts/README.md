# Adding a new host

## Bare metal/lightly managed VPS

1. Create new host folder with a `default.nix`
    - Be sure to include any boot configurations and timezone info
2. Create disk config via [disko][]
3. Create new SOPS secrets (in `secrets/<hostname>/default.yaml`)
    - Requires at least `users.alex` and `tailscale.key` keys
    - Generate new Tailscale auth key for `tailscale.key`
    - Block to add under `creation_rules` in `.sops.yaml`
      ```yaml
      - path_regex: secrets/nix/<hostname>/[^/]+\.(yaml|yml|env)$
        key_groups:
          - age:
            - *personal
      ```
4. Temporarily modify common system options (DO NOT PUSH TO REMOTE)
    1. Expose SSH publicly and enable password authentication (in `common/ssh.nix`)
    2. Replace `hashedPasswordFile` with inlined `hashedPassword` (in `common/users.nix`)
        - This is a workaround since we don't have a host key to use with SOPS yet
        - But we still need access to the system later
5. Perform initial deployment:
    ```sh
    nixos-anywhere \
        --flake .#<hostname> \
        --target-host <user@ip> \
        --generate-hardware-config nixos-generate-config ./hosts/<hostname>/hardware-configuration.nix
    ```
      - Partitioning may fail at this point if the host uses ZFS, see [this section](#troubleshooting)
6. Fetch the public key and regenerate the SOPS secrets
    ```sh
    ssh-keyscan <ip> | ssh-to-age
    # Add age key to host-specific key group(s)
    sops updatekeys secrets/nix/<hostname>/default.nix
    ```
7. Re-deploy with the new secrets
    ```sh
    nixos-rebuild switch \
        --option accept-flake-config true \
        --option tarball-ttl 0 \
        --refresh \
        --flake .#<hostname> \
        --upgrade \
        --target-host <user@ip> \
        --use-remote-sudo
    ```
8. Reboot the system
9. Verify that connection through Tailscale works
10. Revert the temporary changes from step 4
11. Re-deploy the host again with the command from step 7

Future deployments should be done using the Tailscale hostname, unless continuous deployment is enabled.


## Troubleshooting

### ZFS: cannot create '<pool>/<dataset>': no such pool '<pool>'

A pool may fail to create because an `ext4` filesystem already existed on one or more of the drives meant to be in the pool. You can verify this by looking for any logs like:
```
device /dev/disk/by-partlabel/disk-main-zfs already has a partition, skipping creating zpool rpool
```

If this occurred, you'll need to completely wipe all data from the drives in question using the following:
```sh
zpool destroy -f <pool>
wipefs -af /dev/<disk>
sgdisk --zap-all /dev/<disk>
zpool labelclear -f /dev/<disk>
blkdiscard /dev/<disk>
```

[disko]: https://github.com/nix-community/disko
