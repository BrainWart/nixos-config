{ inputs, ... }: {
  imports = [
    inputs.vscode-remote-workaround.nixosModules.default
    ../providers/wsl.nix
  ];

  networking.hostName = "wsl";
}

