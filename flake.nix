{
  description = "NixOS flake build";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    systems.url = "github:nix-systems/default-linux";
    vscode-remote-workaround.url = "github:K900/vscode-remote-workaround";
    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.systems.follows = "systems";
    };
  };

  outputs = { self, nixpkgs, flake-utils, ... } @ inputs:
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
                ({ nix.settings = { max-jobs = 2; cores = 8; }; })
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

            voice-assistant = let
              pkgs = (import nixpkgs { inherit system; config.allowUnfree = true; });
            in nixpkgs.lib.nixosSystem {
              inherit system;

              modules = [
                ({
                  networking.hostName = "voice-assistant";
                  nixpkgs.config.allowUnfree = true;
                  # nixpkgs.config.cudaSupport = true;

                  services.xserver.videoDrivers = ["nvidia"];

                  hardware.opengl.enable = true;
                  hardware.nvidia = {
                    modesetting.enable = true;
                    open = false;
                    nvidiaSettings = true;
                    nvidiaPersistenced = true;
                    # package = pkgs.kernelPackages.nvidiaPackages.stable;
                  };

                  environment.systemPackages = [
                    # pkgs.cudatoolkit
                  ];

                  nixpkgs.overlays = [
                    (_: prev: {
                      ctranslate2 = prev.ctranslate2.override {
                        withCUDA = true;
                        withCuDNN = true;
                        stdenv = prev.gcc12Stdenv;
                      };
                      python3 = prev.python3.override {
                        packageOverrides = (_: pythonPrev: {
                          torch = pythonPrev.torch.override {
                            cudaSupport = true;
                          };
                        });
                      };
                    })
                  ];
                })
                ./providers/pve.nix
                ./tasks/tailscale.nix
                ./tasks/voice-assistant.nix
              ];
            };

            wsl = nixpkgs.lib.nixosSystem {
              inherit system;

              modules = [
                ({ networking.hostName = "wsl"; })
                inputs.vscode-remote-workaround.nixosModules.default
                ./providers/wsl.nix
              ];
            };
          };
        };
      }
    );
}
