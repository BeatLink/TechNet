import asyncio
import subprocess

from textual import on, work
from textual.app import ComposeResult
from textual.containers import Container, Center, CenterMiddle, HorizontalGroup
from textual.widgets import Label, Button, RichLog
from textual.widget import Widget
from textual.events import Focus
from textual.reactive import reactive


CSS = """
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

class CommandRunner(Widget):
    DEFAULT_CSS = CSS
    can_focus = True
    command_queue = []
    final_return_code = 0
    work_dir = reactive(None)
    
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

    def __init__(self, *children: Widget, work_dir=None):
        super().__init__(*children)
        self.work_dir = work_dir
        self.container = Container(id="container")
        self.label = Label(id="label")
        self.logview = RichLog(id="logview")
        self.message = Label(id="message", classes="invisible")
        self.message.loading = True
        self.return_button = Button("Return", id="return", variant="primary")
        self.return_button.compact = True
        self.return_button.flat = True
        self.start_button = Button("Start", id="start", variant="primary")
        self.start_button.compact = True
        self.start_button.flat = True

    def compose(self) -> ComposeResult:
        with self.container:
            with Center():
                yield Center(self.label)
                yield CenterMiddle(self.logview)
                yield Center(self.message)
                with HorizontalGroup():
                    yield self.return_button
                    yield self.start_button

    def on_focus(self, _: Focus):
        self.start_button.focus()

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
    def start(self, _: Button.Pressed):
        self.run_command()
        self.return_button.focus()

    @work(exclusive=True)
    async def run_command(self):
        self.final_return_code = 0
        self.start_button.add_class("invisible")
        self.message.remove_class("invisible")
        for index, command in enumerate(self.command_queue):
            command_message = f"Running command {index+1} of {len(self.command_queue)}: {command}"
            self.label.update(command_message)
            self.logview.write("\n--------------------------------------------------------------------------\n")
            self.logview.write(f">>> {command_message} <<<")
            process = await asyncio.create_subprocess_shell(
                command,
                cwd=self.work_dir,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT
            )
            while True:
                line = await process.stdout.readline()
                if not line:
                    break
                self.logview.write(line.decode().rstrip())
            await process.wait()
            self.final_return_code += int(process.returncode)
            if int(process.returncode) == 0:
                self.logview.write(f"\n>>> Command succeeded with return code {process.returncode} <<")
            else:
                self.logview.write(f"\n>>> Command failed with return code {process.returncode} <<<")

        # When process is finished show the end message        
        if int(self.final_return_code) == 0:
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