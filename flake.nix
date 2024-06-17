{
  description = "NixOS flake build";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    systems.url = "github:nix-systems/default-linux";
    vscode-remote-workaround.url = "github:K900/vscode-remote-workaround";
    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.systems.follows = "systems";
    };
  };

  outputs = { self, nixpkgs, flake-utils, ... } @ inputs:
    flake-utils.lib.eachDefaultSystem (system: 
      let pkgs = import nixpkgs { inherit system; config.allowUnfree = true; }; in
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
                # ({ nix.settings = { max-jobs = 2; cores = 8; }; })
                ({ lib, config, ... }: {
                  nixpkgs.config.allowUnfree = true;
                  hardware.opengl.enable = true;
                  hardware.opengl.driSupport32Bit = true;
                  hardware.nvidia = {
                    package = config.boot.kernelPackages.nvidiaPackages.production;
                    modesetting.enable = true;
                    open = false;
                    nvidiaSettings = true;
                  };
                  services.xserver.enable = true;
                  services.xserver.videoDrivers = [ "nvidia" ];
                  services.xserver.desktopManager.plasma5.enable = true;
                  services.xserver.displayManager.lightdm.enable = true;
                  users.users.mcginnisc.linger = true;
                  services.xrdp = {
                    enable = true;
                    defaultWindowManager = "startplasma-x11";
                    extraConfDirCommands = ''
                      substituteInPlace $out/xrdp.ini --replace port=-1 port=ask-1
                    '';
                  };
                  environment.systemPackages = [
                    pkgs.firefox
                  ];
                })
                ./providers/pve.nix
                ./tasks/tailscale.nix
              ];
            };

            test = nixpkgs.lib.nixosSystem {
              inherit system;

              modules = [
                ({ networking.hostName = "test"; })
                ./providers/base.nix
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
                inputs.vscode-remote-workaround.nixosModules.default
                ./providers/wsl.nix
              ];
            };
          };
        };
      }
    );
}
