{
    home-manager.users.beatlink = {
        programs.powerline-go = {
            enable = true;
            modules = [
                "root"
                "user"
                "host"
                "cwd"
                "readonly"
                "jobs"
                "exit"
                "git"
                "docker"
                "docker-context"
                "venv"
                "ssh"
                "dotenv"
                "duration"
                "nix-shell"

                "direnv"
                #gcp, jobs, newline, perms, plenv, rbenv, root, rvm, shell-var, shenv, termtitle, vgo,
            ];
            modulesRight = [
                "time"
            ];
        };
    };   
}