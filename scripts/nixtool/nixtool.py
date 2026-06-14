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
from nixtool.commands import (
    COMMANDS_TITLE, COMMANDS_DICT,
    INSTALLER_TITLE, INSTALLER_DICT,
    REBUILD_TITLE, REBUILD_DICT,
    HOST_TITLE,
    MenuCommand, GenerationsPurgeCommand, GenerationsGCCommand
)

# Constants
script_folder = pathlib.Path(__file__).parent
config_file = script_folder / "nixtool-config.json"

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
        cmd_obj = COMMANDS_DICT[self.command]

        if isinstance(cmd_obj, MenuCommand):
            self.content_switcher.current = cmd_obj.target_menu
            if cmd_obj.target_menu == "rebuild-menu":
                self.rebuild_menu.focus()
            elif cmd_obj.target_menu == "installer-menu":
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

    def prepare_command_queue(self):
        self.command_queue = []

        if self.rebuild_action:
            cmd_obj = REBUILD_DICT[self.rebuild_action]
            if self.command == "run_all":
                self.command_queue.append("nix flake update --refresh")
                self.command_queue.extend(cmd_obj.get_queue(self))
                self.command_queue.extend(GenerationsPurgeCommand().get_queue(self))
                self.command_queue.extend(GenerationsGCCommand().get_queue(self))
            else:
                self.command_queue.extend(cmd_obj.get_queue(self))
        elif self.installer_command:
            self.command_queue.extend(INSTALLER_DICT[self.installer_command].get_queue(self))
        else:
            self.command_queue.extend(COMMANDS_DICT[self.command].get_queue(self))

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