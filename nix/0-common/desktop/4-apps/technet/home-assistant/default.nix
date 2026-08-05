{ pkgs, ... }:
let
    butler = pkgs.stdenv.mkDerivation (finalAttrs: {
        pname = "butler";
        version = "1.7.0";

        src = pkgs.fetchFromGitHub {
            owner = "cassidyjames";
            repo = "butler";
            tag = finalAttrs.version;
            hash = "sha256-B6JcOL/3apkIDHGQPwWzje2qkFto/g3UlTXF3JlFMF0=";
        };

        nativeBuildInputs = with pkgs; [
            blueprint-compiler
            desktop-file-utils
            meson
            ninja
            pkg-config
            python3
            vala
            wrapGAppsHook4
        ];

        buildInputs = with pkgs; [
            glib
            gtk4
            libadwaita
            webkitgtk_6_0
        ];

        # Defaults to `devel`, which builds as com.cassidyjames.butler.Devel and
        # names the app "Butler (Devel)".
        mesonFlags = [ "-Dprofile=release" ];

        meta = {
            description = "Home Assistant companion for Linux";
            homepage = "https://github.com/cassidyjames/butler";
            license = pkgs.lib.licenses.gpl3Plus;
            mainProgram = "com.cassidyjames.butler";
        };
    });
in
{
    # The server URL as a profile default rather than a locked value, so it is
    # what Butler starts against without preventing the in-app setting from
    # changing it. The name with the hyphen is the one 2-server declares;
    # homeassistant.heimdall.technet does not resolve.
    programs.dconf.profiles.user.databases = [
        {
            settings = {
                "com/cassidyjames/butler".server = "https://home-assistant.heimdall.technet";
            };
        }
    ];

    home-manager.users.beatlink = {
        home = {
            packages = [ butler ];

            # The WebKit session -- cookies and local storage, so the Home
            # Assistant login survives a rollback of /.
            persistence."/Storage/Apps/TechNet/Butler" = {
                directories = [
                    ".local/share/com.cassidyjames.butler"
                    ".config/com.cassidyjames.butler"
                ];
            };
        };
    };
}
