{ inputs, lib, config, ... }: {
  imports = [
    inputs.disko.nixosModules.disko
    ../providers/pve.nix
    ../tasks/tailscale.nix
  ];

  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  networking.hostName = "home-dev";
  # nixpkgs.config.allowUnfree = true;
  hardware.graphics.enable = true;
  hardware.graphics.enable32Bit = true;
  hardware.nvidia = {
    package = config.boot.kernelPackages.nvidiaPackages.production;
    modesetting.enable = true;
    open = false;
    nvidiaSettings = true;
  };
  # services.xserver.enable = true;
  # services.xserver.videoDrivers = [ "nvidia" ];
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
  # environment.systemPackages = [
  #   pkgs.firefox
  # ];
}

