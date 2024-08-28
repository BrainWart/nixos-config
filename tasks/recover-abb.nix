({ config, pkgs, modulesPath, lib, ... }:
let
  winpeAbbIso = pkgs.requireFile {
    name = "synology_recovery_virtio_amd64-winpe.iso";
    url = "build it your self";
    hash = "sha256-3pUHgKjJhzGul1hk+nHy6cKonADlBkZ5mMRMb5XcPeA=";
  };
in
{
  services.logind.extraConfig = ''
    NAutoVTs=0
  '';
  systemd.services."getty@tty2".enable = false;
  systemd.services."getty@tty1".enable = false;
  systemd.services.recovery-system = {
    description = "The qemu recovery system";

    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];

    conflicts = [ "getty@tty2.service" ];

    serviceConfig = {
      StandardInput = "tty";
      StandardOutput = "tty";
      StandardError = "tty";
      TTYPath = "/dev/tty2";
      TTYReset = "yes";
      TTYHangup = "yes";
      TTYVTDisallocate = "yes";
    };

    path = [ pkgs.qemu_full ];

    script = with pkgs; ''
      DRIVE_ARGS="''$(${util-linux}/bin/lsblk --raw --noheadings --output PATH,TYPE | ${gnused}/bin/sed -ne '/disk/p' | ${coreutils-full}/bin/cut -d' ' -f 1 | ${findutils}/bin/xargs -r printf '-drive format=raw,file=%s')"
      echo ${qemu_full}/bin/qemu-system-x86_64 -machine q35 -cpu Westmere -m 4G -smp 2 -cdrom ${winpeAbbIso} -usbdevice tablet -vga qxl -monitor stdio -boot d -nic user ''$DRIVE_ARGS -display none -name winpe -spice port=5900,addr=127.0.0.1,disable-ticketing=on
      ${qemu_full}/bin/qemu-system-x86_64 -machine q35 -cpu Westmere -m 4G -smp 2 -cdrom ${winpeAbbIso} -usbdevice tablet -vga qxl -monitor stdio -boot d -nic user ''$DRIVE_ARGS -display none -name winpe -spice port=5900,addr=127.0.0.1,disable-ticketing=on
    '';
  };

  services.cage = {
    enable = true;
    extraArguments = [ "-s" ];
    program = pkgs.writeScript "view-vm" ''
      while ${pkgs.coreutils-full}/bin/true ; do
        ${pkgs.coreutils-full}/bin/sleep 5
        ${pkgs.virt-viewer}/bin/remote-viewer --kiosk spice://127.0.0.1:5900 --kiosk-quit on-disconnect
      done
    '';
    user = "nixos";
  };
})

