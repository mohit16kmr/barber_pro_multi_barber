#!/usr/bin/env python3
"""Generate app icons for BarberPro"""
from PIL import Image, ImageDraw
import os

def create_barber_icon(size):
    """Create a barber shop icon with red, white, blue stripes"""
    # Create image with white background
    img = Image.new('RGBA', (size, size), (255, 255, 255, 255))
    draw = ImageDraw.Draw(img)
    
    # Draw rounded rectangle background
    margin = size // 10
    draw.rounded_rectangle(
        [(margin, margin), (size - margin, size - margin)],
        radius=size // 8,
        fill=(255, 255, 255),
        outline=(0, 0, 0, 255),
        width=max(1, size // 100)
    )
    
    # Draw vertical stripes (barber pole style)
    stripe_width = size // 15
    stripe_x = margin + size // 20
    
    colors = [(211, 47, 47), (255, 255, 255), (25, 118, 210)]  # Red, White, Blue
    
    for i, color in enumerate(colors):
        x = stripe_x + i * stripe_width
        if x + stripe_width <= size - margin:
            draw.rectangle(
                [(x, margin), (x + stripe_width, size - margin)],
                fill=color
            )
    
    # Draw scissors in center
    center_x, center_y = size // 2, size // 2
    scissor_size = size // 6
    
    # Left scissor blade (upper)
    draw.ellipse(
        [center_x - scissor_size, center_y - scissor_size // 2,
         center_x - scissor_size // 2, center_y + scissor_size // 2],
        fill=(0, 0, 0)
    )
    
    # Right scissor blade (upper)
    draw.ellipse(
        [center_x + scissor_size // 2, center_y - scissor_size // 2,
         center_x + scissor_size, center_y + scissor_size // 2],
        fill=(0, 0, 0)
    )
    
    return img

# Icon sizes for different densities
sizes = {
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192,
}

base_path = 'd:/FlutterProjects/bookyourbarber/newbarberproject/android/app/src/main/res'

for folder, size in sizes.items():
    icon = create_barber_icon(size)
    path = os.path.join(base_path, folder, 'ic_launcher.png')
    icon.save(path)
    print(f"✅ Generated {path}")

print("\n✅ All icons generated successfully!")
