#!/usr/bin/env python3

# yay -S python-websockets
import websockets

from dataclasses import dataclass, field, fields
import asyncio
import json
import os
import argparse
import threading

# using self-signed certs
import ssl
import urllib3
urllib3.disable_warnings(category=urllib3.exceptions.InsecureRequestWarning)
ssl_ctx = ssl.create_default_context()
ssl_ctx.check_hostname = False
ssl_ctx.verify_mode = ssl.CERT_NONE

# Icon names used in JSON
libbar_json_icons = {
    "printing": "3d_printer_printing",
    "heating": "3d_printer_heating",
    "paused": "3d_printer_paused",
    "error": "3d_printer_error",
    "standby": "3d_printer_standby",
    "complete": "3d_printer_complete",
    "cancelled": "3d_printer_cancelled",
}

# Glyph icons
libbar_icons = {
    "printing": "󰑤",
    "heating": "󱢸",
    "paused": "󰏤",
    "error": "",
    "standby": "󰐫",
    "complete": "",
    "cancelled": "󰜺",
}

# JSON color states
libbar_json_colors = {
    "printing": "Good",
    "heating": "Warning",
    "paused": "Warning",
    "error": "Critical",
    "standby": "Idle",
    "complete": "Idle",
    "cancelled": "Idle",
}


def json_print(long_text=None,
               short_text=None,
               icon=None,
               state="standby",
               text=None):
    text = text if text is not None else \
        (long_text if os.path.exists(SWITCH_FILE) else short_text)
    print(json.dumps({
        "icon": libbar_json_icons.get(state, "3d_printer")
        if icon is None else icon,
        "state": libbar_json_colors.get(state, "Idle"),
        "text": text
    }), flush=True)


SWITCH_FILE = "/tmp/statusbar_klipper_toggle"
KLIPPER_HOST = os.environ.get("KLIPPER_HOST")
if not KLIPPER_HOST:
    json_print(icon="error", state="error", text="KLIPPER_HOST env not set")
    raise ValueError("KLIPPER_HOST env var not set")
KLIPPER_WS = os.environ.get("KLIPPER_WS")  \
    if os.environ.get("KLIPPER_WS") \
    else f"wss://{KLIPPER_HOST.lstrip('https://').rstrip('/')}/websocket"


class Notifier:
    def __init__(self, notify_func):
        self.last_progress = 0
        self.interval = 0.05
        self.notify_func = notify_func

    def should_notify(self, progress):
        return progress >= self.last_progress + self.interval

    async def notify_checked(self, progress):
        if not self.should_notify(progress):
            return

        self.last_progress = progress
        await self.notify_async()

    async def notify_async(self):
        await self.notify_func()

    def notify(self):
        asyncio.create_task(self.notify_async())

    def reset(self):
        self.last_progress = 0

    def reset_if_completed(self, status):
        if status != "complete":
            return
        self.last_progress = 0


@dataclass(slots=True)
class PrintStats:
    lock = threading.Lock()
    message: str = ""
    progress: float = 0.0
    state: str = "standby"
    old_state: str = "standby"
    print_duration: int = 0
    total_duration: int = 0
    filename: str | None = None
    info: dict = field(default_factory=dict)
    subscribers: list = field(default_factory=list)

    def on_state_change(self, callback):
        self.subscribers.append(callback)

    def update(self, new_data: dict):
        with self.lock:
            for f in fields(self):
                if f.name in new_data:
                    if f.name == "state":
                        self.set_state(new_data[f.name])
                    else:
                        setattr(self, f.name, new_data[f.name])

    @property
    def remaining_duration(self) -> float:
        return self.print_duration / self.progress - self.print_duration \
            if self.progress > 0 else 0

    @property
    def percent_progress(self) -> int:
        if self.progress is None:
            return 0
        return int(self.progress * 100)

    @property
    def total_layer(self) -> int:
        return self.info.get("total_layer", None)

    @property
    def current_layer(self) -> int:
        return self.info.get("current_layer", None)

    @property
    def print_time_formatted(self) -> str:
        return format_duration(self.print_duration)

    @property
    def remaining_time_formatted(self) -> str:
        return format_duration(self.remaining_duration)

    @property
    def has_layers_info(self) -> bool:
        return self.current_layer is not None and self.total_layer is not None

    @property
    def layers_formatted(self) -> str:
        if not self.has_layers_info:
            return ""
        return f"{self.current_layer + 1}/{self.total_layer}"

    @property
    def escaped_filename(self) -> str:
        from urllib.parse import quote
        return quote(self.filename) if self.filename else ""

    @property
    def message_formatted(self) -> str:
        return self.message if self.message else self.state.capitalize()

    @property
    def is_running(self) -> bool:
        return self.state == "printing" \
            or self.state == "paused"

    def set_state(self, new_state: str):
        if self.state != new_state:
            self.old_state = self.state
            self.state = new_state
            for subscriber in self.subscribers:
                subscriber(self.state, self.old_state)

    @property
    def state_message(self):
        def status_and_message(status):
            return status + f" ({self.message})\n\n" if self.message else "\n\n"

        body = ""
        if self.state == "heating":
            t = f"{temps.extruder_formatted_long} {temps.bed_formatted_long}"
            body += status_and_message("Heating")
            body += f"Temps: {t}\n"
        elif self.state == "printing":
            body += status_and_message("Printing")
            body += f"Progress: {self.percent_progress:.0f}%\n"
        elif self.state == "complete":
            body += status_and_message("Print complete")
        elif self.state == "error":
            body += status_and_message("Print error")
        elif self.state == "paused":
            body += status_and_message("Print paused")
        elif self.state == "cancelled":
            body += status_and_message("Print cancelled")
        else:
            body += status_and_message(self.state.capitalize())

        if stats.print_duration > 0:
            body += f"Duration: {self.print_time_formatted}\n"
        if stats.remaining_duration > 0:
            body += f"Remaining: {self.remaining_time_formatted}\n"
        if self.has_layers_info:
            body += f"Layers: {self.layers_formatted}\n"

        return body.strip()


@dataclass(slots=True)
class TemperatureInfo:
    bed_temperature: float = 0.0
    bed_target: float = 0.0
    extruder_temperature: float = 0.0
    extruder_target: float = 0.0
    extruder_can_extrude: bool = False

    def update_extruder(self, new_data: dict):
        if "temperature" in new_data:
            self.extruder_temperature = new_data["temperature"]
        if "target" in new_data:
            self.extruder_target = new_data["target"]
        if "can_extrude" in new_data:
            self.extruder_can_extrude = new_data["can_extrude"]

    def update_bed(self, new_data: dict):
        if "temperature" in new_data:
            self.bed_temperature = new_data["temperature"]
        if "target" in new_data:
            self.bed_target = new_data["target"]

    def _is_within(self, temp, target, percent=None, tolerance=None):
        if percent is not None:
            tolerance = target * percent / 100
        if tolerance is None:
            raise ValueError("Either percent or tolerance must be provided")
        return abs(target - temp) <= tolerance

    @property
    def can_extrude(self) -> bool:
        return self.extruder_can_extrude

    @property
    def is_heating(self):
        return self.is_bed_heating or self.is_extruder_heating

    @property
    def is_heated(self):
        return not self.is_heating

    @property
    def is_bed_heating(self):
        tolerance = 3
        return self.bed_target > 0 and \
            self.bed_target - self.bed_temperature > tolerance

    @property
    def is_extruder_heating(self):
        tolerance = 3
        return self.extruder_target > 0 and \
            self.extruder_target - self.extruder_temperature > tolerance

    @property
    def extruder_formatted_short(self):
        return f"{int(self.extruder_temperature)}"

    @property
    def bed_formatted_short(self):
        return f"{int(self.bed_temperature)}"

    @property
    def extruder_formatted_long(self):
        return f"{int(self.extruder_temperature)}/{int(self.extruder_target)}"

    @property
    def bed_formatted_long(self):
        return f"{int(self.bed_temperature)}/{int(self.bed_target)}"


stats = PrintStats()
temps = TemperatureInfo()
notifier = Notifier(lambda: klipper_notify_progress())
ZWSP = "\u200b"  # zero-width space


async def klipper_fetch_initial_data():
    import requests

    objects = ["extruder", "heater_bed", "display_status", "print_stats"]
    url = f"{KLIPPER_HOST}/printer/objects/query?" + "&".join(objects)
    response = requests.get(url, verify=False)
    status = response.json().get("result", {}).get("status", {})
    for key in reversed(objects):
        if key in status:
            data = status[key]
            process_data({key: data})


async def klipper_get_webcam_image():
    import requests

    response = requests.get(
        f"{KLIPPER_HOST}/webcam?action=snapshot",
        verify=False)
    if response.status_code != 200:
        return None

    webcam_path = os.path.join("/tmp", "klipper_webcam.jpg")
    with open(webcam_path, "wb") as f:
        f.write(response.content)
    return webcam_path


def klipper_get_thumbnail():
    import requests
    from urllib.parse import quote

    if not stats.filename:
        return

    # Fetch thumbnail info
    filename = stats.escaped_filename
    thumb_url = f"{KLIPPER_HOST}/server/files/thumbnails?filename={filename}"
    response = requests.get(thumb_url, verify=False)
    if response.status_code != 200:
        return None

    thumbnails = response.json().get("result", [])

    if not thumbnails:
        return None

    # Pick thumbnail with max width
    largest_thumb = max(thumbnails, key=lambda x: x.get("width", 0))
    thumb_file = largest_thumb.get("thumbnail_path", "")
    thumbnail_path = os.path.join("/tmp", os.path.basename(thumb_file))

    # Download if not exists
    if not os.path.exists(thumbnail_path):
        gcode_url = f"{KLIPPER_HOST}/server/files/gcodes/{quote(thumb_file)}"
        thumb_data = requests.get(gcode_url, verify=False).content
        with open(thumbnail_path, "wb") as f:
            f.write(thumb_data)
    return thumbnail_path


async def klipper_notify_error(message):
    await klipper_notify(message, icon="dialog-error")


async def klipper_notify(message, icon=None):
    title = "Klipper"
    body = message

    args = [
        title,
        body,
    ]
    if icon:
        args.insert(0, "-i")
        args.insert(1, icon)

    proc = await asyncio.create_subprocess_exec(
        "notify-send",
        *args,
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.DEVNULL,
        start_new_session=True  # critical: fully detach
    )

    try:
        proc.communicate()  # we don't care about the result
    except Exception:
        pass


async def klipper_notify_progress():
    thumbnail_path = klipper_get_thumbnail()

    title = "Klipper"
    if thumbnail_path:
        title += f" - {stats.filename}"
    body = stats.state_message

    args = [
        "-A", "open=Open klipper",
        title,
        body,
    ]
    if thumbnail_path:
        args.extend(["-i", thumbnail_path])
    # if it is not complete we add a small progress bar
    if stats.is_running:
        args.extend(["-h", f"int:value:{stats.percent_progress};max:100"])

    proc = await asyncio.create_subprocess_exec(
        "notify-send",
        *args,
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.DEVNULL,
        start_new_session=True  # critical: fully detach
    )

    # handle action click asynchronously
    asyncio.create_task(_handle_notify_action(proc))


async def _handle_notify_action(proc):
    import webbrowser

    try:
        stdout, _ = await proc.communicate()
        if stdout:
            action = stdout.decode().strip()
            if action == "open":
                webbrowser.open(KLIPPER_HOST)
    except Exception:
        pass


def format_duration(seconds: int | None) -> str:
    if not seconds:
        return "N/A"
    if seconds < 60:
        return f"{int(seconds)}s"
    hours = int(seconds // 3600)
    minutes = int((seconds % 3600) // 60)
    output = ""
    if hours > 0:
        output += f"{hours}h"
    if minutes > 0:
        output += f"{minutes}m"
    return output.strip()


async def klipper_output():
    if stats.state == "heating":
        long_text = f"{temps.extruder_formatted_long} {temps.bed_formatted_long} "
        if stats.message:
            long_text = f"{stats.message} " + long_text
        short_text = f"{temps.extruder_formatted_short} {temps.bed_formatted_short} "
    elif stats.state == "printing":
        long_text = f"{stats.percent_progress:.0f}% "
        if stats.remaining_duration > 0:
            long_text += f"{stats.remaining_time_formatted} "
        if stats.current_layer and stats.total_layer:
            long_text += f"{stats.layers_formatted} "
        if stats.message:
            long_text = f"{stats.message} " + long_text
        short_text = f"{stats.percent_progress:.0f}% "

    elif stats.state == "complete":
        long_text = f"{stats.message_formatted} ({stats.print_time_formatted}) "
        short_text = ZWSP
    else:
        long_text = f"{stats.message_formatted} "
        short_text = ZWSP

    json_print(state=stats.state, long_text=long_text, short_text=short_text)


async def handle_websocket():
    # we subscribe to these objects to get real-time updates
    # but we also fetch their initial state on startup
    objects = {
        "heater_bed": ["temperature", "target"],
        "extruder": ["temperature", "target", "can_extrude"],
        "display_status": ["message", "progress"],
        "print_stats": ["state",
                        "print_duration",
                        "total_duration",
                        "filename", "info"]
    }
    while True:
        try:
            async with websockets.connect(KLIPPER_WS, ssl=ssl_ctx) as ws:
                # fetch initial data
                await ws.send(json.dumps({
                    "jsonrpc": "2.0",
                    "method": "printer.objects.query",
                    "params": {
                        "objects": objects,
                    },
                    "id": 1
                }))

                # subscribe to print_stats
                await ws.send(json.dumps({
                    "jsonrpc": "2.0",
                    "method": "printer.objects.subscribe",
                    "params": {
                        "objects": objects,
                    },
                    "id": 2
                }))

                # receive updates forever
                async for message in ws:
                    data = json.loads(message)

                    if data.get("method") == "notify_status_update":
                        for obj in data["params"]:
                            if isinstance(obj, dict):
                                process_data(obj)
                    elif "result" in data and "status" in data["result"]:
                        process_data(data["result"]["status"])

                    await notifier.notify_checked(stats.progress)
        except (websockets.exceptions.ConnectionClosedError, ConnectionRefusedError) as e:
            message = f"Websocket connection error: {e}. Retrying in 5 seconds."
            klipper_notify_error(message)
            await asyncio.sleep(5)
        except OSError as e:
            message = f"Network error: {e}. Retrying in 5 seconds."
            klipper_notify_error(message)
            await asyncio.sleep(5)
        except Exception as e:
            message = f"An unexpected error occurred: {e}. Retrying in 5 seconds."
            klipper_notify_error(message)
            await asyncio.sleep(5)


def process_data(obj):
    if "display_status" in obj and obj["display_status"] is not None:
        stats.update(obj["display_status"])

    if "print_stats" in obj and obj["print_stats"] is not None:
        # we don't care about the message from this object
        if "message" in obj["print_stats"]:
            del obj["print_stats"]["message"]

        stats.update(obj["print_stats"])

    if "heater_bed" in obj and obj["heater_bed"] is not None:
        temps.update_bed(obj["heater_bed"])
        check_temps_and_update_state()

    if "extruder" in obj and obj["extruder"] is not None:
        temps.update_extruder(obj["extruder"])
        check_temps_and_update_state()


def check_temps_and_update_state():
    if temps.is_heating and stats.state != "heating":
        stats.update({"state": "heating"})
    elif temps.is_heated and stats.state == "heating":
        stats.update({"state": stats.old_state})


async def main_loop(args):
    stats.on_state_change(lambda new, _: notifier.notify())
    stats.on_state_change(lambda new, _: notifier.reset_if_completed(new))
    asyncio.create_task(handle_websocket())
    while True:
        await klipper_output()
        await asyncio.sleep(args.interval)


async def main():
    # compatility with i3status/blocks
    block_button = os.environ.get("BLOCK_BUTTON")

    args_parser = argparse.ArgumentParser()
    args_parser.add_argument("--interval",
                             type=float,
                             default=1.0,
                             help="Interval between updates in seconds")
    args = args_parser.parse_args()

    if block_button == "1":
        await klipper_fetch_initial_data()  # ensure we have the latest data
        await notifier.notify_async()  # show notification immediately on click
    elif block_button == "2":
        if os.path.exists(SWITCH_FILE):
            os.remove(SWITCH_FILE)
        else:
            with open(SWITCH_FILE, "w") as f:
                f.write("toggle")
    elif block_button == "3":
        import webbrowser
        webbrowser.open(KLIPPER_HOST)

    if block_button is not None:
        return

    await main_loop(args)


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        pass
    except Exception as e:
        json_print(icon="error", state="Error", text=f"Error: {str(e)}")
