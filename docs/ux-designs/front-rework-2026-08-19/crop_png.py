#!/usr/bin/env python3
"""Crop a PNG to its top N rows without external deps (truncate scanlines)."""
import struct, sys, zlib

def crop(path, keep_h):
    d = open(path, 'rb').read()
    w = struct.unpack('>I', d[16:20])[0]; h = struct.unpack('>I', d[20:24])[0]
    if h <= keep_h: return
    bitdepth, coltype = d[24], d[25]
    channels = {0:1, 2:3, 3:1, 4:2, 6:4}[coltype]
    stride = w * channels * (bitdepth // 8) + 1
    pos, idat, chunks = 8, b'', []
    while pos < len(d):
        ln = struct.unpack('>I', d[pos:pos+4])[0]; typ = d[pos+4:pos+8]
        if typ == b'IDAT': idat += d[pos+8:pos+8+ln]
        else: chunks.append((typ, d[pos+8:pos+8+ln]))
        pos += 12 + ln
    raw = zlib.decompress(idat)[:keep_h * stride]
    out = struct.pack('>I', len(d[16:20])) # placeholder
    def chunk(typ, data):
        c = struct.pack('>I', len(data)) + typ + data
        return c + struct.pack('>I', zlib.crc32(typ + data) & 0xffffffff)
    ihdr = bytearray(chunks[0][1] if chunks[0][0] == b'IHDR' else d[16:33])
    ihdr[4:8] = struct.pack('>I', keep_h)
    png = d[:8] + chunk(b'IHDR', bytes(ihdr))
    for typ, data in chunks[1:]:
        if typ == b'IEND': break
        png += chunk(typ, data)
    png += chunk(b'IDAT', zlib.compress(raw, 9)) + chunk(b'IEND', b'')
    open(path, 'wb').write(png)
    print(f"cropped {path} -> {w}x{keep_h}")

if __name__ == "__main__":
    crop(sys.argv[1], int(sys.argv[2]))
