# Route URLs to a browser by host. Registered as the default http/https
# handler so every xdg-open (terminal, Slack, editors) passes through it.
# First rule whose host glob matches wins; `default` catches the rest.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.browser-router;

  caseArms = lib.concatMapStringsSep "\n" (rule: ''
    ${lib.concatStringsSep "|" rule.hosts}) exec ${rule.browser} "$url" ;;
  '') cfg.rules;

  router = pkgs.writeShellScriptBin "browser-router" ''
    url="''${1:-}"
    [ -n "$url" ] || exec ${cfg.default}
    # scheme://user@host:port/path -> host
    host="''${url#*://}"
    host="''${host%%/*}"
    host="''${host##*@}"
    host="''${host%%:*}"
    case "$host" in
    ${caseArms}
      *) exec ${cfg.default} "$url" ;;
    esac
  '';
in
{
  options.programs.browser-router = {
    enable = lib.mkEnableOption "host-based browser router as the default web browser";

    default = lib.mkOption {
      type = lib.types.str;
      description = "Browser command for URLs no rule matches.";
    };

    rules = lib.mkOption {
      default = [ ];
      description = "Ordered routing rules; the first matching rule wins.";
      type = lib.types.listOf (
        lib.types.submodule {
          options = {
            hosts = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              description = ''Shell globs matched against the URL host, e.g. "*.example.com".'';
            };
            browser = lib.mkOption {
              type = lib.types.str;
              description = "Browser command; the URL is appended as the last argument.";
            };
          };
        }
      );
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ router ];

    xdg.desktopEntries.browser-router = {
      name = "Browser Router";
      exec = "${router}/bin/browser-router %u";
      mimeType = [
        "x-scheme-handler/http"
        "x-scheme-handler/https"
        "text/html"
      ];
      noDisplay = true;
    };

    xdg.mimeApps = {
      enable = true;
      defaultApplications = {
        "x-scheme-handler/http" = "browser-router.desktop";
        "x-scheme-handler/https" = "browser-router.desktop";
        "text/html" = "browser-router.desktop";
      };
    };
  };
}
