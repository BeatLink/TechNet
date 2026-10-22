{ config, ... }:
{
    # Odin's own ETAPI token, made once by hand under Options > ETAPI, separate from the one X-Monitor uses on Heimdall.
    sops.secrets.trilium_etapi_token = {
        sopsFile = "${config.technet.secrets.path}/trilium.yaml";
        owner = "beatlink";
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
