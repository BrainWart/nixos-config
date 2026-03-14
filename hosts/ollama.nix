{ inputs, lib, config, pkgs, ... }: {
  imports = [
    inputs.disko.nixosModules.disko
    ../providers/pve.nix
    ../tasks/nvidia.nix
  ];

  environment.systemPackages = [
    pkgs.python314Packages.huggingface-hub
  ];

  networking.hostName = "ollama";
}

