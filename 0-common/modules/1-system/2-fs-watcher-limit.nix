# Filesystem Watcher Limit ##########################################################################################################################
#
# Increase number of open files for apps (Steam, syncthing, etc)
#
#####################################################################################################################################################

{
    systemd.extraConfig = "DefaultLimitNOFILE=65536";
}