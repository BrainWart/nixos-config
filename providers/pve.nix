({ config, pkgs, modulesPath, lib, options, ... }:
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    ./base.nix
  ];

  environment.etc.nixos.source = "/persist/nixos";

  boot.initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "virtio_pci" "virtio_scsi" "sd_mod" "sr_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.initrd.postDeviceCommands = pkgs.lib.mkBefore ''
    mkdir -p /mnt
    mount -o subvol=/ /dev/disk/by-label/system /mnt

    if [ ! -e /mnt/snapshots/root-blank ] ; then
      echo "root-blank not found, creating!"
      btrfs subvolume create /mnt/root-blank
      mkdir -p /mnt/snapshots
      btrfs subvolume snapshot -r /mnt/snapshots/root-blank
      btrfs subvolume delete /mnt/root-blank
    fi

    echo "deleting /root subvolume..." &&
    btrfs subvolume delete /mnt/root

    echo "restoring blank /root subvolume..."
    btrfs subvolume snapshot /mnt/snapshots/root-blank /mnt/root

    umount /mnt
    rmdir /mnt
  '';
  boot.kernelParams = [ "console=ttyS0,115200" ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  disko.devices = {
    disk = {
      vdb = {
        type = "disk";
        device = "/dev/sda";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              priority = 1;
              name = "ESP";
              start = "1M";
              end = "128M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };
            system = {
              size = "100%";
              content = {
                type = "btrfs";
                extraArgs = [ "-f" ];
                subvolumes = {
                  "/root" = {
                    mountpoint = "/";
                  };
                  "/home" = {
                    mountpoint = "/home";
                  };
                  "/persist" = {
                    mountpoint = "/persist";
                  };
                  "/nix" = {
                    mountOptions = [ "noatime" ];
                    mountpoint = "/nix";
                  };
                  "/swap" = {
                    mountpoint = "/.swapvol";
                    swap = {
                      swapfile.size = "1G";
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

  networking.useDHCP = lib.mkDefault true;

  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  mcginnis.homePrefix = "/persist";

  services.openssh.enable = true;
  services.openssh.hostKeys = map (key: key // {
    path = "/persist/ssh/ssh_host_${key.type}_key";
  }) options.services.openssh.hostKeys.default;

  services.qemuGuest.enable = true;
  services.resolved.enable = pkgs.lib.mkDefault true;
  services.resolved.fallbackDns = [];
})

