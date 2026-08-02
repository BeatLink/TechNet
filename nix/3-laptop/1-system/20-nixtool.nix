{ config, ... }:
{
    programs.nixtool = {
        enable = true;
        flakePath = "/Storage/Files/Projects/TechNet";
        user = "beatlink";

        hosts = {
            Odin = "odin.technet";
            Heimdall = "heimdall.technet";
            Ragnarok = "ragnarok.technet";
            Thor = "thor.technet";
        };

        hostValues.Thor.SSH_TARGET = "root@172.16.42.1";
    };

    technet.nixtool = {
        enable = true;
        owner = "beatlink";
        sopsFile = "${config.technet.secrets.path}/nixtool.yaml";

        credentials.Thor = {
            ENCRYPTION_KEY = "thor_encryption_key";
            SSH_HOST_KEY = "thor_ssh_host_key";
            SSH_INITRD_KEY = "thor_ssh_initrd_key";
            SSH_PASSWORD = "thor_ssh_password";
        };
    };
}
