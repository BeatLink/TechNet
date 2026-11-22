# IR Learn ###########################################################################################################################################
#
# An HTTP API and web page that record one button press from an infrared receiver wired into an audio input and return it as a code, optionally storing it on a blaster.
# The receiver passes the remote's carrier straight through, so a mark is wherever the recording carries it.
#

import argparse
import array
import json
import statistics
import subprocess
import time
import urllib.error
import urllib.parse
import urllib.request
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

RATE = 48_000
CHUNK = 2_400
WINDOW = 4
SETTLE_SECONDS = 0.5
ACTIVE_LEVEL = 2_000
PRESS_END_SECONDS = 0.25
FRAME_GAP = 6_000
FALLBACK_GAP = 20_000
DEFAULT_CARRIER = 38_000


# Recording ##########################################################################################################################################

# Turns off the input's automatic gain and lowers its gain, so carrier bursts clip cleanly instead of pumping.
def prepare_mixer(card):
    for setting in (["Auto Gain Control", "off"], ["Mic", "capture", "0%", "cap"]):
        subprocess.run(["amixer", "-q", "-c", card, "sset", *setting], check=False)


# Samples from just before the first burst of carrier until the receiver has been quiet for a moment.
def record_press(device, timeout):
    process = subprocess.Popen(["arecord", "-q", "-D", device, "-f", "S16_LE", "-r", str(RATE), "-c", "1", "-t", "raw"], stdout=subprocess.PIPE)
    try:
        started = time.monotonic()
        samples = []
        previous = []
        quiet_samples = 0
        while True:
            raw = process.stdout.read(CHUNK * 2)
            if len(raw) < CHUNK * 2:
                raise OSError("the audio input stopped recording")
            chunk = array.array("h")
            chunk.frombytes(raw)
            settled = time.monotonic() - started > SETTLE_SECONDS
            active = settled and max(abs(after - before) for before, after in zip(chunk, chunk[1:])) > ACTIVE_LEVEL
            if samples:
                samples += chunk
                quiet_samples = 0 if active else quiet_samples + CHUNK
                if quiet_samples >= PRESS_END_SECONDS * RATE:
                    return samples
            elif active:
                samples = previous + list(chunk)
            elif time.monotonic() - started > timeout:
                raise TimeoutError("no button press heard")
            previous = list(chunk)
    finally:
        process.kill()
        process.wait()


# Decoding ###########################################################################################################################################

# Alternating mark and space lengths in microseconds, starting with a mark, found where the recording carries the carrier.
def envelope(samples):
    changes = [abs(after - before) for before, after in zip(samples, samples[1:])]
    energy = [max(changes[index:index + WINDOW]) for index in range(len(changes) - WINDOW)]
    threshold = 0.25 * max(energy)
    runs = []
    carrying = False
    count = 0
    for value in energy:
        if (value > threshold) == carrying:
            count += 1
        else:
            runs.append(count)
            carrying = not carrying
            count = 1
    if carrying:
        runs.append(count)
    cleaned = []
    index = 1
    while index < len(runs):
        if cleaned and runs[index] < 2 * WINDOW and index + 1 < len(runs):
            cleaned[-1] += runs[index] + runs[index + 1]
            index += 2
        else:
            cleaned.append(runs[index])
            index += 1
    window = WINDOW * 1e6 / RATE  # The detection window stretches every mark and shrinks every space by its own length
    return [run * 1e6 / RATE + (-window if position % 2 == 0 else window) for position, run in enumerate(cleaned)]


# Similar lengths grouped together, shortest first.
def groups_of(lengths):
    groups = []
    for length in sorted(lengths):
        if groups and length <= groups[-1][0] * 1.5:
            groups[-1].append(length)
        else:
            groups.append([length])
    return groups


# Each length replaced by the median of the similar lengths of its kind, with marks and spaces evened out apart.
def evened(lengths):
    result = list(lengths)
    for start in (0, 1):
        kind = lengths[start::2]
        medians = {length: statistics.median(group) for group in groups_of(kind) for length in group}
        result[start::2] = [medians[length] for length in kind]
    return result


# The press's first frame as a code, with the gap after it and how many frames like it the press held.
def code_from_press(durations, carrier):
    if len(durations) < 2:
        raise ValueError("the press was too short to read")
    if len(durations) % 2:
        durations = durations + [FALLBACK_GAP]
    frames = [[]]
    for index in range(0, len(durations), 2):
        frames[-1] += durations[index:index + 2]
        if durations[index + 1] >= FRAME_GAP and index + 2 < len(durations):
            frames.append([])
    first = frames[0]
    gap = first[-1] if first[-1] >= FRAME_GAP else FALLBACK_GAP
    return {
        "carrier": carrier,
        "durations": [round(length) for length in evened(first[:-1])] + [round(gap)],
        "repeat": sum(len(frame) == len(first) for frame in frames),
    }


# API ################################################################################################################################################

class Handler(BaseHTTPRequestHandler):
    device = None
    mixer_card = None
    blaster = None
    page = None

    # Answers with a status and a JSON body.
    def reply(self, status, body):
        payload = json.dumps(body, indent=4).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        self.wfile.write(payload)

    # Serves the learning page.
    def do_GET(self):
        if urllib.parse.urlparse(self.path).path != "/":
            self.reply(404, {"error": "no such endpoint"})
            return
        with open(self.page, "rb") as page_file:
            payload = page_file.read()
        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        self.wfile.write(payload)

    # Learns a code from the next press and, when given a name, stores it on the blaster.
    def do_POST(self):
        if urllib.parse.urlparse(self.path).path != "/learn":
            self.reply(404, {"error": "no such endpoint"})
            return
        try:
            length = int(self.headers.get("Content-Length") or 0)
            body = json.loads(self.rfile.read(length)) if length else {}
            if self.mixer_card:
                prepare_mixer(self.mixer_card)
            samples = record_press(self.device, float(body.get("timeout", 30)))
            code = code_from_press(envelope(samples), round(float(body.get("carrier", DEFAULT_CARRIER))))
            result = {"code": code}
            if body.get("name"):
                request = urllib.request.Request(
                    f"{body.get('blaster', self.blaster)}/codes/{urllib.parse.quote(body['name'], safe='')}",
                    data=json.dumps(code).encode(),
                    method="PUT",
                    headers={"Content-Type": "application/json"},
                )
                with urllib.request.urlopen(request, timeout=10) as response:
                    result["stored"] = json.load(response)
            self.reply(200, result)
        except TimeoutError as error:
            self.reply(408, {"error": str(error)})
        except (ValueError, TypeError) as error:
            self.reply(400, {"error": str(error)})
        except (OSError, urllib.error.URLError) as error:
            self.reply(503, {"error": str(error)})


# Serves the API until stopped.
def main():
    parser = argparse.ArgumentParser(description="Learn infrared codes from a receiver wired into an audio input.")
    parser.add_argument("--device", required=True)
    parser.add_argument("--mixer-card")
    parser.add_argument("--blaster", default="http://127.0.0.1:9620")
    parser.add_argument("--page", required=True)
    parser.add_argument("--listen", default="0.0.0.0")
    parser.add_argument("--port", type=int, default=9621)
    arguments = parser.parse_args()
    Handler.device = arguments.device
    Handler.mixer_card = arguments.mixer_card
    Handler.blaster = arguments.blaster
    Handler.page = arguments.page
    ThreadingHTTPServer((arguments.listen, arguments.port), Handler).serve_forever()


if __name__ == "__main__":
    main()
