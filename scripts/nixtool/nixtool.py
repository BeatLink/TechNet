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
    "Run All Tasks": "run_all",
    "Run Nix Flake Update": "flake_update",
    "Export Dconf JSON Configs": "export_dconf",
    "Run Nixos Rebuild": "rebuild",
    "Preview Old Generations": "preview_generations",
    "Remove Old Generations & GC": "purge_generations_gc",
    "Run Nix Garbage Collection": "gc",
    "Run Installation and Formatting Commands": "run_installer"
}

INSTALLER_TITLE = "Select an installation command"
INSTALLER_DICT = {
    "Install NixOS": "install",
    "Format Data Drive (Backup Server)": "format_data_drive_backup",
    "Format Data Drive (Server)": "format_data_drive_server",
    "Format SD Card (Phone)": "format_sd_card_phone"
}

REBUILD_TITLE = "Select a NixOS Rebuild action"
REBUILD_DICT = {
    "switch - Activate config and save to bootloader": "switch",
    "test - Activate config but reset next boot": "test",
    "boot - Activate config on next boot":"boot",
    "dry-activate - Build config but only show changes":"dry-activate",
    "build-vm - Build Test VM": "build-vm",
    "rollback - Rollback to previous configuration":"rollback"
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
        self.command = selected.value
        if self.command == "flake_update":
            self.prepare_command_queue()
        elif self.command == "export_dconf":
            self.prepare_command_queue()
        elif self.command == "rebuild" or self.command == "run_all":
            self.content_switcher.current = "rebuild-menu"
            self.rebuild_menu.focus()
        elif self.command == "run_installer":
            self.content_switcher.current = "installer-menu"
            self.installer_menu.focus()
        else:
            self.content_switcher.current = "host-selector"
            self.host_selector.focus()

    @on(OptionsWidget.Selected, "#installer-menu")
    def process_installer_action(self, selected: OptionsWidget.Selected):
        self.installer_command = selected.value
        self.content_switcher.current = "host-selector"
        self.host_selector.focus()

    @on(OptionsWidget.Selected, "#rebuild-menu")
    def process_rebuild_action(self, selected: OptionsWidget.Selected):
        self.rebuild_action = selected.value
        self.content_switcher.current = "host-selector"
        self.host_selector.focus()

    @on(HostSelector.Selected)
    def process_host(self, message: HostSelector.Selected):
        self.host = {"hostname": message.hostname, "host_url": message.host_url}
        self.prepare_command_queue()

    def prepare_command_queue(self):
        def add_commands_for_hosts(command):
            if self.host["host_url"] == "all":
                for key, value in self.config["hosts"].items():
                    if value != "all":
                        self.command_queue.append(command(key))
            else:
                self.command_queue.append(command(self.host["hostname"]))

        def build_dconf_commands():
            flake_root = pathlib.Path(self.config['flake_path'])
            found_configs = list(flake_root.rglob("dconf-settings.json"))
            
            if not found_configs:
                self.command_queue.append("echo 'No localized dconf-settings.json targets found in the repo.'")
                return

            for config_path in found_configs:
                try:
                    data = json.loads(config_path.read_text())
                    exports = data.get("dconf_exports", [])
                    
                    if not isinstance(exports, list):
                        self.command_queue.append(f"echo 'Error: \"exports\" key must be a list in {config_path.name}'")
                        continue

                    for dconf_path in exports:
                        #dconf_path = item.get("dconf_path")
                        output_name = f"{dconf_path.strip("/").replace("/", ".")}.dconf"
                        
                        if dconf_path and output_name:
                            # Establish output destination relative to where this specific JSON file lives
                            target_dir = config_path.parent
                            relative_output = target_dir / output_name
                            
                            # Calculate path relative to the executing flake directory context
                            execution_path = relative_output.relative_to(flake_root)
                            
                            # Generate sequential processing task
                            self.command_queue.append(f"dconf dump {dconf_path} > ./{execution_path}")
                        else:
                            self.command_queue.append(f"echo 'Warning: Missing dconf_path or output_file_name in {config_path.name}'")
                            
                except Exception as e:
                    self.command_queue.append(f"echo 'Error processing module target at {config_path.name}: {str(e)}'")

        def build_command(hostname):
            return (
                "nixos-rebuild "
                "--sudo "
                "--no-reexec "
                "--show-trace "
                f"--flake {self.config['flake_path']}#{hostname} "
                f"--target-host {self.config['user']}@{self.config['hosts'][hostname]} "
                f"{self.rebuild_action}"
            )

        def preview_generations_command(hostname):

            remote_cmd = (
                f'echo "---- {hostname} (system generations) ----" && '
                'sudo nix-env --profile /nix/var/nix/profiles/system --list-generations && '
                f'echo "---- {hostname} (user generations) ----" && '
                'nix-env --list-generations'
            )
            ssh_cmd = f"ssh {self.config['user']}@{self.config['hosts'][hostname]} '{remote_cmd}'"
            return ssh_cmd

        def remove_generations_command(hostname):
            remote_cmd = (
                "sudo nix-env --profile /nix/var/nix/profiles/system --delete-generations old "
                "&& "
                "nix-env --delete-generations old"
            )
            ssh_cmd = f"ssh {self.config['user']}@{self.config['hosts'][hostname]} '{remote_cmd}'"
            return ssh_cmd

        def gc_command(hostname):
            remote_cmd = (
                "sudo nix-collect-garbage -d"
            )
            ssh_cmd = f"ssh {self.config['user']}@{self.config['hosts'][hostname]} '{remote_cmd}'"
            return ssh_cmd

        match self.command:
            case "run_all": 
                self.command_queue.append("nix flake update --refresh")
                add_commands_for_hosts(build_command)
                add_commands_for_hosts(remove_generations_command)
                add_commands_for_hosts(gc_command)
            case "flake_update":
                self.command_queue.append("nix flake update --refresh")
            case "export_dconf":                 # Triggers the dynamic scanner block
                build_dconf_commands()
            case "rebuild":
                add_commands_for_hosts(build_command)
            case "preview_generations":
                add_commands_for_hosts(preview_generations_command)
            case "purge_generations_gc":
                add_commands_for_hosts(remove_generations_command)
                add_commands_for_hosts(gc_command)
            case "gc":
                add_commands_for_hosts(gc_command)

        self.run_commands()

    def run_commands(self):
        self.content_switcher.current = "command-runner"
        self.command_runner.focus()
        self.command_runner.load_command_queue(self.command_queue)

    @on(Button.Pressed, "#return")
    def reset(self, event: Button.Pressed):
        self.command = ""
        self.rebuild_action = ""
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