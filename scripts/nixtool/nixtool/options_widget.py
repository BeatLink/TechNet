from textual.app import ComposeResult
from textual.containers import Container
from textual.events import Focus
from textual.message import Message
from textual.reactive import reactive
from textual.widget import Widget
from textual.widgets import Label, OptionList
from textual.widgets.option_list import Option


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
        options = []
        if isinstance(self.options, dict):
            for key, value in self.options.items():
                if hasattr(value, "name"):
                    options.append(Option(value.name, id=key))
                elif isinstance(value, dict) and "name" in value:
                    options.append(Option(value["name"], id=key))
                else:
                    options.append(Option(key, id=value))
        elif isinstance(self.options, list):
            for index, item in enumerate(self.options):
                if isinstance(item, dict) and "name" in item:
                    options.append(Option(item["name"], id=str(index)))
                else:
                    options.append(Option(str(item), id=str(index)))

        with Container(id="container"):
            yield Label(self.title, id="label")
            yield OptionList(*options, id="list")

    def on_focus(self, event: Focus):
        self.query_one(OptionList).focus()

    def on_option_list_option_selected(self, event: OptionList.OptionSelected):
        self.post_message(
            self.Selected(
                self,
                event.option.prompt,
                str(event.option.id)
            )
        )
