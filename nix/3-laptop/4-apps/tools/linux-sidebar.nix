{
    home-manager.users.beatlink =
        {
            programs.linux-sidebar.enable = true;
            home = {
                # The settings, the layout and the notes all live here and are written by the
                # app, so none of them can be managed declaratively without making them
                # read-only. Persisting the directory is what keeps the notes.
                persistence."/Storage/Apps/Tools/LinuxSidebar" = {
                    directories = [
                        ".config/linux-sidebar"
                    ];

                };

                # The first launch copies the old scratchpad's settings and note across, which
                # needs the old store still mounted; this can go once it has run once.
                persistence."/Storage/Apps/Tools/SidebarScratchpad" = {
                    directories = [
                        ".config/sidebar-scratchpad"
                    ];

                };
            };
        };
}
