{
  config,
  pkgs,
  ...
}:
{
  nixpkgs.config.cudaSupport = true;

  services.ollama = {
    enable = true;
    host = "[::]";
  };
}
