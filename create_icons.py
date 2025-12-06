#!/usr/bin/env python3
import struct
import zlib
import os

def create_png(filename, size, color_r, color_g, color_b):
    """Create a simple colored PNG file."""
    
    width = size
    height = size
    
    # PNG signature
    png_signature = b'\x89PNG\r\n\x1a\n'
    
    # IHDR chunk
    ihdr_data = struct.pack('>IIBBBBB', width, height, 8, 2, 0, 0, 0)  # 8-bit RGB
    ihdr_crc = zlib.crc32(b'IHDR' + ihdr_data) & 0xffffffff
    ihdr_chunk = struct.pack('>I', len(ihdr_data)) + b'IHDR' + ihdr_data + struct.pack('>I', ihdr_crc)
    
    # IDAT chunk (image data)
    raw_data = b''
    for y in range(height):
        raw_data += b'\x00'  # filter type none
        for x in range(width):
            raw_data += struct.pack('BBB', color_r, color_g, color_b)
    
    idat_data = zlib.compress(raw_data)
    idat_crc = zlib.crc32(b'IDAT' + idat_data) & 0xffffffff
    idat_chunk = struct.pack('>I', len(idat_data)) + b'IDAT' + idat_data + struct.pack('>I', idat_crc)
    
    # IEND chunk
    iend_crc = zlib.crc32(b'IEND') & 0xffffffff
    iend_chunk = struct.pack('>I', 0) + b'IEND' + struct.pack('>I', iend_crc)
    
    # Combine all chunks
    png_data = png_signature + ihdr_chunk + idat_chunk + iend_chunk
    
    # Ensure directory exists
    os.makedirs(os.path.dirname(filename), exist_ok=True)
    
    # Write PNG file
    with open(filename, 'wb') as f:
        f.write(png_data)
    
    return filename

# Define colors for each flavor
flavors = {
    'customer': (255, 107, 107),   # Red
    'barber': (78, 205, 196),      # Teal
    'admin': (149, 225, 211)       # Mint
}

densities = {
    'mdpi': 48,
    'hdpi': 72,
    'xhdpi': 96,
    'xxhdpi': 144,
    'xxxhdpi': 192
}

base_path = r'd:\FlutterProjects\bookyourbarber\newbarberproject\android\app\src'

for flavor, (r, g, b) in flavors.items():
    for density, size in densities.items():
        dir_path = os.path.join(base_path, flavor, 'res', f'mipmap-{density}')
        icon_path = os.path.join(dir_path, 'ic_launcher.png')
        created = create_png(icon_path, size, r, g, b)
        print(f'Created: {created}')

print('\nAll placeholder icons created successfully!')
