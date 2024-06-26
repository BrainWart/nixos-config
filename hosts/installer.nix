{ inputs, modulesPath, pkgs, ... }: {
  imports = [
    (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix")
    (modulesPath + "/installer/cd-dvd/channel.nix")
    ../tasks/tailscale.nix
    ../tasks/install.nix
  ];

  system.autoUpgrade.flake = "github:brainwart/nixos-config";
  networking.hostName = pkgs.lib.mkForce "";
  environment.systemPackages = [
    pkgs.git
    pkgs.tmux
  ];
  nix.extraOptions = "experimental-features = nix-command flakes repl-flake";
}


