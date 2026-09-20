#!/usr/bin/env python3
"""Build diagnostic variant 2 with only the original i3rby libloader.

Removes the target's iGameGod load command and framework, replaces its old
libloader with the unmodified extracted i3rby framework, and preserves game
code. The output needs re-signing. This is an unverified diagnostic build.
"""
import argparse
import copy
import hashlib
import json
from pathlib import Path
import plistlib
import struct
import tempfile
import zipfile

from extract_tweak import read_macho

TARGET_SHA256 = "27500e6357fc4b215f70f7df1379b29bd921fc2b6cb62d0b6c56302e260ee698"
TWEAK_SHA256 = "d44ed5b80ff3418d0ac07829833b95a060da9cf89a0d3d6d9fd2094d70b6dbeb"
MAIN = "Payload/pool.app/pool"
LOADER = "Payload/pool.app/Frameworks/libloader.framework/"
IGG = "Payload/pool.app/Frameworks/iGameGod.framework/"


def digest(data):
    return hashlib.sha256(data).hexdigest()


def file_digest(path):
    h = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def remove_igamegod_command(binary):
    before = read_macho(binary)
    if before["filetype"] != 2 or any(x["cryptid"] for x in before["encryption"]):
        raise ValueError("Expected unencrypted ARM64 application")
    count, size = struct.unpack_from("<II", binary, 16)
    commands, removed = [], []
    cursor = 32
    for _ in range(count):
        command, length = struct.unpack_from("<II", binary, cursor)
        if length < 8 or cursor + length > 32 + size:
            raise ValueError("Invalid load command")
        raw = binary[cursor:cursor + length]
        name = None
        if command in (0xc, 0x80000018):
            start = struct.unpack_from("<I", raw, 8)[0]
            name = raw[start:].split(b"\0", 1)[0].decode()
        if name == "@rpath/iGameGod.framework/iGameGod":
            removed.append({"offset": cursor, "bytes": length, "name": name})
        else:
            commands.append(raw)
        cursor += length
    if len(removed) != 1 or cursor != 32 + size:
        raise ValueError("Expected exactly one iGameGod load command")
    table = b"".join(commands)
    output = bytearray(binary)
    output[32:32 + size] = table.ljust(size, b"\0")
    struct.pack_into("<II", output, 16, len(commands), len(table))
    output = bytes(output)
    if output[:16] != binary[:16] or output[24:32] != binary[24:32] or output[32 + size:] != binary[32 + size:]:
        raise ValueError("Unexpected change outside the load-command table")
    after = read_macho(output)
    expected = [x for x in before["dependencies"] if "iGameGod.framework/iGameGod" not in x["name"]]
    if after["dependencies"] != expected or before["sections"] != after["sections"] or before["segments"] != after["segments"]:
        raise ValueError("Load commands or game layout changed unexpectedly")
    return output, removed


def build(target, framework, output, report_path):
    if output.exists() or report_path.exists():
        raise ValueError("Output paths already exist")
    if file_digest(target) != TARGET_SHA256:
        raise ValueError("Use the original, analyzed iOSGods target IPA")
    tweak = (framework / "libloader").read_bytes()
    if digest(tweak) != TWEAK_SHA256:
        raise ValueError("Unexpected i3rby source binary")
    plist = (framework / "Info.plist").read_bytes()
    if plistlib.loads(plist)["CFBundleExecutable"] != "libloader":
        raise ValueError("Unexpected framework metadata")
    additions = {LOADER + "libloader": tweak, LOADER + "Info.plist": plist}
    output.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(target) as source:
        names = source.namelist()
        if len(names) != len(set(names)):
            raise ValueError("Duplicate ZIP entries")
        patched, removed = remove_igamegod_command(source.read(MAIN))
        retained, removed_files = {}, []
        with tempfile.TemporaryDirectory(prefix="isolated-ipa-", dir=output.parent) as temporary:
            candidate = Path(temporary) / "candidate.ipa"
            with zipfile.ZipFile(candidate, "w", compression=zipfile.ZIP_DEFLATED,
                                 compresslevel=6, allowZip64=True) as destination:
                destination.comment = source.comment
                for entry in source.infolist():
                    if entry.filename.startswith((IGG, LOADER)):
                        removed_files.append(entry.filename)
                        continue
                    data = source.read(entry)
                    if entry.filename == MAIN:
                        data = patched
                    retained[entry.filename] = digest(data)
                    destination.writestr(copy.copy(entry), data)
                for name, data in additions.items():
                    item = zipfile.ZipInfo(name, date_time=(2026, 9, 20, 0, 0, 0))
                    item.create_system = 3
                    item.external_attr = (0o100755 if name.endswith("/libloader") else 0o100644) << 16
                    item.compress_type = zipfile.ZIP_DEFLATED
                    destination.writestr(item, data)
            with zipfile.ZipFile(candidate) as check:
                if set(check.namelist()) != set(retained) | set(additions):
                    raise ValueError("Unexpected output members")
                for name, expected in retained.items():
                    if digest(check.read(name)) != expected:
                        raise ValueError("Retained file mismatch: " + name)
                for name, expected in additions.items():
                    if check.read(name) != expected:
                        raise ValueError("Original i3rby file mismatch: " + name)
                analysis = read_macho(check.read(MAIN))
                if any("iGameGod" in x["name"] or "i3rby.framework" in x["name"] for x in analysis["dependencies"]):
                    raise ValueError("Unexpected additional tweak dependency")
                if sum(x["name"] == "@executable_path/Frameworks/libloader.framework/libloader" for x in analysis["dependencies"]) != 1:
                    raise ValueError("Missing or duplicate original i3rby load path")
            candidate.rename(output)
    report = {
        "variant": "isolated-i3rby-test-2", "purpose": "Diagnose the reported crash of the combined variant",
        "cause_confirmed": False, "crash_log_available": False, "runtime_test_performed": False,
        "input_ipa": target.name, "input_sha256": TARGET_SHA256,
        "output_ipa": output.name, "output_sha256": file_digest(output),
        "output_size_bytes": output.stat().st_size,
        "original_i3rby_binary_sha256": digest(tweak), "i3rby_binary_unchanged": True,
        "original_install_name": read_macho(tweak)["install_name"],
        "removed_load_commands": removed, "removed_or_replaced_members": removed_files,
        "new_framework_files": list(additions), "preserved_member_count": len(retained),
        "game_code_and_section_layout_unchanged": True, "all_output_members_crc_and_hash_verified": True,
        "original_igamegod_removed": True, "old_target_libloader_replaced": True,
        "signing_required": True, "signing_performed": False,
        "limitations": ["A device crash report is required to confirm the actual failure cause.",
                        "The output retains the target game's pre-existing code patches.",
                        "The i3rby binary remains unsigned and must be signed along with the app."]
    }
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    return report


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("target", type=Path)
    parser.add_argument("--framework", type=Path, default=Path(__file__).resolve().parent / "libloader.framework")
    parser.add_argument("--out", required=True, type=Path)
    parser.add_argument("--report", type=Path)
    args = parser.parse_args()
    report = build(args.target, args.framework, args.out, args.report or args.out.with_suffix(".report.json"))
    print(json.dumps({k: report[k] for k in ("variant", "output_ipa", "output_sha256", "output_size_bytes", "cause_confirmed", "signing_required")}, indent=2))


if __name__ == "__main__":
    main()
