{ inputs, modulesPath, pkgs, config, ... }:
let
  dtbName = "sc8280xp-lenovo-thinkpad-x13s.dtb";
in {
  imports = [
#     (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix")
#     (modulesPath + "/installer/cd-dvd/channel.nix")
    (modulesPath + "/installer/cd-dvd/iso-image.nix")
    inputs.x13s.nixosModules.default
    ../tasks/tailscale.nix
    ../tasks/recover-abb.nix
  ];

  system.stateVersion = "24.11";

  nixpkgs.config.allowUnfree = true;
  nixpkgs.overlays = [
    (final: prev: {
      libvirt = (prev.libvirt.override (old: {
        enableZfs = false;
      })).overrideAttrs (old: {
        doCheck = false;
      });
    })
  ];

  nixos-x13s.enable = true;
  nixos-x13s.kernel = "mainline";
  nixos-x13s.bluetoothMac = "0C:6D:61:0D:A8:F4:00:00";

  system.autoUpgrade.flake = "github:brainwart/nixos-config";
  networking.hostName = "recovery";

  isoImage.isoBaseName = "${config.system.nixos.distroId}-recovery";
  isoImage.appendToMenuLabel = " Recovery with Synology ABB";

  isoImage.contents = [
    { source = "${config.hardware.deviceTree.package}/qcom/${dtbName}";
      target = "/boot/${dtbName}";
    }
    { source = "${config.hardware.deviceTree.package}/qcom/${dtbName}";
      target = "/EFI/boot/${dtbName}";
    }
  ];

  boot.kernelParams = [ "dtb=/boot/${dtbName}" ];

  boot.loader = {
    grub = {
      extraFiles = {
        "${dtbName}" = "${config.hardware.deviceTree.package}/qcom/${dtbName}";
      };
    };
    systemd-boot = {
      graceful = true;
      extraFiles = {
        "${dtbName}" = "${config.hardware.deviceTree.package}/qcom/${dtbName}";
      };
    };
  };

  hardware.deviceTree = {
    enable = pkgs.system == "aarch64-linux";
    name = "sc8280xp-lenovo-thinkpad-x13s.dtb";
  };
  boot = {
    blacklistedKernelModules = [ "hyperv_fb" ];
  };

  documentation.enable = false;
  nix.extraOptions = "experimental-features = nix-command flakes repl-flake";
}


