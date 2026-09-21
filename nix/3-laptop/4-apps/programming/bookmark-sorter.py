# Bookmark Sorter
#
# Sorts Firefox's unfiled bookmarks into folders a local LLM proposes.
# "plan" writes a plan to review and edit; "apply" carries it out.
#
import argparse
import json
import os
import random
import shutil
import sqlite3
import subprocess
import sys
import time
import urllib.error
import urllib.request

UNFILED_PARENT = 5
GUID_ALPHABET = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"


# Model ##############################################################################################################################################


class Truncated(Exception):
    """Raised when the model used its whole budget without finishing the answer."""


def ask(endpoint, model, prompt, schema, timeout, budget):
    """Sends one prompt to the LM Studio server and returns the parsed JSON reply."""
    body = {
        "model": model,
        "messages": [{"role": "user", "content": prompt}],
        "temperature": 0.2,
        "max_tokens": budget,
        "response_format": {
            "type": "json_schema",
            "json_schema": {"name": "reply", "strict": True, "schema": schema},
        },
    }
    request = urllib.request.Request(
        endpoint.rstrip("/") + "/v1/chat/completions",
        json.dumps(body).encode(),
        {"Content-Type": "application/json"},
    )
    try:
        with urllib.request.urlopen(request, timeout=timeout) as reply:
            choice = json.load(reply)["choices"][0]
    except urllib.error.URLError as error:
        sys.exit(f"cannot reach the model at {endpoint}: {error}\nIs LM Studio's server running? (lms server start)")
    # These models reason before answering and the JSON grammar does not constrain that, so a budget is the only stop.
    if choice["finish_reason"] == "length":
        raise Truncated(f"spent all {budget} tokens before answering")
    try:
        return json.loads(choice["message"]["content"])
    except (json.JSONDecodeError, TypeError):
        raise Truncated("did not return usable JSON")


def propose_folders(args, bookmarks):
    """Asks the model for a folder scheme covering the whole collection."""
    listing = "\n".join(f"- {b['title'][:110]}" for b in bookmarks)
    prompt = (
        f"Below are {len(bookmarks)} browser bookmarks. Propose between {args.min_folders} and {args.max_folders} "
        "folder names to file them under. Folders should be about subject matter, roughly balanced in size, and "
        "named in two words or fewer. Do not include a catch-all folder; one is added separately.\n\n" + listing
    )
    # Bounded both ways: an unbounded array lets the model keep emitting until it fills the context.
    schema = {
        "type": "object",
        "properties": {
            "folders": {
                "type": "array",
                "items": {"type": "string"},
                "minItems": args.min_folders,
                "maxItems": args.max_folders,
            }
        },
        "required": ["folders"],
    }
    try:
        reply = ask(args.endpoint, args.model, prompt, schema, args.timeout, args.reason_budget)
    except Truncated as error:
        sys.exit(f"the model {error} while proposing folders.\nRaise --reason-budget, or name the folders with --folder.")
    folders = [f.strip() for f in reply["folders"] if f.strip()]
    return list(dict.fromkeys(folders))


def assign_batch(args, batch, choices):
    """Files one batch, halving it and retrying if the model runs out of budget."""
    listing = "\n".join(f"{i}. {b['title'][:110]}  <{b['host']}>" for i, b in enumerate(batch))
    prompt = (
        "File each bookmark under exactly one of these folders:\n"
        + "\n".join(f"- {f}" for f in choices)
        + f"\n\nUse {args.fallback} only when nothing else fits. Answer with exactly {len(batch)} folder"
        " names, one per bookmark, in the same order as the list.\n\n"
        + listing
    )
    # One name per bookmark in order, fixed length: asking for numbered objects instead let the model
    # run past the batch and generate until it filled the context.
    schema = {
        "type": "object",
        "properties": {
            "folders": {
                "type": "array",
                "items": {"type": "string", "enum": choices},
                "minItems": len(batch),
                "maxItems": len(batch),
            }
        },
        "required": ["folders"],
    }
    # Reasoning grows with the batch, so a batch that overruns its budget is split rather than abandoned.
    budget = args.per_bookmark * len(batch) + args.answer_budget
    try:
        reply = ask(args.endpoint, args.model, prompt, schema, args.timeout, budget)
    except Truncated as error:
        if len(batch) == 1:
            print(f"  '{batch[0]['title'][:60]}' {error}; leaving it in {args.fallback}", file=sys.stderr)
            return {batch[0]["id"]: args.fallback}
        half = len(batch) // 2
        print(f"  batch of {len(batch)} {error}; splitting", file=sys.stderr)
        filed = assign_batch(args, batch[:half], choices)
        filed.update(assign_batch(args, batch[half:], choices))
        return filed
    return {batch[index]["id"]: folder for index, folder in enumerate(reply["folders"][:len(batch)])}


def assign(args, bookmarks, folders):
    """Files every bookmark under one of the folders, a batch at a time."""
    choices = folders + [args.fallback]
    assignments = {}
    for start in range(0, len(bookmarks), args.batch):
        assignments.update(assign_batch(args, bookmarks[start:start + args.batch], choices))
        done = min(start + args.batch, len(bookmarks))
        print(f"  filed {done}/{len(bookmarks)}", file=sys.stderr)
    return assignments


# Database ###########################################################################################################################################


def read_unfiled(path):
    """Reads the bookmarks sitting loose in Firefox's unfiled root."""
    connection = sqlite3.connect(f"file:{path}?immutable=1", uri=True)
    rows = connection.execute(
        "select b.id, b.title, p.url from moz_bookmarks b join moz_places p on p.id = b.fk"
        " where b.type = 1 and b.parent = ? order by b.position",
        (UNFILED_PARENT,),
    ).fetchall()
    connection.close()
    bookmarks = []
    for identifier, title, url in rows:
        host = url.split("/")[2] if "://" in url else url[:40]
        bookmarks.append({"id": identifier, "title": title or url, "url": url, "host": host})
    return bookmarks


def new_guid():
    """Makes a bookmark guid in the 12-character form Firefox uses."""
    return "".join(random.choice(GUID_ALPHABET) for _ in range(12))


def firefox_is_running():
    """Reports whether a Firefox process is holding the profile open."""
    return subprocess.run(["pgrep", "-x", "firefox"], capture_output=True).returncode == 0


def apply_plan(path, plan, backup_dir):
    """Creates the planned folders and moves each bookmark into its own."""
    stamp = time.strftime("%Y%m%dT%H%M%S")
    os.makedirs(backup_dir, exist_ok=True)
    backup = os.path.join(backup_dir, f"places.sqlite.{stamp}")
    shutil.copy2(path, backup)
    print(f"backed up the profile to {backup}")

    now = int(time.time() * 1_000_000)
    wanted = sorted({a["folder"] for a in plan["assignments"]})
    connection = sqlite3.connect(path)
    try:
        existing = {
            title: identifier
            for identifier, title in connection.execute(
                "select id, title from moz_bookmarks where type = 2 and parent = ?", (UNFILED_PARENT,)
            )
        }
        position = connection.execute(
            "select coalesce(max(position), -1) + 1 from moz_bookmarks where parent = ?", (UNFILED_PARENT,)
        ).fetchone()[0]

        folders = {}
        for title in wanted:
            if title in existing:
                folders[title] = existing[title]
                continue
            cursor = connection.execute(
                "insert into moz_bookmarks (type, fk, parent, position, title, dateAdded, lastModified, guid,"
                " syncStatus, syncChangeCounter) values (2, NULL, ?, ?, ?, ?, ?, ?, 2, 1)",
                (UNFILED_PARENT, position, title, now, now, new_guid()),
            )
            folders[title] = cursor.lastrowid
            position += 1

        moved = 0
        for folder_title in wanted:
            folder_id = folders[folder_title]
            slot = connection.execute(
                "select coalesce(max(position), -1) + 1 from moz_bookmarks where parent = ?", (folder_id,)
            ).fetchone()[0]
            for entry in plan["assignments"]:
                if entry["folder"] != folder_title:
                    continue
                changed = connection.execute(
                    "update moz_bookmarks set parent = ?, position = ?, lastModified = ?,"
                    " syncChangeCounter = syncChangeCounter + 1 where id = ? and parent = ? and type = 1",
                    (folder_id, slot, now, entry["id"], UNFILED_PARENT),
                ).rowcount
                if changed:
                    slot += 1
                    moved += 1
        connection.commit()
    finally:
        connection.close()
    print(f"filed {moved} bookmarks into {len(wanted)} folders")
    print("Firefox reads the database at startup, so start it again to see them.")


# Commands ###########################################################################################################################################


def do_plan(args):
    """Writes a plan pairing every unfiled bookmark with a proposed folder."""
    bookmarks = read_unfiled(args.profile)
    if not bookmarks:
        sys.exit("no unfiled bookmarks to sort")
    print(f"read {len(bookmarks)} unfiled bookmarks", file=sys.stderr)

    folders = args.folder or propose_folders(args, bookmarks)
    print("proposed folders: " + ", ".join(folders), file=sys.stderr)

    assignments = assign(args, bookmarks, folders)
    plan = {
        "profile": args.profile,
        "model": args.model,
        "folders": folders + [args.fallback],
        "assignments": [
            {
                "id": b["id"],
                "title": b["title"],
                "url": b["url"],
                "folder": assignments.get(b["id"], args.fallback),
            }
            for b in bookmarks
        ],
    }
    with open(args.plan, "w") as handle:
        json.dump(plan, handle, indent=2, ensure_ascii=False)
    counts = {}
    for entry in plan["assignments"]:
        counts[entry["folder"]] = counts.get(entry["folder"], 0) + 1
    print(f"\nwrote {args.plan}\n")
    for title, count in sorted(counts.items(), key=lambda kv: -kv[1]):
        print(f"  {count:4d}  {title}")
    print("\nEdit that file to taste, then run: bookmark-sorter apply")


def do_apply(args):
    """Carries out a reviewed plan against the live profile."""
    with open(args.plan) as handle:
        plan = json.load(handle)
    if firefox_is_running():
        sys.exit("Firefox is running; close it first or it will overwrite these changes on exit")
    apply_plan(plan.get("profile", args.profile), plan, args.backup_dir)


def main():
    """Parses the arguments and runs the requested command."""
    home = os.path.expanduser("~")
    # Shared as a parent so the options read the same before or after the subcommand; on the main parser alone,
    # "bookmark-sorter plan --batch 6" hands --batch to the subparser, which has never heard of it.
    common = argparse.ArgumentParser(add_help=False)
    common.add_argument("--profile", default=f"{home}/.config/mozilla/firefox/Personal/places.sqlite")
    common.add_argument("--plan", default=f"{home}/bookmark-plan.json")
    common.add_argument("--backup-dir", default=f"{home}/.local/state/bookmark-sorter")
    common.add_argument("--endpoint", default="http://127.0.0.1:1234")
    common.add_argument("--model", default="gemma-4-26b-a4b-it-qat")
    common.add_argument("--folder", action="append", help="use these folders instead of asking the model")
    common.add_argument("--fallback", default="Misc")
    common.add_argument("--min-folders", type=int, default=8)
    common.add_argument("--max-folders", type=int, default=16)
    common.add_argument("--batch", type=int, default=6)
    common.add_argument("--per-bookmark", type=int, default=450, help="token budget per bookmark, mostly its reasoning")
    common.add_argument("--answer-budget", type=int, default=500)
    common.add_argument("--reason-budget", type=int, default=6000, help="token budget for the folder proposal")
    common.add_argument("--timeout", type=int, default=1800)

    parser = argparse.ArgumentParser(prog="bookmark-sorter", description=__doc__, parents=[common])
    commands = parser.add_subparsers(dest="command", required=True)
    commands.add_parser("plan", parents=[common], help="propose folders and write a plan to review")
    commands.add_parser("apply", parents=[common], help="carry out a reviewed plan")

    args = parser.parse_args()
    if not os.path.exists(args.profile):
        sys.exit(f"no Firefox profile database at {args.profile}")
    (do_plan if args.command == "plan" else do_apply)(args)


if __name__ == "__main__":
    main()
