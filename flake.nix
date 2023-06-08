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
          ({ config, ... }: {
            networking.hostName = "nixos";
            virtualisation.docker.enable = true;
            users.users.mcginnisc.extraGroups = [ "docker" ];
          })
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
