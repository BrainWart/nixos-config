({ config, pkgs, modulesPath, lib, ... }:
{
  boot.supportedFilesystems = [ "nfs" ];
  boot.kernel.sysctl = {
    "fs.inotify.max_user_instances" = 512;
    "fs.inotify.max_user_watches" = 524288;
  };

  services.resolved = {
    enable = false;
    fallbackDns = [
    ];
  };

  networking.resolvconf.extraConfig = ''
    name_servers="100.126.190.39"
  '';

  services.k3s = {
    enable = true;
    gracefulNodeShutdown.enable = true;
    role = "server";
    extraFlags = toString [
      "--data-dir /persist/k3s"
      "--node-external-ip 100.107.85.18"
      "--node-ip 100.107.85.18"
      "--flannel-iface=tailscale0"
      "--advertise-address 100.107.85.18"
    ];
  };

  networking.firewall.allowedTCPPorts = [ 6443 443 80 ];
  networking.firewall.allowedUDPPorts = [ 8472 ];
})

