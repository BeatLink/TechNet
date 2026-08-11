# FreeTube
#
# Two instances: this one, and the one Thor opens over waypipe, which runs here too under its own
# Electron user data dir. The databases holding subscriptions and playlists are shared between them.
#
{ lib, ... }:
{
    home-manager.users.beatlink =
        { config, pkgs, ... }:
        let
            # Safe because FreeTube resolves each database's realpath before opening it, so nedb compacting over the target leaves the link alone
            shareWithThor =
                name:
                lib.nameValuePair ".config/freetube-waypipe/Thor/${name}.db" {
                    source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/FreeTube/${name}.db";
                };
        in
        {
            home = {
                packages = with pkgs; [ freetube ];

                # settings.db is left out so the phone keeps its own UI scale, and subscription-cache.db because sharing the busiest file buys nothing
                file = lib.listToAttrs (
                    map shareWithThor [
                        "profiles" # Subscriptions live in here, as an array on each profile rather than a database of their own
                        "playlists"
                        "history"
                    ]
                );

                persistence."/Storage/Apps/Fun/FreeTube" = {
                    directories = [
                        ".config/FreeTube"
                        ".config/freetube-waypipe" # Electron userData for the instance Thor opens over waypipe, beside this one rather than inside it
                    ];

                };
            };
        };
}
