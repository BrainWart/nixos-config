{ inputs, modulesPath, pkgs, config, ... }:
let
  dtbName = "sc8280xp-lenovo-thinkpad-x13s.dtb";
in {
  imports = [
   (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix")
   (modulesPath + "/installer/cd-dvd/channel.nix")
    ../tasks/tailscale.nix
    ../tasks/recover-abb.nix
  ];

  system.stateVersion = "24.11";

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

  system.autoUpgrade.flake = "github:brainwart/nixos-config";
  networking.hostName = "recovery";

  isoImage.isoBaseName = "${config.system.nixos.distroId}-recovery";
  isoImage.appendToMenuLabel = " Recovery with Synology ABB";

  boot.kernelPackages = pkgs.linuxPackages_latest;

  # # include all modules in the initrd
  # boot.initrd.availableKernelModules = builtins.concatLists (
  #   builtins.filter
  #     builtins.isList
  #     (map
  #       (builtins.match "^.*/(.*)\.ko\.xz$")
  #       (pkgs.lib.filesystem.listFilesRecursive "${config.boot.kernelPackages.kernel}")));

  boot.initrd.kernelModules = [
    # hyperv
    "hv_balloon" "hv_netvsc" "hv_storvsc" "hv_utils" "hv_vmbus"
    "hyperv_keyboard"

    # x13s
    "nvme" "phy-qcom-qmp-pcie" "pcie-qcom"
    "i2c-core" "i2c-hid" "i2c-hid-of" "i2c-qcom-geni"
    "leds_qcom_lpg" "pwm_bl" "qrtr" "pmic_glink_altmode"
    "gpio_sbu_mux" "phy-qcom-qmp-combo" "gpucc_sc8280xp"
    "dispcc_sc8280xp" "phy_qcom_edp" "panel-edp" "msm"
  ];

  boot = {
    kernelParams = [
      # https://github.com/jhovold/linux/wiki/X13s
      "clk_ignore_unused"
      "pd_ignore_unused"
      "arm64.nopauth"

      # https://fedoraproject.org/wiki/Thinkpad_X13s
      "modprobe.blacklist=qcom_q6v5_pas"
    ];
  };

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


