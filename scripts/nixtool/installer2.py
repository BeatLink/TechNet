#!/usr/bin/env nix-shell
#! nix-shell -i python
#! nix-shell -p python313 python3Packages.textual


import pathlib
import json
import asyncio
import os
import subprocess
import tempfile
from datetime import datetime
from textual import on, work
from textual.app import App, ComposeResult
from textual.containers import CenterMiddle, Center, Middle, Container, Vertical, Horizontal, HorizontalGroup
from textual.widgets import Header, ContentSwitcher, Label, Digits, OptionList, RichLog, Button, Input, TextArea
from textual.widgets.option_list import Option
from textual.widget import Widget
from textual.events import Focus
from textual.message import Message
from textual.reactive import reactive
from textual.theme import Theme

COMMANDS_TITLE = "Select a command"
HOST_TITLE = "Select Host to Install"
DRIVE_TITLE = "Select Drive"
TOWBOOT_TITLE = "Select TowBoot Version"
RAID_TITLE = "Use RAID 1 (Mirror)?"

COMMANDS_DICT = {
script_folder = pathlib.Path(__file__).parent
config_file = script_folder / "nixtool-config.json"

class CommandRunner(Widget):
    DEFAULT_CSS = """
        #container { width: 97.5%; height: 95%; }
        HorizontalGroup { align: center middle; }
        #label { color: $primary; text-style: bold; }
        #logview { height: 100%; border: round $primary; background: transparent; }
        #message { text-align: center; text-style: bold; align: center middle; content-align: center middle; }
        #message.success { color: $success; }
        #message.error { color: $error; }
        #start, #return { text-style: bold; align: center middle; content-align: center middle; }
        .invisible { display: none }
    """
    can_focus = True
    command_queue = []
    final_returncode = 0

    def compose(self) -> ComposeResult:
        self.container = Container(id="container")
        self.label = Label(id="label")
        self.logview = RichLog(id="logview")
        self.message = Label(id="message", classes="invisible")
        self.message.loading = True
        self.start_button = Button("Start", id="start", variant="primary")
        self.return_button = Button("Return", id="return", variant="primary")
        with self.container:
            with Center():
                yield Center(self.label)
                yield CenterMiddle(self.logview)
                yield Center(self.message)
                with HorizontalGroup():
                    yield self.return_button
                    yield self.start_button

    def on_focus(self, event: Focus):
        self.start_button.focus()

    def load_command_queue(self, command_queue):
        self.label.update(f"Ready To Start")
        self.logview.clear()
        self.message.update("")
        self.message.loading = True
        self.message.remove_class("success", "error")
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
        self.final_returncode = 0
        self.start_button.add_class("invisible")
        self.message.remove_class("invisible")
        for index, command in enumerate(self.command_queue):
            command_message = f"Running command {index+1} of {len(self.command_queue)}"
            self.label.update(command_message)
            self.logview.write(f"\n>>> {command} <<<\n")
            process = await asyncio.create_subprocess_shell(
                command, stdout=subprocess.PIPE, stderr=subprocess.STDOUT
            )
            while True:
                line = await process.stdout.readline()
                if not line: break
                self.logview.write(line.decode().rstrip())
            await process.wait()
            self.final_returncode += int(process.returncode)
        
        if int(self.final_returncode) == 0:
            self.message.update("Operation Successful!")
            self.message.add_class("success")
        else:
            self.message.update("Operation Failed. Check logs.")
            self.message.add_class("error")
        self.message.loading = False
        self.return_button.focus()

class InstallForm(Widget):
    DEFAULT_CSS = """
        InstallForm { width: 60%; height: auto; border: round $primary; padding: 1; }
        Label { margin-top: 1; color: $primary; }
        Button { margin-top: 2; width: 100%; }
    """
    def compose(self) -> ComposeResult:
        yield Label("SSH Address (root@ip):")
        yield Input(placeholder="root@192.168.0.2", id="ssh_address")
        yield Label("SSH Host Key:")
        yield Input(id="ssh_key")
        yield Label("SSH InitRD Host Key:")
        yield Input(id="ssh_initrd_key")
        yield Label("Disk Encryption Key:")
        yield Input(password=True, id="enc_key")
        yield Button("Confirm Installation Details", variant="success", id="submit_install")

class OptionsWidget(Widget):
    InstallForm {
        align: center middle;
    }

    config = reactive({})
    selected_command = ""
    selected_host = ""
    selected_drive = ""
    selected_mirror_drive = ""
    is_raid = False
    temp_dir = None

    def on_mount(self) -> None:
        self.title = "TechNet Installer"
        self.sub_title = "Unified Deployment and Formatting Tool"
        self.register_theme(white_blue_theme)  
        self.theme = "white_blue"
        
    def on_ready(self) -> None:
        self.load_config()

    def get_drives(self):
        try:
            result = subprocess.run(["lsblk", "-dn", "-o", "NAME,SIZE,MODEL"], capture_output=True, text=True)
            drives = {}
            for line in result.stdout.strip().split('\n'):
                parts = line.split(None, 2)
                if len(parts) >= 2:
                    name = f"/dev/{parts[0]}"
                    desc = f"{name} ({parts[1]} - {parts[2] if len(parts)>2 else 'Generic'})"
                    drives[desc] = name
            return drives
        except Exception:
            return {"Error listing drives": "error"}

    @work(exclusive=True)
    async def load_config(self):
        if config_file.exists():
            self.config = json.loads(config_file.read_text())
            self.host_menu.options = self.config.get("hosts", {})
        else:
            self.host_menu.options = {"Ragnarok": "ragnarok", "Heimdall": "heimdall", "Odin": "odin", "Thor": "thor"}
        self.content_switcher.loading = False

    def compose(self) -> ComposeResult:
        self.command_menu = OptionsWidget(id="command-menu")
        self.command_menu.title = COMMANDS_TITLE
        self.command_menu.options = COMMANDS_DICT
        
        self.host_menu = OptionsWidget(id="host-menu")
        self.host_menu.title = HOST_TITLE
        
        self.drive_menu = OptionsWidget(id="drive-menu")
        self.drive_menu.title = DRIVE_TITLE

        self.raid_menu = OptionsWidget(id="raid-menu")
        self.raid_menu.title = RAID_TITLE
        self.raid_menu.options = {"No": "no", "Yes": "yes"}

        self.install_form = InstallForm(id="install-form")
        self.command_runner = CommandRunner(id="command-runner")

        yield self.header
        with self.content_switcher:
            yield self.command_menu
            yield self.host_menu
            yield self.drive_menu
            yield self.raid_menu
            yield self.install_form
            yield self.command_runner

    @on(OptionsWidget.Selected, "#command-menu")
    def process_command(self, selected: OptionsWidget.Selected):
        self.selected_command = selected.value
        if self.selected_command == "install":
            self.content_switcher.current = "host-menu"
        elif self.selected_command == "format_data_server":
            self.content_switcher.current = "raid-menu"
        else:
            self.drive_menu.options = self.get_drives()
            self.content_switcher.current = "drive-menu"

    @on(OptionsWidget.Selected, "#raid-menu")
    def process_raid(self, selected: OptionsWidget.Selected):
        self.is_raid = (selected.value == "yes")
        self.drive_menu.options = self.get_drives()
        self.content_switcher.current = "drive-menu"

    @on(OptionsWidget.Selected, "#host-menu")
    def process_host(self, selected: OptionsWidget.Selected):
        self.selected_host = selected.value
        self.content_switcher.current = "install-form"

    @on(OptionsWidget.Selected, "#drive-menu")
    def process_drive(self, selected: OptionsWidget.Selected):
        if self.is_raid and not self.selected_drive:
            self.selected_drive = selected.value
            self.drive_menu.title = "Select Second Mirror Drive"
            self.drive_menu.options = {k: v for k, v in self.get_drives().items() if v != self.selected_drive}
            return
        
        if self.is_raid:
            self.selected_mirror_drive = selected.value
        else:
            self.selected_drive = selected.value
            
        self.build_command_queue()

    @on(Button.Pressed, "#submit_install")
    def handle_install(self):
        self.build_command_queue()

    @on(Button.Pressed, "#return")
    def handle_return(self):
        self.selected_drive = ""
        self.selected_mirror_drive = ""
        self.content_switcher.current = "command-menu"

    def build_command_queue(self):
        queue = []
        if self.selected_command == "install":
            self.temp_dir = tempfile.mkdtemp()
            p = pathlib.Path(self.temp_dir)
            ssh_dir = p / "persistent/etc/ssh"
            ssh_dir.mkdir(parents=True, exist_ok=True)
            
            addr = self.query_one("#ssh_address", Input).value
            enc_key = self.query_one("#enc_key", Input).value
            
            # Scripted setup via queue
            queue.append(f"echo '{self.query_one('#ssh_key', Input).value}' > {ssh_dir}/ssh_host_ed25519_key")
            queue.append(f"echo '{self.query_one('#ssh_initrd_key', Input).value}' > {ssh_dir}/ssh_initrd_host_ed25519_key")
            queue.append(f"echo '{enc_key}' > {p}/encryption.key")
            queue.append(f"chmod 600 {ssh_dir}/*")
            queue.append(f"nix run github:nix-community/nixos-anywhere -- --extra-files {p} --disk-encryption-keys /tmp/encryption.key {p}/encryption.key --flake .#{self.selected_host} {addr}")

        elif self.selected_command == "format_data_backup_server":
            d = self.selected_drive
            queue = [
                f"sudo sgdisk --zap-all {d}",
                f"sudo sgdisk --new=1:0:0 --typecode=1:BF00 {d}",
                f"sudo zpool create -f -d -m none -o feature@zstd_compress=enabled -o ashift=12 -o autotrim=on data-pool {d}1",
                f"sudo zfs create -o encryption=on -o keyformat=passphrase -o keylocation=prompt -o xattr=sa -o acltype=posix -o mountpoint=/Storage data-pool/storage"
            ]

        elif self.selected_command == "format_data_server":
            d1 = self.selected_drive
            queue = [
                f"sudo zpool create -f -d -m none -o feature@zstd_compress=enabled -o ashift=12 -o autotrim=on data-pool {d1}",
                f"sudo zfs create -o encryption=on -o keyformat=passphrase -o keylocation=prompt -o xattr=sa -o acltype=posix -o mountpoint=/Storage data-pool/storage"
            ]
            if self.is_raid:
                queue.append(f"sudo zpool attach data-pool {d1} {self.selected_mirror_drive}")

        elif self.selected_command == "format_sd_card_phone":
            d = self.selected_drive
            v = "2023.07-007"
            queue = [
                f"sudo sgdisk --zap-all {d}",
                f"sudo dd if=/dev/zero of={d} bs=32k seek=4 count=1 conv=notrunc",
                f"wget -O towboot.tar.xz https://github.com/Tow-Boot/Tow-Boot/releases/download/release-{v}/pine64-pinephoneA64-{v}.tar.xz",
                f"tar -xJf towboot.tar.xz",
                f"sudo dd if=pine64-pinephoneA64-{v}/shared.disk-image.img of={d} bs=1M oflag=direct,sync status=progress",
                f"echo 'write' | sudo sfdisk --append {d}",
                f"sudo sgdisk --new=2:0:0 --typecode=1:BF00 {d}",
                f"sudo zpool create -f -d -m none -o feature@zstd_compress=enabled -o ashift=12 -o autotrim=on data-pool-thor {d}2",
                f"sudo zfs create -o encryption=on -o keyformat=passphrase -o keylocation=prompt -o xattr=sa -o acltype=posix -o mountpoint=legacy data-pool-thor/storage"
            ]

        self.content_switcher.current = "command-runner"
        self.command_runner.load_command_queue(queue)

if __name__ == "__main__":
class InstallerScriptCommand(NixCommand):
    def __init__(self, name, script_name):
        super().__init__(name)
        self.script_name = script_name
    def _resolve(self, app, hostname):
        return [f"bash ./{self.script_name}"]