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

