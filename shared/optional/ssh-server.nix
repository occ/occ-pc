{
  config,
  pkgs,
  ...
}:
{
  services.openssh = {
    enable = true;
    openFirewall = true;
    settings = {
      AllowUsers = [ "occ" ];
      PasswordAuthentication = true;
      PermitRootLogin = "no";
    };
  };
}
