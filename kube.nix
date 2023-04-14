({ config, pkgs, modulesPath, lib, ... }:
{
  boot.kernel.sysctl = {
    "fs.inotify.max_user_instances" = 512;
    "fs.inotify.max_user_watches" = 524288;
  };
  services.k3s = {
    enable = true;
    role = "server";
    extraFlags = "--data-dir /persist/k3s --node-external-ip 100.69.240.109";
  };
  networking.firewall.allowedTCPPorts = [ 6443 443 80 ];
})

