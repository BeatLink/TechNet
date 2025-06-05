#!/usr/bin/env bash

dconf dump /org/cinnamon/ | nix-shell -p dconf2nix --run "dconf2nix --root "/org/cinnamon/" > ./org.cinnamon.nix"

dconf dump /org/gnome/desktop/ | nix-shell -p dconf2nix --run "dconf2nix --root "/org/gnome/desktop/" > ./org.gnome.desktop.nix"

dconf dump /org/gtk/settings/ | nix-shell -p dconf2nix --run "dconf2nix --root "/org/gtk/settings/" > ./org.gtk.settings.nix"

dconf dump /org/x/apps/ | nix-shell -p dconf2nix --run "dconf2nix --root "/org/x/apps/" > ./org.x.apps.nix"
