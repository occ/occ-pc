{
  pkgs-unstable,
  ...
}:
{
  programs.atuin = {
    enable = true;
    # Atuin iterates fast; track unstable so keybinds/config stay current.
    package = pkgs-unstable.atuin;

    # Fish is the interactive shell (see apps/starship); bash is the fallback.
    enableFishIntegration = true;
    enableBashIntegration = true;

    # Keep atuin's own up-arrow bind; ctrl-r is the primary search entry.
    flags = [ "--disable-up-arrow" ];

    settings = {
      # --- search UX ---
      search_mode = "fuzzy";
      filter_mode = "global";
      # Ctrl-r cycles the per-key filter; start scoped to this host.
      filter_mode_shell_up_key_binding = "session";
      style = "compact";
      inline_height = 25;
      show_preview = true;
      show_help = true;
      # Enter runs the selected command instead of only editing the buffer.
      enter_accept = true;

      # --- history hygiene ---
      # Never record obvious secrets or trivial navigation noise.
      history_filter = [
        "^\\s"
        "^\\s*(export )?(ATUIN|OPENAI|ANTHROPIC|AWS|GITHUB|AGE)_?\\w*="
      ];
      cwd_filter = [ ];

      # --- sync (inert until `atuin login`/`register`) ---
      auto_sync = true;
      sync_frequency = "10m";
      sync_address = "https://api.atuin.sh";

      # --- AI (`?` command generation; sends OS/shell name+version only) ---
      ai.enabled = true;

      # --- daemon: persistent background process for faster search/sync ---
      daemon = {
        enabled = true;
        autostart = true;
        sync_frequency = 600;
      };
    };
  };
}
