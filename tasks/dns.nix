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
        hosts {
          100.126.190.39 dns.mcginnis.internal ns1.mcginnis.internal dns
          100.116.71.11 pve.mcginnis.internal pve
          100.87.242.79 ds718.mcginnis.internal idm.mcginnis.internal ha.mcginnis.internal grafana.mcginnis.internal ds718 idm ha grafana
          100.107.85.18 kube.mcginnis.internal gitea.mcginnis.internal drone.mcginnis.internal kube gitea drone
          100.103.31.83 home-dev.mcginnis.internal home-dev
        }
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

