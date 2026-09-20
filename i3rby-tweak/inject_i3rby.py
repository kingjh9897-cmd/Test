#!/usr/bin/env python3
"""Embed the extracted i3rby framework into the supplied 8 Ball Pool IPA.

Preserves the existing libloader/iGameGod frameworks, uses a distinct framework
name, and edits only Mach-O load-command metadata. The result MUST be re-signed.
This tool does not execute game code, sign the app, or bypass a runtime check.
"""
import argparse
import copy
import hashlib
import json
from pathlib import Path, PurePosixPath
import plistlib
import shutil
import struct
import tempfile
import zipfile

from extract_tweak import read_macho

ORIGINAL_TWEAK_SHA256 = "d44ed5b80ff3418d0ac07829833b95a060da9cf89a0d3d6d9fd2094d70b6dbeb"
INSTALL_NAME = "@rpath/i3rby.framework/i3rby"
LOAD_NAME = "@executable_path/Frameworks/i3rby.framework/i3rby"
FRAMEWORK_ID = "local.extracted.i3rby"


def sha256(data):
    return hashlib.sha256(data).hexdigest()


def file_sha256(path):
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def commands(binary):
    count, size = struct.unpack_from("<II", binary, 16)
    cursor = 32
    for _ in range(count):
        command, length = struct.unpack_from("<II", binary, cursor)
        if length < 8 or cursor + length > 32 + size:
            raise ValueError("Invalid Mach-O load command")
        yield command, cursor, length
        cursor += length
    if cursor != 32 + size:
        raise ValueError("Invalid load-command table size")


def rename_framework_binary(original):
    if sha256(original) != ORIGINAL_TWEAK_SHA256:
        raise ValueError("Unexpected source tweak; inspect its version before using this script")
    analysis = read_macho(original)
    if analysis["filetype"] != 6 or analysis["code_signature_command_present"]:
        raise ValueError("Expected original unsigned MH_DYLIB")
    identity_commands = [x for x in commands(original) if x[0] == 0xd]
    if len(identity_commands) != 1:
        raise ValueError("Expected exactly one LC_ID_DYLIB")
    _, offset, length = identity_commands[0]
    name_offset, _, current, compatibility = struct.unpack_from("<4I", original, offset + 8)
    new_name = INSTALL_NAME.encode() + b"\0"
    if len(new_name) > length - name_offset:
        raise ValueError("New framework identity does not fit")
    start, end = offset + name_offset, offset + length
    renamed = bytearray(original)
    renamed[start:end] = new_name.ljust(end - start, b"\0")
    renamed = bytes(renamed)
    if renamed[:start] != original[:start] or renamed[end:] != original[end:]:
        raise ValueError("Framework changed outside its install-name field")
    if read_macho(renamed)["install_name"] != INSTALL_NAME:
        raise ValueError("Framework identity verification failed")
    return renamed, current, compatibility, {"offset": start, "size": end - start}


def append_framework_load(original, current, compatibility):
    analysis = read_macho(original)
    if analysis["filetype"] != 2:
        raise ValueError("Expected application MH_EXECUTE")
    if any(item["cryptid"] for item in analysis["encryption"]):
        raise ValueError("Encrypted executable; this script does not decrypt it")
    if any(item["name"] == LOAD_NAME for item in analysis["dependencies"]):
        raise ValueError("i3rby load command already present")
    ncmds, old_size = struct.unpack_from("<II", original, 16)
    old_end = 32 + old_size
    first_section = min(x["offset"] for x in analysis["sections"] if x["offset"] > 0)
    name = LOAD_NAME.encode() + b"\0"
    command_size = (24 + len(name) + 7) & ~7
    new_end = old_end + command_size
    if new_end > first_section or any(original[old_end:new_end]):
        raise ValueError("Insufficient empty header padding; refusing to move game code")
    command = struct.pack("<6I", 0xc, command_size, 24, 0, current, compatibility)
    command += name.ljust(command_size - 24, b"\0")
    patched = bytearray(original)
    patched[old_end:new_end] = command
    struct.pack_into("<II", patched, 16, ncmds + 1, old_size + command_size)
    patched = bytes(patched)
    if (patched[:16] != original[:16] or patched[24:old_end] != original[24:old_end]
            or patched[new_end:] != original[new_end:]):
        raise ValueError("App changed outside header counters and reserved padding")
    after = read_macho(patched)
    if [x["name"] for x in after["dependencies"]].count(LOAD_NAME) != 1:
        raise ValueError("Framework load command verification failed")
    if after["sections"] != analysis["sections"] or after["segments"] != analysis["segments"]:
        raise ValueError("Section or segment layout changed")
    return patched, {"load_command_offset": old_end, "load_command_bytes": command_size,
                     "header_padding_before": first_section - old_end,
                     "header_padding_after": first_section - new_end,
                     "executable_sections_unchanged": True,
                     "existing_load_commands_unchanged": True}


def zip_entry(name, executable=False):
    item = zipfile.ZipInfo(name, date_time=(2026, 9, 20, 0, 0, 0))
    item.create_system = 3
    item.external_attr = (0o100755 if executable else 0o100644) << 16
    item.compress_type = zipfile.ZIP_DEFLATED
    return item


def inject(target, framework, output, report_path):
    if output.exists() or report_path.exists():
        raise ValueError("Output or report already exists; select new paths")
    if not framework.is_dir():
        raise ValueError("Source framework directory is missing")
    original_tweak = (framework / "libloader").read_bytes()
    tweak, current, compatibility, rename_range = rename_framework_binary(original_tweak)
    info = plistlib.loads((framework / "Info.plist").read_bytes())
    info.update(CFBundleExecutable="i3rby", CFBundleName="i3rby", CFBundleIdentifier=FRAMEWORK_ID)
    framework_plist = plistlib.dumps(info, fmt=plistlib.FMT_BINARY, sort_keys=False)
    output.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(target) as source:
        entries = source.infolist()
        names = source.namelist()
        if len(set(names)) != len(names):
            raise ValueError("Duplicate ZIP entries")
        for name in names:
            path = PurePosixPath(name)
            if path.is_absolute() or ".." in path.parts or "\\" in name:
                raise ValueError("Unsafe archive entry")
        plist_paths = [n for n in names if n.startswith("Payload/") and n.count("/") == 2
                       and n.endswith("/Info.plist")]
        if len(plist_paths) != 1:
            raise ValueError("Expected one top-level iOS app")
        app_info = plistlib.loads(source.read(plist_paths[0]))
        expected = ("com.miniclip.8ballpoolmult", "56.29.2", "5324")
        actual = tuple(app_info.get(k) for k in ("CFBundleIdentifier", "CFBundleShortVersionString", "CFBundleVersion"))
        if actual != expected:
            raise ValueError("Target app does not match the analyzed game version/build")
        app_prefix = plist_paths[0].rsplit("/", 1)[0] + "/"
        executable_name = app_prefix + app_info["CFBundleExecutable"]
        prefix = app_prefix + "Frameworks/i3rby.framework/"
        if any(name.startswith(prefix) for name in names):
            raise ValueError("Destination framework already exists")
        original_executable = source.read(executable_name)
        patched_executable, patch = append_framework_load(original_executable, current, compatibility)
        additions = {prefix + "i3rby": tweak, prefix + "Info.plist": framework_plist}
        original_hashes = {}
        with tempfile.TemporaryDirectory(prefix="ipa-build-", dir=output.parent) as temporary:
            candidate = Path(temporary) / "candidate.ipa"
            with zipfile.ZipFile(candidate, "w", compression=zipfile.ZIP_DEFLATED,
                                 compresslevel=6, allowZip64=True) as destination:
                destination.comment = source.comment
                for entry in entries:
                    data = source.read(entry)
                    original_hashes[entry.filename] = sha256(data)
                    if entry.filename == executable_name:
                        data = patched_executable
                    destination.writestr(copy.copy(entry), data)
                for name, data in additions.items():
                    destination.writestr(zip_entry(name, name.endswith("/i3rby")), data)
            with zipfile.ZipFile(candidate) as result:
                if len(result.namelist()) != len(names) + len(additions):
                    raise ValueError("Unexpected output entry count")
                for entry in entries:
                    data = result.read(entry.filename)  # Also validates each CRC.
                    expected_hash = sha256(patched_executable) if entry.filename == executable_name else original_hashes[entry.filename]
                    if sha256(data) != expected_hash:
                        raise ValueError("Changed or missing original ZIP member: " + entry.filename)
                for name, data in additions.items():
                    if result.read(name) != data:
                        raise ValueError("New framework member mismatch")
                rewritten_info = plistlib.loads(result.read(prefix + "Info.plist"))
                if rewritten_info["CFBundleExecutable"] != "i3rby":
                    raise ValueError("Invalid framework executable metadata")
            candidate.rename(output)
    report = {
        "input_ipa": target.name, "input_ipa_sha256": file_sha256(target),
        "output_ipa": output.name, "output_ipa_sha256": file_sha256(output),
        "output_size_bytes": output.stat().st_size,
        "bundle_id": expected[0], "version": expected[1], "build": expected[2],
        "framework_path": prefix, "load_name": LOAD_NAME, "install_name": INSTALL_NAME,
        "framework_bundle_id": FRAMEWORK_ID,
        "original_tweak_sha256": sha256(original_tweak), "embedded_tweak_sha256": sha256(tweak),
        "framework_install_name_changed_range": rename_range,
        "original_app_executable_sha256": sha256(original_executable),
        "patched_app_executable_sha256": sha256(patched_executable),
        "patch": patch,
        "verification": {"all_zip_entries_crc_checked": True,
                         "all_original_files_preserved_except_app_header": True,
                         "original_entries": len(entries), "added_files": list(additions),
                         "existing_libloader_preserved": True,
                         "existing_igamegod_preserved": True,
                         "runtime_test_performed": False},
        "signing": {"resigning_required": True, "signing_performed": False,
                    "note": "The existing app signature is invalidated by the changes. Re-sign app, frameworks and extensions with the user's signing tool."},
        "limitations": ["Static packaging checks do not prove runtime compatibility between the existing tweaks and i3rby.",
                        "The original tweak may have runtime checks or service requirements that were not changed."]
    }
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    return report


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("target", type=Path)
    parser.add_argument("--framework", type=Path, default=Path(__file__).resolve().parent / "libloader.framework")
    parser.add_argument("--out", type=Path, required=True)
    parser.add_argument("--report", type=Path)
    args = parser.parse_args()
    report = inject(args.target, args.framework, args.out, args.report or args.out.with_suffix(".report.json"))
    print(json.dumps({k: report[k] for k in ("output_ipa", "output_ipa_sha256", "output_size_bytes", "signing")}, indent=2))


if __name__ == "__main__":
    main()
