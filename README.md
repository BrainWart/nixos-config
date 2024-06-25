# Services to be converted

- Gitea
  - I would like to move from Gitea. Maybe a lightweight static git website?
- Drone
  - This went unused. We should consider dropping it

- Step CA - mcginnis.internal ACME server
- Node Red - Has book update notifier


# Build test image for azure

nix run github:nix-community/nixos-generators#nixos-generate -- --flake .#test -f azure

# Build auto installer iso

nix build .#nixosConfigurations.installer.config.system.build.isoImage
