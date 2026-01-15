# Generated via dconf2nix: https://github.com/gvolpe/dconf2nix
{ lib, ... }:

with lib.hm.gvariant;

{
  dconf.settings = {
    "org/nemo/desktop" = {
      desktop-layout = "false::false";
      font = "Noto Sans Regular 12";
      show-orphaned-desktop-icons = false;
      volumes-visible = false;
    };

    "org/nemo/list-view" = {
      default-column-order = [ "name" "size" "type" "date_modified" "date_created_with_time" "date_accessed" "date_created" "detailed_type" "owner" "group" "where" "mime_type" "date_modified_with_time" "octal_permissions" "permissions" ];
      default-visible-columns = [ "name" "size" "type" "date_modified" ];
      enable-folder-expansion = true;
    };

    "org/nemo/plugins" = {
      disabled-actions = [];
    };

    "org/nemo/preferences" = {
      click-double-parent-folder = true;
      default-folder-viewer = "list-view";
      ignore-view-metadata = true;
      inherit-folder-viewer = true;
      last-server-connect-method = 0;
      show-advanced-permissions = true;
      show-computer-icon-toolbar = false;
      show-directory-item-counts = "always";
      show-full-path-titles = true;
      show-hidden-files = true;
      show-image-thumbnails = "always";
      show-new-folder-icon-toolbar = true;
      show-open-in-terminal-toolbar = true;
      show-show-thumbnails-toolbar = false;
      tooltips-in-list-view = true;
    };

    "org/nemo/preferences/menu-config" = {
      background-menu-open-in-terminal = true;
      selection-menu-copy-to = true;
      selection-menu-duplicate = true;
      selection-menu-make-link = true;
      selection-menu-move-to = true;
      selection-menu-open-in-terminal = true;
    };

    "org/nemo/window-state" = {
      maximized = true;
      sidebar-bookmark-breakpoint = 12;
      sidebar-width = 373;
      start-with-sidebar = true;
    };

  };
}
