import pathlib
import json

class NixCommand:
    """Encapsulates command metadata and execution logic."""
    def __init__(self, name, is_remote=False, needs_host=False):
        self.name = name
        self.is_remote = is_remote
        self.needs_host = needs_host

    def get_queue(self, app, hostname=None):
        """Resolves the action into a list of shell commands."""
        if self.needs_host and hostname is None:
            queue = []
            target_hosts = (
                [h for h, u in app.config["hosts"].items() if u != "all"]
                if app.host["host_url"] == "all"
                else [app.host["hostname"]]
            )
            for h in target_hosts:
                queue.extend(self._resolve(app, h))
            return queue

        return self._resolve(app, hostname)

    def _resolve(self, app, hostname):
        """Generic resolver to be overriden by command objects."""
        return []






class DconfExportCommand(NixCommand):
    def __init__(self):
        super().__init__("Export Dconf JSON Configs")
        
    def _resolve(self, app, hostname):
        

f"ssh {app.config['user']}@{app.config['hosts'][hostname]} '{remote_cmd}'"
f"ssh {app.config['user']}@{app.config['hosts'][hostname]} "
f"ssh {app.config['user']}@{app.config['hosts'][hostname]} "



COMMANDS_TITLE = 
COMMANDS_DICT = {
    "run_all": MenuCommand(, "rebuild-menu"),
    "export_dconf": DconfExportCommand(),
    "rebuild": MenuCommand(, "rebuild-menu"),
    "run_installer": MenuCommand("Run Installation and Formatting Commands", "installer-menu")
}