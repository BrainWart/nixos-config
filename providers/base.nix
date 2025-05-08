{ config, options, lib, pkgs, ... }:

{
  options = with lib; with types; {
    # Allows some systems to follow "erase your darlings"
    mcginnis.homePrefix = mkOption {
      type = str;
      default = "";
      description = "The prefix used to generate the home path";
    };
  };

  config = {
    security.pki.certificateFiles = [
      ../certs/mcginnis-internal.pem
    ];

    nix.registry = {
      nixpkgs.to = {
        type = "path";
        path = pkgs.path;
      };
    };

    users.mutableUsers = false;
    users.users.mcginnisc = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      initialHashedPassword = "$6$4kkQrVsuuIBT5/KI$OqD9eItkkCtTRe7ZVqxvcKj2YC.YA8ZZazDR4kMJ39uzp8rPqAE/ogOz.hPYTnKMwQhKCVzH1s./rOD0/8jO40";
      openssh.authorizedKeys.keys = [
        "ecdsa-sha2-nistp384 AAAAE2VjZHNhLXNoYTItbmlzdHAzODQAAAAIbmlzdHAzODQAAABhBNEWqfQnTxcMGv6pRqJt6G5uj86fwJ2BicoeDgnInmpxl7v5qCOcHgcM5BHO+Jjx+ve+t7Ds8IFzaII49AXlSZm6uo997trFjQiyE9nML47xpCz1iskmrHrz7ocwKEEzOw== yubikey"
      ];
      home = "${config.mcginnis.homePrefix}/home/mcginnisc";
    };

    services.openssh = {
      settings = {
        KbdInteractiveAuthentication = false;
        PasswordAuthentication = true;
        KexAlgorithms = (options.services.openssh.settings.type.getSubOptions {}).KexAlgorithms.default ++ [
          "ecdh-sha2-nistp256"
          "ecdh-sha2-nistp384"
          "ecdh-sha2-nistp521"
        ];
      };
    };

    system.autoUpgrade = {
      flake = "github:brainwart/nixos-config";
      enable = true;
    };

    security.sudo.wheelNeedsPassword = false;
    nix.settings.trusted-users = [ "@wheel" ];

    nix.extraOptions = "experimental-features = nix-command flakes";

    system.stateVersion = "23.11";
  };
}
