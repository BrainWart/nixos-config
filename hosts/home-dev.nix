{ inputs, lib, config, pkgs, ... }: {
  imports = [
    inputs.disko.nixosModules.disko
    ../providers/pve.nix
    ../tasks/tailscale.nix
  ];

  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  networking.hostName = "home-dev";

  # services.xserver.desktopManager.plasma5.enable = true;
  # services.xserver.displayManager.lightdm.enable = true;
  # users.users.mcginnisc.linger = true;
  # services.xrdp = {
  #   enable = true;
  #   defaultWindowManager = "startplasma-x11";
  #   extraConfDirCommands = ''
  #     substituteInPlace $out/xrdp.ini --replace port=-1 port=ask-1
  #   '';
  # };

  environment.systemPackages = [
    pkgs.firefox
    pkgs.kubectl
  ];
}

