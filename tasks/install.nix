({ config, pkgs, modulesPath, lib, ... }:
{
  services.logind.extraConfig = ''
    NAutoVTs=0
  '';
  systemd.services."getty@tty2".enable = true;
  systemd.services."getty@tty1".enable = false;
  systemd.services.autoinstall = {
    description = "Automatic installation";

    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];

    conflicts = [ "getty@tty1.service" ];

    serviceConfig = {
      StandardInput = "tty";
      StandardOutput = "tty";
      StandardError = "tty";
      TTYPath = "/dev/tty1";
      TTYReset = "yes";
      TTYHangup = "yes";
      TTYVTDisallocate = "yes";
    };

    path = [ pkgs.nix pkgs.nixos-install-tools ];

    script = with pkgs; ''
      sleep 5

      if [ -e /dev/disk/by-label/cidata ] ; then
        mkdir -p /tmp/cidata
        ${mount}/bin/mount -r /dev/disk/by-label/cidata /tmp/cidata
        HOSTNAME=$(${gnused}/bin/sed -ne '/hostname:/s/hostname: \(.*\)/\1/p' /tmp/cidata/user-data)
      fi

      if [ -z "$HOSTNAME" ] ; then
        HOSTNAME="$(${systemd}/bin/systemd-ask-password --timeout=0 "Hostname:")"
      fi

      echo "Installing system for: ''${HOSTNAME}"
      
      echo "Building system disk"
      DISKO="$(nix build ${config.system.autoUpgrade.flake}#nixosConfigurations.''${HOSTNAME}.config.system.build.diskoScript --print-out-paths)"
      $DISKO

      echo ""
      echo "Installing NixOS on system"
      nixos-install --flake ${config.system.autoUpgrade.flake}#$HOSTNAME --no-root-password
      reboot
    '';
  };
})

