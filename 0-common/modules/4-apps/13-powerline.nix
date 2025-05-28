{
    home-manager.users.beatlink = {
        programs.powerline-go = {
            enable = true;
            modules = [
                "cwd"
                "host"
                "time"
                "jobs"
                "exit"
                "root"
                "read-only"
                "git"
                "docker"
                "docker-context"
                "venv"
                "ssh"
                "dontenv"
                "duration"
                "nix-shell"
                "user"

                "direnv"
                #gcp, jobs, newline, perms, plenv, rbenv, root, rvm, shell-var, shenv, termtitle, vgo,
            ];
        };
    };   
}