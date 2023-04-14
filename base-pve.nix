({ config, pkgs, modulesPath, lib, options, ... }:
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  environment.etc.nixos.source = "/persist/nixos";

  boot.initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "virtio_pci" "virtio_scsi" "sd_mod" "sr_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.initrd.postDeviceCommands = pkgs.lib.mkBefore ''
    mkdir -p /mnt
    mount -o subvol=/ /dev/disk/by-label/system /mnt
    btrfs subvolume list -o /mnt/root |
    cut -f9 -d' ' |
    while read subvolume; do
    echo "deleting /$subvolume subvolume..."
    btrfs subvolume delete "/mnt/$subvolume"
    done &&
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

  fileSystems."/" = {
    device = "/dev/disk/by-label/system";
    fsType = "btrfs";
    options = [ "subvol=root" ];
  };

  fileSystems."/nix" = {
    device = "/dev/disk/by-label/system";
    fsType = "btrfs";
    options = [ "subvol=nix" ];
  };

  fileSystems."/persist" = {
    device = "/dev/disk/by-label/system";
    fsType = "btrfs";
    options = [ "subvol=persist" ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/BOOT";
    fsType = "vfat";
  };

  swapDevices = [
    { device = "/dev/disk/by-label/swap"; }
  ];

  networking.useDHCP = lib.mkDefault true;
  #networking.firewall.enable = false;

  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  users.mutableUsers = false;
  users.users.mcginnisc = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    initialHashedPassword = "$6$4kkQrVsuuIBT5/KI$OqD9eItkkCtTRe7ZVqxvcKj2YC.YA8ZZazDR4kMJ39uzp8rPqAE/ogOz.hPYTnKMwQhKCVzH1s./rOD0/8jO40";
    openssh.authorizedKeys.keys = [
      "ecdsa-sha2-nistp384 AAAAE2VjZHNhLXNoYTItbmlzdHAzODQAAAAIbmlzdHAzODQAAABhBNEWqfQnTxcMGv6pRqJt6G5uj86fwJ2BicoeDgnInmpxl7v5qCOcHgcM5BHO+Jjx+ve+t7Ds8IFzaII49AXlSZm6uo997trFjQiyE9nML47xpCz1iskmrHrz7ocwKEEzOw== yubikey"
    ];
    home = "/persist/home/mcginnisc";
  };

  environment.systemPackages = with pkgs; [
    vim_configurable
    wget
    bc
  ];

  services.openssh = {
    enable = true;
    settings = {
      KbdInteractiveAuthentication = false;
      PasswordAuthentication = true;
      KexAlgorithms = (options.services.openssh.settings.type.getSubOptions {}).KexAlgorithms.default ++ [
        "ecdh-sha2-nistp256"
        "ecdh-sha2-nistp384"
        "ecdh-sha2-nistp521"
      ];
    };
    hostKeys = [
      {
        bits = 4096;
        path = "/persist/ssh/ssh_host_rsa_key";
        type = "rsa";
      }
      {
        path = "/persist/ssh/ssh_host_ed25519_key";
        type = "ed25519";
      }
    ];
  };
  services.qemuGuest.enable = true;

  services.resolved.enable = true;

  security.sudo.wheelNeedsPassword = false;
  nix.settings.trusted-users = [ "@wheel" ];
  nix.extraOptions = "experimental-features = nix-command flakes";

  system.stateVersion = "22.11";
})

