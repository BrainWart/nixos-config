
({ config, pkgs, modulesPath, lib, options, ... }:
{
  users.mutableUsers = false;
  users.users.mcginnisc = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    initialHashedPassword = "$6$4kkQrVsuuIBT5/KI$OqD9eItkkCtTRe7ZVqxvcKj2YC.YA8ZZazDR4kMJ39uzp8rPqAE/ogOz.hPYTnKMwQhKCVzH1s./rOD0/8jO40";
    openssh.authorizedKeys.keys = [
      "ecdsa-sha2-nistp384 AAAAE2VjZHNhLXNoYTItbmlzdHAzODQAAAAIbmlzdHAzODQAAABhBNEWqfQnTxcMGv6pRqJt6G5uj86fwJ2BicoeDgnInmpxl7v5qCOcHgcM5BHO+Jjx+ve+t7Ds8IFzaII49AXlSZm6uo997trFjQiyE9nML47xpCz1iskmrHrz7ocwKEEzOw== yubikey"
    ];
    home = "/persist/home/mcginnisc";
  };

  environment.systemPackages = with pkgs; [
    vim_configurable
    wget
    bc
  ];

  services.openssh = {
    enable = true;
    settings = {
      KbdInteractiveAuthentication = false;
      PasswordAuthentication = true;
      KexAlgorithms = (options.services.openssh.settings.type.getSubOptions {}).KexAlgorithms.default ++ [
        "ecdh-sha2-nistp256"
        "ecdh-sha2-nistp384"
        "ecdh-sha2-nistp521"
      ];
    };
    
    hostKeys = [
      {
        bits = 4096;
        path = "/persist/ssh/ssh_host_rsa_key";
        type = "rsa";
      }
      {
        path = "/persist/ssh/ssh_host_ed25519_key";
        type = "ed25519";
      }
    ];
  };
  services.qemuGuest.enable = true;

  security.pki.certificateFiles = [ ./certs/mcginnis-internal.pem ];
  services.resolved.enable = true;

  security.sudo.wheelNeedsPassword = false;
  nix.settings.trusted-users = [ "@wheel" ];
  nix.extraOptions = "experimental-features = nix-command flakes";

  system.stateVersion = "22.11";
})

