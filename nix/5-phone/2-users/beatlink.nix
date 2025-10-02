{ inputs, config, ... }:
{
    sops.secrets.beatlink_hashed_password_phone = {
        sopsFile = "${inputs.self}/secrets/4-phone.yaml";
        neededForUsers = true;
    };
    users.users."beatlink".hashedPasswordFile = config.sops.secrets.beatlink_hashed_password_phone.path;
}
