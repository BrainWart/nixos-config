({ config, pkgs, modulesPath, lib, ... }:
let
  builder = with pkgs; writeScript "buildSystem" ''
    if [ -e /dev/disk/by-label/cidata ] ; then
      mkdir -p /tmp/cidata
      ${mount}/bin/mount /dev/disk/by-label/cidata /tmp/cidata
      HOSTNAME=$(${gnused}/bin/sed -ne '/hostname:/s/hostname: \(.*\)/\1/p' /tmp/cidata/user-data)
    fi

    if [ -z "$HOSTNAME" ] ; then
      HOSTNAME="$(${systemd}/bin/systemd-ask-password --timeout=0 "Hostname:")"
    fi

    echo "doing disko-install on ${config.system.autoUpgrade.flake} $HOSTNAME"
    ${disko}/bin/disko-install -f ${config.system.autoUpgrade.flake}#$HOSTNAME
  '';
in {
  services.getty.loginProgram = pkgs.writeScript "build-system-then-login" ''
    ${builder} && reboot || ${pkgs.shadow}/bin/login
  '';
})

