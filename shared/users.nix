{
  config,
  lib,
  pkgs,
  pkgs-unstable,
  ...
}:
{
  sops.secrets = {
    occ_hashed_password = {
      sopsFile = ./users.sops.yaml;
      neededForUsers = true;
    };
    ezgi_hashed_password = {
      sopsFile = ./users.sops.yaml;
      neededForUsers = true;
    };
  };

  users = {
    mutableUsers = false;

    users.occ = {
      hashedPasswordFile = config.sops.secrets.occ_hashed_password.path;
      isNormalUser = true;
      extraGroups = [
        "adbusers"
        "dialout"
        "docker"
        "i2c"
        "input"
        "kvm"
        "libvirtd"
        "lpadmin"
        "networkmanager"
        "render"
        "tss"
        "vboxusers"
        "video"
        "wheel"
      ];
      packages = with pkgs; [
        pkgs-unstable.fish
        home-manager
      ];
      shell = pkgs-unstable.fish;
    };

    users.ezgi = {
      hashedPasswordFile = config.sops.secrets.ezgi_hashed_password.path;
      isNormalUser = true;
      extraGroups = [
        "adbusers"
        "docker"
        "input"
        "lpadmin"
        "networkmanager"
        "tss"
        "vboxusers"
        "wheel"
      ];
      packages = with pkgs; [
        home-manager
      ];
    };
  };
}
