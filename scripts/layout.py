#!/usr/bin/env python3
"""Validate the tested vendor partition layout and emit a compact GPT script."""
import json
import sys

STARTS = [16384, 24576, 32768, 40960, 49152, 81920, 163840, 262144, 4718592]
SIZES = [8192, 8192, 8192, 8192, 32768, 81920, 98304, 4456448]
NAMES = ["uboot", "trust", "misc", "dtbo", "resource", "kernel", "boot", "rootfs", "userdata"]
SECTORS = 5242880

def compact(table):
    t = table["partitiontable"]
    ps = t["partitions"]
    if t["label"] != "gpt" or t.get("sectorsize") != 512 or len(ps) != 9:
        raise ValueError("Requires the tested 512-byte-sector, nine-partition vendor GPT")
    for i, part in enumerate(ps):
        if part["start"] != STARTS[i] or part.get("name") != NAMES[i]:
            raise ValueError(f"Unexpected partition {i + 1}: start/name")
        if i < 8 and part["size"] != SIZES[i]:
            raise ValueError(f"Unexpected partition {i + 1}: size")
    if ps[8]["size"] < SECTORS - 33 - STARTS[8]:
        raise ValueError("userdata is smaller than the output layout")
    lines = ["label: gpt", "label-id: " + t["id"], "unit: sectors", "first-lba: 34",
             f"last-lba: {SECTORS - 34}", "sector-size: 512", ""]
    for i, part in enumerate(ps):
        size = SIZES[i] if i < 8 else SECTORS - 33 - STARTS[i]
        lines.append(f'start={STARTS[i]}, size={size}, type={part["type"]}, uuid={part["uuid"]}, name="{NAMES[i]}"')
    return "\n".join(lines) + "\n"

if __name__ == "__main__":
    try:
        print(compact(json.load(sys.stdin)), end="")
    except (KeyError, ValueError, TypeError) as exc:
        sys.exit(f"Unsupported layout: {exc}")
