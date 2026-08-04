{
    config,
    lib,
    pkgs,
    ...
}:

with lib;

let
    cfg = config.dconfImports;
    allFilesDeep =
        dir:
        let
            contents = builtins.readDir dir;
            files = mapAttrsToList (
                name: type:
                let
                    path = dir + "/${name}";
                in
                if type == "directory" then allFilesDeep path else path
            ) contents;
        in
        flatten files;
    allPaths = flatten (map allFilesDeep cfg.roots);
    jsonPaths = filter (path: baseNameOf path == "dconf-settings.json") allPaths;
    parsedConfigsList = flatten (
        map (
            path:
            let
                content = builtins.fromJSON (builtins.readFile path);
                parentDir = dirOf path;
                exports = content.dconf_exports or [ ];
            in
            if (builtins.isAttrs content) && (hasAttr "dconf_exports" content) && (builtins.isList exports) then
                map (
                    dconfPath:
                    let
                        strippedPath = removePrefix "/" (removeSuffix "/" dconfPath);
                        dconfFileName = "${replaceStrings [ "/" ] [ "." ] strippedPath}.dconf";
                        safeServiceName = "dconf-load-${replaceStrings [ "/" ] [ "-" ] strippedPath}";
                    in
                    {
                        name = safeServiceName;
                        value = {
                            targetPath = dconfPath;
                            sourceFile = parentDir + "/${dconfFileName}";
                        };
                    }
                ) exports
            else
                [ ]
        ) jsonPaths
    );
    dconfServices = listToAttrs parsedConfigsList;

in
{
    options.dconfImports = {
        enable = mkEnableOption "Enable automated scattered dconf loader";

        roots = mkOption {
            type = types.listOf types.path;
            default = [ ];
            description = ''
                Directories searched for dconf-settings.json.

                Scoped rather than the whole flake, because this walks the
                filesystem and not the module graph: every export it finds is
                loaded, whether or not the host imports the module it belongs
                to. Odin's Cinnamon export covers /org/gnome/desktop/, which on
                another host would overwrite that host's own interface settings.
            '';
        };
    };

    config = mkIf cfg.enable {
        systemd.user.services = mapAttrs (serviceName: configData: {
            Unit = {
                Description = "Load dconf settings for ${configData.targetPath}";
                After = [ "dconf.service" ];
            };
            Service = {
                ExecStart = "${pkgs.bash}/bin/bash -c '${pkgs.dconf}/bin/dconf load ${configData.targetPath} < ${configData.sourceFile}'";
                Type = "oneshot";
                RemainOnExit = true;
            };
            Install = {
                WantedBy = [ "default.target" ];
            };
        }) dconfServices;
    };
}
