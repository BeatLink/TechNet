{
    home-manager.users.beatlink =
        {
            programs.sidebar-scratchpad.enable = true;
            home = {
                # The settings file and the note itself both live here and are written by
                # the app, so neither can be managed declaratively without making them
                # read-only. Persisting the directory is what keeps the notes.
                persistence."/Storage/Apps/Tools/SidebarScratchpad" = {
                    directories = [
                        ".config/sidebar-scratchpad"
                    ];

                };
            };
        };
}
