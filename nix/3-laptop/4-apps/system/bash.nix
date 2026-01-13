{ ... }:
{
    home-manager.users.beatlink =
        { ... }:
        {
            home = {
                persistence."/Storage/Apps/System/Bash" = {
                    directories = [
                        ".local/share/bash"
                    ];

                };
            };
        };
}
