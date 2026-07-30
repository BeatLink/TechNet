{ config, ... }:
{
    sops.secrets.beatlink_hashed_password_phone = {
        sopsFile = "${config.technet.secrets.path}/users.yaml";
        neededForUsers = true;
    };
    users.users."beatlink".hashedPasswordFile = config.sops.secrets.beatlink_hashed_password_phone.path;
}
