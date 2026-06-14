from .main import NixOSManager
import pathlib

def run(config_path: pathlib.Path = None):
    """Bootstraps and runs the NixOSManager application."""
    app = NixOSManager(config_path)
    app.run()