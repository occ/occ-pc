{ config, pkgs, ... }:

let
  lensAppImage = pkgs.fetchurl {
    url = "https://downloads.k8slens.dev/ide/Lens-2025.12.101934-latest.x86_64.AppImage";
    sha256 = "sha256-jo6bowAAPi+84dKM1MjeZRg6iyxx6R7t3lrmKrdPJGQ=";
  };

  lens = pkgs.writeShellScriptBin "lens" ''
    exec ${pkgs.appimage-run}/bin/appimage-run ${lensAppImage} "$@"
  '';
in
{
  home.packages = [
    lens
  ];

  xdg.desktopEntries.lens = {
    name = "Lens";
    genericName = "Kubernetes IDE";
    comment = "Lens: the Kubernetes IDE";
    exec = "${lens}/bin/lens";
    terminal = false;
    type = "Application";
    categories = [ "Development" "IDE" "Network" ];
    icon = "${./lens-desktop.png}";
  };
}
