#!/usr/bin/env nix-shell
#! nix-shell -i python
#! nix-shell -p python313 python3Packages.textual

"""
An App to show the current time.
"""

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
    "Run All Tasks": "run_all",
    "Run Nix Flake Update": "flake_update",
    "Run Nixos Rebuild": "rebuild",
    "Preview Old Generations": "preview_generations",
    "Remove Old Generations & GC": "purge_generations_gc",
    "Run Nix Garbage Collection": "gc"
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

class CommandRunner(Widget):
    DEFAULT_CSS = """
        #container {
            width: 97.5%;
            height: 95%;
        }

        HorizontalGroup {
            align: center middle;
        }

        #label {
            color: $primary;
            text-style: bold;
        }

        #logview {
            height: 100%;
            border: round $primary;
            background: transparent;
        }

        #message {
            text-align: center;
            text-style: bold;
            align: center middle;
            content-align: center middle;
        }

        #message.success {
            color: $success;
        }

        #message.error {
            color: $error;
        }

        #start, #return {
            text-style: bold;
            align: center middle;
            content-align: center middle;
        }

        .borders {
            border: round orange;
        }

        .invisible {
            display: none
        }
    """

    command_queue = []
    final_returncode = 0
    
    """class Selected(Message):
        Sent when the command has been selected.
        def __init__(self, widget: Widget, command: str) -> None:
            super().__init__()
            self.selected_command = command
            self.widget = widget
        @property
        def control(self) -> Widget:
            Returns the widget
            return self.widget

    """
    
    def compose(self) -> ComposeResult:
        self.container = Container(id="container")
        self.label = Label(id="label")
        self.logview = RichLog(id="logview")
        self.message = Label(id="message", classes="invisible")
        self.message.loading = True
        self.start_button = Button("Start", id="start", variant="primary")
        self.start_button.compact = True
        self.start_button.flat = True
        self.return_button = Button("Return", id="return", variant="primary")
        self.return_button.compact = True
        self.return_button.flat = True
        with self.container:
            with Center():
                yield Center(self.label)
                yield CenterMiddle(self.logview)
                yield Center(self.message)
                with HorizontalGroup():
                    yield self.return_button
                    yield self.start_button


    def load_command_queue(self, command_queue):
        # Clear UI
        self.label.update(f"Ready To Start")
        self.label.refresh()
        self.logview.clear()
        self.message.update("")
        self.message.loading = True
        self.message.remove_class("success", "error")
        self.message.refresh()
        self.start_button.remove_class("invisible")
        self.return_button.remove_class("invisible")
        self.command_queue = command_queue

        self.logview.write("The following commands will now be executed\n")
        for command in self.command_queue:
            self.logview.write(f"- {command}")
        self.logview.write("\nPress Start to begin")


    @on(Button.Pressed, "#start")
    def start(self, event: Button.Pressed):
        self.run_command()

    @work(exclusive=True)
    async def run_command(self):
        self.start_button.add_class("invisible")
        self.message.remove_class("invisible")
        for index, command in enumerate(self.command_queue):
            command_message = f"Running command {index+1} of {len(self.command_queue)}: {command}"
            self.label.update(command_message)
            self.logview.write("\n--------------------------------------------------------------------------\n")
            self.logview.write(f">>> {command_message} <<<")
            process = await asyncio.create_subprocess_shell(
                command,
                cwd=script_folder.parent,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT
            )
            while True:
                line = await process.stdout.readline()
                if not line:
                    break
                self.logview.write(line.decode().rstrip())
            await process.wait()
            self.final_returncode += process.returncode
            if process.returncode == 0:
                self.logview.write(f"\n>>> Command succeeded with return code {process.returncode} <<")
            else:
                self.logview.write(f"\n>>> Command failed with return code {process.returncode} <<<")

        # When process is finished show the end message        
        if self.final_returncode == 0:
            self.message.update(f"All commands succeeded!")
            self.message.add_class("success")
        else:
            self.message.update(f"One or more commands have failed! Please check the logs")
            self.message.add_class("error")
        self.message.loading = False
        self.message.remove_class("invisible")
        self.message.refresh()
        self.return_button.remove_class("invisible")
        self.refresh()


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
    rebuild_action = ""
    host = {
        "hostname": "",
        "hosturl": ""
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
        self.rebuild_menu = OptionsWidget(id="rebuild-menu")
        self.rebuild_menu.title = REBUILD_TITLE
        self.rebuild_menu.options = REBUILD_DICT
        self.host_menu = OptionsWidget(id="host-menu")
        self.host_menu.title = HOST_TITLE
        self.host_menu.options = {}
        self.command_runner = CommandRunner(id="command-runner")
        yield self.header
        with self.content_switcher:
            yield self.command_menu
            yield self.rebuild_menu
            yield self.host_menu
            yield self.command_runner


    def on_mount(self) -> None:
        self.title = "TechNet Updater"
        self.sub_title = "CLI tool for managing flake based NixOS installations"
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
        self.host_menu.options = self.config["hosts"]
        self.host_menu.mutate_reactive(OptionsWidget.options)
        self.content_switcher.loading = False

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
                
    @on(OptionsWidget.Selected, "#rebuild-menu")
    def process_rebuild_action(self, selected: OptionsWidget.Selected):
        self.rebuild_action = selected.value
        self.content_switcher.current = "host-menu"
        self.host_menu.focus()

    @on(OptionsWidget.Selected, "#host-menu")
    def process_host(self, selected: OptionsWidget.Selected):
        self.host = {"hostname": selected.key, "hosturl": selected.value}
        self.prepare_command_queue()

    def prepare_command_queue(self):
        def add_commands_for_hosts(command):
            if self.host["hosturl"] == "all":
                for key, value in self.config["hosts"].items():
                    if value != "all":
                        self.command_queue.append(command(key))
            else:
                self.command_queue.append(command(self.host["hostname"]))

        def build_command(hostname):
            return (
                "nixos-rebuild "
                "--sudo "
                "--no-reexec "
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
            "hosturl": ""
        }
        self.command_queue = []
        self.content_switcher.current = "command-menu"
        self.command_menu.focus()



if __name__ == "__main__":
    app = NixOSManager()
    app.run()