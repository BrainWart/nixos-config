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

- `nix build .#nixosConfigurations.installer.config.system.build.isoImage`

# Build recovery iso

You will need to build the Windows PE recovery environment manually and add
it to the Nix store.

- current: `nix build .#nixosConfigurations.recovery.config.system.build.isoImage`

If you would like to cross build an alternative add the following snippet to
your system's configuration. \
`boot.binfmt.emulatedSystems = [ "aarch64-linux" ];` 

- aarch64: `nix build .#packages.aarch64-linux.nixosConfigurations.recovery.config.system.build.isoImage`
- x86_64: `nix build .#packages.x86_64-linux.nixosConfigurations.recovery.config.system.build.isoImage`
