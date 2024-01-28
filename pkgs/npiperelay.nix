
{ lib
, buildGoModule
, fetchFromGitHub
, applyPatches
, ...
}:

let
  description = "Access Windows named pipes from WSL";

  version = "0.0.1";
  src = applyPatches {
    src = fetchFromGitHub {
      owner = "albertony";
      repo = "npiperelay";
      rev = "fork";
      sha256 = "sha256-4N11vz1JjPYuwukqt6Zw1aL7bDOihMEkcjXuSJl2juY=";
    };

    patches = [ ];
  };

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
    dir=$GOPATH/bin/windows_arm64
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
}).overrideAttrs (old: old // { GOOS = "windows"; GOARCH = "arm64"; })
