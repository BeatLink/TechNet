#!/usr/bin/env nix-shell
#! nix-shell -i python
#! nix-shell -p python313 python3Packages.textual nh

"""
An App to show the current time.
"""

import pathlib
import json

from textual import on, work
from textual.app import App, ComposeResult

from textual.containers import Container
from textual.widgets import Header, ContentSwitcher, Label, OptionList, Button
from textual.widgets.option_list import Option
from textual.widget import Widget
from textual.events import Focus
from textual.message import Message
from textual.reactive import reactive

from nixtool.theme import white_blue_theme
from nixtool.command_runner import CommandRunner
from nixtool.host_selector import HostSelector
from nixtool.options_widget import OptionsWidget

# Constants
script_folder = pathlib.Path(__file__).parent
config_file = script_folder / "nixtool-config.json"

class NixCommand:
    """Encapsulates command metadata and execution logic."""
    def __init__(self, name, action, is_remote=False, needs_host=False):
        self.name = name
        self.action = action  # Can be a string, list, callable, or menu redirect
        self.is_remote = is_remote
        self.needs_host = needs_host

    def get_queue(self, app, hostname=None):
        """Resolves the action into a list of shell commands."""
        if callable(self.action):
            if self.needs_host and hostname:
                return self.action(app, hostname)
            return self.action(app)
        if isinstance(self.action, list):
            return self.action
        if isinstance(self.action, str):
            return [self.action]
        return []


COMMANDS_TITLE = "Select a command"
COMMANDS_DICT = {
    "run_all": NixCommand("Run All Tasks", "run_all"),
    "flake_update": NixCommand("Run Nix Flake Update", ["nix flake update --refresh"]),
    "export_dconf": NixCommand("Export Dconf JSON Configs", lambda app: app.get_dconf_commands()),
    "rebuild": NixCommand("Run Nixos Rebuild", "menu:rebuild-menu"),
    "preview_generations": NixCommand(
        "Preview Old Generations", 
        lambda app: app.add_commands_for_hosts(lambda a, h: a.get_preview_cmd(h)),
        is_remote=True, needs_host=True
    ),
    "purge_generations_gc": NixCommand(
        "Remove Old Generations & GC",
        lambda app: app.add_commands_for_hosts(lambda a, h: a.get_purge_cmd(h)) + app.add_commands_for_hosts(lambda a, h: a.get_gc_cmd(h)),
        is_remote=True, needs_host=True
    ),
    "gc": NixCommand(
        "Run Nix Garbage Collection",
        lambda app: app.add_commands_for_hosts(lambda a, h: a.get_gc_cmd(h)),
        is_remote=True, needs_host=True
    ),
    "run_installer": NixCommand("Run Installation and Formatting Commands", "menu:installer-menu")
}

INSTALLER_TITLE = "Select an installation command"
INSTALLER_DICT = {
    "install": NixCommand("Install NixOS", ["bash ./install.sh"]),
    "format_data_drive_backup": NixCommand(
        "Format Data Drive (Backup Server)", 
        ["bash ./format-data-drive-backup-server.sh"]
    ),
    "format_data_drive_server": NixCommand(
        "Format Data Drive (Server)", 
        ["bash ./format-data-drive-server.sh"]
    ),
    "format_sd_card_phone": NixCommand(
        "Format SD Card (Phone)", 
        ["bash ./format-sd-card-phone.sh"]
    )
}

REBUILD_TITLE = "Select a NixOS Rebuild action"
REBUILD_DICT = {
    "switch": NixCommand(
        "switch - Activate config and save to bootloader",
        lambda app, host: app.get_rebuild_cmd(host, "switch"),
        is_remote=True, needs_host=True
    ),
    "test": NixCommand(
        "test - Activate config but reset next boot",
        lambda app, host: app.get_rebuild_cmd(host, "test"),
        is_remote=True, needs_host=True
    ),
    "boot": NixCommand(
        "boot - Activate config on next boot",
        lambda app, host: app.get_rebuild_cmd(host, "boot"),
        is_remote=True, needs_host=True
    ),
    "dry-activate": NixCommand(
        "dry-activate - Build config but only show changes",
        lambda app, host: app.get_rebuild_cmd(host, "dry-activate"),
        is_remote=True, needs_host=True
    ),
    "build-vm": NixCommand(
        "build-vm - Build Test VM",
        lambda app, host: app.get_rebuild_cmd(host, "build-vm"),
        is_remote=True, needs_host=True
    ),
    "rollback": NixCommand(
        "rollback - Rollback to previous configuration",
        lambda app, host: app.get_rebuild_cmd(host, "rollback"),
        is_remote=True, needs_host=True
    )
}

HOST_TITLE = "Select Hosts"

class NixOSManager(App):
    CSS = """
    Screen { 
        align: center middle;
        content-align: center middle;
    }

    Header {
        align: center middle;
        content-align: center middle;
    }

    Header, HeaderClock {
        background: $background;
        color: $primary;
        text-style: bold;
    }

    ContentSwitcher  {
        width: 100%;
        height: 100%;
        align: center middle;
        content-align: center middle;
        border: round $primary;
    }

    ContentSwitcher > * {
        width: 100%;
        height: 100%;
        align: center middle;
        content-align: center middle;
    }
 
    """
    
    config = reactive({})
    command = ""
    installer_command = ""
    rebuild_action = ""
    host = {
        "hostname": "",
        "host_url": ""
    }
    command_queue = []

    def compose(self) -> ComposeResult:
        self.header = Header(show_clock=True)
        self.header.tall = True
        self.content_switcher = ContentSwitcher(initial="command-menu")
        self.content_switcher.loading = True

        self.command_menu = OptionsWidget(id="command-menu")
        self.command_menu.title = COMMANDS_TITLE
        self.command_menu.options = COMMANDS_DICT

        self.installer_menu = OptionsWidget(id="installer-menu")
        self.installer_menu.title = INSTALLER_TITLE
        self.installer_menu.options = INSTALLER_DICT

        self.rebuild_menu = OptionsWidget(id="rebuild-menu")
        self.rebuild_menu.title = REBUILD_TITLE
        self.rebuild_menu.options = REBUILD_DICT
        
        self.host_selector = HostSelector(config_file, id="host-selector")

        self.command_runner = CommandRunner(id="command-runner")

        yield self.header
        with self.content_switcher:
            yield self.command_menu
            yield self.installer_menu
            yield self.rebuild_menu
            yield self.host_selector
            yield self.command_runner


    def on_mount(self) -> None:
        self.title = "NixTool"
        self.sub_title = "CLI tool for managing flake based NixOS installations"
        self.register_theme(white_blue_theme)  
        self.theme = "white_blue"
        
    def on_ready(self) -> None:
        self.load_config()

    @work(exclusive=True)
    async def load_config(self):
        self.config = json.loads(config_file.read_text())
        self.content_switcher.loading = False

    @on(OptionsWidget.Selected, "#command-menu")
    def process_command(self, selected: OptionsWidget.Selected):
        print(f"command selected {selected.value}")
        self.command = str(selected.value)
        logic = COMMANDS_DICT[self.command].action

        if isinstance(logic, str) and logic.startswith("menu:"):
            target = logic.split(":")[1]
            self.content_switcher.current = target
            if target == "rebuild-menu":
                self.rebuild_menu.focus()
            elif target == "installer-menu":
                self.installer_menu.focus()
        elif self.command in ["flake_update", "export_dconf"]:
            self.prepare_command_queue()
        else:
            self.content_switcher.current = "host-selector"
            self.host_selector.focus()

    @on(OptionsWidget.Selected, "#installer-menu")
    def process_installer_action(self, selected: OptionsWidget.Selected):
        self.installer_command = str(selected.value)
        self.content_switcher.current = "host-selector"
        self.host_selector.focus()

    @on(OptionsWidget.Selected, "#rebuild-menu")
    def process_rebuild_action(self, selected: OptionsWidget.Selected):
        self.rebuild_action = str(selected.value)
        self.content_switcher.current = "host-selector"
        self.host_selector.focus()

    @on(HostSelector.Selected)
    def process_host(self, message: HostSelector.Selected):
        self.host = {"hostname": message.hostname, "host_url": message.host_url}
        self.prepare_command_queue()

    def add_commands_for_hosts(self, command_func):
        """Executes a command generator function for the currently selected host(s)."""
        queue = []
        target_hosts = [h for h, u in self.config["hosts"].items() if u != "all"] if self.host["host_url"] == "all" else [self.host["hostname"]]
        for hostname in target_hosts:
            queue.append(command_func(self, hostname))
        return queue

    def get_rebuild_cmd(self, hostname, action):
        return (
            f"nixos-rebuild --sudo --no-reexec --show-trace "
            f"--flake {self.config['flake_path']}#{hostname} "
            f"--target-host {self.config['user']}@{self.config['hosts'][hostname]} {action}"
        )

    def get_preview_cmd(self, hostname):
        remote_cmd = (
            f'echo "---- {hostname} (system generations) ----" && '
            'sudo nix-env --profile /nix/var/nix/profiles/system --list-generations && '
            f'echo "---- {hostname} (user generations) ----" && nix-env --list-generations'
        )
        return f"ssh {self.config['user']}@{self.config['hosts'][hostname]} '{remote_cmd}'"

    def get_purge_cmd(self, hostname):
        remote_cmd = "sudo nix-env --profile /nix/var/nix/profiles/system --delete-generations old && nix-env --delete-generations old"
        return f"ssh {self.config['user']}@{self.config['hosts'][hostname]} '{remote_cmd}'"

    def get_gc_cmd(self, hostname):
        return f"ssh {self.config['user']}@{self.config['hosts'][hostname]} 'sudo nix-collect-garbage -d'"

    def get_dconf_commands(self):
        queue = []
        flake_root = pathlib.Path(self.config['flake_path'])
        for config_path in flake_root.rglob("dconf-settings.json"):
            try:
                data = json.loads(config_path.read_text())
                for dconf_path in data.get("dconf_exports", []):
                    output_name = f"{dconf_path.strip('/').replace('/', '.')}.dconf"
                    target_file = (config_path.parent / output_name).relative_to(flake_root)
                    queue.append(f"dconf dump {dconf_path} > ./{target_file}")
            except Exception as e:
                queue.append(f"echo 'Error processing {config_path.name}: {str(e)}'")
        return queue if queue else ["echo 'No localized dconf targets found.'"]

    def prepare_command_queue(self):
        self.command_queue = []

        if self.rebuild_action:
            cmd_obj = REBUILD_DICT[self.rebuild_action]
            if self.command == "run_all":
                self.command_queue.append("nix flake update --refresh")
                self.command_queue.extend(self.add_commands_for_hosts(cmd_obj.action))
                self.command_queue.extend(self.add_commands_for_hosts(lambda a, h: a.get_purge_cmd(h)))
                self.command_queue.extend(self.add_commands_for_hosts(lambda a, h: a.get_gc_cmd(h)))
            else:
                self.command_queue.extend(self.add_commands_for_hosts(cmd_obj.action))
        elif self.installer_command:
            cmd_obj = INSTALLER_DICT[self.installer_command]
            self.command_queue.extend(cmd_obj.get_queue(self))
        else:
            cmd_obj = COMMANDS_DICT[self.command]
            self.command_queue.extend(cmd_obj.get_queue(self))

        self.run_commands()

    def run_commands(self):
        self.content_switcher.current = "command-runner"
        self.command_runner.focus()
        self.command_runner.load_command_queue(self.command_queue)

    @on(Button.Pressed, "#return")
    def reset(self, event: Button.Pressed):
        self.command = ""
        self.rebuild_action = ""
        self.installer_command = ""
        self.host = {
            "hostname": "",
            "host_url": ""
        }
        self.command_queue = []
        self.content_switcher.current = "command-menu"
        self.command_menu.focus()


if __name__ == "__main__":
    app = NixOSManager()
    app.run()