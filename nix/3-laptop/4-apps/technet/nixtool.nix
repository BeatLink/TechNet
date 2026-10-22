# NixTool
#
# Odin drives every install, so nixtool needs every host's install credentials. It decrypts them itself with the user's own age key, so no host key
# can read them: every one lives in secrets/admin/nixtool.yaml.
#
{ ... }:
let
    adminSecret = key: {
        file = "secrets/admin/nixtool.yaml";
        inherit key;
    };
in
{
    # NixTool ########################################################################################################################################
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

        values = {
            TOWBOOT_REPO = "/Storage/Files/Projects/Coding/Pinephone/Tow-Boot";
        };

        # No SSH_PASSWORD: it is whatever the target's live installer was given that boot, so install-nixos prompts for it
        hostSopsValues = {
            Odin = {
                ENCRYPTION_KEY = adminSecret "odin_encryption_key";
                SSH_HOST_KEY = adminSecret "odin_ssh_host_key";
                SSH_INITRD_KEY = adminSecret "odin_ssh_initrd_key";
            };
            Heimdall = {
                ENCRYPTION_KEY = adminSecret "heimdall_encryption_key";
                SSH_HOST_KEY = adminSecret "heimdall_ssh_host_key";
                SSH_INITRD_KEY = adminSecret "heimdall_ssh_initrd_key";
            };
            Ragnarok = {
                ENCRYPTION_KEY = adminSecret "ragnarok_encryption_key";
                SSH_HOST_KEY = adminSecret "ragnarok_ssh_host_key";
                SSH_INITRD_KEY = adminSecret "ragnarok_ssh_initrd_key";
            };
            Thor = {
                ENCRYPTION_KEY = adminSecret "thor_encryption_key";
                SSH_HOST_KEY = adminSecret "thor_ssh_host_key";
                SSH_INITRD_KEY = adminSecret "thor_ssh_initrd_key";
            };
        };
    };
}
