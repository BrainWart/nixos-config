{ inputs, ... }: {
  imports = [
    inputs.disko.nixosModules.disko
    ../providers/pve.nix
    ../tasks/tailscale.nix
    ../tasks/kube.nix
  ];

  networking.hostName = "kube";
}

