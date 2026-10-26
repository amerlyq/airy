#!/usr/bin/env python3
"""
ranger-fm plugin: :enca / :deca commands
Encrypt/compress and decrypt/decompress current or selected files/dirs.

Encode flow:  compress → encrypt (ts passphrase, minute-res) → base64 → xci
Decode flow:  xco | tr -d '\\r' → base64 -d → decrypt → decompress

Compatible: Python 3.12+  (targeted at 3.14+)
Dependencies: xci/xco clipboard wrappers
Optional: age (preferred if available), falls back to openssl enc

ARCHITECTURE: Each helper is a pure function (bytes→bytes or paths→bytes) so the
pipeline stages can be tested, swapped, or composed independently.

CONFIGURATION (environment variables — ranger settings not used, see DIAGNOSIS below):
    ENCA_COMPRESSOR   lzma|gzip|zstd|bzip2|none   (default: lzma)
    ENCA_COMP_LEVEL   0-9                          (default: 6)
    ENCA_ENCRYPTOR    age|openssl|none              (default: auto-detect)

DIAGNOSIS: ranger's Settings.__getattr__ raises on unknown setting names
(tuple index out of range in types_of()), so we use env vars instead of
`set enca_*` in rc.conf. Export in shell profile or ranger's rifle.conf.
"""

from __future__ import annotations

import base64
import gzip
import io
import lzma
import os
import shutil
import subprocess
import tarfile
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from ranger.api.commands import Command as _Base
else:
    from ranger.api.commands import Command as _Base


# ---------------------------------------------------------------------------
# Configuration — env-based (avoids ranger settings crash)
# ---------------------------------------------------------------------------

# DIAGNOSIS: ranger.container.settings.Settings.__getattr__ calls types_of()
# which fails with IndexError on unregistered setting names. Using os.environ
# is crash-proof and works identically across ranger versions.


def _get_config() -> dict[str, str | int]:
    """Read ENCA_* config from environment. Returns dict with defaults."""
    return {
        "compressor": os.environ.get("ENCA_COMPRESSOR", "lzma").lower(),
        "comp_level": int(os.environ.get("ENCA_COMP_LEVEL", "6")),
        "encryptor": os.environ.get("ENCA_ENCRYPTOR", "auto").lower(),
    }

    ## ALT: ranger settings via `set enca_compressor lzma` in rc.conf
    ## benefit: native ranger config; deficiency: crashes on unknown settings
    ## in ranger's Settings.__getattr__ → types_of() → IndexError.
    ## Would need monkey-patching DEFAULT_VALUES or a ranger PR to fix.


# ---------------------------------------------------------------------------
# Configuration — encryption backend auto-detection
# ---------------------------------------------------------------------------

# WHY auto-detect: `age` is preferred (purpose-built, audited) but not
# packaged on Ubuntu 24.04. `openssl` is universally available.
# EXTENSIBILITY: add new backends by extending _ENCRYPTORS and _detect_encryptor.


def _detect_encryptor() -> str:
    """Return best available encryptor: 'age' > 'openssl' > 'none'.

    ALGORITHM: check PATH via shutil.which; first hit wins.
    Cached after first call via module-level global.
    """
    global _DETECTED_ENCRYPTOR
    if _DETECTED_ENCRYPTOR is not None:
        return _DETECTED_ENCRYPTOR

    if shutil.which("age"):
        _DETECTED_ENCRYPTOR = "age"
    elif shutil.which("openssl"):
        _DETECTED_ENCRYPTOR = "openssl"
    else:
        _DETECTED_ENCRYPTOR = "none"
    return _DETECTED_ENCRYPTOR


_DETECTED_ENCRYPTOR: str | None = None


def _resolve_encryptor(cfg_value: str) -> str:
    """Resolve 'auto' to detected backend, or validate explicit choice."""
    if cfg_value == "auto":
        return _detect_encryptor()
    if cfg_value in ("age", "openssl", "none"):
        return cfg_value
    raise ValueError(f"unknown ENCA_ENCRYPTOR: {cfg_value!r}")


# ---------------------------------------------------------------------------
# Helpers — encryption backends
# ---------------------------------------------------------------------------

# --- age backend ---
# WHY age: simpler CLI, no keyring state, passphrase-only mode fits the
# ephemeral-timestamp use case. Single binary, auditable.
# DIAGNOSIS: AGE_PASSPHRASE env var requires age >= 1.1.0.


def _age_encrypt(data: bytes, passphrase: str) -> bytes:
    """Encrypt *data* with age symmetric passphrase. Returns ASCII-armored."""
    env = {**os.environ, "AGE_PASSPHRASE": passphrase}
    proc = subprocess.run(
        ["age", "-p", "-a"],  # -a = armor (ASCII safe for base64 chain)
        input=data,
        capture_output=True,
        env=env,
        check=False,
    )
    if proc.returncode != 0:
        raise RuntimeError(f"age encrypt failed: {proc.stderr.decode().strip()}")
    return proc.stdout


def _age_decrypt(data: bytes, passphrase: str) -> bytes:
    """Decrypt *data* with age symmetric passphrase."""
    env = {**os.environ, "AGE_PASSPHRASE": passphrase}
    proc = subprocess.run(
        ["age", "-d"],
        input=data,
        capture_output=True,
        env=env,
        check=False,
    )
    if proc.returncode != 0:
        raise RuntimeError(
            f"age decrypt failed (wrong timestamp?): {proc.stderr.decode().strip()}"
        )
    return proc.stdout


# --- openssl backend ---
# WHY openssl: universally available on Linux (Ubuntu, Arch, Alpine, macOS).
# Uses aes-256-cbc with pbkdf2 key derivation — good enough for ephemeral
# timestamp-based passphrases.
# DIAGNOSIS: `-pbkdf2` requires openssl >= 1.1.1 (Ubuntu 20.04+, Arch always).
# The `-iter 100000` is fast enough for minute-resolution passphrases.

_OPENSSL_CIPHER = "aes-256-cbc"
_OPENSSL_ITER = "100000"


def _openssl_encrypt(data: bytes, passphrase: str) -> bytes:
    """Encrypt *data* with openssl symmetric passphrase."""
    proc = subprocess.run(
        [
            "openssl",
            "enc",
            f"-{_OPENSSL_CIPHER}",
            "-pbkdf2",
            "-iter",
            _OPENSSL_ITER,
            "-pass",
            f"pass:{passphrase}",
            "-a",  # base64-armor output (like age -a)
        ],
        input=data,
        capture_output=True,
        check=False,
    )
    if proc.returncode != 0:
        raise RuntimeError(f"openssl encrypt failed: {proc.stderr.decode().strip()}")
    return proc.stdout


def _openssl_decrypt(data: bytes, passphrase: str) -> bytes:
    """Decrypt *data* with openssl symmetric passphrase."""
    proc = subprocess.run(
        [
            "openssl",
            "enc",
            f"-{_OPENSSL_CIPHER}",
            "-d",
            "-pbkdf2",
            "-iter",
            _OPENSSL_ITER,
            "-pass",
            f"pass:{passphrase}",
            "-a",  # input is base64-armored
        ],
        input=data,
        capture_output=True,
        check=False,
    )
    if proc.returncode != 0:
        raise RuntimeError(
            f"openssl decrypt failed (wrong timestamp?): {proc.stderr.decode().strip()}"
        )
    return proc.stdout


# --- dispatch ---

# Magic prefix so :deca auto-detects which backend was used for encryption.
# FORMAT: 2-byte backend tag + encrypted data
_ENC_TAG_AGE = b"EA"
_ENC_TAG_OPENSSL = b"EO"
_ENC_TAG_NONE = b"E0"
_ENC_TAG_LEN = 2


def _encrypt(data: bytes, passphrase: str, backend: str) -> bytes:
    """Encrypt *data* with the specified backend. Prepends backend tag."""
    if backend == "age":
        return _ENC_TAG_AGE + _age_encrypt(data, passphrase)
    elif backend == "openssl":
        return _ENC_TAG_OPENSSL + _openssl_encrypt(data, passphrase)
    elif backend == "none":
        return _ENC_TAG_NONE + data
    else:
        raise ValueError(f"unknown encryptor backend: {backend!r}")


def _decrypt(payload: bytes, passphrase: str) -> bytes:
    """Auto-detect encryption backend from tag and decrypt.

    ALGORITHM: read 2-byte prefix to select backend; strip prefix before
    passing to backend-specific decryptor.
    DIAGNOSIS: if tag is unrecognized, assume legacy age format (no tag).
    """
    if len(payload) < _ENC_TAG_LEN:
        raise ValueError("payload too short — missing encryption tag")

    tag = payload[:_ENC_TAG_LEN]
    body = payload[_ENC_TAG_LEN:]

    if tag == _ENC_TAG_AGE:
        return _age_decrypt(body, passphrase)
    elif tag == _ENC_TAG_OPENSSL:
        return _openssl_decrypt(body, passphrase)
    elif tag == _ENC_TAG_NONE:
        return body
    else:
        # FALLBACK: assume legacy format (raw age, no tag) for backward compat
        return _age_decrypt(payload, passphrase)


# ---------------------------------------------------------------------------
# Helpers — compressor selection
# ---------------------------------------------------------------------------

# WHY pluggable compressor: different use-cases favour different tradeoffs —
#   lzma: best ratio, slow (default, good for clipboard-size payloads)
#   gzip: fast, universally available
#   zstd: best speed/ratio, requires pyzstd
#   bzip2: middle ground, stdlib only
#   none: skip compression (already-compressed or speed-critical)
# EXTENSIBILITY: add new compressor by adding branch to _compress/_decompress.

# Magic bytes prefixed to compressed payload so :deca auto-detects compressor
# without needing config on the receiving side.
# FORMAT: 4-byte tag + compressed data
_TAG_LZMA = b"EL\x01\x00"
_TAG_GZIP = b"EG\x01\x00"
_TAG_ZSTD = b"EZ\x01\x00"
_TAG_BZ2 = b"EB\x01\x00"
_TAG_NONE = b"EN\x01\x00"
_TAG_LEN = 4


def _compress(data: bytes, name: str, level: int) -> bytes:
    """Compress *data* using the named compressor. Returns tag + compressed bytes."""
    if name == "lzma":
        return _TAG_LZMA + lzma.compress(data, preset=min(level, 9))
    elif name == "gzip":
        return _TAG_GZIP + gzip.compress(data, compresslevel=min(level, 9))
    elif name == "bzip2":
        import bz2

        return _TAG_BZ2 + bz2.compress(data, compresslevel=min(level, 9))
    elif name == "zstd":
        # REQUIRES: pip install pyzstd
        try:
            import pyzstd
        except ImportError as exc:
            raise RuntimeError("zstd compressor requires `pyzstd` package") from exc
        return _TAG_ZSTD + pyzstd.compress(data, level_or_option=min(level, 22))
    elif name == "none":
        return _TAG_NONE + data
    else:
        raise ValueError(f"unsupported compressor: {name!r}")


def _decompress(payload: bytes) -> bytes:
    """Auto-detect compressor from tag prefix and decompress."""
    if len(payload) < _TAG_LEN:
        raise ValueError("payload too short — missing compressor tag")

    tag = payload[:_TAG_LEN]
    body = payload[_TAG_LEN:]

    if tag == _TAG_LZMA:
        return lzma.decompress(body)
    elif tag == _TAG_GZIP:
        return gzip.decompress(body)
    elif tag == _TAG_BZ2:
        import bz2

        return bz2.decompress(body)
    elif tag == _TAG_ZSTD:
        try:
            import pyzstd
        except ImportError as exc:
            raise RuntimeError("zstd decompressor requires `pyzstd` package") from exc
        return pyzstd.decompress(body)
    elif tag == _TAG_NONE:
        return body
    else:
        # FALLBACK: assume legacy format (raw lzma, no tag) for backward compat
        return lzma.decompress(payload)


# ---------------------------------------------------------------------------
# Helpers — clipboard (xci / xco wrappers)
# ---------------------------------------------------------------------------

# WHY xci/xco: user-defined wrappers abstract away clipboard backend
# (xclip, xsel, wl-copy, pbcopy, OSC-52, SSH-forwarded, etc.)
# EXTENSIBILITY: swap these for dbus/wayland calls without touching pipeline


def _clipboard_copy(data: bytes) -> None:
    """Pipe raw bytes into clipboard via `xci` wrapper."""
    proc = subprocess.Popen(
        ["xci"],
        stdin=subprocess.PIPE,
    )
    proc.communicate(input=data)
    if proc.returncode != 0:
        raise RuntimeError(f"xci (clipboard copy) failed, exit={proc.returncode}")
    ## ALT: xclip -selection clipboard -i — direct xclip, no wrapper dependency
    ## benefit: zero-config on X11; deficiency: not portable to wayland/macOS


def _clipboard_paste() -> bytes:
    """Read raw bytes from clipboard via `xco` wrapper."""
    proc = subprocess.run(
        ["xco"],
        capture_output=True,
        check=True,
    )
    return proc.stdout
    ## ALT: xclip -selection clipboard -o — same tradeoff as above


# ---------------------------------------------------------------------------
# Helpers — passphrase
# ---------------------------------------------------------------------------

# WHY minute-resolution UTC: deterministic shared secret between sender/receiver
# within the same minute window without any key exchange.
# DIAGNOSIS: if decrypt fails, most likely the minute rolled over between
# enca and deca — pass explicit ts to :deca to compensate.

_ROLLOVER_THRESHOLD_S = 30  # seconds remaining before minute boundary


def _ts_passphrase() -> str:
    """Generate a deterministic passphrase from the current UTC minute.

    ROLLOVER FIX: if fewer than _ROLLOVER_THRESHOLD_S seconds remain in the
    current minute, round UP to the next minute. This gives the receiver a
    full ≥30s window instead of a near-zero one.
    ALGORITHM: check seconds component; if >= (60 - threshold), add 60s to
    the timestamp before truncating to minute.
    DIAGNOSIS: if sender rounded up but receiver calls :deca in the "old"
    minute, the auto-ts won't match — pass explicit ts.
    """
    now = datetime.now(timezone.utc)
    seconds_left = 60 - now.second
    if seconds_left <= _ROLLOVER_THRESHOLD_S:
        # Round up: advance to next minute
        now = now + timedelta(seconds=seconds_left)
    return now.strftime("%Y-%m-%dT%H:%M")


# ---------------------------------------------------------------------------
# Helpers — tar archiving
# ---------------------------------------------------------------------------


def _tar_archive(paths: list[Path]) -> bytes:
    """Create an in-memory .tar (uncompressed) archive from *paths*.

    WHY separate from compression: compression is now pluggable via
    _compress/_decompress, so tar is always raw here.
    """
    buf = io.BytesIO()
    with tarfile.open(fileobj=buf, mode="w") as tar:
        for p in paths:
            # arcname=p.name strips parent dirs → flat archive
            tar.add(str(p), arcname=p.name)
    return buf.getvalue()


def _tar_extract(data: bytes, dest: Path) -> list[str]:
    """Extract a .tar archive from *data* into *dest*. Return member names."""
    buf = io.BytesIO(data)
    with tarfile.open(fileobj=buf, mode="r") as tar:
        names = tar.getnames()
        # filter="data" (safe extraction) available py3.12+; we require 3.12
        tar.extractall(path=str(dest), filter="data")
    return names

    ## ALT: _tar_xz_compress / _tar_xz_extract — original monolithic helpers
    ## that combined tar+lzma in one step via lzma.open wrapping tarfile.
    ## benefit: single streaming pass, slightly less peak memory.
    ## replaced by: split tar + pluggable _compress/_decompress for flexibility.


# ---------------------------------------------------------------------------
# Helpers — ranger selection
# ---------------------------------------------------------------------------


def _selected_paths(cmd: _Base) -> list[Path]:
    """Return paths of selected files/dirs (or the current file if none marked).

    WHY fallback to thisfile: single-file operation is the common case;
    multi-select via `V`/space is the batch case. Covers both ergonomically.
    """
    tfile = cmd.fm.thisfile
    marked = cmd.fm.thistab.get_selection()
    paths = [Path(f.path) for f in marked] if marked else []
    if not paths and tfile:
        paths = [Path(tfile.path)]
    if not paths:
        cmd.fm.notify("No file or directory selected.", bad=True)
    return paths


# ---------------------------------------------------------------------------
# :enca  —  encode / encrypt → clipboard
# ---------------------------------------------------------------------------


class enca(_Base):
    """:enca

    Pipeline: selected files/dirs → tar → compress → encrypt (UTC-minute ts) → base64 → xci
    """

    def execute(self) -> None:
        paths = _selected_paths(self)
        if not paths:
            return

        cfg = _get_config()
        comp_name = cfg["compressor"]
        comp_level = cfg["comp_level"]
        enc_backend = _resolve_encryptor(cfg["encryptor"])

        try:
            # STEP 1: tar archive (uncompressed)
            self.fm.notify(f"Archiving {len(paths)} item(s)…")
            archive = _tar_archive(paths)

            # STEP 2: compress with selected compressor
            self.fm.notify(f"Compressing ({comp_name}, level={comp_level})…")
            compressed = _compress(archive, comp_name, comp_level)

            # STEP 3: encrypt with minute-resolution timestamp (rollover-safe)
            passphrase = _ts_passphrase()
            self.fm.notify(f"Encrypting ({enc_backend})…")
            encrypted = _encrypt(compressed, passphrase, enc_backend)

            # STEP 4: base64 encode (transport-safe)
            encoded = base64.b64encode(encrypted)

            # STEP 5: copy to clipboard via xci
            _clipboard_copy(encoded)

            names = ", ".join(p.name for p in paths[:3])
            if len(paths) > 3:
                names += f" … (+{len(paths) - 3})"
            self.fm.notify(
                f"enca: {names} → clipboard  "
                f"(ts={passphrase}, {enc_backend}, {comp_name}/{comp_level}, "
                f"{len(encoded):,} bytes b64)"
            )
        except Exception as exc:
            self.fm.notify(f"enca error: {exc}", bad=True)


# ---------------------------------------------------------------------------
# :deca  —  clipboard → decode / decrypt → extract
# ---------------------------------------------------------------------------


class deca(_Base):
    """:deca [passphrase]

    Pipeline: xco | tr -d '\\r' → base64 -d → decrypt (auto-detect) → decompress (auto-detect) → un-tar → cwd

    Without arguments the current UTC minute is used as passphrase.
    Pass an explicit ISO-minute string to decrypt from a different minute:
        :deca 2026-10-26T14:05
    """

    def execute(self) -> None:
        passphrase = self.arg(1) if self.arg(1) else _ts_passphrase()
        dest = Path(self.fm.thisdir.path)

        try:
            # STEP 1: paste from clipboard via xco & strip \r (Windows line-endings)
            self.fm.notify("Reading clipboard…")
            raw = _clipboard_paste()
            raw = raw.replace(b"\r", b"")

            # STEP 2: base64 decode
            decoded = base64.b64decode(raw, validate=True)

            # STEP 3: decrypt (auto-detect backend from tag)
            self.fm.notify(f"Decrypting (ts={passphrase})…")
            decrypted = _decrypt(decoded, passphrase)

            # STEP 4: decompress (auto-detect from tag)
            self.fm.notify("Decompressing…")
            tar_data = _decompress(decrypted)

            # STEP 5: extract into current dir
            self.fm.notify("Extracting…")
            names = _tar_extract(tar_data, dest)

            self.fm.notify(f"deca: extracted {len(names)} item(s) → {dest}")
        except Exception as exc:
            self.fm.notify(f"deca error: {exc}", bad=True)
        finally:
            # REFRESH: ranger dir listing to show newly extracted files
            self.fm.thisdir.load_content()
