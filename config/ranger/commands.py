from ranger.api.commands import Command
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
