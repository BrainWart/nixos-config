{
  description = "NixOS flake build";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    systems.url = "github:nix-systems/default-linux";
    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.systems.follows = "systems";
    };
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system: 
      let pkgs = nixpkgs.legacyPackages.${system}; in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = [
            pkgs.nixd
          ];
        };

        packages = {
          nixosConfigurations = {
            nixos = nixpkgs.lib.nixosSystem {
              inherit system;

              modules = [
                ({ networking.hostName = "nixos"; })
                ./providers/pve.nix
                ./tasks/tailscale.nix
              ];
            };

            kube = nixpkgs.lib.nixosSystem {
              inherit system;

              modules = [
                ({ networking.hostName = "kube"; })
                ./providers/pve.nix
                ./tasks/tailscale.nix
                ./tasks/kube.nix
              ];
            };

            dns = nixpkgs.lib.nixosSystem {
              inherit system;

              modules = [
                ({ networking.hostName = "dns"; })
                ./providers/pve.nix
                ./tasks/tailscale.nix
                ./tasks/dns.nix
              ];
            };

            voice-assistant = nixpkgs.lib.nixosSystem {
              inherit system;

              modules = [
                ({ networking.hostName = "voice-assistant"; })
                ./providers/pve.nix
                ./tasks/tailscale.nix
                ./tasks/voice-assistant.nix
              ];
            };

            wsl = nixpkgs.lib.nixosSystem {
              inherit system;

              modules = [
                ({ networking.hostName = "wsl"; })
                ./providers/wsl.nix
              ];
            };
          };
        };
      }
    );
}
