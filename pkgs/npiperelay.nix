
{ lib
, buildGoModule
, fetchFromGitHub
, applyPatches
, pkgs
, ...
}:

let
  description = "Access Windows named pipes from WSL";

  version = "1.7.1";
  src = applyPatches {
    src = fetchFromGitHub {
      owner = "albertony";
      repo = "npiperelay";
      rev = "v${version}";
      sha256 = "sha256-xhufZaDwCrVbebh5oBq64ekmvlgTcHQsRVVz9WazFEQ=";
    };

    patches = [ ];
  };

  GOOS = "windows";
  GOARCH = if (pkgs.system == "aarch64-linux") then "arm64" else "amd64";

in

(buildGoModule {
  pname = "npiperelay";
  inherit src version;

  vendorHash = null;

  dontPatchELF = true;
  dontFixup = true;
  dontStrip = true;
  dontPatchShebangs = true;

  ldflags = [
    "-X main.version=${version}"
    "-X main.builtBy=nix"
  ];

  postBuild = ''
    dir=$GOPATH/bin/$GOOS_$GOARCH
    if [[ -n "$(shopt -s nullglob; echo $dir/*)" ]]; then
      mv $dir/* $dir/..
    fi
    if [[ -d $dir ]]; then
      rmdir $dir
    fi
  '';

  meta = with lib; {
    inherit description;
    homepage = "https://github.com/albertony/npiperelay/blob/fork/versioninfo.json";
    license = lib.licenses.mit;
    maintainers = [ ];
    platforms = [ "x86_64-linux" "aarch64-linux" ];
  };
}).overrideAttrs (old: old // {
  env = {
    inherit GOOS GOARCH;
  };
})
