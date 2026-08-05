# The phone's other WebLaunch apps.
#
# Home Assistant is declared in 0-common/desktop/4-apps/technet/home-assistant,
# because both hosts want it. These two are Thor-only: Trilium because the
# desktop client is Electron and would be absurd here, and Syncthing because its
# interface is a local web page with no client at all.
#
# The engine question underneath all of them is settled. WebKit under GTK3,
# asked for GLES 2.0 rather than the desktop GL it requests by default, is the
# one thing measured compositing in hardware on this phone -- GTK4 and Chromium
# both demand GLES 3.0 and are refused by lima.
#
# Icons come from the packages that already ship them rather than being copied
# into this repository: trilium-desktop for one, syncthing for the other. That
# costs a build-time reference to each package but nothing at runtime, and it
# means the icon tracks the upstream artwork instead of going stale.
#
# Each app gets its own profile, so the sites do not share cookies with each
# other, and each is persisted against the rollback of /.
# The module itself is imported by the shared Home Assistant declaration, and
# importing it twice declares its options twice, which evaluation rejects. This
# file only adds apps.
{ pkgs, ... }:
{
    programs.weblaunch.apps = {
        trilium = {
            name = "Trilium";
            url = "https://trilium.heimdall.technet";
            icon = "${pkgs.trilium-desktop}/share/icons/hicolor/512x512/apps/trilium.png";
            profile = "/home/beatlink/.local/share/weblaunch/Trilium";
        };

        syncthing = {
            name = "Syncthing";
            url = "http://localhost:8384";
            icon = "${pkgs.syncthing}/share/icons/hicolor/scalable/apps/syncthing.svg";
            profile = "/home/beatlink/.local/share/weblaunch/Syncthing";
        };
    };

    home-manager.users.beatlink.home.persistence."/Storage/Apps/Core/WebLaunch" = {
        directories = [
            ".local/share/weblaunch/Trilium"
            ".local/share/weblaunch/Syncthing"
        ];
    };
}
