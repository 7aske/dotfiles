from ranger.api.commands import Command
import os
import subprocess

class rgs_cd(Command):
    def execute(self):
        try:
            path = subprocess.check_output(['rgs', '-C']).decode().strip()
        except subprocess.CalledProcessError:
            self.fm.notify("rgs -C failed", bad=True)
            return
        if path:
            self.fm.cd(path)


class mime_ext(Command):
    def execute(self):
        thisfile = self.fm.thisfile
        if thisfile is None:
            self.fm.notify("No file selected", bad=True)
            return

        path = thisfile.path
        extension = os.path.splitext(path)[1].lstrip(".") or "[none]"

        try:
            mime_type = subprocess.check_output(
                ["xdg-mime", "query", "filetype", path],
                text=True
            ).strip()
        except (subprocess.CalledProcessError, FileNotFoundError):
            self.fm.notify("xdg-mime query failed", bad=True)
            return

        self.fm.notify(f"mime: {mime_type} | ext: {extension}")
