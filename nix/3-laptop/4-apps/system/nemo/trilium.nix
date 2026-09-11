{ config, ... }:
{
    # Heimdall's ETAPI token, made once by hand under Options > ETAPI and shared with
    # the server's own copy in 2-server/trilium.nix. .sops.yaml names Odin as a second
    # recipient of that file so the action running as beatlink can read it here.
    sops.secrets.trilium_etapi_token = {
        sopsFile = "${config.technet.secrets.root}/2-server/trilium.yaml";
        owner = "beatlink";
        mode = "0400";
    };

    home-manager.users.beatlink = {
        programs.nemo-trilium = {
            enable = true;
            # token_command rather than token, so the token is read at save time instead of being written to the store
            settings = {
                url = "https://trilium.heimdall.technet";
                token_command = "cat ${config.sops.secrets.trilium_etapi_token.path}";
                inbox = "uy1KP4Sgqy8P";
            };
        };
    };
}
