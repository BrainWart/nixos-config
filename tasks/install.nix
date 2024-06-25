({ config, pkgs, modulesPath, lib, ... }:
let
  builder = with pkgs; writeScript "buildSystem" ''
    set -e
    sleep 10

    if [ -e /dev/disk/by-label/cidata ] ; then
      mkdir -p /tmp/cidata
      ${mount}/bin/mount /dev/disk/by-label/cidata /tmp/cidata
      HOSTNAME=$(${gnused}/bin/sed -ne '/hostname:/s/hostname: \(.*\)/\1/p' /tmp/cidata/user-data)
    fi

    if [ -z "$HOSTNAME" ] ; then
      HOSTNAME="$(${systemd}/bin/systemd-ask-password --timeout=0 "Hostname:")"
    fi

    DISKO="$(nix build ${config.system.autoUpgrade.flake}#nixosConfigurations.''${HOSTNAME}.config.system.build.diskoScript --print-out-paths)"
    $DISKO
    ${nixos-install-tools}/bin/nixos-install --flake ${config.system.autoUpgrade.flake}#$HOSTNAME --no-root-password
    reboot
  '';
in {
  systemd.services.autoinstall = {
    description = "Automatic installation";

    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    requires = [ "getty@tty1.service" ];

    script = "${builder}";
  };
})

