from textual.app import ComposeResult
from textual.containers import Container
from textual.events import Focus
from textual.message import Message
from textual.reactive import reactive
from textual.widget import Widget
from textual.widgets import Label
from textual.widgets._option_list import Option, OptionList


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

    def __init__(
            self,
            *children: Widget,
            name: str | None = None,
            id: str | None = None,
            classes: str | None = None,
            disabled: bool = False,
            markup: bool = True,
    ):
        super().__init__(children, name, id, classes, disabled, markup)
        options = [
            Option(key, id=value)
            for key, value
            in self.options.items()
        ]
        self.container = Container(id="container")
        self.label = Label(self.title, id="label")
        self.list = OptionList(*options, id="list")

    def compose(self) -> ComposeResult:
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
