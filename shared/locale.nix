{
  config,
  lib,
  pkgs,
  ...
}:
{
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  sops.secrets.google_geolocation_api_key.sopsFile = ./locale.sops.yaml;

  location.provider = "geoclue2";
  services.geoclue2 = {
    enable = true;
    geoProviderUrl = "https://www.googleapis.com/geolocation/v1/geolocate?key=${config.sops.placeholder.google_geolocation_api_key}";
    submitData = false;
  };

  sops.templates."geoclue.conf".content =
    config.environment.etc."geoclue/geoclue.conf".text;

  environment.etc."geoclue/geoclue.conf".source =
    lib.mkForce config.sops.templates."geoclue.conf".path;
}
