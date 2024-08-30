{ inputs, modulesPath, pkgs, config, ... }: {
  imports = [
    (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix")
    (modulesPath + "/installer/cd-dvd/channel.nix")
    ../tasks/tailscale.nix
    ../tasks/recover-abb.nix
  ];

  system.autoUpgrade.flake = "github:brainwart/nixos-config";
  networking.hostName = pkgs.lib.mkForce "";
  isoImage.isoBaseName = "${config.system.nixos.distroId}-recovery";
  isoImage.appendToMenuLabel = " Recovery with Synology ABB";
  nix.extraOptions = "experimental-features = nix-command flakes repl-flake";

  hardware.deviceTree.enable = pkgs.system == "aarch64-linux";
  services.udev.extraRules = ''
    SUBSYSTEM=="block", MODE="777"
  '';
  virtualisation.hypervGuest.enable = true;
  boot = {
    blacklistedKernelModules = [ "hyperv_fb" ];
  };
}


