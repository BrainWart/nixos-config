{ inputs, modulesPath, pkgs, config, ... }:
{
  imports = [
    inputs.disko.nixosModules.disko
    inputs.nixos-hardware.nixosModules.lenovo-thinkpad-x13s
    ../providers/base.nix
  ];

  system.stateVersion = "25.11";

  networking.hostName = "x13s";

  programs.regreet.enable = true;
  programs.niri.enable = true;
  programs.waybar.enable = true;

  boot.loader.systemd-boot.enable = true;

  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/nvme0n1";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              priority = 1;
              name = "ESP";
              size = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };
            root = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            };
          };
        };
      };
    };
  };
}
