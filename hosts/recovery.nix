{ inputs, modulesPath, pkgs, config, ... }:
let
  dtbName = "sc8280xp-lenovo-thinkpad-x13s.dtb";
in {
  imports = [
   (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix")
   # (modulesPath + "/installer/cd-dvd/channel.nix")
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

  # boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelPackages = pkgs.linuxPackagesFor (pkgs.callPackage ({ buildLinux, ...}@args: 
    buildLinux (
      args // {
        kernelPatches = (args.kernelPatches or [ ]);
        extraMeta.branch = "6.11.0-rc6";
        src = pkgs.fetchFromGitHub {
          owner = "jhovold";
          repo = "linux";
          rev = "wip/sc8280xp-6.11-rc6";
          hash = "sha256-p2rP8fErEnrlrkl2l4ZfnWOG2U/ohAC9blx+sTpU4+I=";
        };
        version = "6.11.0-rc6";
      }
    )
  ) {});

  boot.initrd = {
    systemd = {
      enable = false;
      emergencyAccess = true;
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
      "qnoc-sc8280xp"
      # NVME
      "phy_qcom_qmp_pcie" "nvme" # "pcie_qcom" # not a module in this version
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
    kernelPatches = with pkgs.lib; with pkgs.lib.kernel; [
      {
        patch = null;
        extraStructuredConfig = {
          ARM64_PTR_AUTH =                           no; # note<'X13s not functional yet?'>
          ARM_QCOM_CPUFREQ_HW =                      yes; # note<'X13s set to y'>
          ARM_SCMI_CPUFREQ =                         yes; # note<'X13s set to y'>
          ARM_SCPI_CPUFREQ =                         yes; # note<'X13s set to y'>
          ARM_SCPI_PROTOCOL =                        yes; # note<'X13s set to y'>
          BATTERY_QCOM_BATTMGR =                     module; # note<'X13s set to m'>
          CMA_SIZE_MBYTES =                          mkForce (freeform "128"); # note<'X13s for NVMe'>
          COMMON_CLK_QCOM =                          yes; # note<'X13s set to y'>
          COMMON_CLK_SCMI =                          yes; # note<'X13s set to y'>
          COMMON_CLK_SCPI =                          yes; # note<'X13s set to y'>
          HWSPINLOCK_QCOM =                          yes; # note<'X13s set to y'>
          INTERCONNECT_QCOM_SC8280XP =               yes; # note<'X13s set to y'>
          NVMEM_QCOM_QFPROM =                        yes; # note<'X13s set to y'>
          PCIE_QCOM =                                yes; # note<'X13s set to m'>
          PINCTRL_QCOM_SPMI_PMIC =                   module; # note<'X13s set to m'>
          PINCTRL_SC8280XP =                         yes; # note<'X13s set to y'>
          QCOM_AOSS_QMP =                            yes; # note<'X13s set to y'>
          QCOM_APCS_IPC =                            yes; # note<'X13s set to y'>
          QCOM_CLK_RPMH =                            yes; # note<'X13s set to y'>
          QCOM_CLK_SMD_RPM =                         yes; # note<'X13s set to y'>
          QCOM_CPR =                                 yes; # note<'X13s set to y'>
          QCOM_GENI_SE =                             yes; # note<'X13s set to y'>
          QCOM_LLCC =                                yes; # note<'X13s set to y'>
          QCOM_PMIC_GLINK =                          module; # note<'X13s patchset'>
          QCOM_QSEECOM =                             yes; # note<'X13s patchset'>
          QCOM_QSEECOM_UEFISECAPP =                  yes; # note<'X13s patchset'>
          QCOM_RPMPD =                               yes; # note<'X13s set to y'>
          QCOM_SMD_RPM =                             yes; # note<'X13s set to y'>
          QCOM_SMEM =                                yes; # note<'X13s set to y'>
          QCOM_SMP2P =                               yes; # note<'X13s set to y'>
          QCOM_SMSM =                                yes; # note<'X13s set to y'>
          QCOM_TSENS =                               yes; # note<'X13s set to y'>
          REGULATOR_FIXED_VOLTAGE =                  yes; # note<'X13s set to y'>
          REGULATOR_GPIO =                           yes; # note<'X13s set to y'>
          REGULATOR_QCOM_PM8008 =                    module; # note<'X13s patchset'>
          REGULATOR_QCOM_RPMH =                      yes; # note<'X13s set to y'>
          REGULATOR_QCOM_SMD_RPM =                   yes; # note<'X13s set to y'>
          REGULATOR_QCOM_SPMI =                      module; # note<'X13s set to m'>
          RPMSG_QCOM_GLINK_RPM =                     yes; # note<'X13s set to y'>
          RPMSG_QCOM_SMD =                           yes; # note<'X13s set to y'>
          SC_DISPCC_8280XP =                         yes; # note<'X13s set to y'>
          SC_GPUCC_8280XP =                          yes; # note<'X13s set to y'>
          SERIAL_QCOM_GENI =                         yes; # note<'X13s set to y'>
          SYSFB_SIMPLEFB =                           mkForce no; # note<'X13s required'>

          # ARM64_PTR_AUTH_KERNEL =                    -; # policy;<{'arm64': '-'}>
          INTERCONNECT_QCOM_BCM_VOTER =              yes;
          INTERCONNECT_QCOM_RPMH =                   yes;
          RPMSG =                                    yes;
          RPMSG_QCOM_GLINK =                         yes;
          SC_GCC_8280XP =                            yes;
        };
      }
    ];
  };

  hardware.enableRedistributableFirmware = true;
  hardware.deviceTree = {
    enable = pkgs.system == "aarch64-linux";
    filter = "*sc8280xp*.dtb";
    name = "${dtbName}";
  };
  
  isoImage.squashfsCompression = "zstd -Xcompression-level 9";
  
  documentation.enable = false;
  nix.extraOptions = "experimental-features = nix-command flakes repl-flake";
}


