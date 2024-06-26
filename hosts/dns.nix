{ inputs, ... }: {
  imports = [
    inputs.disko.nixosModules.disko
    ../providers/pve.nix
    ../tasks/tailscale.nix
    ../tasks/dns.nix
  ];

  networking.hostName = "dns";
}

