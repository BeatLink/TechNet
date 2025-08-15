#!/usr/bin/env bash

dconf dump /org/cinnamon/ > ./org.cinnamon.dconf

dconf dump /org/gnome/desktop/ > ./org.gnome.desktop.dconf

dconf dump /org/gtk/settings/ > ./org.gtk.settings.dconf

dconf dump /org/x/apps/ > ./org.x.apps.dconf




