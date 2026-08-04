# Waydroid
#
# Android in an LXC container, sharing the running kernel rather than emulating
# one. That is why it is viable on this hardware at all -- and why it needs
# kernel support megi's tree happens to have:
#
#     CONFIG_ANDROID_BINDER_IPC=y
#     CONFIG_ANDROID_BINDERFS=y
#     CONFIG_MEMFD_CREATE=y
#     CONFIG_ANDROID_BINDER_DEVICES="binder,hwbinder,vndbinder"
#
# No kernel change was needed. CONFIG_ASHMEM is absent and that is correct -- it
# was removed upstream in 5.18 and Waydroid uses memfd instead.
#
# The module does not fetch the Android image; that is a one-off
# `sudo waydroid init` on the phone, which downloads a LineageOS system and
# vendor image for arm64 into /var/lib/waydroid.
#
# Started on demand
# -----------------
# Nothing here runs until an Android app is launched, which matters on a phone
# with ~3GB of RAM that already sits under 1GB free with just phosh and Firefox.
#
# Two halves, on demand for different reasons:
#
#   The session -- the part that actually boots Android -- is already lazy.
#   `waydroid app launch` calls maybeLaunchLater(), which starts a session when
#   D-Bus shows none running:
#
#       except dbus.DBusException:
#           logging.error("Starting waydroid session")
#           tools.actions.session_manager.start(args, launchNow, background=False)
#
#   The container is the part that needed changing. It is Type=dbus owning
#   id.waydro.Container, and waydroid ships a D-Bus service file naming
#   `SystemdService=waydroid-container.service`, so systemd will activate it the
#   moment anything asks for that name. The NixOS module nevertheless pins it to
#   multi-user.target, which starts it at every boot whether or not Android is
#   ever used. Dropping that leaves activation to do the work.
#
# To stop it again: `waydroid session stop`, then `systemctl stop
# waydroid-container`. There is no idle timeout -- Waydroid freezes the
# container when no app is in the foreground, but it does not shut itself down.
#
#
# Persistence
# -----------
# Both the root and home datasets roll back to a blank snapshot every boot, so
# without this `waydroid init` would download a couple of gigabytes of LineageOS
# images and lose them at the next reboot -- along with every app installed and
# all their data.
#
# /var/lib/waydroid is the whole of it. tools/config derives images, rootfs,
# overlay, overlay_rw, overlay_work, data, lxc and host-permissions from that one
# `work` directory, so persisting the parent covers the lot -- including `data`,
# which is Android's own /data.
#
# On /Storage rather than /persistent because of size: the images alone are
# gigabytes and the eMMC root pool has 22G free against the card's 225G. It
# follows the /Storage/Apps/<Category>/<App> convention the other apps use.
#
# The consequence of that choice is worth stating: /Storage is a removable card
# mounted nofail, so with the card out Waydroid comes up with an empty work
# directory and wants initialising again. That is the right failure -- the
# alternative is filling the eMMC with Android images.
#
{ lib, ... }:
{
    virtualisation.waydroid.enable = true;

    systemd.services.waydroid-container.wantedBy = lib.mkForce [ ];

    environment.persistence."/Storage/Apps/System/Waydroid" = {
        enable = true;
        hideMounts = true;

        directories = [
            "/var/lib/waydroid"
        ];

        users.beatlink = {
            directories = [
                ".local/share/waydroid"
            ];
        };
    };
}
