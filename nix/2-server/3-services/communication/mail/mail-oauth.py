# Mail OAuth #########################################################################################################################################
#
# Signs an Outlook.com account in once and then hands out fresh access tokens for IMAP. `init` walks through the browser sign-in and keeps the
# refresh token in a state file; `token` trades it for an access token written to a file, so no token ever reaches the terminal or a command line.
#

import argparse
import base64
import hashlib
import json
import os
import secrets
import sys
import urllib.error
import urllib.parse
import urllib.request

SIGN_IN_ENDPOINT = "https://login.microsoftonline.com/common/oauth2/v2.0/authorize"
EXCHANGE_ENDPOINT = "https://login.microsoftonline.com/common/oauth2/v2.0/token"
SCOPE = "https://outlook.office.com/IMAP.AccessAsUser.All offline_access"


# State File #########################################################################################################################################

def read_state(state_path):
    with open(state_path, encoding="utf-8") as state_file:
        return json.load(state_file)


def write_private_file(path, text):
    temporary_path = f"{path}.new"
    file_descriptor = os.open(temporary_path, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
    with os.fdopen(file_descriptor, "w", encoding="utf-8") as private_file:
        private_file.write(text)
    os.replace(temporary_path, path)


def write_state(state_path, state):
    write_private_file(state_path, json.dumps(state, indent=4) + "\n")


# Exchange Endpoint ##################################################################################################################################

def request_tokens(form_fields):
    request_body = urllib.parse.urlencode(form_fields).encode()
    try:
        with urllib.request.urlopen(urllib.request.Request(EXCHANGE_ENDPOINT, data=request_body), timeout=60) as response:
            return json.load(response)
    except urllib.error.HTTPError as error:
        details = json.load(error)
        first_line = details.get("error_description", "").splitlines()[:1]
        sys.exit(f"Microsoft refused the request: {details.get('error')}: {''.join(first_line)}")


# Sign In ############################################################################################################################################

def sign_in(arguments):
    code_verifier = secrets.token_urlsafe(64)
    code_challenge = base64.urlsafe_b64encode(hashlib.sha256(code_verifier.encode()).digest()).rstrip(b"=").decode()
    expected_state = secrets.token_urlsafe(16)

    sign_in_query = urllib.parse.urlencode({
        "client_id": arguments.client_id,
        "response_type": "code",
        "redirect_uri": arguments.redirect_uri,
        "response_mode": "query",
        "scope": SCOPE,
        "state": expected_state,
        "code_challenge": code_challenge,
        "code_challenge_method": "S256",
        "prompt": "select_account",
    })
    print(f"Open this address in a browser and sign in:\n\n{SIGN_IN_ENDPOINT}?{sign_in_query}\n", file=sys.stderr)
    print(f"The browser then lands on a page under {arguments.redirect_uri} that fails to load; paste that page's full address here.", file=sys.stderr)
    returned_address = input("Address: ").strip()

    returned_query = urllib.parse.parse_qs(urllib.parse.urlparse(returned_address).query)
    if returned_query.get("state") != [expected_state]:
        sys.exit("The pasted address does not belong to this sign-in; run init again.")
    if "code" not in returned_query:
        reason = returned_query.get("error_description", returned_query.get("error", ["no code returned"]))[0]
        sys.exit(f"The sign-in failed: {reason}")

    granted = request_tokens({
        "client_id": arguments.client_id,
        "grant_type": "authorization_code",
        "code": returned_query["code"][0],
        "redirect_uri": arguments.redirect_uri,
        "code_verifier": code_verifier,
        "scope": SCOPE,
    })
    write_state(arguments.state_file, {"client_id": arguments.client_id, "refresh_token": granted["refresh_token"]})
    print(f"Signed in; the sign-in is kept in {arguments.state_file}.", file=sys.stderr)


# Access Token #######################################################################################################################################

def refresh_access_token(arguments):
    if not os.path.exists(arguments.state_file):
        sys.exit(f"{arguments.state_file} is missing; sign in first with `mail-oauth init`.")

    state = read_state(arguments.state_file)
    granted = request_tokens({
        "client_id": state["client_id"],
        "grant_type": "refresh_token",
        "refresh_token": state["refresh_token"],
        "scope": SCOPE,
    })

    # Microsoft replaces the refresh token as it is used, so the new one is kept for the next run
    if granted.get("refresh_token"):
        state["refresh_token"] = granted["refresh_token"]
        write_state(arguments.state_file, state)
    write_private_file(arguments.output, granted["access_token"] + "\n")


# Command Line #######################################################################################################################################

def main():
    parser = argparse.ArgumentParser(description="Sign an Outlook.com account in for IMAP and hand out access tokens.")
    commands = parser.add_subparsers(dest="command", required=True)

    init_command = commands.add_parser("init", help="sign in through a browser and keep the refresh token")
    init_command.add_argument("state_file")
    init_command.add_argument("--client-id", required=True)
    init_command.add_argument("--redirect-uri", default="http://localhost")
    init_command.set_defaults(run=sign_in)

    access_command = commands.add_parser("token", help="write a fresh access token to a file")
    access_command.add_argument("state_file")
    access_command.add_argument("--output", required=True)
    access_command.set_defaults(run=refresh_access_token)

    arguments = parser.parse_args()
    arguments.run(arguments)


if __name__ == "__main__":
    main()
