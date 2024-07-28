{
  description = "NixOS flake build";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    vscode-remote-workaround.url = "github:K900/vscode-remote-workaround";
  };

  outputs = { self, nixpkgs, flake-utils, ... } @ inputs:
    map (system: 
      let
        pkgs = import nixpkgs { inherit system; config.allowUnfree = true; };
        nixosConfigurations = with builtins; listToAttrs (map (host: {
          name = host;
          value = nixpkgs.lib.nixosSystem {
            inherit system;
            specialArgs = { inherit inputs; }; 
            modules = [
              (import (./hosts + "/${host}.nix"))
            ];
          };
        }) (let
          entries = readDir ./hosts;
        in map (key: elemAt (match "(.+)\\.nix" (baseNameOf key)) 0)
          (filter (key: (getAttr key entries) == "regular") (attrNames entries))));
      in
      {
        inherit nixosConfigurations;

        devShells.default = pkgs.mkShell {
          buildInputs = [
            pkgs.nixd
          ];
        };

        packages = {
          inherit nixosConfigurations;
        };
      }
    ) [ "aarch64-linux" "x86_64-linux" ];
}
