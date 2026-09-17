{ inputs, config, pkgs, pkgs-unstable, ... }:

let
  # VS Code's safeStorage keyring fails with "the OS keyring is not available
  # for encryption" when `code` is launched from a shell lacking the session
  # environment (e.g. `code .` from a tmux server or console login that predates
  # the graphical session). Without XDG_RUNTIME_DIR + DBUS_SESSION_BUS_ADDRESS,
  # Electron/libsecret cannot reach the org.freedesktop.secrets D-Bus service
  # ("Cannot autolaunch D-Bus without X11 $DISPLAY"). Backfill both when unset so
  # CLI launches always find the user bus; GUI (app-grid) launches already
  # inherit these via systemd --user, and explicit values are preserved.
  vscode = pkgs.symlinkJoin {
    name = "vscode-session-env-${pkgs-unstable.vscode.version}";
    paths = [ pkgs-unstable.vscode ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/code \
        --run 'export XDG_RUNTIME_DIR="''${XDG_RUNTIME_DIR:-/run/user/$(${pkgs.coreutils}/bin/id -u)}"' \
        --run 'export DBUS_SESSION_BUS_ADDRESS="''${DBUS_SESSION_BUS_ADDRESS:-unix:path=$XDG_RUNTIME_DIR/bus}"'
    '';
  };
in
{
  programs.vscode = {
    enable = true;
    package = vscode;
  };
}
