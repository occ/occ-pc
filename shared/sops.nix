{ ... }:
{
  sops = {
    defaultSopsFile = ../secrets/secrets.yaml;
    age.keyFile = "/var/lib/sops-nix/occ-pc.key";
    secrets = {
      nix_cache_priv_key = { };
      occ_hashed_password = {
        neededForUsers = true;
      };
      ezgi_hashed_password = {
        neededForUsers = true;
      };
      google_geolocation_api_key = { };
    };
  };
}
