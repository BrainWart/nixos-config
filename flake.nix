{
  description = "NixOS flake build";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }: {

    nixosConfigurations = {
      nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ({ networking.hostName = "nixos"; })
          ./base-pve.nix
          ./tailscale.nix
        ];
      };
      kube = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ({ networking.hostName = "kube"; })
          ./base-pve.nix
          ./tailscale.nix
          ./kube.nix
          ./remote-storage.nix
        ];
      };
      dns = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ({ networking.hostName = "dns"; })
          ./base-pve.nix
          ./tailscale.nix
          ./dns.nix
        ];
      };
    };
  };
}
