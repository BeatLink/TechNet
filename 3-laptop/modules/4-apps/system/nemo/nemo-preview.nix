{
  pkgs,
  stdenv,
  lib,
  fetchFromGitHub,
  meson,
  pkg-config,
  ninja,
  glib,
  gtk3,
  cjs,
  gtksourceview4,
  gobject-introspection,
  libmusicbrainz5,
   webkitgtk_4_1,
  clutter-gtk,
  clutter-gst,
  wrapGAppsHook3,
  nemo,
}:


    stdenv.mkDerivation rec {
        pname = "nemo-preview";
        version = "6.4.0";

        src = fetchFromGitHub {
            owner = "linuxmint";
            repo = "nemo-extensions";
            rev = version;
            hash = "sha256-39hWA4SNuEeaPA6D5mWMHjJDs4hYK7/ZdPkTyskvm5Y=";
        };

        sourceRoot = "${src.name}/nemo-preview";


        nativeBuildInputs = [
            wrapGAppsHook3
            gobject-introspection
            meson
            pkg-config
            glib
            ninja
            (pkgs.xreader.overrideAttrs (finalAttrs: previousAttrs: {
                  mesonFlags = previousAttrs.mesonFlags ++ [
                    "-Dintrospection=true"
                ];
            }))
        ];

        buildInputs = [
            gtk3
            cjs
            gtksourceview4
            libmusicbrainz5
            webkitgtk_4_1
            clutter-gtk
            clutter-gst
            nemo
        ];

        PKG_CONFIG_LIBNEMO_EXTENSION_EXTENSIONDIR = "${placeholder "out"}/${nemo.extensiondir}";
        PKG_CONFIG_GOBJECT_INTROSPECTION_1_0_GIRDIR = "${placeholder "out"}/share/gir-1.0";
        PKG_CONFIG_GOBJECT_INTROSPECTION_1_0_TYPELIBDIR = "${placeholder "out"}/lib/girepository-1.0";

        meta = with lib; {
            homepage = "https://github.com/linuxmint/nemo-extensions/tree/master/nemo-preview";
            description = "A quick previewer for Nemo, the Cinnamon desktop file manager.";
            license = licenses.gpl2Plus;
            platforms = platforms.linux;
            maintainers = teams.cinnamon.members;
        };
    }
