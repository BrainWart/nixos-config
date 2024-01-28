{ config, lib, pkgs, ... }:

{
  security.pki.certificateFiles = [
    ../certs/mcginnis-internal.pem
  ];

  nix.extraOptions = "experimental-features = nix-command flakes";

  system.stateVersion = "23.11";
}
