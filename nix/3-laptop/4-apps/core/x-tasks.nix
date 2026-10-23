# X-Tasks ############################################################################################################################################
#
# The task app built in /Storage/Files/Projects/X-Tech-Laboratories/X-Tasks.
#
{
    home-manager.users.beatlink = {
        # Its data lives here, and the home rollback would otherwise blank it.
        home.persistence."/Storage/Apps/Core/X-Tasks" = {
            directories = [
                ".config/x-tasks"
            ];
        };
    };
}
