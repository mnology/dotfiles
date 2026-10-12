#!/usr/bin/env python3
"""Append the path of a file the agent changed to a review queue.

A Kiro PostFileSave / PostFileCreate hook runs this and pipes the event JSON on
stdin. The editor opens the queue with :KiroChanged, then clears it. The stdin
field name is not documented offline, so search common keys and recurse.

Queue: $XDG_CACHE_HOME/kiro/changed-files, else ~/.cache/kiro/changed-files.
Exit 0 always: a hook must not block the agent on a parse miss.
"""

import json
import os
import sys

# Keys a Kiro event may use for the changed file path. Order is the search
# priority; the first string value wins.
PATH_KEYS = ("filePath", "path", "file_path", "file")


def find_path(obj):
    if not isinstance(obj, dict):
        return None
    for key in PATH_KEYS:
        value = obj.get(key)
        if isinstance(value, str) and value:
            return value
    for value in obj.values():
        found = find_path(value)
        if found:
            return found
    return None


def queue_file():
    cache = os.environ.get("XDG_CACHE_HOME") or os.path.expanduser("~/.cache")
    return os.path.join(cache, "kiro", "changed-files")


def main():
    try:
        event = json.load(sys.stdin)
    except (json.JSONDecodeError, ValueError):
        return 0
    path = find_path(event)
    if not path:
        return 0
    queue = queue_file()
    os.makedirs(os.path.dirname(queue), exist_ok=True)
    with open(queue, "a", encoding="utf-8") as handle:
        handle.write(path + "\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
