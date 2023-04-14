({ config, pkgs, modulesPath, lib, ... }:
{
  environment.systemPackages = [ pkgs.tailscale ];
  services.tailscale.enable = true;

  systemd.services.tailscale-autoconnect = {
    description = "Automatic connection to Tailscale";

    after = [ "network-pre.target" "tailscale.service" ];
    wants = [ "network-pre.target" "tailscale.service" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig.Type = "oneshot";

    script = with pkgs; ''
      mkdir -p /persist/tailscale

      sleep 5

      status="$(${tailscale}/bin/tailscale status -json | ${jq}/bin/jq -r .BackendState)"

      if [ $status = "Running" ]; then
        exit 0
      fi

      ${tailscale}/bin/tailscale up -authkey $(systemd-ask-password --timeout=0 Tailscale authkey:)
    '';
  };

  systemd.services.tailscaled.serviceConfig.BindPaths = "/persist/tailscale:/var/lib/tailscale";

  networking.firewall = {
    enable = true;
    checkReversePath = "loose";
    trustedInterfaces = [ config.services.tailscale.interfaceName ];
    allowedUDPPorts = [ config.services.tailscale.port ];
    allowedTCPPorts = [ ] ++ config.services.openssh.ports;
  };
})

