{ inputs, modulesPath, pkgs, config, ... }:
let
  dtbName = "sc8280xp-lenovo-thinkpad-x13s.dtb";
in {
  imports = [
#    (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix")
#    (modulesPath + "/installer/cd-dvd/channel.nix")
    (modulesPath + "/installer/cd-dvd/iso-image.nix")
#    inputs.x13s.nixosModules.default
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
    (_: super: {
      # don't try and use zfs
      zfs = super.zfs.overrideAttrs (_: {
        meta.platforms = [ ];
      });

      # allow missing modules
      makeModulesClosure = x: super.makeModulesClosure (x // { allowMissing = true; });
    })
  ];

  users.users.root.initialHashedPassword = "";
  users.users.nixos = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" ];
    initialHashedPassword = "";
  };
  security.polkit.enable = true;
  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };

  services.getty.autologinUser = "nixos";

  system.autoUpgrade.flake = "github:brainwart/nixos-config";
  networking.hostName = "recovery";

  isoImage.isoBaseName = "${config.system.nixos.distroId}-recovery";
  isoImage.isoName = "${config.isoImage.isoBaseName}-${config.system.nixos.label}-${pkgs.stdenv.hostPlatform.system}.iso";
  isoImage.appendToMenuLabel = " Recovery with Synology ABB";
  isoImage.makeEfiBootable = true;
  isoImage.makeUsbBootable = true;
  isoImage.volumeID = "NIXOS";
  isoImage.edition = "recovery";

  swapDevices = [];
  fileSystems = config.lib.isoFileSystems;

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    # initrd = {
    #   systemd.enable = true;
    #   systemd.emergencyAccess = true;
    # };
    kernelParams = [
      # https://github.com/jhovold/linux/wiki/X13s
      "clk_ignore_unused"
      "pd_ignore_unused"
      "arm64.nopauth"

      # https://fedoraproject.org/wiki/Thinkpad_X13s
      "modprobe.blacklist=qcom_q6v5_pas"
    ];
  };

  hardware.enableRedistributableFirmware = true;
  hardware.deviceTree = {
    enable = pkgs.system == "aarch64-linux";
    filter = "*sc8280xp*.dtb";
    name = "${dtbName}";
  };

  boot = {
    blacklistedKernelModules = [
      "hyperv_fb"
      "qcom_q6v5_pas"
    ];
  };

  documentation.enable = false;
  nix.extraOptions = "experimental-features = nix-command flakes repl-flake";
}


