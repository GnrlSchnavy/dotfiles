{ ... }:
{
  plugins.neo-tree = {
    enable = true;
    settings = {
      close_if_last_window = true;
      window = {
        width = 30;
        auto_expand_width = false;
      };
      filesystem = {
        filtered_items = {
          hide_dotfiles = false;
          hide_gitignored = false;
          hide_hidden = false;
        };
        follow_current_file = {
          enabled = true;
          leave_dirs_open = false;
        };
        use_libuv_file_watcher = true;
      };
      buffers = {
        follow_current_file = {
          enabled = true;
          leave_dirs_open = false;
        };
      };
    };
  };
}
