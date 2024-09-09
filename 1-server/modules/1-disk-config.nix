{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/disk/by-id/ata-WDC_WDS120G2G0B-00EPW0_185253802728";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [
                  "defaults"
                ];
              };
            };
            luks = {
              size = "100%";
              content = {
                type = "luks";
                name = "heimdall_crypt";
                passwordFile = "/tmp/disk-1.key"; # Interactive
                settings = {
                  allowDiscards = true;
                };
                content = {
                  type = "btrfs";
                  extraArgs = [ "-f" ];
                  postCreateHook = /* sh */ ''
										MNTPOINT=$(mktemp -d)
										mount "/dev/mapper/heimdall_crypt" "$MNTPOINT" -o subvol=/
										trap 'umount $MNTPOINT; rm -rf $MNTPOINT' EXIT
										btrfs subvolume snapshot -r "$MNTPOINT"/root "$MNTPOINT"/root-blank
									'';
                  subvolumes = {
                    "/root" = {
                      mountpoint = "/";
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };
                    "/home" = {
                      mountpoint = "/home";
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };
                    "/nix" = {
                      mountpoint = "/nix";
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };
                    "/persistent" = {
                      mountpoint = "/persistent";
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };
                    "/swap" = {
                      mountpoint = "/.swapvol";
                      swap.swapfile.size = "8G";
                    };
                  };
                };
              };
            };
          };
        };
      };
    };
  };
  fileSystems."/persistent".neededForBoot = true;
}
