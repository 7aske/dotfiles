#!/usr/bin/env python3

# yay -S python-websockets
import websockets

import asyncio
import json
import os
import argparse

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


def json_print(long_text, short_text, icon=None, state="standby", text=None):
    text = text if text is not None else (long_text if os.path.exists(SWITCH_FILE) else short_text)
    print(json.dumps({
        "icon": libbar_json_icons.get(state, "3d_printer") if icon is None else icon,
        "state": libbar_json_colors.get(state, "Idle"),
        "text": text
    }), flush=True)


SWITCH_FILE = "/tmp/statusbar_klipper_toggle"
KLIPPER_HOST = os.environ.get("KLIPPER_HOST")
if not KLIPPER_HOST:
    json_print(icon="error", state="error", text="KLIPPER_HOST env var not set")
KLIPPER_WS = os.environ.get("KLIPPER_WS") if os.environ.get("KLIPPER_WS") else f"wss://{KLIPPER_HOST.lstrip('https://').rstrip('/')}/websocket"

print_stats = {}
display_status = {}
heater_bed = {}
extruder = {}
last_progress_notif = 0
progress_notif_interval = 0.05
ZWSP = "\u200b"  # zero-width space


async def klipper_fetch_initial_data():
    import requests

    response = requests.get(f"{KLIPPER_HOST}/printer/objects/query?heater_bed&extruder&display_status&print_stats", verify=False)
    data = response.json()
    for key in ["heater_bed", "extruder", "display_status", "print_stats"]:
        if key in data.get("result", {}).get("status", {}):
            process_data({key: data["result"]["status"][key]})


async def klipper_get_webcam_image():
    import requests

    response = requests.get(f"{KLIPPER_HOST}/webcam?action=snapshot", verify=False)
    if response.status_code != 200:
        return None

    webcam_path = os.path.join("/tmp", "klipper_webcam.jpg")
    with open(webcam_path, "wb") as f:
        f.write(response.content)
    return webcam_path


def klipper_get_thumbnail():
    import requests
    from urllib.parse import quote

    filename = print_stats.get("filename")
    if not filename:
        return

    # URL encode the filename
    escaped_filename = quote(filename)
    # Fetch thumbnail info
    thumb_url = f"{KLIPPER_HOST}/server/files/thumbnails?filename={escaped_filename}"
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


async def klipper_notify_progress():
    await klipper_fetch_initial_data()

    thumbnail_path = await klipper_get_webcam_image()

    progress, percent, remaining_time, print_time, current_layer, total_layer = get_formatted_data()

    title = "Klipper"
    if thumbnail_path:
        title += f" - {print_stats.get('filename', 'Unknown file')}"
    body = ""
    if progress == 1.0:
        body += "Print complete!\n"
    else:
        body += f"Progress:  {percent:.0f}%\n"
    if print_time:
        body += f"Total:  {print_time}\n"
    if remaining_time:
        body += f"Remaining: {remaining_time}\n"
    if current_layer and total_layer and progress != 1.0:
        body += f"Layers:    {current_layer}/{total_layer}\n"

    args = [
        "-A", "open=Open klipper",
        title,
        body,
    ]
    if thumbnail_path:
        args.extend(["-i", thumbnail_path])
    # if it is not complete we add a small progress bar
    if progress != 1.0:
        args.extend(["-h", f"int:value:{int(percent)}"])

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
    if not seconds or seconds < 60:
        return ""
    hours = int(seconds // 3600)
    minutes = int((seconds % 3600) // 60)
    return f"{hours}h " if hours else "" + (f"{minutes}m" if minutes else "")


def get_formatted_data() -> tuple[float, int, str, str, int, int]:
    current_layer = print_stats.get("info", {}).get("current_layer", 0)
    total_layer = print_stats.get("info", {}).get("total_layer", 0)
    progress = display_status.get("progress", 0)
    print_duration = print_stats.get("print_duration", 0)
    percent = int(display_status.get("progress", 0) * 100)
    remaining_duration = \
        print_duration / progress - print_duration \
        if progress > 0 else 0
    remaining_time = format_duration(remaining_duration)
    print_time = format_duration(print_duration)

    return progress, percent, remaining_time, print_time, current_layer, total_layer


def get_temperatures():
    extruder_can_extrude = extruder.get("can_extrude", False)
    extruder_temp = extruder.get("temperature", 0)
    extruder_target = extruder.get("target", 0)
    bed_temp = heater_bed.get("temperature", 0)
    bed_target = heater_bed.get("target", 0)

    return extruder_can_extrude, int(extruder_temp), int(extruder_target), int(bed_temp), int(bed_target)


async def klipper_output():
    extruder_can_extrude, extruder_temp, extruder_target, bed_temp, bed_target = get_temperatures()
    progress, percent, remaining_time, print_time, current_layer, total_layer = get_formatted_data()
    state = print_stats.get("state", "standby")

    if state == "heating":
        long_text = f"{extruder_temp}/{extruder_target} {bed_temp}/{bed_target} "
        short_text = f"{extruder_temp} {bed_temp} "
    elif state == "printing":
        long_text = (
            f"{percent:.0f}% "
            f"{remaining_time} "
        )
        if current_layer and total_layer and progress != 1.0:
            long_text += f"{current_layer}/{total_layer} "
        short_text = f"{percent:.0f}% "

    elif state == "complete":
        long_text = f"{state.capitalize()} ({print_time}) "
        short_text = ZWSP
    else:
        long_text = f"{state.capitalize()} "
        short_text = ZWSP

    json_print(state=state, long_text=long_text, short_text=short_text)


async def handle_websocket():
    async with websockets.connect(KLIPPER_WS, ssl=ssl_ctx) as ws:
        # fetch initial data
        await ws.send(json.dumps({
            "jsonrpc": "2.0",
            "method": "printer.objects.query",
            "params": {
                "objects": {
                    "heater_bed": ["temperature", "target"],
                    "extruder": ["temperature", "target", "can_extrude"],
                    "display_status": ["message", "progress"],
                    "print_stats": ["state", "print_duration", "total_duration", "filename", "info"]
                }
            },
            "id": 1
        }))

        # subscribe to print_stats
        await ws.send(json.dumps({
            "jsonrpc": "2.0",
            "method": "printer.objects.subscribe",
            "params": {
                "objects": {
                    "heater_bed": ["temperature", "target"],
                    "extruder": ["temperature", "target", "can_extrude"],
                    "display_status": ["message", "progress"],
                    "print_stats": ["state", "print_duration", "total_duration", "filename", "info"]
                }
            },
            "id": 2
        }))

        # receive updates forever
        async for message in ws:
            data = json.loads(message)
            old_state = print_stats.get("state", "standby")

            if data.get("method") == "notify_status_update":
                for obj in data["params"]:
                    if isinstance(obj, dict):
                        process_data(obj)
            elif "result" in data and "status" in data["result"]:
                process_data(data["result"]["status"])

            global last_progress_notif
            progress = display_status.get("progress", 0)
            if progress == 1.0 and last_progress_notif != 0:
                last_progress_notif = 0
                asyncio.create_task(klipper_notify_progress())
            elif progress < 1.0 and progress >= last_progress_notif + progress_notif_interval:
                last_progress_notif = progress
                asyncio.create_task(klipper_notify_progress())
            if old_state != print_stats.get("state", "standby"):
                asyncio.create_task(klipper_notify_progress())


def process_data(obj):
    global last_progress_notif
    if "display_status" in obj and obj["display_status"] is not None:
        display_status.update(obj["display_status"])

    if "print_stats" in obj and obj["print_stats"] is not None:
        print_stats.update({k: v for k, v in obj["print_stats"].items() if k != "info"})
        if "info" in obj["print_stats"]:
            print_stats.setdefault("info", {}).update(obj["print_stats"]["info"])

    if "heater_bed" in obj and obj["heater_bed"] is not None:
        heater_bed.update(obj["heater_bed"])

    if "extruder" in obj and obj["extruder"] is not None:
        extruder.update(obj["extruder"])


    # update state based on temperatures if not already printing/paused/error
    extruder_can_extrude, extruder_temp, extruder_target, bed_temp, bed_target = get_temperatures()
    if (
        extruder_can_extrude is False
        and (extruder_temp < extruder_target or bed_temp < bed_target)
    ):
        print_stats.setdefault("state", "heating")


async def main_loop(args):
    asyncio.create_task(handle_websocket())
    while True:
        await klipper_output()
        await asyncio.sleep(args.interval)


def main():
    # compatility with i3status/blocks
    block_button = os.environ.get("BLOCK_BUTTON")

    args_parser = argparse.ArgumentParser()
    args_parser.add_argument("--interval", type=float, default=1.0, help="Interval between updates in seconds")
    args = args_parser.parse_args()

    if block_button == "1":
        asyncio.run(klipper_notify_progress())
    elif block_button == "2":
        print("Toggling display mode")
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

    try:
        asyncio.run(main_loop(args))
    except KeyboardInterrupt:
        pass


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        pass
    except Exception as e:
        json_print(icon="error", state="Error", text=f"Error: {str(e)}")
