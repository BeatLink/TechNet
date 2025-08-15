{
    home-manager.users.beatlink = {
        programs.powerline-go = {
            enable = true;
            modules = [
                "user"
                "host"
                "cwd"
                "perms"
                "ssh"
                "git"
                "venv"
                "nix-shell"
                "exit"
                "jobs"
                "root"
            ];
        };
    };   
    home-manager.users.root = {
        programs.powerline-go = {
            enable = true;
            modules = [
                "user"
                "host"
                "cwd"
                "perms"
                "ssh"
                "git"
                "venv"
                "nix-shell"
                "exit"
                "jobs"
                "root"
            ];
        };
    };
}