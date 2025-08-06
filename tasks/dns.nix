({ config, pkgs, modulesPath, lib, ... }:
{
  services.coredns = {
    enable = true;
    config = ''
      dev.mcginnis.internal {
        log . "dev.mcginnis.internal {remote}:{port} - {>id} \"{type} {class} {name} {proto} {size} {>do} {>bufsize}\" {rcode} {>rflags} {rsize} {duration}"
        errors
        file ${./dns/dev.mcginnis.internal}
      }
      
      mcginnis.internal {
        log . "mcginnis.internal {remote}:{port} - {>id} \"{type} {class} {name} {proto} {size} {>do} {>bufsize}\" {rcode} {>rflags} {rsize} {duration}"
        errors
        file ${./dns/mcginnis.internal}
      }

      . {
        log . ". {remote}:{port} - {>id} \"{type} {class} {name} {proto} {size} {>do} {>bufsize}\" {rcode} {>rflags} {rsize} {duration}"
        errors
        cache
        forward . 1.1.1.1 8.8.8.8
      }
    '';
  };

  systemd.services.coredns.serviceConfig.CapabilityBoundingSet = pkgs.lib.mkForce "cap_net_bind_service cap_net_admin";
  systemd.services.coredns.serviceConfig.AmbientCapabilities = pkgs.lib.mkForce "cap_net_bind_service cap_net_admin";

  services.resolved.enable = false;
})

