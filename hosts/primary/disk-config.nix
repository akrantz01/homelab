{lib, ...}: {
  networking.hostId = "4156e94e";

  boot.loader.grub.enable = true;
  boot.loader.grub.efiSupport = true;
  boot.loader.grub.zfsSupport = true;
  boot.loader.grub.devices = ["nodev"];
  boot.loader.efi.canTouchEfiVariables = true;

  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/disk/by-id/nvme-eui.002538ba51b1ce5e";
        content = {
          type = "gpt";
          partitions = {
            boot = {
              size = "1M";
              type = "EF02";
            };
            ESP = {
              size = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "rpool";
              };
            };
          };
        };
      };
      data = {
        type = "disk";
        device = "/dev/disk/by-id/nvme-eui.002538ba51b1ce62";
        content = {
          type = "gpt";
          partitions = {
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "dpool";
              };
            };
          };
        };
      };
    };

    zpool = let
      mkPool = overrides:
        lib.recursiveUpdate {
          type = "zpool";
          mode = "";
          options = {
            ashift = "12";
            autotrim = "on";
          };

          rootFsOptions = {
            compression = "zstd";
            acltype = "posix";
            xattr = "sa";
            dnodesize = "auto";
            relatime = "on";
            normalization = "formD";
            canmount = "off";
            mountpoint = "none";
            "com.sun:auto-snapshot" = "false";
          };
        }
        overrides;

      unmountableDataset = {
        type = "zfs_fs";
        options = {
          canmount = "off";
          mountpoint = "none";
        };
      };
      dataset = path: {
        type = "zfs_fs";
        mountpoint = path;
        options.mountpoint = "legacy";
      };
    in {
      rpool = mkPool {
        postCreateHook = ''
          zfs list -t snapshot -H -o name | grep -E '^rpool/local/root@blank$' || zfs snapshot rpool/local/root@blank
        '';

        datasets = {
          local = unmountableDataset;
          "local/root" = dataset "/";
          "local/nix" = lib.recursiveUpdate (dataset "/nix") {options.atime = "off";};

          safe = unmountableDataset;
          "safe/persist" = dataset "/persist";
        };
      };

      dpool = mkPool {
        datasets = {
          srv = dataset "/srv";
        };
      };
    };
  };
}
