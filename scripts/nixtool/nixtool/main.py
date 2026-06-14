import pathlib
import json

from textual import on, work
from textual.app import App, ComposeResult
from textual.widgets import Header, ContentSwitcher, Button
from textual.reactive import reactive

from .theme import white_blue_theme
from .command_runner import CommandRunner
from .host_selector import HostSelector
from .options_widget import OptionsWidget
from .commands import all_commands, HOST_TITLE

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
    current_cmd = reactive({})
    selected_vars = reactive({})
    current_var = ""
    host = {
        "hostname": "",
        "host_url": ""
    }
    command_queue = []

    def __init__(self, config_path: pathlib.Path = None):
        super().__init__()
        self.config_path = config_path or pathlib.Path.cwd() / "nixtool-config.json"

    def compose(self) -> ComposeResult:
        self.header = Header(show_clock=True)
        self.header.tall = True
        self.content_switcher = ContentSwitcher(initial="command-menu")
        self.content_switcher.loading = True
        self.command_menu = OptionsWidget(id="command-menu")
        self.command_menu.title = all_commands.get("title", "Select a command")
        self.command_menu.options = all_commands.get("commands", [])
        self.variable_menu = OptionsWidget(id="variable-menu")
        self.host_selector = HostSelector(self.config_path, id="host-selector")
        self.command_runner = CommandRunner(id="command-runner")
        yield self.header
        with self.content_switcher:
            yield self.command_menu
            yield self.variable_menu
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
        if self.config_path.exists():
            self.config = json.loads(self.config_path.read_text())
        self.content_switcher.loading = False

    @on(OptionsWidget.Selected, "#command-menu")
    def process_command(self, selected: OptionsWidget.Selected):
        idx = int(selected.value)
        self.current_cmd = all_commands['commands'][idx]
        self.selected_vars = {}
        self.check_next_step()

    @on(OptionsWidget.Selected, "#variable-menu")
    def process_variable(self, selected: OptionsWidget.Selected):
        self.selected_vars[self.current_var] = str(selected.value)
        self.check_next_step()

    @on(HostSelector.Selected)
    def process_host(self, message: HostSelector.Selected):
        self.host = {"hostname": message.hostname, "host_url": message.host_url}
        self.check_next_step()

    def check_next_step(self):
        if "menu_variables" in self.current_cmd:
            for var_name, var_cfg in self.current_cmd["menu_variables"].items():
                if var_name not in self.selected_vars:
                    self.current_var = var_name
                    self.variable_menu.title = var_cfg.get("title", f"Select {var_name}")
                    self.variable_menu.options = var_cfg.get("options", {})
                    self.content_switcher.current = "variable-menu"
                    self.variable_menu.focus()
                    return

        needs_host = self.current_cmd.get("run_on_remote", False) or self.is_host_needed_recursive(self.current_cmd)
        if needs_host and not self.host["hostname"]:
            self.content_switcher.current = "host-selector"
            self.host_selector.focus()
            return

        self.prepare_command_queue()

    def is_host_needed_recursive(self, cmd_dict):
        cmds = cmd_dict.get("commands", [])
        for item in cmds:
            if isinstance(item, str) and ("<HOSTNAME>" in item or "<HOSTURL>" in item):
                return True
            if isinstance(item, dict) and (item.get("run_on_remote", False) or self.is_host_needed_recursive(item)):
                return True
        return False

    def prepare_command_queue(self):
        self.command_queue = []
        is_batch = self.host.get("host_url") == "all"
        
        if is_batch and (self.current_cmd.get("run_on_remote") or self.is_host_needed_recursive(self.current_cmd)):
            for hname, hurl in self.config["hosts"].items():
                if hurl != "all":
                    self.command_queue.extend(self.resolve_command_recursive(self.current_cmd, hname))
        else:
            self.command_queue.extend(self.resolve_command_recursive(self.current_cmd, self.host.get("hostname")))

        self.run_commands()

    def resolve_command_recursive(self, cmd_dict, hostname):
        queue = []
        for item in cmd_dict.get("commands", []):
            if isinstance(item, str):
                queue.append(self.resolve_placeholders(item, hostname))
            elif callable(item):
                queue.extend(item(self.config.get("flake_path")))
            elif isinstance(item, dict):
                queue.extend(self.resolve_command_recursive(item, hostname))
        return queue

    def resolve_placeholders(self, cmd_str, hostname):
        flake_path = self.config.get("flake_path", "")
        user = self.config.get("user", "")
        host_url = self.config["hosts"].get(hostname, "") if hostname else ""
        replacements = {"<FLAKEPATH>": flake_path, "<HOSTNAME>": hostname or "", "<USER>": user, "<HOSTURL>": host_url}
        for k, v in self.selected_vars.items(): replacements[f"<{k}>"] = v
        for k, v in replacements.items(): cmd_str = cmd_str.replace(k, str(v))
        return cmd_str

    def run_commands(self):
        self.content_switcher.current = "command-runner"
        self.command_runner.focus()
        if self.config.get("flake_path"):
            self.command_runner.work_dir = self.config["flake_path"]
        self.command_runner.load_command_queue(self.command_queue)

    @on(Button.Pressed, "#return")
    def reset(self, event: Button.Pressed):
        self.current_cmd = {}
        self.selected_vars = {}
        self.host = {
            "hostname": "",
            "host_url": ""
        }
        self.command_queue = []
        self.content_switcher.current = "command-menu"
        self.command_menu.focus()