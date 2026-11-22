# IR Blaster #########################################################################################################################################
#
# An HTTP API that stores infrared codes and sends them through a CH340 USB-serial board with an IR emitter on TX.
# A code is a carrier frequency and alternating mark and space lengths in microseconds, starting with a mark and ending with the gap after the last one.
#

import argparse
import json
import os
import threading
import time
import urllib.parse
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

import serial

CLOCK = 12_000_000
PRONTO_UNIT = 0.241246
DEFAULT_CARRIER = 38_000
MARK_PATTERNS = [bytes([0xFF, 0xFF, 0x00, 0x00]), bytes([0xFF, 0x00])]
SEND_PADDING_SECONDS = 0.02
FALLBACK_GAP = 20_000
FRAME_GAP = 40_000


# Codes ##############################################################################################################################################

# Carrier and durations from a raw Pronto hex code, with its repeat part sent once after the rest.
def from_pronto(text):
    words = [int(word, 16) for word in text.split()]
    if len(words) < 4 or words[0] != 0:
        raise ValueError("only raw Pronto codes, starting with 0000, are supported")
    unit = words[1] * PRONTO_UNIT
    counts = words[4:]
    if len(counts) != 2 * (words[2] + words[3]):
        raise ValueError("the Pronto code's length does not match its header")
    return {"carrier": round(1e6 / unit), "durations": [round(count * unit) for count in counts], "repeat": 1}


# A raw Pronto hex code for a stored code, with every pair in the once-only part.
def to_pronto(code):
    frequency_word = round(1e6 / (code["carrier"] * PRONTO_UNIT))
    unit = frequency_word * PRONTO_UNIT
    durations = code["durations"]
    words = [0, frequency_word, len(durations) // 2, 0] + [max(1, round(duration / unit)) for duration in durations]
    return " ".join(f"{word:04X}" for word in words)


# A stored code from an API body holding a protocol and its fields, a Pronto string, or a carrier and durations.
def code_from_body(body):
    if "protocol" in body:
        code = encode(body)
    elif "pronto" in body:
        code = from_pronto(body["pronto"])
    else:
        durations = [round(float(duration)) for duration in body["durations"]]
        if not durations or min(durations) <= 0:
            raise ValueError("durations must be positive microseconds")
        if len(durations) % 2:
            durations.append(FALLBACK_GAP)
        code = {"carrier": round(float(body.get("carrier", DEFAULT_CARRIER))), "durations": durations}
    code["repeat"] = int(body.get("repeat", code.get("repeat", 1)))
    if not 20_000 <= code["carrier"] <= 100_000 or code["repeat"] < 1:
        raise ValueError("carrier must be 20-100 kHz and repeat at least 1")
    return code


# Protocols ##########################################################################################################################################

# The bits of a value, least significant first.
def bits_lsb(value, count):
    return [(value >> index) & 1 for index in range(count)]


# The bits of a value, most significant first.
def bits_msb(value, count):
    return bits_lsb(value, count)[::-1]


# A whole number field from an API body, checked to fit in a number of bits.
def field(body, name, bits):
    value = int(body.get(name, 0))
    if not 0 <= value < 1 << bits:
        raise ValueError(f"{name} must fit in {bits} bits")
    return value


# A frame of a header, a fixed mark and two space lengths for zero and one, ending with a stop mark and the gap.
def pulse_distance_frame(header, mark, zero, one, bits):
    durations = list(header)
    for bit in bits:
        durations += [mark, one if bit else zero]
    return durations + [mark, FRAME_GAP]


# A frame of a header and marks of two lengths for zero and one, each followed by a fixed space, with the last space stretched to the gap.
def pulse_width_frame(header, space, zero, one, bits):
    durations = list(header)
    for bit in bits:
        durations += [one if bit else zero, space]
    durations[-1] = FRAME_GAP
    return durations


# Alternating mark and space lengths from carrier levels of one unit each, starting at the first mark and ending with the gap.
def level_runs(levels, unit):
    if not levels[0]:
        levels = levels[1:]
    durations = []
    previous = None
    for level in levels:
        if level == previous:
            durations[-1] += unit
        else:
            durations.append(unit)
            previous = level
    if len(durations) % 2:
        durations.append(FRAME_GAP)
    else:
        durations[-1] += FRAME_GAP
    return durations


# Carrier levels for Manchester bits, each a number of units wide, with a mark first meaning one when mark_first is set.
def manchester_levels(bits, width, mark_first):
    levels = []
    for bit in bits:
        first = bool(bit) == mark_first
        levels += [first] * width + [not first] * width
    return levels


# A code from NEC, NECx or Samsung fields, with the address and command followed by their inverses where the protocol sends them.
def encode_nec(body, protocol):
    header = (9000, 4500) if protocol.startswith("NEC") else (4500, 4500)
    if protocol.endswith("-raw"):
        bits = bits_lsb(field(body, "data", 32), 32)
    else:
        command = field(body, "command", 8)
        if protocol == "NECx":
            address_bits = bits_lsb(field(body, "address", 16), 16)
        else:
            address = field(body, "address", 8)
            address_bits = bits_lsb(address, 8) + bits_lsb(address if protocol == "Samsung" else address ^ 0xFF, 8)
        bits = address_bits + bits_lsb(command, 8) + bits_lsb(command ^ 0xFF, 8)
    return {"carrier": 38_000, "durations": pulse_distance_frame(header, 560, 560, 1690, bits)}


# A code for a protocol and its fields, such as NEC with an address and a command, or Sony12 and RC5, using the same names ir-learn reports.
def encode(body):
    protocol = str(body["protocol"])
    if protocol in ("NEC", "NECx", "Samsung", "NEC-raw", "Samsung-raw"):
        return encode_nec(body, protocol)
    if protocol == "JVC":
        bits = bits_lsb(field(body, "address", 8), 8) + bits_lsb(field(body, "command", 8), 8)
        return {"carrier": 38_000, "durations": pulse_distance_frame((8400, 4200), 525, 525, 1575, bits)}
    if protocol == "Kaseikyo":
        data = body.get("data", [0, 0, 0, 0])
        if len(data) != 4 or any(not 0 <= byte < 256 for byte in data):
            raise ValueError("data must be four bytes")
        bits = bits_lsb(field(body, "vendor", 16), 16) + [bit for byte in data for bit in bits_lsb(byte, 8)]
        return {"carrier": 37_000, "durations": pulse_distance_frame((3456, 1728), 432, 432, 1296, bits)}
    if protocol == "Sharp":
        bits = bits_lsb(field(body, "address", 5), 5) + bits_lsb(field(body, "command", 8), 8) + [1, 0]
        return {"carrier": 38_000, "durations": pulse_distance_frame((), 320, 680, 1680, bits)}
    if protocol in ("Sony12", "Sony15", "Sony20"):
        address_bits = 8 if protocol == "Sony15" else 5
        bits = bits_lsb(field(body, "command", 7), 7) + bits_lsb(field(body, "address", address_bits), address_bits)
        if protocol == "Sony20":
            bits += bits_lsb(field(body, "extended", 8), 8)
        return {"carrier": 40_000, "durations": pulse_width_frame((2400, 600), 600, 600, 1200, bits), "repeat": 3}
    if protocol == "RC5":
        command = field(body, "command", 7)
        bits = [1, int(command < 64), field(body, "toggle", 1)] + bits_msb(field(body, "address", 5), 5) + bits_msb(command & 63, 6)
        return {"carrier": 36_000, "durations": level_runs(manchester_levels(bits, 1, False), 889)}
    if protocol.startswith("RC6-"):
        parts = protocol.split("-")
        if not all(part.isdigit() for part in parts[1:]) or len(parts) > 3:
            raise ValueError(f"unknown protocol {protocol}")
        mode = int(parts[1])
        data_bits = int(parts[2]) if len(parts) == 3 else 16
        if mode > 7 or data_bits not in (16, 20, 24, 32):
            raise ValueError(f"unknown protocol {protocol}")
        if len(parts) == 3:
            data = bits_msb(field(body, "data", data_bits), data_bits)
        else:
            data = bits_msb(field(body, "address", 8), 8) + bits_msb(field(body, "command", 8), 8)
        levels = manchester_levels([1] + bits_msb(mode, 3), 1, True)
        levels += manchester_levels([field(body, "toggle", 1)], 2, True) + manchester_levels(data, 1, True)
        return {"carrier": 36_000, "durations": [2666, 889] + level_runs(levels, 444)}
    raise ValueError(f"unknown protocol {protocol}")


# Transmitting #######################################################################################################################################

# Bit times the CH340 spends sending one byte at a baud.
def frame_bits(baud):
    return 11 if baud >= 600_000 else 10  # Fast bauds get an extra idle bit per byte; without it the carrier comes out 10% low


# The baud and repeating mark bytes for a carrier, with four bytes per cycle when that comes within 3% so the dark fill flickers far above it.
def carrier_settings(carrier):
    options = []
    for pattern in MARK_PATTERNS:
        for divisor in range(6, 21):
            baud = round(CLOCK / divisor)
            options.append((abs(baud / (len(pattern) * frame_bits(baud)) - carrier) / carrier, baud, pattern))
    four_bytes = min(option for option in options if len(option[2]) == 4)
    return four_bytes[1:] if four_bytes[0] <= 0.03 else min(options)[1:]


# The baud to send a code at and the bytes that drive the emitter through it.
def transmit_bytes(code, space_byte):
    baud, pattern = carrier_settings(code["carrier"])
    byte_microseconds = frame_bits(baud) * 1e6 / baud
    stream = bytearray()
    elapsed = 0
    for index, duration in enumerate(code["durations"]):
        elapsed += duration
        missing = round(elapsed / byte_microseconds) - len(stream)
        if index % 2 == 0:
            stream += pattern * max(1, round(missing / len(pattern)))
        else:
            stream += bytes([space_byte]) * max(0, missing)
    stream += bytes([space_byte]) * round(SEND_PADDING_SECONDS * 1e6 / byte_microseconds)
    return baud, bytes(stream)


# Device #############################################################################################################################################

class Blaster:

    # The board at a device path, its code file, and which byte keeps an emitter of its polarity dark.
    def __init__(self, device, codes_path, space_byte):
        self.device = device
        self.codes_path = codes_path
        self.space_byte = space_byte
        self.port = None
        self.port_lock = threading.Lock()
        self.codes_lock = threading.Lock()

    # Every stored code by name.
    def codes(self):
        with self.codes_lock:
            try:
                with open(self.codes_path) as codes_file:
                    return json.load(codes_file)
            except FileNotFoundError:
                return {}

    # Stores a code under a name, or removes the name when the code is None.
    def store(self, name, code):
        with self.codes_lock:
            try:
                with open(self.codes_path) as codes_file:
                    codes = json.load(codes_file)
            except FileNotFoundError:
                codes = {}
            if code is None:
                del codes[name]
            else:
                codes[name] = code
            temporary_path = self.codes_path + ".new"
            with open(temporary_path, "w") as codes_file:
                json.dump(codes, codes_file, indent=4, sort_keys=True)
            os.replace(temporary_path, self.codes_path)

    # Sends a code, repeated as many times as asked, and leaves the emitter dark afterwards.
    def send(self, code, repeat):
        baud, stream = transmit_bytes(code, self.space_byte)
        seconds = len(stream) * frame_bits(baud) / baud
        with self.port_lock:
            try:
                if self.port is None:
                    self.port = serial.Serial(self.device, baud)
                self.port.baudrate = baud
                self.port.break_condition = False
                for _ in range(repeat):
                    started = time.monotonic()
                    self.port.write(stream)
                    self.port.flush()
                    time.sleep(max(0, started + seconds - time.monotonic()))
                self.port.break_condition = self.space_byte == 0x00
            except serial.SerialException:
                self.port = None
                raise
        return {"baud": baud, "bytes": len(stream), "repeat": repeat}


# API ################################################################################################################################################

class Handler(BaseHTTPRequestHandler):
    blaster = None

    # Answers with a status and a JSON body.
    def reply(self, status, body):
        payload = json.dumps(body, indent=4).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        self.wfile.write(payload)

    # The request's JSON body, or an empty object.
    def body(self):
        length = int(self.headers.get("Content-Length") or 0)
        return json.loads(self.rfile.read(length)) if length else {}

    # Runs one request and maps failures to HTTP errors.
    def handle_method(self, method):
        parts = [urllib.parse.unquote(part) for part in urllib.parse.urlparse(self.path).path.split("/") if part]
        try:
            self.reply(200, self.dispatch(method, parts))
        except LookupError as error:
            self.reply(404, {"error": str(error)})
        except (ValueError, TypeError) as error:
            self.reply(400, {"error": str(error)})
        except serial.SerialException as error:
            self.reply(503, {"error": str(error)})

    # The response body for a method and path.
    def dispatch(self, method, parts):
        blaster = self.blaster
        if method == "GET" and parts == ["codes"]:
            return {name: {**code, "pronto": to_pronto(code)} for name, code in blaster.codes().items()}
        if method == "POST" and parts == ["send"]:
            code = code_from_body(self.body())
            return blaster.send(code, code["repeat"])
        if len(parts) not in (2, 3) or parts[0] != "codes":
            raise LookupError("no such endpoint")
        name = parts[1]
        action = parts[2] if len(parts) == 3 else None
        if method == "PUT" and action is None:
            code = code_from_body(self.body())
            blaster.store(name, code)
            return {name: code}
        codes = blaster.codes()
        if name not in codes:
            raise LookupError(f"no code named {name}")
        if method == "GET" and action is None:
            return {name: {**codes[name], "pronto": to_pronto(codes[name])}}
        if method == "DELETE" and action is None:
            blaster.store(name, None)
            return {"deleted": name}
        if method == "POST" and action == "send":
            return blaster.send(codes[name], int(self.body().get("repeat", codes[name].get("repeat", 1))))
        raise LookupError("no such endpoint")

    def do_GET(self):
        self.handle_method("GET")

    def do_PUT(self):
        self.handle_method("PUT")

    def do_POST(self):
        self.handle_method("POST")

    def do_DELETE(self):
        self.handle_method("DELETE")


# Serves the API until stopped.
def main():
    parser = argparse.ArgumentParser(description="Store infrared codes and send them through a CH340 USB-serial board.")
    parser.add_argument("--device", required=True)
    parser.add_argument("--codes", required=True)
    parser.add_argument("--listen", default="0.0.0.0")
    parser.add_argument("--port", type=int, default=9620)
    parser.add_argument("--emitter-active-low", action="store_true")
    arguments = parser.parse_args()
    Handler.blaster = Blaster(arguments.device, arguments.codes, 0xFF if arguments.emitter_active_low else 0x00)
    ThreadingHTTPServer((arguments.listen, arguments.port), Handler).serve_forever()


if __name__ == "__main__":
    main()
