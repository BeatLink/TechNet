# Attic Garbage Collection ###########################################################################################################################
#
# Drains Attic's whole deletion backlog once a day, since atticd's own collector removes only 500 chunks per run and then sleeps.
# Vigil watches the run and can start one by hand.
#
{
    config,
    lib,
    pkgs,
    ...
}:
let
    atticdConfig = (pkgs.formats.toml { }).generate "server.toml" config.services.atticd.settings;

    db = "/var/lib/atticd/server.db";
    store = "/var/lib/atticd/storage";

    # Counts the chunks marked for deletion whose files are still to be removed.
    pending = ''sqlite3 -readonly ${db} "select count(*) from chunk where state = 'D'"'';
in
{
    config = lib.mkMerge [

        # Drain ######################################################################################################################################
        {
            systemd.services.attic-gc = {
                description = "Collect the Attic cache's garbage until none is left";
                after = [ "atticd.service" ];
                unitConfig.RequiresMountsFor = [ "/Storage/Services/Attic" ];

                path = [
                    config.services.atticd.package
                    pkgs.sqlite
                    pkgs.gnugrep
                ];

                environment.RUST_LOG = "info";

                script = ''
                    locked=0

                    for pass in $(seq 1 1000); do
                        # attic retries a chunk whose file is already gone forever, so an empty stand-in lets its own delete succeed.
                        sqlite3 -readonly ${db} "select json_extract(remote_file, '$.Local.name') from chunk where state = 'D'" |
                            while read -r name; do
                                file=${store}/''${name:0:1}/''${name:0:2}/$name
                                [ -e "$file" ] || { mkdir -p "''${file%/*}" && : > "$file"; }
                            done

                        if ! out=$(atticd -f ${atticdConfig} --mode garbage-collector-once 2>&1); then
                            if grep -q "database is locked" <<< "$out" && [ $((locked += 1)) -lt 20 ]; then
                                echo "pass $pass: database busy, retrying"
                                sleep 15
                                continue
                            fi
                            echo "$out"
                            exit 1
                        fi
                        locked=0

                        deleted=$(grep -o "Deleted [0-9]* orphan chunks" <<< "$out" | grep -o "[0-9]*" || echo 0)
                        left=$(${pending})
                        echo "pass $pass: deleted $deleted chunks, $left left"

                        [ "$left" = 0 ] && exit 0
                        if [ "$deleted" = 0 ]; then
                            echo "$out"
                            exit 1
                        fi
                    done

                    echo "still $(${pending}) chunks left after 1000 passes"
                    exit 1
                '';

                serviceConfig = {
                    Type = "oneshot";
                    DynamicUser = true;
                    User = config.services.atticd.user;
                    Group = config.services.atticd.group;
                    StateDirectory = "atticd";
                    EnvironmentFile = config.services.atticd.environmentFile;

                    Nice = 19;
                    IOSchedulingClass = "idle";
                    TimeoutStartSec = "6h";
                };
            };
        }

        # Schedule ###################################################################################################################################
        {
            systemd.timers.attic-gc = {
                description = "Daily drain of the Attic cache's garbage";
                wantedBy = [ "timers.target" ];

                timerConfig = {
                    OnCalendar = "*-*-* 03:00:00"; # Clear of Vigil's builds from 04:00, whose pushes would contend for the database
                    Persistent = true;
                    RandomizedDelaySec = "15m";
                };
            };
        }
    ];
}
