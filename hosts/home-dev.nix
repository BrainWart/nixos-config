{ inputs, lib, config, pkgs, ... }: {
  imports = [
    inputs.disko.nixosModules.disko
    ../providers/pve.nix
    ../tasks/tailscale.nix
    ../tasks/mail-forwarding.nix
  ];

  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  networking.hostName = "home-dev";

  users.users.nginx.extraGroups = [ "acme" ];
  
  security.acme = {
    acceptTerms = true;
    defaults = {
      server = "https://stepca.dev.mcginnis.internal/acme/acme/directory";
      email = "cody@mcginnis.dev";
    };
  };

  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    virtualHosts."home-dev.mcginnis.internal" =  {
      enableACME = true;
      forceSSL = true;
      locations."/" = {
        root = "/var/www";
      };
      locations."/ide/" = {
        proxyPass = "http://127.0.0.1:4444/";
        proxyWebsockets = true; # needed if you need to use WebSocket
        extraConfig =
          # required when the target is also TLS server with multiple hosts
          "proxy_ssl_server_name on;" +
          # required when the server wants to use HTTP Authentication
          "proxy_pass_header Authorization;"
          ;
      };
    };
  };

  services.code-server = {
    enable = true;
    user = "mcginnisc";
    group = "users";
    disableUpdateCheck = true;
    disableTelemetry = true;
    host = "127.0.0.1";
    port = 4444;
    hashedPassword = "$argon2i$v=19$m=4096,t=3,p=1$aWF2WCs4UTlidzNaQTFlQytRVlRpaE1zeEZjPQ$a49d0Q5wN/v7cGFcIl9DaSGvtS8PKiLz5pfYU+HzgYY";
  };
  networking.firewall.allowedTCPPorts = [ 80 443 4444 ];

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

  virtualisation.podman.enable = true;

  environment.systemPackages = [
    pkgs.firefox
    pkgs.kubectl
  ];
}

