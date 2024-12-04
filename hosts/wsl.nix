{ inputs, ... }: {
  imports = [
    inputs.vscode-remote-workaround.nixosModules.default
    ../providers/wsl.nix
  ];

  system.includeBuildDependencies = true;

  networking.hostName = "wsl";
}

