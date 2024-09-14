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

  boot.loader.grub.extraGrubInstallArgs = [
    "--modules=acpi"
  ];

  boot.initrd = {
    systemd = {
      enable = false;
      emergencyAccess = true;
    };
    # extraFiles = {
    #   "lib" = {
    #     source = config.hardware.firmware;
    #   };
    # };

    kernelModules = [
      # # HyperV
      # "hv_balloon" "hv_netvsc" "hv_storvsc"
      # "hv_utils" "hv_vmbus" "hyperv_keyboard"

      # x13s ubuntu concept
      # Core
      "qnoc-sc8280xp"
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
    kernelPatches = with pkgs.lib; with pkgs.lib.kernel; [
      {
        patch = null;
        extraStructuredConfig = {
          SYSVIPC = yes;
          POSIX_MQUEUE = yes;
          AUDIT = yes;
          NO_HZ_IDLE = yes;
          HIGH_RES_TIMERS = yes;
          BPF_SYSCALL = yes;
          BPF_JIT = yes;
          PREEMPT = pkgs.lib.mkForce yes;
          IRQ_TIME_ACCOUNTING = yes;
          BSD_PROCESS_ACCT = yes;
          BSD_PROCESS_ACCT_V3 = yes;
          TASKSTATS = yes;
          TASK_XACCT = yes;
          TASK_IO_ACCOUNTING = yes;
          IKCONFIG = yes;
          IKPROC = yes;
          NUMA_BALANCING = yes;
          MEMCG = yes;
          BLK_CGROUP = yes;
          CGROUP_PIDS = yes;
          CGROUP_HUGETLB = yes;
          CPUSETS = yes;
          CGROUP_DEVICE = yes;
          CGROUP_CPUACCT = yes;
          CGROUP_PERF = yes;
          CGROUP_BPF = yes;
          USER_NS = yes;
          SCHED_AUTOGROUP = yes;
          BLK_DEV_INITRD = yes;
          PROFILING = yes;
          ARCH_QCOM = yes;
          # ARM64_ERRATUM_2077057 is not set
          # ARM64_ERRATUM_3194386 is not set
          # ROCKCHIP_ERRATUM_3588001 is not set
          ARM64_VA_BITS_48 = yes;
          SCHED_MC = yes;
          SCHED_SMT = yes;
          NUMA = yes;
          COMPAT = yes;
          # ARM64_SME is not set
          RANDOMIZE_BASE = yes;
          HIBERNATION = yes;
          WQ_POWER_EFFICIENT_DEFAULT = yes;
          ENERGY_MODEL = yes;
          CPU_IDLE = yes;
          ARM_PSCI_CPUIDLE = yes;
          CPU_FREQ = yes;
          CPU_FREQ_STAT = yes;
          CPU_FREQ_GOV_POWERSAVE = module;
          CPU_FREQ_GOV_USERSPACE = yes;
          CPU_FREQ_GOV_ONDEMAND = yes;
          CPU_FREQ_GOV_CONSERVATIVE = module;
          CPUFREQ_DT_PLATDEV = yes;
          ARM_QCOM_CPUFREQ_HW = yes;
          JUMP_LABEL = yes;
          MODULES = yes;
          MODULE_UNLOAD = yes;
          # BLOCK_LEGACY_AUTOLOAD is not set
          # IOSCHED_BFQ is not set
          # CORE_DUMP_DEFAULT_ELF_HEADERS is not set
          # BINFMT_MISC = module;
          KSM = yes;
          MEMORY_FAILURE = yes;
          TRANSPARENT_HUGEPAGE = yes;
          CMA = yes;
          NET = yes;
          PACKET = yes;
          UNIX = yes;
          INET = yes;
          IP_MULTICAST = yes;
          IP_ADVANCED_ROUTER = yes;
          IP_MULTIPLE_TABLES = yes;
          IP_PNP = pkgs.lib.mkForce yes;
          IP_PNP_DHCP = pkgs.lib.mkForce yes;
          IP_PNP_BOOTP = pkgs.lib.mkForce yes;
          # IPV6 = module;
          IPV6_MULTIPLE_TABLES = yes;
          NETFILTER = yes;
          NF_CONNTRACK = module;
          NF_CONNTRACK_EVENTS = yes;
          NETFILTER_XTABLES_COMPAT = yes;
          NETFILTER_XT_MARK = module;
          NETFILTER_XT_TARGET_LOG = module;
          NETFILTER_XT_MATCH_ADDRTYPE = module;
          NETFILTER_XT_MATCH_COMMENT = module;
          NETFILTER_XT_MATCH_CONNMARK = module;
          NETFILTER_XT_MATCH_CONNTRACK = module;
          IP_NF_IPTABLES = module;
          IP_NF_FILTER = module;
          IP_NF_TARGET_REJECT = module;
          IP_NF_MANGLE = module;
          IP_NF_RAW = module;
          IP6_NF_IPTABLES = module;
          IP6_NF_FILTER = module;
          IP6_NF_TARGET_REJECT = module;
          IP6_NF_MANGLE = module;
          IP6_NF_RAW = module;
          QRTR_SMD = module;
          QRTR_TUN = module;
          BT = module;
          BT_RFCOMM = module;
          BT_HIDP = module;
          BT_HCIUART = module;
          BT_HCIUART_QCA = yes;
          CFG80211 = module;
          MAC80211 = module;
          MAC80211_LEDS = yes;
          RFKILL = module;
          PCI = yes;
          PCIEPORTBUS = yes;
          PCIEAER = yes;
          PCIE_QCOM = module;
          DEVTMPFS = yes;
          DEVTMPFS_MOUNT = yes;
          FW_LOADER_USER_HELPER = yes;
          FW_LOADER_COMPRESS = yes;
          FW_LOADER_COMPRESS_ZSTD = yes;
          # QCOM_EBI2 is not set
          MHI_BUS_PCI_GENERIC = module;
          EFI_CAPSULE_LOADER = yes;
          QCOM_QSEECOM = yes;
          QCOM_QSEECOM_UEFISECAPP = yes;
          ZRAM = module;
          BLK_DEV_LOOP = yes;
          BLK_DEV_NVME = module;
          QCOM_FASTRPC = module;
          SCSI = yes;
          # SCSI_PROC_FS is not set
          BLK_DEV_SD = yes;
          # SCSI_LOWLEVEL is not set
          MD = yes;
          BLK_DEV_DM = module;
          DM_CRYPT = module;
          NETDEVICES = yes;
          WIREGUARD = module;
          TUN = yes;
          VETH = module;
          # ETHERNET is not set
          USB_NET_DRIVERS = module;
          USB_RTL8152 = module;
          # WLAN_VENDOR_ADMTEK is not set
          ATH11K = module;
          ATH11K_PCI = module;
          # WLAN_VENDOR_ATMEL is not set
          # WLAN_VENDOR_BROADCOM is not set
          # WLAN_VENDOR_INTEL is not set
          # WLAN_VENDOR_INTERSIL is not set
          # WLAN_VENDOR_MARVELL is not set
          # WLAN_VENDOR_MEDIATEK is not set
          # WLAN_VENDOR_MICROCHIP is not set
          # WLAN_VENDOR_PURELIFI is not set
          # WLAN_VENDOR_RALINK is not set
          # WLAN_VENDOR_REALTEK is not set
          # WLAN_VENDOR_RSI is not set
          # WLAN_VENDOR_SILABS is not set
          # WLAN_VENDOR_ST is not set
          # WLAN_VENDOR_TI is not set
          # WLAN_VENDOR_ZYDAS is not set
          # WLAN_VENDOR_QUANTENNA is not set
          WWAN = module;
          MHI_WWAN_CTRL = module;
          MHI_WWAN_MBIM = module;
          INPUT_EVDEV = yes;
          # KEYBOARD_ATKBD is not set
          KEYBOARD_GPIO = yes;
          # INPUT_MOUSE is not set
          INPUT_MISC = yes;
          INPUT_PM8941_PWRKEY = yes;
          # SERIO is not set
          LEGACY_PTY_COUNT = freeform "16";
          SERIAL_QCOM_GENI = yes;
          SERIAL_QCOM_GENI_CONSOLE = yes;
          SERIAL_DEV_BUS = yes;
          # DEVPORT is not set
          I2C_CHARDEV = module;
          I2C_QCOM_CCI = module;
          I2C_QCOM_GENI = module;
          SPI = yes;
          SPI_QCOM_GENI = module;
          SPMI = yes;
          PINCTRL_SINGLE = yes;
          PINCTRL_MSM = yes;
          PINCTRL_SC8280XP = yes;
          PINCTRL_QCOM_SPMI_PMIC = yes;
          PINCTRL_LPASS_LPI = module;
          PINCTRL_SC8280XP_LPASS_LPI = module;
          POWER_RESET_QCOM_PON = module;
          BATTERY_QCOM_BATTMGR = module;
          THERMAL = yes;
          THERMAL_GOV_POWER_ALLOCATOR = yes;
          CPU_THERMAL = yes;
          DEVFREQ_THERMAL = yes;
          THERMAL_EMULATION = yes;
          QCOM_TSENS = yes;
          QCOM_SPMI_ADC_TM5 = module;
          QCOM_SPMI_TEMP_ALARM = module;
          QCOM_LMH = module;
          WATCHDOG = yes;
          WATCHDOG_CORE = yes;
          QCOM_WDT = module;
          MFD_SPMI_PMIC = yes;
          MFD_QCOM_PM8008 = module;
          REGULATOR_FIXED_VOLTAGE = yes;
          REGULATOR_QCOM_PM8008 = module;
          REGULATOR_QCOM_RPMH = yes;
          MEDIA_SUPPORT = module;
          MEDIA_CAMERA_SUPPORT = yes;
          MEDIA_PLATFORM_SUPPORT = yes;
          MEDIA_USB_SUPPORT = yes;
          USB_VIDEO_CLASS = module;
          V4L_PLATFORM_DRIVERS = yes;
          V4L_MEM2MEM_DRIVERS = yes;
          VIDEO_QCOM_CAMSS = module;
          VIDEO_QCOM_VENUS = module;
          VIDEO_OV5675 = module;
          # DRM = module;
          DRM_MALI_DISPLAY = module;
          DRM_MSM = module;
          # DRM_MSM_MDP4 is not set
          # DRM_MSM_MDP5 is not set
          # DRM_MSM_DSI is not set
          # DRM_MSM_HDMI is not set
          DRM_PANEL_EDP = module;
          DRM_DISPLAY_CONNECTOR = module;
          FB = yes;
          FB_EFI = yes;
          BACKLIGHT_CLASS_DEVICE = yes;
          BACKLIGHT_PWM = module;
          SOUND = module;
          SND = module;
          # SND_SUPPORT_OLD_API is not set
          # SND_DRIVERS is not set
          # SND_PCI is not set
          # SND_SPI is not set
          SND_USB_AUDIO = module;
          SND_SOC = module;
          SND_SOC_QCOM = module;
          SND_SOC_SC8280XP = module;
          SND_SOC_WCD938X_SDW = module;
          SND_SOC_WSA883X = module;
          SND_SOC_LPASS_WSA_MACRO = module;
          SND_SOC_LPASS_VA_MACRO = module;
          SND_SOC_LPASS_RX_MACRO = module;
          SND_SOC_LPASS_TX_MACRO = module;
          UHID = module;
          # HID_A4TECH is not set
          # HID_APPLE is not set
          # HID_BELKIN is not set
          # HID_CHERRY is not set
          # HID_CHICONY is not set
          # HID_CYPRESS is not set
          # HID_EZKEY is not set
          # HID_ITE is not set
          # HID_KENSINGTON is not set
          # HID_LOGITECH is not set
          # HID_REDRAGON is not set
          # HID_MICROSOFT is not set
          # HID_MONTEREY is not set
          HID_MULTITOUCH = module;
          I2C_HID_OF = module;
          I2C_HID_OF_ELAN = module;
          USB = yes;
          # USB_PCI is not set
          USB_OTG = yes;
          USB_XHCI_HCD = yes;
          USB_STORAGE = module;
          USB_DWC3 = yes;
          # USB_DWC3_OF_SIMPLE is not set
          USB_SERIAL = pkgs.lib.mkForce module;
          USB_SERIAL_FTDI_SIO = module;
          USB_GADGET = yes;
          USB_CONFIGFS = module;
          USB_CONFIGFS_SERIAL = yes;
          TYPEC = module;
          TYPEC_TCPM = module;
          TYPEC_TCPCI = module;
          TYPEC_UCSI = module;
          UCSI_PMIC_GLINK = module;
          TYPEC_MUX_GPIO_SBU = module;
          MMC = module;
          MMC_SDHCI = module;
          MMC_SDHCI_PLTFM = module;
          MMC_SDHCI_MSM = module;
          SCSI_UFSHCD = yes;
          SCSI_UFSHCD_PLATFORM = yes;
          SCSI_UFS_QCOM = module;
          NEW_LEDS = yes;
          LEDS_CLASS = module;
          LEDS_CLASS_MULTICOLOR = module;
          LEDS_GPIO = module;
          LEDS_QCOM_LPG = module;
          LEDS_TRIGGER_TIMER = yes;
          LEDS_TRIGGER_HEARTBEAT = yes;
          LEDS_TRIGGER_CPU = yes;
          LEDS_TRIGGER_DEFAULT_ON = yes;
          LEDS_TRIGGER_PANIC = yes;
          RTC_CLASS = yes;
          RTC_DRV_PM8XXX = module;
          DMADEVICES = yes;
          DMABUF_HEAPS = yes;
          DMABUF_HEAPS_SYSTEM = yes;
          DMABUF_HEAPS_CMA = yes;
          # VIRTIO_MENU is not set
          # VHOST_MENU is not set
          # SURFACE_PLATFORMS is not set
          COMMON_CLK_QCOM = yes;
          QCOM_CLK_RPMH = yes;
          SC_CAMCC_8280XP = module;
          SC_DISPCC_8280XP = module;
          SC_GCC_8280XP = yes;
          SC_GPUCC_8280XP = module;
          SC_LPASSCC_8280XP = module;
          SM_VIDEOCC_8350 = module;
          HWSPINLOCK = yes;
          HWSPINLOCK_QCOM = yes;
          # FSL_ERRATUM_A008585 is not set
          # HISILICON_ERRATUM_161010101 is not set
          MAILBOX = yes;
          QCOM_IPCC = yes;
          ARM_SMMU = yes;
          ARM_SMMU_V3 = yes;
          QCOM_IOMMU = yes;
          REMOTEPROC = yes;
          QCOM_Q6V5_ADSP = module;
          QCOM_Q6V5_PAS = module;
          QCOM_SYSMON = module;
          RPMSG_CHAR = module;
          RPMSG_CTRL = module;
          RPMSG_QCOM_GLINK_SMEM = module;
          SOUNDWIRE = module;
          SOUNDWIRE_QCOM = module;
          QCOM_AOSS_QMP = yes;
          QCOM_COMMAND_DB = yes;
          QCOM_GENI_SE = yes;
          QCOM_LLCC = module;
          QCOM_PMIC_GLINK = module;
          QCOM_RPMH = yes;
          QCOM_SMEM = yes;
          QCOM_SMP2P = yes;
          QCOM_SOCINFO = module;
          QCOM_STATS = module;
          QCOM_APR = module;
          QCOM_ICC_BWMON = module;
          QCOM_RPMHPD = yes;
          IIO = module;
          QCOM_SPMI_ADC5 = module;
          PWM = yes;
          QCOM_PDC = yes;
          RESET_QCOM_AOSS = yes;
          RESET_QCOM_PDC = module;
          PHY_QCOM_EDP = module;
          PHY_QCOM_QMP = module;
          # PHY_QCOM_QMP_PCIE_8996 is not set
          PHY_QCOM_USB_SNPS_FEMTO_V2 = module;
          NVMEM_QCOM_QFPROM = yes;
          NVMEM_SPMI_SDAM = module;
          # SLIMBUS is not set
          INTERCONNECT_QCOM = yes;
          INTERCONNECT_QCOM_OSM_L3 = module;
          INTERCONNECT_QCOM_SC8280XP = yes;
          EXT4_FS = yes;
          EXT4_FS_POSIX_ACL = yes;
          EXT4_FS_SECURITY = yes;
          FANOTIFY = yes;
          QUOTA = yes;
          AUTOFS_FS = module;
          FUSE_FS = module;
          OVERLAY_FS = module;
          VFAT_FS = yes;
          NTFS_FS = module;
          TMPFS_POSIX_ACL = yes;
          HUGETLBFS = yes;
          CONFIGFS_FS = yes;
          EFIVAR_FS = yes;
          # NETWORK_FILESYSTEMS is not set
          NLS_CODEPAGE_437 = pkgs.lib.mkForce yes;
          NLS_ASCII = yes;
          NLS_ISO8859_1 = pkgs.lib.mkForce yes;
          SECURITY = yes;
          SECURITY_LANDLOCK = yes;
          # INTEGRITY is not set
          LSM = pkgs.lib.mkForce (freeform "\"landlock,lockdown,yama,loadpin,safesetid,integrity,bpf\"");
          CRYPTO_NULL = yes;
          CRYPTO_DES = module;
          CRYPTO_ANSI_CPRNG = yes;
          CRYPTO_DRBG_MENU = yes;
          CRYPTO_USER_API_HASH = module;
          CRYPTO_USER_API_SKCIPHER = module;
          CRYPTO_GHASH_ARM64_CE = yes;
          CRYPTO_SHA1_ARM64_CE = yes;
          CRYPTO_SHA2_ARM64_CE = yes;
          CRYPTO_SHA512_ARM64_CE = module;
          CRYPTO_SHA3_ARM64 = module;
          CRYPTO_SM3_ARM64_CE = module;
          CRYPTO_AES_ARM64_BS = module;
          CRYPTO_AES_ARM64_CE_CCM = yes;
          CRYPTO_DEV_QCOM_RNG = module;
          CRYPTO_DEV_CCREE = module;
          DMA_CMA = yes;
          CMA_SIZE_MBYTES = pkgs.lib.mkForce (freeform "128");
          PRINTK_TIME = yes;
          DYNAMIC_DEBUG = yes;
          DEBUG_KERNEL = yes;
          DEBUG_FS = yes;
          # SCHED_DEBUG is not set
          # FTRACE is not set
          # RUNTIME_TESTING_MENU is not set
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


