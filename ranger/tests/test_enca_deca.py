"""Encryption and compression helpers round trip data without external tools."""

import pytest
from plugins import enca_deca


@pytest.mark.parametrize("compressor", ["none", "lzma", "gzip", "bzip2"])
def test_compress_decompress_round_trip(compressor):
    source = b"ranger plugin data\x00" * 20
    packed = enca_deca._compress(source, compressor, 6)
    assert enca_deca._decompress(packed) == source


def test_encryptor_configuration_validation_and_none_backend(monkeypatch):
    encrypted = enca_deca._encrypt(b"data", "pass", "none")
    assert encrypted == b"E0data"
    assert enca_deca._decrypt(encrypted, "pass") == b"data"
    with pytest.raises(ValueError, match="unknown ENCA_ENCRYPTOR"):
        enca_deca._resolve_encryptor("unknown")
    monkeypatch.setenv("ENCA_COMPRESSOR", "GZIP")
    assert enca_deca._get_config()["compressor"] == "gzip"
