{
    home-manager.users.beatlink =
        { pkgs, ... }:
        {
            programs.poetry = {
                enable = true;
            };
            home = {
                packages = with pkgs; [ jetbrains.pycharm-community ];
                persistence."/Storage/Apps/Programming/PyCharm" = {
                    directories = [
                        ".cache/JetBrains"
                        ".cache/pip"
                        ".cache/pypoetry"
                        ".config/JetBrains"
                        ".local/share/JetBrains"
                        ".local/share/virtualenv"
                    ];
                    allowOther = true;
                };
            };
        };
}
