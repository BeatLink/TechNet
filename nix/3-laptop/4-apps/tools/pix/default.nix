{ pkgs, ... }:
{
    # Pix reads WebP through gdk-pixbuf, so the loader has to be in the system cache.
    programs.gdk-pixbuf.modulePackages = [ pkgs.webp-pixbuf-loader ];

    home-manager.users.beatlink =
        { pkgs, ... }:
        {
            home = {
                packages = with pkgs; [ pix ];
                persistence."/Storage/Apps/Tools/Pix" = {
                    directories = [
                        ".config/pix"
                    ];

                };
            };
        };
}
