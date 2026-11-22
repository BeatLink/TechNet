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


# Protocols ##########################################################################################################################################

# Whether a measured length is close enough to a protocol's nominal one.
def near(length, nominal):
    return abs(length - nominal) <= max(0.3 * nominal, 150)


# The number whose bits are given, least significant first.
def lsb_first(bits):
    return sum(bit << index for index, bit in enumerate(bits))


# The number whose bits are given, most significant first.
def msb_first(bits):
    return lsb_first(bits[::-1])


# Bits from a header, fixed marks and two space lengths, ending with a stop mark, or None when the frame is not shaped that way.
def pulse_distance(durations, header, mark, zero, one):
    if header:
        if not (near(durations[0], header[0]) and near(durations[1], header[1])):
            return None
        durations = durations[2:]
    if len(durations) < 4 or len(durations) % 2:
        return None
    bits = []
    for index in range(0, len(durations) - 2, 2):
        if not near(durations[index], mark):
            return None
        if near(durations[index + 1], zero):
            bits.append(0)
        elif near(durations[index + 1], one):
            bits.append(1)
        else:
            return None
    return bits if near(durations[-2], mark) else None


# Bits from a header and marks of two lengths, each followed by a fixed space, or None when the frame is not shaped that way.
def pulse_width(durations, header, space, zero, one):
    if not (near(durations[0], header[0]) and near(durations[1], header[1])):
        return None
    bits = []
    for index in range(2, len(durations), 2):
        if near(durations[index], zero):
            bits.append(0)
        elif near(durations[index], one):
            bits.append(1)
        else:
            return None
        if index + 2 < len(durations) and not near(durations[index + 1], space):
            return None
    return bits


# Carrier levels in half-bit units, marks as True, or None when a length is not a whole number of units.
def half_bits(durations, unit, longest):
    levels = []
    for index, length in enumerate(durations):
        count = round(length / unit)
        if not 1 <= count <= longest or not near(length, count * unit):
            return None
        levels += [index % 2 == 0] * count
    return levels


# Manchester bits from levels, each the given number of halves wide, with a mark first meaning one when mark_first is set.
def manchester(levels, width, mark_first):
    bits = []
    for start in range(0, len(levels), 2 * width):
        first = levels[start:start + width]
        second = levels[start + width:start + 2 * width]
        if len(second) < width or len(set(first)) != 1 or len(set(second)) != 1 or first[0] == second[0]:
            return None
        bits.append(int(first[0] == mark_first))
    return bits


# NEC, NECx and Samsung frames: a header and 32 bits holding an address and a command with its inverse.
def decode_nec(durations):
    for protocol, header in (("NEC", (9000, 4500)), ("Samsung", (4500, 4500))):
        bits = pulse_distance(durations, header, 560, 560, 1690)
        if bits is None or len(bits) != 32:
            continue
        address, inverse_address, command, inverse_command = (lsb_first(bits[start:start + 8]) for start in range(0, 32, 8))
        if command ^ inverse_command != 0xFF:
            return {"protocol": protocol + "-raw", "data": lsb_first(bits)}
        if protocol == "NEC" and address ^ inverse_address != 0xFF:
            return {"protocol": "NECx", "address": lsb_first(bits[:16]), "command": command}
        return {"protocol": protocol, "address": address, "command": command}
    return None


# JVC frames: a header and 16 bits holding an address and a command.
def decode_jvc(durations):
    bits = pulse_distance(durations, (8400, 4200), 525, 525, 1575)
    if bits is None or len(bits) != 16:
        return None
    return {"protocol": "JVC", "address": lsb_first(bits[:8]), "command": lsb_first(bits[8:])}


# Kaseikyo frames, used by Panasonic and others: a header and 48 bits starting with a vendor id.
def decode_kaseikyo(durations):
    bits = pulse_distance(durations, (3456, 1728), 432, 432, 1296)
    if bits is None or len(bits) != 48:
        return None
    return {"protocol": "Kaseikyo", "vendor": lsb_first(bits[:16]), "data": [lsb_first(bits[start:start + 8]) for start in range(16, 48, 8)]}


# Sharp frames: no header and 15 bits holding an address, a command and two check bits.
def decode_sharp(durations):
    bits = pulse_distance([0, 0] + durations, (0, 0), 320, 680, 1680)
    if bits is None or len(bits) != 15:
        return None
    return {"protocol": "Sharp", "address": lsb_first(bits[:5]), "command": lsb_first(bits[5:13])}


# Sony SIRC frames: a header and 12, 15 or 20 pulse-width bits holding a command and an address.
def decode_sony(durations):
    bits = pulse_width(durations, (2400, 600), 600, 600, 1200)
    if bits is None or len(bits) not in (12, 15, 20):
        return None
    decoded = {"protocol": f"Sony{len(bits)}", "command": lsb_first(bits[:7])}
    if len(bits) == 20:
        return {**decoded, "address": lsb_first(bits[7:12]), "extended": lsb_first(bits[12:])}
    return {**decoded, "address": lsb_first(bits[7:])}


# Philips RC5 frames: 14 Manchester bits of 1778 us, whose leading space the receiver cannot see.
def decode_rc5(durations):
    levels = half_bits(durations[:-1], 889, 2)
    if levels is None:
        return None
    levels = [False] + levels
    levels += [False] * (28 - len(levels))
    bits = manchester(levels, 1, False) if len(levels) == 28 else None
    if bits is None or bits[0] != 1:
        return None
    return {"protocol": "RC5", "address": msb_first(bits[3:8]), "command": msb_first(bits[8:]) + (0 if bits[1] else 64), "toggle": bits[2]}


# Philips RC6 frames: a leader, a start bit, three mode bits, a double-width toggle bit and Manchester data bits of 889 us.
def decode_rc6(durations):
    if len(durations) < 4 or not (near(durations[0], 2666) and near(durations[1], 889)):
        return None
    levels = half_bits(durations[2:-1], 444, 3)
    if levels is None:
        return None
    for data_bits in (16, 20, 24, 32):
        total = 8 + 4 + 2 * data_bits
        if len(levels) > total:
            continue
        padded = levels + [False] * (total - len(levels))
        head = manchester(padded[:8], 1, True)
        toggle = manchester(padded[8:12], 2, True)
        data = manchester(padded[12:], 1, True)
        if head is None or toggle is None or data is None or head[0] != 1:
            return None
        mode = msb_first(head[1:])
        if data_bits == 16:
            return {"protocol": f"RC6-{mode}", "address": msb_first(data[:8]), "command": msb_first(data[8:]), "toggle": toggle[0]}
        return {"protocol": f"RC6-{mode}-{data_bits}", "data": msb_first(data), "toggle": toggle[0]}
    return None


# The protocol, address and command a code's frame carries, or None when it matches no protocol known here.
def decode(code):
    durations = code["durations"]
    if len(durations) < 4:
        return None
    for decoder in (decode_nec, decode_jvc, decode_kaseikyo, decode_sony, decode_rc6, decode_rc5, decode_sharp):
        decoded = decoder(durations)
        if decoded:
            return decoded
    return None


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
            result = {"code": code, "decoded": decode(code)}
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
