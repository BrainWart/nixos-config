({ config, pkgs, modulesPath, lib, ... }:
{
  services.bind.enable = true;
  services.bind.forwarders = [ "1.1.1.1" "8.8.8.8" ];
  services.bind.zones = {
    "mcginnis.internal" = {
      master = true;
      file = ./dns/mcginnis.internal;
    };
    "dev.mcginnis.internal" = {
      master = true;
      file = ./dns/dev.mcginnis.internal;
    };
  };
})

