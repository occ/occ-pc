{ pkgs, ... }:
let
  # Chrome only moves a web notification's origin (e.g. mail.google.com) out
  # of the body and into the `x-kde-origin-name` hint when the notification
  # server advertises that capability. GNOME's FdoNotificationDaemon hardcodes
  # its capability list and has no setting for it, so this tiny local
  # extension appends the capability at runtime. GNOME ignores the hint, so
  # the origin line simply disappears from Chrome notifications.
  # Bump shell-version in kde-origin-name/metadata.json on GNOME upgrades.
  kde-origin-name = pkgs.stdenvNoCC.mkDerivation {
    pname = "gnome-shell-extension-kde-origin-name";
    version = "1";
    src = ./kde-origin-name;
    dontBuild = true;
    installPhase = ''
      mkdir -p $out/share/gnome-shell/extensions/kde-origin-name@occ.me
      cp -r $src/. $out/share/gnome-shell/extensions/kde-origin-name@occ.me
    '';
    passthru.extensionUuid = "kde-origin-name@occ.me";
  };
in
{
  home.packages = [ kde-origin-name ];
  my.gnome.enabledExtensions = [ kde-origin-name.passthru.extensionUuid ];
}
