# Borg
#
# The `borg` CLI, system-wide on every host.
#
# Vorta and borgmatic both bundle their own borg, but privately — borgmatic's
# lives in its systemd unit's path and Vorta's in beatlink's home-manager
# profile, so neither puts `borg` on the system PATH. Vigil's borg monitors run
# `borg list` over an SSH exec as `vigil-access` (and under sudo, as root), and
# both of those need it on the system PATH — without this, the monitor fails
# with "sudo: borg: command not found" even though backups are running fine.
#

{ pkgs, ... }:
{
    environment.systemPackages = with pkgs; [ borgbackup ];
}
