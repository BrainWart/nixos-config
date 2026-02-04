{ inputs, modulesPath, pkgs, config, ... }:
{
  imports = [
    inputs.disko.nixosModules.disko
    inputs.nixos-hardware.nixosModules.lenovo-thinkpad-x13s
    ../providers/base.nix
  ];

  programs.dconf.profiles.user.databases = [
    {
      # lockAll = true; # prevents overriding
      settings = {
        "org/gnome/desktop/interface" = {
          color-scheme = "prefer-dark";
        };
        "org/gnome/desktop/input-sources" = {
          xkb-options = [ "ctrl:nocaps" ];
        };
      };
    }
  ];

  system.stateVersion = "25.11";

  networking.hostName = "x13s";

  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 5;
  hardware.bluetooth.enable = true;
  networking.networkmanager.enable = true;
  systemd.tpm2.enable = false;

  programs.regreet.enable = true;
  programs.niri.enable = true;
  programs.vim = {
    enable = true;
    defaultEditor = true;
  };
  security.polkit.enable = true; # polkit
  services.gnome.gnome-keyring.enable = true; # secret service
  security.pam.services.swaylock = {};
  environment.systemPackages = with pkgs; [
    alacritty
    fuzzel
    swaylock
    mako
    waybar
    swayidle
    firefox
    git
    git-credential-oauth
  ];
  fonts.packages = with pkgs; [
    fira-code
    fira-code-symbols
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    font-awesome
  ];

  users.users.mcginnisc.extraGroups = [ "networkmanager" ];

  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/nvme0n1";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              priority = 1;
              name = "ESP";
              size = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };
            root = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            };
          };
        };
      };
    };
  };
}
