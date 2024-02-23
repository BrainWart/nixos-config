{ config, lib, pkgs, ... }:

let
  npiperelay = pkgs.callPackage ../pkgs/npiperelay.nix {};
  nixwsl = fetchGit {
    url = "https://github.com/nix-community/NixOS-WSL.git";
    rev = "31346e340e828f79be23d9c83ec1674b152f17bc";
  };
in
{
  imports = [
    (nixwsl.outPath + "/modules/default.nix")
    ./base.nix
  ];

  wsl.enable = true;
  wsl.defaultUser = "mcginnisc";
  wsl.interop.register = true;

  environment.systemPackages = with pkgs; [
    wslu
    (writeScriptBin "ssh-agent" ''
      #!${bash}/bin/bash

      if [ -z ''${SSH_AUTH_SOCK+x} ]; then
        echo "SSH_AUTH_SOCK must be set!"
        exit 1
      fi

      if [ -e "$SSH_AUTH_SOCK" ]; then
        echo "removing existing ssh-agent socket"
        ${coreutils-full}/bin/rm $SSH_AUTH_SOCK
      fi

      ${socat}/bin/socat UNIX-LISTEN:$SSH_AUTH_SOCK,fork EXEC:"${npiperelay}/bin/npiperelay.exe -ei -s //./pipe/openssh-ssh-agent",nofork
    '')
  ];
  vscode-remote-workaround.enable = true;
  wsl.extraBin = 
    map
    (name: { inherit name; src = "${pkgs.coreutils}/bin/${name}"; })
    [ "uname" "dirname" "rm" "mkdir" "wc" "date" "mv" "sleep" "readlink" "cat" ]
  ++ [
    (let name = "tar"; in { inherit name; src = "${pkgs.gnutar}/bin/${name}"; })
    (let name = "gzip"; in { inherit name; src = "${pkgs.gzip}/bin/${name}"; })
    (let name = "find"; in { inherit name; src = "${pkgs.findutils}/bin/${name}"; })
    (let name = "getconf"; in { inherit name; src = "${pkgs.getconf}/bin/${name}"; })
    (let name = "sed"; in { inherit name; src = "${pkgs.gnused}/bin/${name}"; })
  ];
}
