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

# Constants
script_folder = pathlib.Path(__file__).parent
config_file = script_folder / "nixtool-config.json"


COMMANDS_TITLE = "Select a command"
COMMANDS_DICT = {
    "run_all": {
        "name": "Run All Tasks",
        "command": "run_all"
    },
    "flake_update": {
        "name": "Run Nix Flake Update",
        "command": ["nix flake update --refresh"]
    },
    "export_dconf": {
        "name": "Export Dconf JSON Configs",
        "command": lambda app: app.get_dconf_commands()
    },
    "rebuild": {
        "name": "Run Nixos Rebuild",
        "command": "menu:rebuild-menu"
    },
    "preview_generations": {
        "name": "Preview Old Generations",
        "command": lambda app: app.add_commands_for_hosts(lambda a, h: a.get_preview_cmd(h))
    },
    "purge_generations_gc": {
        "name": "Remove Old Generations & GC",
        "command": lambda app: app.add_commands_for_hosts(lambda a, h: a.get_purge_cmd(h)) + app.add_commands_for_hosts(lambda a, h: a.get_gc_cmd(h))
    },
    "gc": {
        "name": "Run Nix Garbage Collection",
        "command": lambda app: app.add_commands_for_hosts(lambda a, h: a.get_gc_cmd(h))
    },
    "run_installer": {
        "name": "Run Installation and Formatting Commands",
        "command": "menu:installer-menu"
    }
}

INSTALLER_TITLE = "Select an installation command"
INSTALLER_DICT = {
    "install": {
        "name": "Install NixOS",
        "command": ["bash ./install.sh"]
    },
    "format_data_drive_backup": {
        "name": "Format Data Drive (Backup Server)",
        "command": ["bash ./format-data-drive-backup-server.sh"]
    },
    "format_data_drive_server": {
        "name": "Format Data Drive (Server)",
        "command": ["bash ./format-data-drive-server.sh"]
    },
    "format_sd_card_phone": {
        "name": "Format SD Card (Phone)",
        "command": ["bash ./format-sd-card-phone.sh"]
    }
}

REBUILD_TITLE = "Select a NixOS Rebuild action"
REBUILD_DICT = {
    "switch": {
        "name": "switch - Activate config and save to bootloader",
        "command": lambda app, host: app.get_rebuild_cmd(host, "switch")
    },
    "test": {
        "name": "test - Activate config but reset next boot",
        "command": lambda app, host: app.get_rebuild_cmd(host, "test")
    },
    "boot": {
        "name": "boot - Activate config on next boot",
        "command": lambda app, host: app.get_rebuild_cmd(host, "boot")
    },
    "dry-activate": {
        "name": "dry-activate - Build config but only show changes",
        "command": lambda app, host: app.get_rebuild_cmd(host, "dry-activate")
    },
    "build-vm": {
        "name": "build-vm - Build Test VM",
        "command": lambda app, host: app.get_rebuild_cmd(host, "build-vm")
    },
    "rollback": {
        "name": "rollback - Rollback to previous configuration",
        "command": lambda app, host: app.get_rebuild_cmd(host, "rollback")
    }
}

HOST_TITLE = "Select Hosts"

class OptionsWidget(Widget):
    DEFAULT_CSS = """
        #container {
            width: auto;
            height: auto;
        }
        #label {
            width: 100%;
            height: auto;
            text-align: center;
            color: $primary;
            text-style: bold;
        }
        #list {
            width: auto;
            height: auto;
            margin: 0;
            border: round $primary;
            background: transparent;
        }
    """
    can_focus = True
    title = reactive("")
    options = reactive({}, recompose=True)
    
    class Selected(Message):

        def __init__(self, widget: Widget, key: str, value: str) -> None:
            super().__init__()
            self.widget = widget
            self.key = key
            self.value = value

        @property
        def control(self) -> Widget:
            return self.widget
            

    def compose(self) -> ComposeResult:
        options = [Option(v["name"], id=k) for k, v in self.options.items()]
        self.container = Container(id="container")
        self.label = Label(self.title, id="label")
        self.list = OptionList(*options, id="list")
        with self.container:
            yield self.label
            yield self.list

    def on_focus(self, event: Focus):
        self.list.focus()

    def on_option_list_option_selected(self, event: OptionList.OptionSelected):
        self.post_message(
            self.Selected(
                self,
                event.option.prompt,
                str(event.option.id)
            )
        )

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
        logic = COMMANDS_DICT[self.command]["command"]

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
            logic = REBUILD_DICT[self.rebuild_action]["command"]
            if self.command == "run_all":
                self.command_queue.append("nix flake update --refresh")
                self.command_queue.extend(self.add_commands_for_hosts(logic))
                self.command_queue.extend(self.add_commands_for_hosts(lambda a, h: a.get_purge_cmd(h)))
                self.command_queue.extend(self.add_commands_for_hosts(lambda a, h: a.get_gc_cmd(h)))
            else:
                self.command_queue.extend(self.add_commands_for_hosts(logic))
        elif self.installer_command:
            logic = INSTALLER_DICT[self.installer_command]["command"]
            if callable(logic):
                self.command_queue.extend(logic(self))
            else:
                self.command_queue.extend(logic)
        else:
            logic = COMMANDS_DICT[self.command]["command"]
            if callable(logic):
                self.command_queue.extend(logic(self))
            else:
                self.command_queue.extend(logic)

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