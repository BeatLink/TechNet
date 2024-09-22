{ config, lib, pkgs, modulesPath, ... }: 
{
    system.activationScripts = {
        update_permissions = "
            systemd-tmpfiles --create
        "
    };
}