#!/usr/bin/env nix-shell
#! nix-shell -i python
#! nix-shell -p python313 python3Packages.textual

import pathlib
import json
import asyncio
import subprocess
from datetime import datetime
from textual import on, work
from textual.app import App, ComposeResult
from textual.containers import CenterMiddle, Center, Middle, Container, Vertical, Horizontal, HorizontalGroup
from textual.widgets import Header, ContentSwitcher, Label, Digits, OptionList, RichLog, Button
from textual.widgets.option_list import Option
from textual.widget import Widget
from textual.events import Focus
from textual.message import Message
from textual.reactive import reactive
from textual.theme import Theme

COMMANDS_TITLE = "Select a command"

COMMANDS_DICT = {
    "Install NixOS": "install",
    "Format Data Drive for Backup Server": "format_data_backup_server",
    "Format Data Drive for Server": "format_data_server",
    "Format SD Card for Phone": "format_sd_card_phone"
}

white_blue_theme = Theme(
    name="white_blue",
    primary="#00ACFF",
    secondary="#00ACFF",
    accent="#B48EAD",
    foreground="#D8DEE9",
    background="#001B29",
    success="#00FF00",
    warning="#EBCB8B",
    error="#FF0000",
    surface="#001B29",
    panel="#434C5E",
    dark=True,
    variables={    
        "block-cursor-text-style": "none",
        "footer-key-foreground": "#88C0D0",
        "input-selection-background": "#81a1c1 35%",
    },
)

script_folder = pathlib.Path(__file__).parent
config_file = script_folder / "nixtool-config.json"

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
    options = reactive ({}, recompose=True)
    
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
        options = [
            Option(key, id=value)
            for key, value
            in self.options.items()
        ]
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
                event.option.id
            )
        )

class NixOSInstaller(App):
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

    def on_mount(self) -> None:
        self.title = "TechNet Installer"
        self.sub_title = "This script automatically installs NixOS to a device in the TechNet"
        self.register_theme(white_blue_theme)  
        self.theme = "white_blue"
        
    def on_ready(self) -> None:
        self.load_config()

    @work(exclusive=True)
    async def load_config(self):
        self.config = json.loads(config_file.read_text())
        self.config["hosts"] = dict(
            {"All Hosts": "all"}, 
            **self.config["hosts"]
        )
        #self.host_menu.options = self.config["hosts"]
        #self.host_menu.mutate_reactive(OptionsWidget.options)
        self.content_switcher.loading = False

    def compose(self) -> ComposeResult:
        self.header = Header(show_clock=True)
        self.header.tall = True
        self.content_switcher = ContentSwitcher(initial="command-menu")
        self.content_switcher.loading = True
        self.command_menu = OptionsWidget(id="command-menu")
        self.command_menu.title = COMMANDS_TITLE
        self.command_menu.options = COMMANDS_DICT
        #self.rebuild_menu = OptionsWidget(id="rebuild-menu")
        #self.rebuild_menu.title = REBUILD_TITLE
        #self.rebuild_menu.options = REBUILD_DICT
        #self.host_menu = OptionsWidget(id="host-menu")
        #self.host_menu.title = HOST_TITLE
        #self.host_menu.options = {}
        #self.command_runner = CommandRunner(id="command-runner")
        yield self.header
        with self.content_switcher:
            yield self.command_menu
            #yield self.rebuild_menu
            #yield self.host_menu
            #yield self.command_runner

    @on(OptionsWidget.Selected, "#command-menu")
    def process_command(self, selected: OptionsWidget.Selected):
        print(f"command selected {selected.value}")
        self.command = selected.value
        if self.command == "flake_update":
            self.prepare_command_queue()
        elif self.command == "rebuild" or self.command == "run_all":
            self.content_switcher.current = "rebuild-menu"
            self.rebuild_menu.focus()
        else:
            self.content_switcher.current = "host-menu"
            self.host_menu.focus()


if __name__ == "__main__":
    app = NixOSInstaller()
    app.run()