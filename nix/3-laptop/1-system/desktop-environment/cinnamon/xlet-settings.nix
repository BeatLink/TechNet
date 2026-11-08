# Xlet settings for system-installed applets
#
# xlet-settings.py looks for an applet's metadata only in the cinnamon package itself and in ~/.local/share/cinnamon,
# so the configure button does nothing for the applets and extensions this directory installs through
# environment.systemPackages. Cinnamon itself finds them through XDG_DATA_DIRS; this teaches the settings dialog to
# look in the system profile as well.
#
{ ... }:
{
    nixpkgs.overlays = [
        (final: prev: {
            cinnamon = prev.cinnamon.overrideAttrs (old: {
                postInstall = (old.postInstall or "") + ''
                    sed -i '/self.xlet_dir = f"{home}\/.local\/share\/cinnamon\/{self.type}s\/{self.uuid}"/a\        if not os.path.exists(self.xlet_dir):\n            self.xlet_dir = f"/run/current-system/sw/share/cinnamon/{self.type}s/{self.uuid}"' \
                        "$out/share/cinnamon/cinnamon-settings/xlet-settings.py"
                    grep -q "/run/current-system/sw/share/cinnamon/{self.type}s" "$out/share/cinnamon/cinnamon-settings/xlet-settings.py"
                '';
            });
        })
    ];
}
