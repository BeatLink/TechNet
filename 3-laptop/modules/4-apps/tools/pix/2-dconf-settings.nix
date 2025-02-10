# Generated via dconf2nix: https://github.com/gvolpe/dconf2nix
{ lib, ... }:

with lib.hm.gvariant;

{
  dconf.settings = {
    "org/x/pix/browser" = {
      browser-sidebar-width = 285;
      fullscreen-sidebar = "hidden";
      fullscreen-thumbnails-visible = false;
      go-to-last-location = true;
      maximized = true;
      properties-visible = false;
      reuse-active-window = true;
      sidebar-sections = [ "GthFileProperties:expanded" "GthFileComment:expanded" "GthFileDetails:expanded" "GthImageHistogram:expanded" ];
      sidebar-visible = false;
      sort-inverse = false;
      sort-type = "file::mtime";
      startup-current-file = "";
      startup-location = "file:///Storage/Files/Pictures";
      statusbar-visible = true;
      use-startup-location = false;
      viewer-sidebar = "properties";
    };

    "org/x/pix/data-migration" = {
      catalogs-2-10 = true;
    };

    "org/x/pix/dialogs/messages" = {
      confirm-deletion = false;
    };

    "org/x/pix/dialogs/save-file" = {
      show-options = true;
    };

    "org/x/pix/general" = {
      active-extensions = [ "resize_images" "image_print" "webalbums" "burn_disc" "search" "list_tools" "convert_format" "exiv2_tools" "edit_metadata" "find_duplicates" "rename_series" "photo_importer" "raw_files" "gstreamer_tools" "catalogs" "desktop_background" "change_date" "contact_sheet" "image_rotation" "selections" "bookmarks" "terminal" "file_manager" "comments" "red_eye_removal" "slideshow" ];
      store-metadata-in-files = true;
    };

    "org/x/pix/gstreamer-tools" = {
      screenshot-location = "file:///Storage/Files/Pictures";
      use-hardware-acceleration = false;
    };

    "org/x/pix/image-print" = {
      font-name = "Sans 12";
      footer-font-name = "sans 8";
      header-font-name = "sans Bold 12";
    };

    "org/x/pix/pixbuf-savers/avif" = {
      lossless = false;
      quality = 50;
    };

    "org/x/pix/pixbuf-savers/jpeg" = {
      default-ext = "jpeg";
      optimize = true;
      progressive = false;
      quality = 100;
      smoothing = 0;
    };

    "org/x/pix/pixbuf-savers/png" = {
      compression-level = 6;
    };

    "org/x/pix/pixbuf-savers/tga" = {
      rle-compression = true;
    };

    "org/x/pix/pixbuf-savers/tiff" = {
      compression = "deflate";
      default-ext = "tiff";
      horizontal-resolution = 72;
      vertical-resolution = 72;
    };

    "org/x/pix/pixbuf-savers/webp" = {
      lossless = true;
      method = 4;
      quality = 100;
    };

  };
}
