# Generated via dconf2nix: https://github.com/gvolpe/dconf2nix
{ lib, ... }:

with lib.hm.gvariant;

{
  dconf.settings = {
    "net/launchpad/plank/docks/dock1" = {
      alignment = "center";
      auto-pinning = true;
      current-workspace-only = false;
      dock-items = [ "firefox.dockitem" "org.keepassxc.KeePassXC.dockitem" "trilium.dockitem" "org.moneymanagerex.MMEX.dockitem" "nemo.dockitem" "separator-380c7a99-902c-4742-8cff-e3342b3bf48f.dockitem" "org.mozilla.Thunderbird.dockitem" "WhatsApp.dockitem" "WhatsApp (Private).dockitem" "im.riot.Riot.dockitem" "com.discordapp.Discord.dockitem" "separator-6c01701d-2e87-4009-86d6-62a88c7bd088.dockitem" "io.gitlab.news_flash.NewsFlash.dockitem" "org.gmusicbrowser.gmusicbrowser-1.dockitem" "io.freetubeapp.FreeTube.dockitem" "com.stremio.Stremio.dockitem" "steam.dockitem" "com.calibre_ebook.calibre.dockitem" "org.kde.gwenview.dockitem" "separator-3ff87b4f-0ae5-48c7-8276-5b52b7361b3a.dockitem" "org.gnome.Terminal.dockitem" "com.vscodium.codium.dockitem" "virt-manager.dockitem" ];
      hide-delay = 200;
      hide-mode = "dodge-active";
      icon-size = 48;
      items-alignment = "center";
      lock-items = true;
      monitor = "";
      offset = 0;
      pinned-only = false;
      position = "bottom";
      pressure-reveal = false;
      show-dock-item = false;
      theme = "Gtk+";
      tooltips-enabled = true;
      unhide-delay = 100;
      zoom-enabled = true;
      zoom-percent = 175;
    };

  };
}
