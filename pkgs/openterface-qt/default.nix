{ lib
, stdenv
, appimageTools
, fetchurl
, makeDesktopItem
}:

let
  system = stdenv.hostPlatform.system;

  version = "0.5.26";
  arch = if system == "aarch64-linux" then
      "arm64"
    else if system == "x86_64-linux" then
      "amd64"
    else
      throw "unsupported system: ${system}";
    
  pkg = appimageTools.wrapType2 {
    pname = "openterface-qt";
    name = "openterface-qt";
    version = "0";
    src = fetchurl {
      url = "https://github.com/TechxArtisanStudio/Openterface_QT/releases/download/${version}/openterfaceQT_linux_${arch}.AppImage";
      hash = "sha256-8AEE/lpzsqBNQow5wIlpjcvySb0bUNKJNo/Q1sfSBUE=";
    };
  };
in
  makeDesktopItem {
    name = "Openterface QT";
    exec = "${pkg}/bin/openterface-qt";
    desktopName = "Openterface QT";
    comment = "Openterface QT version ${version}";
  }
