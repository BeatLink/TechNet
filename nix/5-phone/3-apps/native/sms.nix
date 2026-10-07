{ pkgs, ... }:
{

    nixpkgs.config.permittedInsecurePackages = [
        "olm-3.2.16"
    ];

    # Chatty's plugin list is empty, so the PURPLE_PLUGIN_PATH it prefixes is an empty PATH segment that makeWrapper now refuses to write.
    nixpkgs.overlays = [
        (_final: prev: {
            chatty = prev.chatty.overrideAttrs (_: {
                preFixup = "";
            });
        })
    ];

    environment.systemPackages = [ pkgs.chatty ];
}
