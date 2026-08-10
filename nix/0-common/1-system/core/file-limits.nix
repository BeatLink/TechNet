# File Limits ########################################################################################################################################
#
# Raises the inotify watch and open file-descriptor ceilings, which large source trees and file watchers exhaust at the defaults.
#

{
    boot.kernel.sysctl."fs.inotify.max_user_watches" = "1048576"; # 128 times the default 8192
    systemd.settings.Manager = {
        DefaultLimitNOFILE = 65536;
    };
}
