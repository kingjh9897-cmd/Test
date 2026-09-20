#!/usr/bin/env python3
"""Extract the original libloader framework from the supplied 8 Ball Pool IPA.

Uses Python's standard library. Reads ZIP/Mach-O data only; never runs app code.
The .dylib output is an unchanged copy, not a rebuild or source-code recovery.
"""
import argparse
import hashlib
import json
from pathlib import Path, PurePosixPath
import plistlib
import shutil
import stat
import struct
import tempfile
import zipfile

PREFIX = "Payload/pool.app/Frameworks/libloader.framework/"
MARKERS = ["GBModMenu", "GBPredictionDrawView", "com.i3rby.8poolmod",
           "Prediction Lines", "Pocket Rings", "Scratch Alert", "Stream Proof",
           "Auto Select Pocket", "Aim Mode", "Humanization", "Break Mode",
           "Automation PRO required"]
LOADS = {0xc: "LC_LOAD_DYLIB", 0x80000018: "LC_LOAD_WEAK_DYLIB",
         0x8000001f: "LC_REEXPORT_DYLIB", 0x80000023: "LC_LOAD_UPWARD_DYLIB",
         0x20: "LC_LAZY_LOAD_DYLIB"}


def sha256(data):
    return hashlib.sha256(data).hexdigest()


def read_macho(b):
    def unpack(fmt, offset):
        size = struct.calcsize(fmt)
        if offset < 0 or offset + size > len(b):
            raise ValueError("Mach-O structure outside file")
        return struct.unpack_from(fmt, b, offset)

    def cstring(offset, end=None):
        end = len(b) if end is None else end
        if not 0 <= offset < end <= len(b):
            raise ValueError("Invalid string range")
        terminator = b.find(b"\0", offset, end)
        if terminator < 0:
            raise ValueError("Unterminated string")
        return b[offset:terminator].decode("utf-8", errors="replace")

    magic, cpu, subtype, kind, ncmds, cmdbytes, flags, _ = unpack("<8I", 0)
    if magic != 0xfeedfacf or cpu != 0x0100000c:
        raise ValueError("This extractor expects thin little-endian ARM64 Mach-O")
    end = 32 + cmdbytes
    if end > len(b) or ncmds > cmdbytes // 8:
        raise ValueError("Invalid load-command table")
    report = {"size_bytes": len(b), "sha256": sha256(b), "architecture": "arm64",
              "cpu_subtype": subtype, "filetype": kind, "flags": flags,
              "load_commands": [], "dependencies": [], "rpaths": [],
              "encryption": [], "sections": [], "segments": [],
              "code_signature_command_present": False}
    pos = 32
    symtab = function_data = None
    for _ in range(ncmds):
        cmd, size = unpack("<II", pos)
        if size < 8 or pos + size > end:
            raise ValueError("Invalid load command")
        report["load_commands"].append(hex(cmd))
        if cmd in LOADS or cmd in (0xd, 0x8000001c):
            string_offset, = unpack("<I", pos + 8)
            minimum = 12 if cmd == 0x8000001c else 24
            if not minimum <= string_offset < size:
                raise ValueError("Invalid load-command string")
            name = cstring(pos + string_offset, pos + size)
            if cmd == 0xd:
                report["install_name"] = name
            elif cmd == 0x8000001c:
                report["rpaths"].append(name)
            else:
                report["dependencies"].append({"command": LOADS[cmd], "name": name})
        elif cmd in (0x21, 0x2c):
            cryptoff, cryptsize, cryptid = unpack("<III", pos + 8)
            report["encryption"].append({"cryptoff": cryptoff, "cryptsize": cryptsize,
                                         "cryptid": cryptid})
        elif cmd == 0x19:
            segment = unpack("<16sQQQQIIII", pos + 8)
            name, va, vs, fo, fs, _, _, ns, _ = segment
            if size < 72 + ns * 80 or fo + fs > len(b):
                raise ValueError("Invalid segment or section table")
            report["segments"].append({"name": name.split(b"\0")[0].decode(),
                                       "vmaddr": va, "vmsize": vs,
                                       "fileoff": fo, "filesize": fs})
            for j in range(ns):
                section = unpack("<16s16sQQIIIIIIII", pos + 72 + j * 80)
                sn, sg, addr, length, offset, _, _, _, sflags, _, _, _ = section
                report["sections"].append({"name": sn.split(b"\0")[0].decode(),
                                           "segment": sg.split(b"\0")[0].decode(),
                                           "address": addr, "size": length,
                                           "offset": offset, "flags": sflags})
        elif cmd == 2:
            symtab = unpack("<IIII", pos + 8)
        elif cmd == 0x26:
            function_data = unpack("<II", pos + 8)
        elif cmd == 0x1d:
            report["code_signature_command_present"] = True
        pos += size
    if pos != end:
        raise ValueError("Load-command size mismatch")

    def vm_offset(address):
        for segment in report["segments"]:
            start = segment["vmaddr"]
            if start <= address < start + segment["filesize"]:
                return segment["fileoff"] + address - start
        raise ValueError("Virtual address has no file-backed bytes")

    def pointer(address):
        return unpack("<Q", vm_offset(address))[0]

    report["objc_classes"] = []
    for section in report["sections"]:
        if section["name"] == "__objc_classlist":
            for i in range(0, section["size"], 8):
                class_address, = unpack("<Q", section["offset"] + i)
                try:
                    ro = pointer(class_address + 32) & ~7
                    name = cstring(vm_offset(pointer(ro + 24)))
                    report["objc_classes"].append(name)
                except ValueError:
                    report["objc_classes"].append({"unparsed_address": class_address})
    if symtab:
        so, count, strings, string_bytes = symtab
        if so + count * 16 > len(b) or strings + string_bytes > len(b):
            raise ValueError("Invalid symbol table")
        imports, defined = [], []
        for i in range(count):
            idx, typ, _, _, _ = unpack("<IBBHQ", so + i * 16)
            if idx >= string_bytes:
                raise ValueError("Invalid symbol name")
            name = cstring(strings + idx, strings + string_bytes)
            (imports if typ & 0x0e == 0 else defined).append(name)
        report["symbol_table"] = {"count": count, "defined": defined, "imports": imports}
    if function_data:
        cursor, length = function_data
        limit = cursor + length
        if limit > len(b):
            raise ValueError("Invalid function-start table")
        count = value = shift = 0
        while cursor < limit:
            byte = b[cursor]
            cursor += 1
            value |= (byte & 127) << shift
            if byte & 128:
                shift += 7
                if shift > 63:
                    raise ValueError("Invalid ULEB128")
            else:
                if value == 0:
                    break
                count += 1
                value = shift = 0
        report["function_start_entries"] = count
    return report


def extract(ipa, output):
    if output.exists():
        raise ValueError("Output already exists; choose a new directory")
    with zipfile.ZipFile(ipa) as archive:
        names = archive.namelist()
        if len(set(names)) != len(names):
            raise ValueError("Duplicate ZIP entry names")
        selected = [i for i in archive.infolist()
                    if i.filename.startswith(PREFIX) and not i.is_dir()]
        if not selected or sum(i.file_size for i in selected) > 100 * 1024 * 1024:
            raise ValueError("Framework missing or unexpectedly large")
        binary = archive.read(PREFIX + "libloader")
        app_plist = plistlib.loads(archive.read("Payload/pool.app/Info.plist"))
        tweak = read_macho(binary)
        if tweak["filetype"] != 6:
            raise ValueError("Framework binary is not MH_DYLIB")
        marker_hits = {m: binary.find(m.encode()) for m in MARKERS if m.encode() in binary}
        if not {"GBModMenu", "GBPredictionDrawView", "com.i3rby.8poolmod"} <= marker_hits.keys():
            raise ValueError("Expected i3rby markers not present; inspect this IPA separately")
        app_binary = archive.read("Payload/pool.app/" + app_plist["CFBundleExecutable"])
        app = read_macho(app_binary)
        bundle = {k: app_plist.get(k) for k in ["CFBundleIdentifier", "CFBundleName",
                  "CFBundleShortVersionString", "CFBundleVersion", "MinimumOSVersion"]}
        report = {"source_ipa": ipa.name, "source_ipa_sha256": sha256(ipa.read_bytes()),
                  "bundle": bundle, "framework_archive_path": PREFIX,
                  "tweak": tweak, "app": app, "marker_offsets": marker_hits,
                  "verification": {"binary_extracted_unchanged": True,
                                   "runtime_test_performed": False,
                                   "source_code_recovered": False}, "files": []}
        output.parent.mkdir(parents=True, exist_ok=True)
        with tempfile.TemporaryDirectory(prefix="extract-", dir=output.parent) as tmp:
            stage = Path(tmp) / "result"
            stage.mkdir()
            for item in selected:
                relative = PurePosixPath(item.filename[len(PREFIX):])
                if relative.is_absolute() or ".." in relative.parts or "\\" in str(relative):
                    raise ValueError("Unsafe ZIP path")
                if stat.S_ISLNK(item.external_attr >> 16):
                    raise ValueError("Unexpected ZIP symbolic link")
                data = archive.read(item)
                destination = stage / "libloader.framework" / relative
                destination.parent.mkdir(parents=True, exist_ok=True)
                destination.write_bytes(data)
                if destination.read_bytes() != data:
                    raise ValueError("Extraction byte mismatch")
                destination.chmod(0o755 if relative.name == "libloader" else 0o644)
                report["files"].append({"archive_path": item.filename,
                                         "output_path": destination.relative_to(stage).as_posix(),
                                         "size_bytes": len(data), "sha256": sha256(data)})
            dylib = stage / "i3rby_8BallPool_original.dylib"
            dylib.write_bytes(binary)
            dylib.chmod(0o755)
            if dylib.read_bytes() != binary:
                raise ValueError("Dylib byte mismatch")
            (stage / "analysis.json").write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n")
            stage.rename(output)
    return report


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("ipa", type=Path)
    parser.add_argument("--out", type=Path, default=Path("extracted_tweak"))
    args = parser.parse_args()
    report = extract(args.ipa, args.out)
    print(json.dumps({"output": str(args.out.resolve()),
                      "binary_sha256": report["tweak"]["sha256"],
                      "size_bytes": report["tweak"]["size_bytes"],
                      "marker_count": len(report["marker_offsets"])}, indent=2))


if __name__ == "__main__":
    main()
