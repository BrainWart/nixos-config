{ inputs, ... }: {
  imports = [
    inputs.disko.nixosModules.disko
    ../providers/pve.nix
    ../tasks/tailscale.nix
    ../tasks/voice-assistant.nix
  ];

  networking.hostName = "voice-assistant";
}

