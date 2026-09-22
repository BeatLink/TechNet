{ pkgs, ... }:
{
    # Pix reads WebP through gdk-pixbuf, so the loader has to be in the system cache.
    programs.gdk-pixbuf.modulePackages = [ pkgs.webp-pixbuf-loader ];

    # Pix's wrapper pins its own loader cache, so the extra loaders go in before the wrapper is built.
    nixpkgs.overlays = [
        (final: prev: {
            pix = prev.pix.overrideAttrs (old: {
                # Pix's own WebP reader decodes still images only, and it animates GIF alone, so an
                # animated WebP draws as an empty transparent frame; hand WebP to gdk-pixbuf instead.
                postPatch = (old.postPatch or "") + ''
                    substituteInPlace extensions/cairo_io/main.c \
                        --replace-fail '"image/webp",' '"image/x-webp-handled-by-gdk-pixbuf",'
                    substituteInPlace pix/pixbuf-io.c \
                        --replace-fail 'g_content_type_equals (mime_type, "image/gif")' \
                                       'g_content_type_equals (mime_type, "image/gif") || g_content_type_equals (mime_type, "image/webp")'
                    substituteInPlace pix/gth-main-default-types.c \
                        --replace-fail 'g_content_type_is_a (mime_types[i], "image/gif")' \
                                       'g_content_type_is_a (mime_types[i], "image/gif") || g_content_type_is_a (mime_types[i], "image/webp")'
                '';

                postInstall = (old.postInstall or "") + ''
                    export GDK_PIXBUF_MODULE_FILE="${
                        final.gnome._gdkPixbufCacheBuilder_DO_NOT_USE {
                            extraLoaders = [
                                final.libheif.lib
                                final.libjxl
                                final.librsvg
                                final.webp-pixbuf-loader
                            ];
                        }
                    }"
                '';
            });
        })
    ];

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
