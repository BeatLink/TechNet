# Redundant Defaults #################################################################################################################################
#
# Scans one host for options this repo assigns a value the option already carries by default, so the assignment can be deleted without changing the
# built system. Walks the config each of the repo's own module files produces, in parallel with the option tree, and compares what a file writes
# against that option's default. Findings are keyed by the source position of the assignment, so values mirrored in from elsewhere never report.
#
{
    flakePath,
    host,
}:
let
    flake = builtins.getFlake (toString flakePath);
    lib = flake.inputs.nixpkgs.lib;
    system = flake.nixosConfigurations.${host};
    source = toString flake.outPath;

    inherit (builtins)
        attrNames
        functionArgs
        intersectAttrs
        isAttrs
        isFunction
        isPath
        tryEval
        unsafeGetAttrPos
        ;

    allowed = import ./allowed-defaults.nix;

    # Module Loading #################################################################################################################################
    #
    # Module files are read and applied by hand rather than through the module system, because only the raw attrset a file returns carries the source
    # positions the report is keyed by.
    #

    moduleArgs =
        { modulesPath = "${flake.inputs.nixpkgs}/nixos/modules"; }
        // system._module.args
        // {
            inherit lib;
            inherit (system) config options;
            pkgs = system.pkgs;
            inputs = flake.inputs // { self = flake; };
        };

    # Evaluates a value, yielding null instead of propagating a throw.
    safe = expression: let attempt = tryEval expression; in if attempt.success then attempt.value else null;

    # Calls a module function with the arguments it declares.
    applyModule = f: let declared = functionArgs f; in if declared == { } then f moduleArgs else f (intersectAttrs declared moduleArgs);

    # Imports a module file, applying it if it is a function.
    loadModule = file: let module = import file; in if isFunction module then applyModule module else module;

    # Resolves an import entry to the file that backs it.
    moduleFile =
        path:
        let
            asString = toString path;
        in
        if lib.hasSuffix ".nix" asString then
            asString
        else if builtins.pathExists (asString + "/default.nix") then
            asString + "/default.nix"
        else
            asString;

    # The top level module directories this host actually builds from.
    roots =
        let
            declaring = lib.concatMap (option: option.files) [
                system.options.environment.systemPackages
                system.options.system.stateVersion
            ];
            inside = builtins.filter (file: lib.hasPrefix (source + "/nix/") (toString file)) declaring;
            topLevel = map (file: builtins.head (lib.splitString "/" (lib.removePrefix (source + "/nix/") (toString file)))) inside;
        in
        map (directory: source + "/nix/" + directory) (lib.unique topLevel);

    # Follows imports from the roots, collecting every module file in this repo that the host reaches.
    collectFiles =
        seen: queue:
        if queue == [ ] then
            seen
        else
            let
                file = builtins.head queue;
                rest = builtins.tail queue;
                imports = safe (map moduleFile (builtins.filter isPath ((loadModule file).imports or [ ])));
            in
            if builtins.elem file seen || !(lib.hasPrefix source file) then
                collectFiles seen rest
            else
                collectFiles (seen ++ [ file ]) (rest ++ (if imports == null then [ ] else imports));

    files = collectFiles [ ] (map moduleFile roots);

    # Comparison #####################################################################################################################################
    #
    # A definition counts as redundant only when it is written in this repo, applies to the build, and renders identically to the option's default.
    #

    # Renders a value for comparison. Derivations render as their name, which two different builds of one package share, so such a match is reported
    # as uncertain rather than as a warning: resolving them to a store path instead can hit evaluation errors that tryEval cannot catch.
    render = value: lib.generators.toPretty { multiline = false; } value;

    isOption = value: isAttrs value && (value._type or null) == "option";

    # Strips mkIf, mkMerge, mkDefault and mkOrder down to the values that reach the build; mkForce and friends are dropped as deliberate overrides.
    unwrap =
        value:
        if !(isAttrs value) || !(value ? _type) then
            [ value ]
        else if value._type == "if" then
            (if safe value.condition == true then unwrap value.content else [ ])
        else if value._type == "merge" then
            lib.concatMap unwrap (value.contents or [ ])
        else if value._type == "override" then
            (if (value.priority or 1000) < 1000 then [ ] else unwrap value.content)
        else if value._type == "order" then
            unwrap value.content
        else
            [ ];

    unwrapSafe = value: let attempt = tryEval (unwrap value); in if attempt.success then attempt.value else [ ];

    # Options declared inside a submodule, so a warning can reach settings written under one.
    subOptionsOf =
        option:
        let
            type = option.type or null;
            elemType = type.nestedTypes.elemType or null;
            isSubmodule = name: name == "submodule" || name == "submoduleWith";
        in
        if isSubmodule (type.name or "") then
            { kind = "submodule"; options = safe (type.getSubOptions [ ]); }
        else if (type.name or "") == "attrsOf" || (type.name or "") == "lazyAttrsOf" then
            (
                if isSubmodule (elemType.name or "") then
                    { kind = "attrsOfSubmodule"; options = safe (elemType.getSubOptions [ ]); }
                else
                    { kind = "leaf"; options = null; }
            )
        else
            { kind = "leaf"; options = null; };

    # True when the report should stay quiet about this option, per lint/allowed-defaults.nix.
    isAllowed =
        option:
        let
            toRegex = pattern: lib.concatMapStrings (c: if c == "*" then ".*" else lib.escapeRegex c) (lib.stringToCharacters pattern);
        in
        lib.any (pattern: builtins.match (toRegex pattern) option != null) allowed;

    # Descends an attrset of definitions alongside the matching branch of the option tree.
    walk =
        depth: options: path: raw:
        if depth > 8 then
            [ ]
        else
            lib.concatMap (
                value:
                if !(isAttrs value) then
                    [ ]
                else
                    lib.concatMap (
                        name:
                        let
                            child = tryEval value.${name};
                            position = safe (unsafeGetAttrPos name value);
                        in
                        if !child.success || !(options ? ${name}) then
                            [ ]
                        else if isOption options.${name} then
                            check depth position (path ++ [ name ]) options.${name} child.value
                        else
                            walk (depth + 1) options.${name} (path ++ [ name ]) child.value
                    ) (attrNames value)
            ) (unwrapSafe raw);

    # Compares one assignment with its option's default, then keeps descending if the option holds a submodule.
    check =
        depth: position: path: option: raw:
        let
            sub = subOptionsOf option;
            values = unwrapSafe raw;
            written = position != null && lib.hasPrefix source (toString (position.file or ""));
            name = lib.concatStringsSep "." path;

            here = lib.concatMap (
                value:
                let
                    shown = tryEval (render value);
                    matches = tryEval (option ? default && shown.value == (render option.default));
                in
                if written && !(isAllowed name) && shown.success && matches.success && matches.value then
                    [
                        {
                            option = name;
                            file = lib.removePrefix (source + "/") (toString position.file);
                            line = position.line or 0;
                            value = lib.substring 0 160 shown.value;
                            certain = !(lib.hasInfix "<derivation " shown.value);
                        }
                    ]
                else
                    [ ]
            ) values;

            descend =
                if sub.kind == "submodule" then
                    lib.concatMap (value: walk (depth + 1) sub.options path value) values
                else
                    lib.concatMap (
                        value:
                        if !(isAttrs value) then
                            [ ]
                        else
                            lib.concatMap (
                                key:
                                let
                                    child = tryEval value.${key};
                                in
                                if child.success then walk (depth + 1) sub.options (path ++ [ key ]) child.value else [ ]
                            ) (attrNames value)
                    ) values;
        in
        if sub.kind == "leaf" || sub.options == null then here else here ++ descend;

    # Scans one module file, reporting the scan itself when the file cannot be walked.
    scanFile =
        file:
        let
            module = safe (loadModule file);
            definitions =
                if module == null then
                    null
                else if module ? config then
                    safe module.config
                else
                    safe (builtins.removeAttrs module [ "imports" "options" "config" "_file" "key" "meta" "freeformType" "disabledModules" "class" ]);
            walked = if definitions == null then { success = false; } else tryEval (walk 0 system.options [ ] definitions);
        in
        if walked.success or false then
            walked.value
        else
            [
                {
                    option = null;
                    file = lib.removePrefix (source + "/") file;
                    line = 0;
                    value = "this file could not be scanned";
                    certain = true;
                }
            ];
in
lib.concatMap scanFile files
