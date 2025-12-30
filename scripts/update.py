#!/usr/bin/env nix-shell
#! nix-shell -i python
#! nix-shell -p python313 python3Packages.tkinter python3Packages.sv-ttk

from tkinter import *
from tkinter.scrolledtext import ScrolledText
from tkinter.ttk import *
import sv_ttk

import pathlib
import subprocess

script_folder = pathlib.Path(__file__).parent

commands = {
    "Run All Tasks": "run_all",
    "Run Nix Flake Update": "flake_update",
    "Run Nixos Rebuild": "rebuild",
    "Preview Old Generations": "preview_generations",
    "Remove Old Generations & GC": "purge_generations_gc",
    "Run Nix Garbage Collection": "gc"
}

rebuild_actions = {
    "switch - Activate config and save to bootloader": "switch",
    "test - Activate config but reset next boot": "test",
    "boot - Activate config on next boot":"boot",
    "dry-activate - Build config but only show changes":"dry-activate",
    "build-vm - Build Test VM": "build-vm",
    "rollback - Rollback to previous configuration":"rollback"
}


class Command(Frame):
    def __init__(self, parent, controller):
        super().__init__(parent)
        self.controller = controller

        # Display the overview of the script        
        Label(self, text="This script automatically updates the selected Host from this flake", font=("Noto Sans", 16)).pack(expand=True)

        # Create the radio buttons for commands
        commands_frame = LabelFrame(self, text="Commands")
        commands_frame.pack(expand=True)
                
        self.selected_command = StringVar(value="rebuild")
        for command in commands:
            r = Radiobutton(
                commands_frame,
                text=command,
                value=commands[command],
                variable=self.selected_command
            )
            r.pack(fill='x', padx=5, pady=5)

        Button(self, text="Next", command=self.on_next_button_selected).pack(expand=True)

    def on_next_button_selected(self):
        if self.selected_command.get() == "flake_update":
            self.controller.show_frame("UpdateFlake")
        elif self.selected_command.get() == "rebuild":
            self.controller.show_frame("RebuildActions")

    def on_page_shown(self, **parameters):
        pass



class UpdateFlake(Frame):
    def __init__(self, parent, controller):
        super().__init__(parent)
        self.controller = controller
        self.title = Label(self, text="Updating Nix Flake...", font=("Noto Sans", 16))
        self.title.pack(expand=True)
        self.text = ScrolledText(self, height=20)
        self.text.pack(padx=12, expand=True, fill=BOTH)
        self.text['state'] = 'disabled'
        self.progress_bar = Progressbar(self, orient='horizontal', mode='indeterminate', length=280)
        self.progress_bar.pack(expand=True)
        self.button = Button(self, text="Return", command=lambda: controller.show_frame("Command"))
        self.button.pack(expand=True)
        self.output = ""

    def on_page_shown(self, **parameters):
        self.progress_bar.start()
        self.button.state(['disabled'])
        self.process = subprocess.Popen("nix flake update", shell=True, text=True, cwd=script_folder.parent, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        self.monitor()
    
    def monitor(self):
        """ Monitor the download thread """
        if self.process.poll() is not None:
            if self.process.returncode == 0:
                self.title.config(text = "Updating Nix Flake...Done")
            else:
                self.title.config(text = "Updating Nix Flake...Failed!")
            self.progress_bar.configure(mode='determinate', value=99.9)
            self.progress_bar.stop()
            self.button.state(['!disabled'])
        else:
            self.output, err = self.process.communicate()            
            self.text.configure(state='normal')
            self.text.delete('1.0', END)
            self.text.insert(index="1.0", chars=self.output)
            self.text.configure(state='disabled')
            self.after(5000, lambda: self.monitor())



class RebuildActions(Frame):
    def __init__(self, parent, controller):
        super().__init__(parent)
        self.controller = controller

        # Create label for instructions        
        Label(self, text="Select NixOS Rebuild Action", font=("Noto Sans", 16)).pack(expand=True)

        # Create the radio buttons for the rebuild actions
        actions_frame = LabelFrame(self, text="Actions")
        actions_frame.pack(expand=True)
                
        self.selected_action = StringVar(value="switch")
        for action in rebuild_actions:
            r = Radiobutton(
                actions_frame,
                text=action,
                value=rebuild_actions[action],
                variable=self.selected_action
            )
            r.pack(fill='x', padx=5, pady=5)


        self.button_frame = Frame(self)
        self.button_frame.pack(expand=True)
        self.return_button = Button(self.button_frame, text="Return", command=lambda: controller.show_frame("Command"))
        self.return_button.pack(side=LEFT, expand=True, padx=12)

        Button(self.button_frame, text="Next", command=self.on_next_button_selected).pack(side=LEFT, expand=True, padx=12)

    def on_next_button_selected(self):
        pass
        #if self.selected_command.get() == "flake_update":
        #    self.controller.show_frame("UpdateFlake")
        #elif self.selected_command.get() == "rebuild":
        #    self.controller.show_frame("UpdateFlake")

    def on_page_shown(self, **parameters):
        pass

class PageOne(Frame):
    def __init__(self, parent, controller):
        super().__init__(parent)

        self.controller = controller
        # Add the app description
        Label(self, text="This script automatically updates the selected Host from this flake").pack()
        Label(self, text="Page One", font=("Arial", 16)).pack(pady=20)
        Button(self, text="Back to Start", command=lambda: controller.show_frame("StartPage")).pack()


class App(Tk):
    def __init__(self):
        super().__init__()

        # Set the window title
        self.title("TechNet Updater")

        # Maximize the window
        screen_width, screen_height = self.winfo_screenwidth(), self.winfo_screenheight()
        self.geometry(f"{screen_width}x{screen_height}+0+0")

        # Set the style
        style = Style(self)
        print(style.theme_names())
        style.theme_use("classic")
        sv_ttk.set_theme("light")

        # Create the paging system
        container = Frame(self)
        container.pack(fill="both", expand=True)
        container.rowconfigure(0, weight=1)
        container.columnconfigure(0, weight=1)
        self.frames = {}
        for F in (Command, UpdateFlake, RebuildActions, PageOne):
            page_name = F.__name__
            frame = F(parent=container, controller=self)
            self.frames[page_name] = frame
            frame.grid(row=0, column=0, sticky="nsew")

        # Shows the command screen
        self.show_frame("Command")

    def show_frame(self, page_name, **parameters):
        frame = self.frames[page_name]
        frame.tkraise()
        frame.on_page_shown(**parameters)

if __name__ == "__main__":
    app = App()
    app.mainloop()
