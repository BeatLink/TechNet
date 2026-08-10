# Vigil Sudo Scope
#
# vigil-access previously rode in on `wheel` with `wheelNeedsPassword = false`,
# which is unrestricted passwordless root on every host it can SSH into. Its
# private key lives only on Heimdall (secrets/2-server/vigil.yaml), but a
# compromise of Heimdall or that key would otherwise mean instant root on the
# whole fleet. This replaces that with an explicit allowlist matching exactly
# what the deployed Vigil plugins invoke over SSH (see Vigil's
# vigil/plugins/{systemd_service,service_list,smart_disk,borg}.py):
#
#   - systemctl: only the subcommands the UI can trigger (start/stop/restart/
#     enable/disable/daemon-reload) plus the read-only cat/status/show used to
#     resolve unit paths and render the unit file / status views.
#   - smartctl: disk health checks (-H, -d sat).
#   - borg: backup freshness checks (require_sudo: true in config).
#
# Deliberately NOT included: the `python3 -` heredoc unit-file-write helper
# used when `allow_unit_file_edit: true` (not currently set on any host). A
# sudoers rule matches on argv, not on a heredoc's script body, so there is no
# safe way to scope that command — permitting it at all is equivalent to
# permitting arbitrary root code execution. If unit-file editing is ever
# enabled, this needs a different mechanism (e.g. a small wrapper script sudo
# can scope by path) rather than widening this rule.
#

{
    security.sudo.extraRules = [
        {
            users = [ "vigil-access" ];
            commands = [
                { command = "/run/current-system/sw/bin/systemctl start *"; options = [ "NOPASSWD" ]; }
                { command = "/run/current-system/sw/bin/systemctl stop *"; options = [ "NOPASSWD" ]; }
                { command = "/run/current-system/sw/bin/systemctl restart *"; options = [ "NOPASSWD" ]; }
                { command = "/run/current-system/sw/bin/systemctl enable *"; options = [ "NOPASSWD" ]; }
                { command = "/run/current-system/sw/bin/systemctl disable *"; options = [ "NOPASSWD" ]; }
                { command = "/run/current-system/sw/bin/systemctl daemon-reload"; options = [ "NOPASSWD" ]; }
                { command = "/run/current-system/sw/bin/systemctl cat *"; options = [ "NOPASSWD" ]; }
                { command = "/run/current-system/sw/bin/systemctl status *"; options = [ "NOPASSWD" ]; }
                { command = "/run/current-system/sw/bin/systemctl show *"; options = [ "NOPASSWD" ]; }
                { command = "/run/current-system/sw/bin/smartctl -H *"; options = [ "NOPASSWD" ]; }
                { command = "/run/current-system/sw/bin/smartctl -H -d sat *"; options = [ "NOPASSWD" ]; }
                { command = "/run/current-system/sw/bin/borg *"; options = [ "NOPASSWD" "SETENV" ]; }
            ];
        }
    ];
}
