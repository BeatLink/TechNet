import json
import pathlib
from textual import on
from textual.app import ComposeResult
from textual.message import Message
from textual.widget import Widget
from textual.widgets import Label, OptionList
from textual.widgets.option_list import Option

class HostSelector(Widget):
    """A portable widget for selecting NixOS hosts from a configuration file."""

    DEFAULT_CSS = """
    HostSelector {
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

    class Selected(Message):
        """Sent when a host is selected."""
        def __init__(self, hostname: str, host_url: str) -> None:
            super().__init__()
            self.hostname = hostname
            self.host_url = host_url

    def __init__(self, config_path: pathlib.Path, id: str | None = None) -> None:
        super().__init__(id=id)
        self.config_path = config_path

    def compose(self) -> ComposeResult:
        yield Label("Select Hosts", id="label")
        yield OptionList(id="list")

    def on_mount(self) -> None:
        self.refresh_hosts()

    def refresh_hosts(self) -> None:
        """Loads host data from config and populates the list."""
        try:
            config = json.loads(self.config_path.read_text())
            hosts = {"All Hosts": "all"} | config.get("hosts", {})
            option_list = self.query_one(OptionList)
            option_list.clear_options()
            for name, url in hosts.items():
                option_list.add_option(Option(name, id=url))
        except Exception:
            self.query_one(Label).update("Error loading hosts")

    @on(OptionList.OptionSelected)
    def _on_option_selected(self, event: OptionList.OptionSelected) -> None:
        self.post_message(self.Selected(event.option.prompt, str(event.option.id)))

    def focus(self, scroll_visible: bool = True) -> Widget:
        self.query_one(OptionList).focus()
        return self