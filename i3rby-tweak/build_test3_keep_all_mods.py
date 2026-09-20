#!/usr/bin/env python3
"""Build Test 3: keep all existing iOSGods mods and restore i3rby's original path.

Strategy:
- keep iGameGod and all other target files/mods,
- relocate the target's existing libloader.framework to Frameworks/lg.framework,
- patch the target loader's LC_ID_DYLIB to @rpath/lg.framework/libloader,
- patch the app's existing libloader dependency to the relocated target loader,
- place the original i3rby libloader.framework back at its original path,
- append a second app load command for i3rby at the original path.

The output is unsigned and must be re-signed. Runtime success is not guaranteed.
"""

import argparse
import copy
import hashlib
import json
from pathlib import Path, PurePosixPath
import plistlib
import struct
import tempfile
import zipfile

from extract_tweak import read_macho

TARGET_SHA256 = "27500e6357fc4b215f70f7df1379b29bd921fc2b6cb62d0b6c56302e260ee698"
TWEAK_SHA256 = "d44ed5b80ff3418d0ac07829833b95a060da9cf89a0d3d6d9fd2094d70b6dbeb"

APP_PREFIX = "Payload/pool.app/"
MAIN = APP_PREFIX + "pool"
OLD_FW = APP_PREFIX + "Frameworks/libloader.framework/"
NEW_FW = APP_PREFIX + "Frameworks/lg.framework/"
IGG_FW = APP_PREFIX + "Frameworks/iGameGod.framework/"

OLD_LOAD = "@executable_path/Frameworks/libloader.framework/libloader"
NEW_LOAD = "@executable_path/Frameworks/lg.framework/libloader"
NEW_ID = "@rpath/lg.framework/libloader"
I3RBY_ID = "@rpath/libloader.framework/libloader"

DYLIB_COMMANDS = {
    0x0C,
    0x0D,
    0x18,
    0x80000018,
    0x1F,
    0x8000001F,
    0x20,
    0x23,
    0x80000023,
}


def sha256(data):
    return hashlib.sha256(data).hexdigest()


def file_sha256(path):
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def macho_commands(binary):
    if len(binary) < 32 or binary[:4] != b"\xcf\xfa\xed\xfe":
        raise ValueError("Expected thin little-endian 64-bit Mach-O")
    ncmds, sizeofcmds = struct.unpack_from("<II", binary, 16)
    cursor = 32
    end = 32 + sizeofcmds
    for _ in range(ncmds):
        if cursor + 8 > end:
            raise ValueError("Invalid load-command table")
        cmd, cmdsize = struct.unpack_from("<II", binary, cursor)
        if cmdsize < 8 or cursor + cmdsize > end:
            raise ValueError("Invalid load command")
        yield cmd, cursor, cmdsize
        cursor += cmdsize
    if cursor != end:
        raise ValueError("Invalid load-command table size")


def dylib_name(binary, offset, size):
    name_offset = struct.unpack_from("<I", binary, offset + 8)[0]
    if name_offset < 24 or name_offset >= size:
        raise ValueError("Invalid dylib name offset")
    start = offset + name_offset
    end = offset + size
    raw = binary[start:end].split(b"\0", 1)[0]
    return raw.decode("utf-8"), start, end


def replace_dylib_name(binary, old_name, new_name, allowed_commands=None):
    allowed = allowed_commands or DYLIB_COMMANDS
    data = bytearray(binary)
    changes = []
    for cmd, offset, size in list(macho_commands(binary)):
        if cmd not in allowed:
            continue
        name, start, end = dylib_name(binary, offset, size)
        if name != old_name:
            continue
        encoded = new_name.encode("utf-8") + b"\0"
        if len(encoded) > end - start:
            raise ValueError(f"Replacement path does not fit: {old_name} -> {new_name}")
        data[start:end] = encoded.ljust(end - start, b"\0")
        changes.append({"command": hex(cmd), "offset": start, "old": old_name, "new": new_name})
    return bytes(data), changes


def replace_single_id(binary, new_id):
    ids = []
    for cmd, offset, size in macho_commands(binary):
        if cmd == 0x0D:
            name, _, _ = dylib_name(binary, offset, size)
            ids.append(name)
    if len(ids) != 1:
        raise ValueError("Expected exactly one LC_ID_DYLIB in target libloader")
    patched, changes = replace_dylib_name(binary, ids[0], new_id, {0x0D})
    if len(changes) != 1:
        raise ValueError("Failed to rewrite target libloader identity")
    if read_macho(patched).get("install_name") != new_id:
        raise ValueError("Relocated loader identity verification failed")
    return patched, ids[0], changes[0]


def id_versions(binary):
    ids = []
    for cmd, offset, size in macho_commands(binary):
        if cmd == 0x0D:
            name_offset, timestamp, current, compatibility = struct.unpack_from("<4I", binary, offset + 8)
            ids.append((name_offset, timestamp, current, compatibility))
    if len(ids) != 1:
        raise ValueError("Expected exactly one LC_ID_DYLIB")
    return ids[0][2], ids[0][3]


def append_i3rby_load(binary, current, compatibility):
    analysis = read_macho(binary)
    if analysis["filetype"] != 2 or any(x["cryptid"] for x in analysis["encryption"]):
        raise ValueError("Expected unencrypted ARM64 app executable")
    deps = [x["name"] for x in analysis["dependencies"]]
    if OLD_LOAD in deps:
        raise ValueError("Old libloader path still points to target loader; relocate it first")
    if deps.count(NEW_LOAD) != 1:
        raise ValueError("Expected exactly one relocated target-loader dependency")
    ncmds, old_size = struct.unpack_from("<II", binary, 16)
    old_end = 32 + old_size
    first_section = min(x["offset"] for x in analysis["sections"] if x["offset"] > 0)
    name = OLD_LOAD.encode("utf-8") + b"\0"
    command_size = (24 + len(name) + 7) & ~7
    new_end = old_end + command_size
    if new_end > first_section or any(binary[old_end:new_end]):
        raise ValueError("Not enough zero header padding to append i3rby load command")
    command = struct.pack("<6I", 0x0C, command_size, 24, 0, current, compatibility)
    command += name.ljust(command_size - 24, b"\0")

    data = bytearray(binary)
    data[old_end:new_end] = command
    struct.pack_into("<II", data, 16, ncmds + 1, old_size + command_size)
    patched = bytes(data)

    after = read_macho(patched)
    after_deps = [x["name"] for x in after["dependencies"]]
    if after_deps.count(NEW_LOAD) != 1 or after_deps.count(OLD_LOAD) != 1:
        raise ValueError("Unexpected loader dependency count after patch")
    if after["sections"] != analysis["sections"] or after["segments"] != analysis["segments"]:
        raise ValueError("Section or segment layout changed")
    return patched, {
        "load_command_offset": old_end,
        "load_command_bytes": command_size,
        "header_padding_before": first_section - old_end,
        "header_padding_after": first_section - new_end,
    }


def zipinfo_like(entry, new_name):
    out = copy.copy(entry)
    out.filename = new_name
    return out


def new_zipinfo(name, executable=False):
    item = zipfile.ZipInfo(name, date_time=(2026, 9, 20, 0, 0, 0))
    item.create_system = 3
    item.external_attr = (0o100755 if executable else 0o100644) << 16
    item.compress_type = zipfile.ZIP_DEFLATED
    return item


def build(target, framework, output, report_path):
    if output.exists() or report_path.exists():
        raise ValueError("Output or report already exists")
    if file_sha256(target) != TARGET_SHA256:
        raise ValueError("Use the exact analyzed iOSGods 56.29.2 / build 5324 IPA")

    source_i3rby = (framework / "libloader").read_bytes()
    source_plist_bytes = (framework / "Info.plist").read_bytes()
    if sha256(source_i3rby) != TWEAK_SHA256:
        raise ValueError("Unexpected i3rby source binary")
    source_plist = plistlib.loads(source_plist_bytes)
    if source_plist.get("CFBundleExecutable") != "libloader":
        raise ValueError("Unexpected i3rby framework metadata")
    if read_macho(source_i3rby).get("install_name") != I3RBY_ID:
        raise ValueError("i3rby no longer has its original install name")

    output.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(target) as src:
        entries = src.infolist()
        names = src.namelist()
        if len(names) != len(set(names)):
            raise ValueError("Duplicate ZIP entries")
        for name in names:
            path = PurePosixPath(name)
            if path.is_absolute() or ".." in path.parts or "\\" in name:
                raise ValueError("Unsafe archive entry")
        if MAIN not in names:
            raise ValueError("Target main executable not found")
        if not any(n.startswith(OLD_FW) for n in names):
            raise ValueError("Existing target libloader.framework is missing")
        if not any(n.startswith(IGG_FW) for n in names):
            raise ValueError("iGameGod.framework is missing; this test must preserve all mods")
        if any(n.startswith(NEW_FW) for n in names):
            raise ValueError("Relocation destination already exists")

        old_loader_bin_name = OLD_FW + "libloader"
        old_loader_plist_name = OLD_FW + "Info.plist"
        if old_loader_bin_name not in names or old_loader_plist_name not in names:
            raise ValueError("Target libloader framework is incomplete")

        i3rby_current, i3rby_compatibility = id_versions(source_i3rby)

        original_main = src.read(MAIN)
        main_relocated, main_changes = replace_dylib_name(original_main, OLD_LOAD, NEW_LOAD, {0x0C})
        if len(main_changes) != 1:
            raise ValueError("Expected one app load command for target libloader")
        patched_main, append_report = append_i3rby_load(
            main_relocated, i3rby_current, i3rby_compatibility
        )

        target_loader_original = src.read(old_loader_bin_name)
        target_loader_patched, old_target_id, target_id_change = replace_single_id(
            target_loader_original, NEW_ID
        )

        target_loader_plist = plistlib.loads(src.read(old_loader_plist_name))
        original_target_bundle_id = target_loader_plist.get("CFBundleIdentifier")
        i3rby_bundle_id = source_plist.get("CFBundleIdentifier")
        bundle_id_changed = False
        if original_target_bundle_id == i3rby_bundle_id:
            target_loader_plist["CFBundleIdentifier"] = "local.iosgods.relocated.loader"
            bundle_id_changed = True
        relocated_target_plist = plistlib.dumps(
            target_loader_plist, fmt=plistlib.FMT_BINARY, sort_keys=False
        )

        preserved_hashes = {}
        relocated_entries = []
        removed_signature_entries = []
        other_loader_reference_changes = []
        with tempfile.TemporaryDirectory(prefix="test3-", dir=output.parent) as tmp:
            candidate = Path(tmp) / "candidate.ipa"
            with zipfile.ZipFile(
                candidate, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=6, allowZip64=True
            ) as dst:
                dst.comment = src.comment
                for entry in entries:
                    name = entry.filename
                    data = src.read(entry)
                    preserved_hashes[name] = sha256(data)

                    if name.startswith(OLD_FW):
                        relative = name[len(OLD_FW):]
                        if relative.startswith("_CodeSignature/"):
                            removed_signature_entries.append(name)
                            continue
                        new_name = NEW_FW + relative
                        if name == old_loader_bin_name:
                            data = target_loader_patched
                        elif name == old_loader_plist_name:
                            data = relocated_target_plist
                        dst.writestr(zipinfo_like(entry, new_name), data)
                        relocated_entries.append(new_name)
                        continue

                    if name == MAIN:
                        data = patched_main
                    elif data[:4] == b"\xcf\xfa\xed\xfe":
                        data, changes = replace_dylib_name(
                            data, OLD_LOAD, NEW_LOAD, DYLIB_COMMANDS - {0x0D}
                        )
                        if changes:
                            other_loader_reference_changes.append(
                                {"file": name, "changes": changes}
                            )
                    dst.writestr(copy.copy(entry), data)

                dst.writestr(new_zipinfo(OLD_FW + "libloader", executable=True), source_i3rby)
                dst.writestr(new_zipinfo(OLD_FW + "Info.plist"), source_plist_bytes)

            with zipfile.ZipFile(candidate) as check:
                result_names = check.namelist()
                if result_names.count(OLD_FW + "libloader") != 1:
                    raise ValueError("i3rby binary missing or duplicated")
                if result_names.count(NEW_FW + "libloader") != 1:
                    raise ValueError("Relocated target loader missing or duplicated")
                if check.read(OLD_FW + "libloader") != source_i3rby:
                    raise ValueError("i3rby binary changed")
                if check.read(OLD_FW + "Info.plist") != source_plist_bytes:
                    raise ValueError("i3rby Info.plist changed")
                if check.read(NEW_FW + "libloader") != target_loader_patched:
                    raise ValueError("Relocated target loader changed unexpectedly")
                if check.read(MAIN) != patched_main:
                    raise ValueError("Patched app executable mismatch")

                final_main = read_macho(check.read(MAIN))
                final_deps = [x["name"] for x in final_main["dependencies"]]
                if final_deps.count(NEW_LOAD) != 1 or final_deps.count(OLD_LOAD) != 1:
                    raise ValueError("Final app does not load both target loader and i3rby exactly once")
                if not any("iGameGod.framework/iGameGod" in x for x in final_deps):
                    raise ValueError("iGameGod dependency was not preserved")

                final_target_loader = read_macho(check.read(NEW_FW + "libloader"))
                if final_target_loader.get("install_name") != NEW_ID:
                    raise ValueError("Relocated target loader has wrong install name")
                final_i3rby = read_macho(check.read(OLD_FW + "libloader"))
                if final_i3rby.get("install_name") != I3RBY_ID:
                    raise ValueError("i3rby original identity was not preserved")

            candidate.rename(output)

    report = {
        "variant": "test3-keep-all-mods-original-i3rby-path",
        "purpose": "Keep the complete iOSGods target while giving i3rby its original framework path and identity",
        "input_ipa": target.name,
        "input_sha256": TARGET_SHA256,
        "output_ipa": output.name,
        "output_sha256": file_sha256(output),
        "output_size_bytes": output.stat().st_size,
        "all_existing_mods_requested": True,
        "igamegod_preserved": True,
        "target_loader_relocated": {
            "from": OLD_FW,
            "to": NEW_FW,
            "old_install_name": old_target_id,
            "new_install_name": NEW_ID,
            "id_patch": target_id_change,
            "bundle_id_before": original_target_bundle_id,
            "bundle_id_after": target_loader_plist.get("CFBundleIdentifier"),
            "bundle_id_changed_only_to_avoid_collision": bundle_id_changed,
        },
        "app_loader_patch": main_changes[0],
        "other_loader_reference_changes": other_loader_reference_changes,
        "i3rby": {
            "framework_path": OLD_FW,
            "binary_sha256": sha256(source_i3rby),
            "binary_unchanged": True,
            "plist_unchanged": True,
            "install_name": I3RBY_ID,
            "app_load_name": OLD_LOAD,
            "append": append_report,
        },
        "removed_stale_framework_signature_entries": removed_signature_entries,
        "signing_required": True,
        "signing_performed": False,
        "runtime_test_performed": False,
        "cause_confirmed": False,
        "limitations": [
            "This is a static packaging change; it cannot prove that two third-party tweaks are runtime-compatible.",
            "A device .ips crash report is still required if the app continues to exit after launch.",
            "The complete app and all embedded frameworks must be re-signed after modification.",
        ],
    }
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    return report


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("target", type=Path)
    parser.add_argument(
        "--framework",
        type=Path,
        default=Path(__file__).resolve().parent / "libloader.framework",
    )
    parser.add_argument("--out", type=Path, required=True)
    parser.add_argument("--report", type=Path)
    args = parser.parse_args()
    report = build(
        args.target,
        args.framework,
        args.out,
        args.report or args.out.with_suffix(".report.json"),
    )
    print(json.dumps({
        "variant": report["variant"],
        "output_ipa": report["output_ipa"],
        "output_sha256": report["output_sha256"],
        "output_size_bytes": report["output_size_bytes"],
        "signing_required": report["signing_required"],
        "runtime_test_performed": report["runtime_test_performed"],
    }, indent=2))


if __name__ == "__main__":
    main()
