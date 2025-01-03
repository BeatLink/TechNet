{ impermanence, config, pkgs, ... }:

{

    home-manager.backupFileExtension = "hmbackup";
    home-manager.users.beatlink = {
        imports = [ impermanence.homeManagerModules.impermanence ];
        home = {
            username = "beatlink";
            homeDirectory = "/home/beatlink";
            stateVersion = "24.11";                             # Please read the comment before changing.


            packages = [
                # pkgs.hello

                # # It is sometimes useful to fine-tune packages, for example, by applying
                # # overrides. You can do that directly here, just don't forget the
                # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
                # # fonts?
                # (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })

                # # You can also create simple shell scripts directly inside your
                # # configuration. For example, this adds a command 'my-hello' to your
                # # environment:
                # (pkgs.writeShellScriptBin "my-hello" ''
                #   echo "Hello, ${config.home.username}!"
                # '')
            ];

            # Home Manager is pretty good at managing dotfiles. The primary way to manage
            # plain files is through 'home.file'.
            file = {
                # # Building this configuration will create a copy of 'dotfiles/screenrc' in
                # # the Nix store. Activating the configuration will then make '~/.screenrc' a
                # # symlink to the Nix store copy.
                # ".screenrc".source = dotfiles/screenrc;

                # # You can also set the file content immediately.
                # ".gradle/gradle.properties".text = ''
                #   org.gradle.console=verbose
                #   org.gradle.daemon.idletimeout=3600000
                # '';
            };

            # Home Manager can also manage your environment variables through
            # 'home.sessionVariables'. These will be explicitly sourced when using a
            # shell provided by Home Manager. If you don't want to manage your shell
            # through Home Manager then you have to manually source 'hm-session-vars.sh'
            # located at either
            #
            #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
            #
            # or
            #
            #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
            #
            # or
            #
            #  /etc/profiles/per-user/beatlink/etc/profile.d/hm-session-vars.sh
            #
            sessionVariables = {
                EDITOR = "nano";
            };
        };
    };
}
