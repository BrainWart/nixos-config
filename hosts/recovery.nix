{ inputs, modulesPath, pkgs, config, ... }:
let
  dtbName = "sc8280xp-lenovo-thinkpad-x13s.dtb";

  modulesClosure = pkgs.makeModulesClosure {
    rootModules = config.boot.initrd.availableKernelModules ++ config.boot.initrd.kernelModules;
    kernel = config.system.modulesTree;
    firmware = config.hardware.firmware;
    allowMissing = false;
  };

  modulesWithExtra = pkgs.symlinkJoin {
    name = "modules-closure";
    paths = [
      modulesClosure
      pkgs.x13s.firmware.graphics
      pkgs.linux-firmware
    ];
  };
in {
  imports = [
   (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix")
   # (modulesPath + "/installer/cd-dvd/channel.nix")
   # ../tasks/tailscale.nix
   # ../tasks/recover-abb.nix
   # inputs.x13s.nixosModules.aarch64-linux.default
  ];

  # nixos-x13s.enable = true;
  nixpkgs.config.allowUnfree = true;

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

  # boot.kernelPackages = pkgs.linuxPackages_latest;
  # nixos-x13s.kernel = inputs.x13s.packages.${pkgs.system}.x13s.linux_jhovold.override { 
  #   extraStructuredConfig = {
  #     CONFIG_PHY_QCOM_EUSB2 = pkgs.lib.kernel.yes;
  #     CONFIG_PHY_QCOM_EUSB2_REPEATER = pkgs.lib.kernel.yes;
  #   };
  # };

  boot.loader.grub.enable = pkgs.lib.mkForce false;
  # boot.loader.grub.extraGrubInstallArgs = [
  #   "--modules=acpi"
  # ];

  hardware.firmware = [
    pkgs.linux-firmware
  ];

  boot.initrd = {
    systemd = {
      enable = true;
      emergencyAccess = true;
      contents = {
        "/lib".source = pkgs.lib.mkOverride 1 "${modulesWithExtra}/lib";
      };
    };
    extraFiles = {
      "lib" = {
        source = config.hardware.firmware;
      };
    };

    kernelModules = [
      # # HyperV
      # "hv_balloon" "hv_netvsc" "hv_storvsc"
      # "hv_utils" "hv_vmbus" "hyperv_keyboard"

      # x13s ubuntu concept
      # Core
      "qnoc-sc8280xp" "qcom_hwspinlock"
      "uio_pdrv_genirq"
      # NVME
      "phy_qcom_qmp_pcie" "nvme" "pcie_qcom"
      # Keyboard
      "i2c_qcom_geni" "i2c_hid_of" "hid_generic"
      # Display
      "pwm_bl" "qrtr" "phy_qcom_edp" "i2c_qcom_geni"
      "gpio_sbu_mux" "pmic_glink_altmode" "spmi_pmic_arb"
      "phy_qcom_qmp_combo" "qcom_spmi_pmic" "msm"
      "pinctrl_spmi_gpio" "leds_qcom_lpg" "panel_edp"
      # USB (required for installation from USB)
      "qcom_q6v5_pas" "usb_storage" "uas"
      # more from jhovald
      "dispcc_sc8280xp" "gpucc_sc8280xp" "ufs_qcom"
      "phy_qcom_qmp_ufs"
    ];
  };

  boot = {
    kernelParams = [
      # https://github.com/jhovold/linux/wiki/X13s
      "clk_ignore_unused"
      "pd_ignore_unused"
      "arm64.nopauth"
    ];
  };

  hardware.enableAllFirmware = true;
  hardware.deviceTree = {
    enable = true;
    filter = "*sc8280xp*.dtb";
    name = "${dtbName}";
  };
  
  isoImage.squashfsCompression = "zstd -Xcompression-level 2";
  
  documentation.enable = false;
  nix.extraOptions = "experimental-features = nix-command flakes repl-flake";
}

