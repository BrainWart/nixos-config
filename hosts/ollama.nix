{ inputs, lib, config, pkgs, ... }: {
  imports = [
    inputs.disko.nixosModules.disko
    ../providers/pve.nix
    # ../tasks/nvidia.nix
    # ../tasks/ollama.nix
  ];

  networking.hostName = "ollama";
}

