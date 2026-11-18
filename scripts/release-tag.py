#!/usr/bin/env python3
# SPDX-License-Identifier: CC0-1.0

import argparse
import re
import subprocess
import sys
import xml.etree.ElementTree as ET
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]


def git(*args):
    return subprocess.check_output(
        ["git", *args], cwd=REPO_ROOT, text=True
    ).strip()


def main():
    parser = argparse.ArgumentParser(description="Check release versions in HEAD and create a local annotated tag.")
    parser.add_argument("version", help="Release version, for example 0.1.4")
    parser.add_argument("--check", action="store_true", help="Validate HEAD without creating a tag")
    args = parser.parse_args()
    if not re.fullmatch(r"(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)", args.version):
        parser.error("version must use MAJOR.MINOR.PATCH")

    commit = git("rev-parse", "--verify", "HEAD")

    def read(path):
        return git("show", f"{commit}:{path}")

    spec_path = "packaging/ktmpv.spec"
    cmake_path = "CMakeLists.txt"
    metainfo_path = "data/io.github.kamiertop.ktmpv.metainfo.xml"
    spec = read(spec_path)
    spec_version = re.search(r"^Version:[ \t]*(\S+)", spec, re.MULTILINE)
    cmake_version = re.search(r"^project\(ktmpv\s+VERSION\s+(\S+)", read(cmake_path), re.MULTILINE)
    release = ET.fromstring(read(metainfo_path)).find("./releases/release")
    changelog = re.search(r"^%changelog\s*\n\*[^\n]* - (\S+)", spec, re.MULTILINE)

    versions = {
        spec_path: spec_version[1] if spec_version else None,
        cmake_path: cmake_version[1] if cmake_version else None,
        metainfo_path: release.get("version") if release is not None else None,
        f"{spec_path} latest changelog entry": changelog[1].partition("-")[0] if changelog else None,
    }
    mismatches = {path: value for path, value in versions.items() if value != args.version}
    if mismatches:
        for path, value in mismatches.items():
            print(f"{path}: expected {args.version}, found {value or 'no version'} in HEAD", file=sys.stderr)
        return 1

    tag = f"ktmpv-v{args.version}"
    if args.check:
        print(f"{commit[:12]} has matching versions for {tag}.")
    else:
        git("tag", "-a", tag, "-m", f"Ktmpv {args.version}", commit)
        print(f"Created local tag {tag} at {commit[:12]}.")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except subprocess.CalledProcessError as error:
        sys.exit(error.returncode)
    except ET.ParseError as error:
        sys.exit(f"Invalid AppStream metadata: {error}")
