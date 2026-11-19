
#!/usr/bin/env python3
"""Linux Server Hardening - Finance backup validation."""

import gzip
import os
import re
import shutil
import stat
import subprocess
import sys
import tarfile
import tempfile
from datetime import date, datetime, timedelta
from pathlib import Path

BACKUP_SCRIPT = Path("/usr/local/sbin/backup_finance.sh")
BACKUP_DIR = Path("/backup")
SOURCES = (Path("/home/cfo"), Path("/home/accountant1"))
RETENTION_DAYS = 30
BACKUP_PATTERN = re.compile(r"finance-(\d{4}-\d{2}-\d{2})\.tar\.gz")

passed = 0
failed = 0
warnings = 0


def report(status, message):
    global passed, failed, warnings

    print(f"[{status}] {message}")

    if status == "PASS":
        passed += 1
    elif status == "FAIL":
        failed += 1
    else:
        warnings += 1


def check(condition, message):
    report("PASS" if condition else "FAIL", message)


def validate_configuration():
    check(
        BACKUP_SCRIPT.is_file() and os.access(BACKUP_SCRIPT, os.X_OK),
        "Production backup script exists and is executable",
    )

    if BACKUP_SCRIPT.is_file():
        result = subprocess.run(
            ["bash", "-n", str(BACKUP_SCRIPT)],
            capture_output=True,
            check=False,
        )
        check(result.returncode == 0, "Production backup script syntax")

        config = BACKUP_SCRIPT.read_text()
        check(
            "RETENTION_DAYS=30" in config
            and "ENABLE_RETENTION=true" in config,
            "30-day retention configured",
        )

    for source in SOURCES:
        check(source.is_dir(), f"Source directory exists: {source}")

    if BACKUP_DIR.is_symlink() or not BACKUP_DIR.is_dir():
        report("FAIL", "Backup directory missing or unsafe")
        return False

    report("PASS", "Backup directory exists and is not a symlink")

    permissions = stat.S_IMODE(BACKUP_DIR.stat().st_mode)
    check(permissions == 0o700, "Backup directory permissions: 700")

    for command in ("bash", "tar", "gzip", "flock"):
        check(shutil.which(command) is not None, f"Command available: {command}")

    return True


def find_backups():
    backups = []

    for path in BACKUP_DIR.iterdir():
        match = BACKUP_PATTERN.fullmatch(path.name)

        if not match or path.is_symlink() or not path.is_file():
            continue

        try:
            backup_date = date.fromisoformat(match.group(1))
        except ValueError:
            report("WARN", f"Invalid backup date: {path.name}")
            continue

        backups.append((backup_date, path))

    return sorted(backups, key=lambda item: item[0], reverse=True)


def validate_archive(path):
    report("PASS", f"Latest backup found: {path.name}")

    permissions = stat.S_IMODE(path.stat().st_mode)
    check(permissions == 0o600, "Backup archive permissions: 600")

    try:
        with gzip.open(path, "rb") as archive:
            while archive.read(1024 * 1024):
                pass
        report("PASS", "GZIP integrity verification")
    except (OSError, EOFError) as error:
        report("FAIL", f"GZIP integrity: {error}")
        return

    try:
        with tarfile.open(path, "r:gz") as archive:
            members = archive.getmembers()
            names = {member.name.rstrip("/") for member in members}

        report("PASS", "TAR archive readability")
    except (tarfile.TarError, OSError) as error:
        report("FAIL", f"TAR archive readability: {error}")
        return

    for source in SOURCES:
        relative = str(source).lstrip("/")
        check(relative in names, f"Backup includes: {relative}")

    # Validate paths before extracting any archive content.
    for member in members:
        name = member.name

        if (
            name.startswith("/")
            or ".." in Path(name).parts
            or not (member.isfile() or member.isdir())
        ):
            report("FAIL", f"Unsafe archive entry: {name}")
            return

        if not (
            name == "home/cfo"
            or name.startswith("home/cfo/")
            or name == "home/accountant1"
            or name.startswith("home/accountant1/")
        ):
            report("FAIL", f"Unexpected archive entry: {name}")
            return

    report("PASS", "Archive paths and entry types validated")

    # Extract regular files only, without restoring ownership.
    try:
        with tempfile.TemporaryDirectory(prefix="backup-validation-") as temp:
            destination = Path(temp)

            with tarfile.open(path, "r:gz") as archive:
                for member in archive:
                    target = destination / member.name

                    if member.isdir():
                        target.mkdir(parents=True, exist_ok=True)
                    elif member.isfile():
                        target.parent.mkdir(parents=True, exist_ok=True)

                        source_file = archive.extractfile(member)
                        if source_file is None:
                            raise OSError(f"Cannot read {member.name}")

                        with source_file, target.open("wb") as output:
                            shutil.copyfileobj(source_file, output)

            report("PASS", "Temporary backup restoration")

            for source in SOURCES:
                restored = destination / str(source).lstrip("/")
                check(restored.is_dir(), f"Restored directory: {source.name}")

    except (OSError, tarfile.TarError) as error:
        report("FAIL", f"Temporary restoration: {error}")


def validate_retention(backups):
    # Match the production script's find -mtime +29 semantics:
    # files must have reached at least 30 complete days of age.
    threshold = datetime.now().timestamp() - RETENTION_DAYS * 86400
    expired = []

    for _, path in backups:
        if path.stat().st_mtime < threshold:
            expired.append(path)

    if expired:
        for path in expired:
            report("WARN", f"Expired backup detected: {path.name}")
    else:
        report("PASS", "No expired production backups detected")


def main():
    print("Linux Server Hardening - Backup Validation")
    print("=" * 43)

    if os.geteuid() != 0:
        sys.exit("ERROR: Run this script with sudo.")

    if validate_configuration():
        backups = find_backups()

        if backups:
            validate_archive(backups[0][1])
            validate_retention(backups)
        else:
            report("FAIL", "No production backup archives found")

    print("\nValidation summary")
    print("=" * 18)
    print(f"Passed:   {passed}")
    print(f"Failed:   {failed}")
    print(f"Warnings: {warnings}")

    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
