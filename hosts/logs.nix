{ inputs, ... }: {
  imports = [
    inputs.disko.nixosModules.disko
    ../providers/pve.nix
    ../tasks/tailscale.nix
  ];

  networking.hostName = "logs";

  services.loki = {
    enable = true;
    dataDir = "/persist/var/lib/loki";
  };
}
