# Qt Theme #########################################################################################################################################
#
# Halon for Qt, so Qt applications match the GTK and Cinnamon side of the desktop. The theme is two halves: a colour scheme, which is a QPalette and
# therefore reaches every widget in every Qt application whether or not it cooperates, and a style sheet, which carries the geometry and the component
# treatments a palette cannot express. Both go through qt5ct, the platform theme that also covers Qt 6 — qt6ct registers itself under the qt5ct key,
# which is why one QT_QPA_PLATFORMTHEME serves both and nixpkgs pairs the two packages under a single option.
#
# The configuration files are written declaratively, so the qt5ct and qt6ct GUIs can be used to look but not to save.
#

{ inputs, pkgs, ... }:
let
    halon = inputs.halon.packages.${pkgs.stdenv.hostPlatform.system}.halon-qt-theme;

    # Fusion is what the style sheet is written against; it assumes Fusion's element structure for everything it does not restyle.
    settings = qtct: ''
        [Appearance]
        custom_palette=true
        color_scheme_path=${halon}/share/${qtct}/colors/Halon.conf
        style=Fusion
        standard_dialogs=default

        [Interface]
        stylesheets=${halon}/share/halon/qt/Halon.qss
    '';
in
{
    qt = {
        enable = true;
        platformTheme = "qt5ct";
    };

    environment.systemPackages = [ halon ];

    home-manager.users.beatlink = {
        xdg.configFile = {
            "qt5ct/qt5ct.conf".text = settings "qt5ct";
            "qt6ct/qt6ct.conf".text = settings "qt6ct";
        };
    };
}
