# X-Tasks ############################################################################################################################################
#
# The task app from /Storage/Files/Projects/X-Tech-Laboratories/X-Tasks, run by X-WebView on the system WebKit, since Chromium cannot draw on this
# phone's GLES 2.0 GPU.
#
{ inputs, pkgs, ... }:
{
    environment.systemPackages = [ inputs.x-tasks.packages.${pkgs.stdenv.hostPlatform.system}.webview ];

    home-manager.users.beatlink = {
        # Its tasks and settings, and the page's own storage, which the home rollback would otherwise blank.
        home.persistence."/Storage/Apps/Core/X-Tasks".directories = [
            ".config/x-tasks"
            ".local/share/x-tasks"
        ];
    };
}
