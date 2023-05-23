({ config, pkgs, modulesPath, lib, ... }:
{
  boot.supportedFilesystems = [ "cifs" ];

  systemd.services.remote-storage-credentials = {
    description = "Get the remote storage credentials";

    after = [ "network.target" "tailscale.service" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig.Type = "oneshot";

    script = with pkgs; ''
      #!/bin/bash
      umask 077

      if [[ -f "/run/remote-storage-credentials" ]]; then
        exit 0
      fi

      echo "username=$(systemd-ask-password --echo=yes --timeout=0 Remote storage username:)" > /run/remote-storage-credentials
      echo "password=$(systemd-ask-password --echo=no --timeout=0 Remote storage password)" >> /run/remote-storage-credentials
      echo "domain=$(systemd-ask-password --echo=yes --timeout=0 Remote storage domain:)" >> /run/remote-storage-credentials
    '';
  };

  systemd.mounts = [{
    description = "Remote storage mount";
    what = "//ds718.mcginnis.internal/kubernetes/";
    where = "/opt/kubernetes";
    type = "cifs";
    options = "rw,credentials=/run/remote-storage-credentials";
  }];

  systemd.automounts = [{
    description = "Automount for remote storage";
    where = "/opt/kubernetes";
    wantedBy = ["multi-user.target"];
    requires = ["remote-storage-credentials.service"];
  }];

})

