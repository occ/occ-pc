{
  lib,
  pkgs,
  ...
}:
# AzinTelecom GlobalProtect VPN (vpn-t004.azintelecom.az) over openconnect.
#
# The portal uses SAML SSO with Duo as the IdP. NetworkManager's openconnect
# plugin *has* an embedded SAML browser, but its GlobalProtect cookie hand-off
# is broken (GNOME NetworkManager-openconnect issue #130: SAML/Duo succeeds,
# then HTTP 512 / "authentication in progress" loops forever). So we do the
# SAML auth out-of-band with gp-saml-gui, mint a real session cookie with
# `openconnect --authenticate`, and inject it into a NetworkManager-managed
# connection via `nmcli ... passwd-file`. NM then owns the tunnel/routes/DNS
# and the applet shows status; only the auth click is delegated.
#
#   azin-vpn         connect (opens a Duo window)
#   azin-vpn down    disconnect
#   azin-vpn status  show connection state
let
  server = "vpn-t004.azintelecom.az";
  connName = "AzinTelecom";

  azin-vpn = pkgs.writeShellScriptBin "azin-vpn" ''
    set -euo pipefail
    export PATH=${
      lib.makeBinPath (
        with pkgs;
        [
          gp-saml-gui
          openconnect
          networkmanager
        ]
      )
    }:$PATH

    server=${lib.escapeShellArg server}
    conn=${lib.escapeShellArg connName}

    case "''${1:-up}" in
      down | stop | off | disconnect) exec nmcli connection down "$conn" ;;
      status) exec nmcli connection show --active "$conn" ;;
    esac

    # Create the NM profile if it doesn't exist yet (occ-laptop already has it;
    # occ-desktop gets it on first run). Secret flags = 2 (not-saved) so NM asks
    # an agent for them -- which is exactly what `passwd-file` provides below.
    if ! nmcli -g connection.id connection show "$conn" >/dev/null 2>&1; then
      echo ">> Creating NetworkManager connection '$conn'..." >&2
      nmcli connection add type vpn con-name "$conn" \
        vpn-type openconnect connection.autoconnect no >/dev/null
      nmcli connection modify "$conn" \
        vpn.data "protocol=gp,gateway=$server,authtype=password,cookie-flags=2,gateway-flags=2,gwcert-flags=2,resolve-flags=2" >/dev/null
    fi

    # 1. SAML/Duo login in a WebKit window -> HOST USER COOKIE OS
    echo ">> SAML/Duo login (a browser window will open)..." >&2
    eval "$(gp-saml-gui -q "$server")"

    # 2. Turn the prelogin-cookie into a real session cookie + gateway + cert pin.
    #    --authenticate builds no tunnel, so no root is needed here.
    echo ">> Finalizing OpenConnect session cookie..." >&2
    eval "$(printf '%s' "$COOKIE" | openconnect --protocol=gp --authenticate \
              --user="$USER" --os="$OS" --passwd-on-stdin "$HOST")"

    # 3. Hand the secrets to NetworkManager; it builds and owns the tunnel.
    secrets=(
      "vpn.secrets.cookie:$COOKIE"
      "vpn.secrets.gateway:$HOST"
      "vpn.secrets.gwcert:$FINGERPRINT"
    )
    [ -n "''${RESOLVE:-}" ] && secrets+=("vpn.secrets.resolve:$RESOLVE")

    echo ">> Bringing up '$conn' via NetworkManager..." >&2
    nmcli connection up "$conn" passwd-file <(printf '%s\n' "''${secrets[@]}")

    echo ">> Connected. Disconnect with: azin-vpn down" >&2
  '';
in
{
  # The host is expected to enable NetworkManager with the openconnect plugin
  # (occ-laptop and occ-desktop both declare `networkmanager-openconnect`). The
  # azin-vpn script bundles gp-saml-gui/openconnect/nmcli on its own PATH, so it
  # works regardless; gp-saml-gui is also exposed for the manual `-S` fallback.
  environment.systemPackages = [
    azin-vpn
    pkgs.gp-saml-gui
  ];
}
