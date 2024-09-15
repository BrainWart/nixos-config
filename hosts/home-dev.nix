{ inputs, lib, config, pkgs, ... }: {
  imports = [
    inputs.disko.nixosModules.disko
    ../providers/pve.nix
    ../tasks/tailscale.nix
  ];

  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  networking.hostName = "home-dev";

  boot.blacklistedKernelModules = [ "nouveau" ];
  # boot.extraModulePackages = [ config.boot.kernelPackages.nvidia_x11 ];
  boot.initrd.kernelModules = [ "nvidia" ];
  nixpkgs.config.allowUnfree = true;
  # services.xserver.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.opengl.enable = true;
  hardware.graphics.enable = true;
  hardware.graphics.enable32Bit = true;
  hardware.nvidia = {
    package = config.boot.kernelPackages.nvidiaPackages.production;
    modesetting.enable = true;
    open = false;
    nvidiaSettings = true;
    nvidiaPersistenced = true;
  };

  services.ollama = {
    enable = true;
    user = "ollama";
    host = "0.0.0.0";

    package = pkgs.ollama.override { 
      config.rocmSupport = false;
      config.cudaSupport = true;
    };
    loadModels = [
      "llama3.1:8b"
    ];
    models = "/persist/ollama/models";
    home = "/persist/ollama";
    acceleration = "cuda";
    environmentVariables = {
      OLLAMA_ORIGINS = "http://ollama.mcginnis.internal:3000";
      CUDA_PATH = "${pkgs.cudatoolkit}";

    };
  };
  services.nextjs-ollama-llm-ui = {
    enable = true;
    hostname = "0.0.0.0";
    ollamaUrl = "http://ollama.mcginnis.internal:${toString config.services.ollama.port}";
    port = 3000;
  };

  networking.firewall.allowedTCPPorts = [
    config.services.ollama.port
    config.services.nextjs-ollama-llm-ui.port
  ];

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

