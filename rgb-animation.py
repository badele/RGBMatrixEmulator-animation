#!/usr/bin/env python
"""
Halloween GIF Animation
Displays an animated GIF on the RGB LED matrix by cycling through all frames
"""

import time
import sys
import os
import argparse
import random
from PIL import Image

# Configure pygame environment before importing RGBMatrixEmulator
os.environ["PYGAME_HIDE_SUPPORT_PROMPT"] = "1"  # Hide pygame welcome message

from RGBMatrixEmulator import RGBMatrix, RGBMatrixOptions


def load_gif_frames(gif_path):
    """
    Load all frames from an animated GIF
    Returns a list of PIL Image objects and their durations
    """

    frames = []
    durations = []

    try:
        img = Image.open(gif_path)

        # Extract all frames from the GIF
        for frame_num in range(img.n_frames):
            img.seek(frame_num)

            duration = img.info.get("duration", 100)
            durations.append(duration / 1000.0)

            frame = img.copy().convert("RGB")
            frames.append(frame)

        print(f"Loaded {len(frames)} frames from {gif_path}")

    except Exception as e:
        print(f"Error loading GIF: {e}")
        sys.exit(1)

    return frames, durations


def load_and_process_gifs(matrix, gif_files):
    """Load and process all frames from GIF files"""

    all_frames = []
    all_durations = []

    for gif_file in gif_files:
        frames, durations = load_gif_frames(gif_file)
        if not frames:
            sys.exit(f"Error: No frames loaded from {gif_file}")
        all_frames.extend(frames)
        all_durations.extend(durations)

    # Resize all frames to fit the matrix while maintaining aspect ratio
    processed_frames = []
    for frame in all_frames:
        # Create a copy to avoid modifying the original
        img = frame.copy()

        # Calculate scaling to fit within matrix dimensions
        img.thumbnail((matrix.width, matrix.height), Image.LANCZOS)

        # Create a black background
        centered_img = Image.new("RGB", (matrix.width, matrix.height), (0, 0, 0))

        # Calculate position to center the image
        x_offset = (matrix.width - img.width) // 2
        y_offset = (matrix.height - img.height) // 2

        # Paste the resized image onto the centered background
        centered_img.paste(img, (x_offset, y_offset))

        processed_frames.append(centered_img)

    return processed_frames, all_durations


def run_animation(matrix, gif_files, shuffle=False):
    """Run the GIF animation on the matrix"""

    for gif_file in gif_files:
        if not os.path.exists(gif_file):
            sys.exit(f"Error: File '{gif_file}' not found")

    print(f"Loading {len(gif_files)} GIF file(s)...")
    print(f"🌐 Matrix size: {matrix.width}x{matrix.height}")

    if shuffle:
        print("Shuffle mode enabled - GIF files will be randomized after each cycle")

    # Configure pygame after first frame is displayed (pygame will be initialized by then)
    pygame_configured = False

    try:
        while True:
            # Shuffle the order of GIF files if requested
            current_gif_files = gif_files.copy()
            if shuffle:
                random.shuffle(current_gif_files)
                print(
                    f"Playing GIFs in order: {[os.path.basename(f) for f in current_gif_files]}"
                )

            # Load and process frames for current cycle
            processed_frames, all_durations = load_and_process_gifs(
                matrix, current_gif_files
            )

            print(f"Animating {len(processed_frames)} frames...")

            # Play all frames once
            for frame_idx in range(len(processed_frames)):
                # Display current frame
                matrix.SetImage(processed_frames[frame_idx])

                # Configure pygame after first frame (pygame is now initialized)
                if not pygame_configured:
                    import pygame

                    try:
                        pygame.mouse.set_visible(False)
                        pygame_configured = True
                    except:
                        pass  # Ignore if pygame not fully ready

                # Wait for the frame duration
                time.sleep(all_durations[frame_idx])

            # After playing all frames, loop back (and shuffle if needed)
            if shuffle:
                print("Cycle complete, reshuffling...")

    except KeyboardInterrupt:
        print("\nAnimation stopped by user")
        sys.exit(0)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Display animated GIF on RGB LED matrix"
    )
    parser.add_argument(
        "gif_files",
        nargs="*",
        help="Path(s) to GIF file(s) (default: halloween-1.gif)",
        default=None,
    )
    parser.add_argument(
        "--led-rows", type=int, default=32, help="Display rows (default: 32)"
    )
    parser.add_argument(
        "--led-cols", type=int, default=64, help="Panel columns (default: 64)"
    )
    parser.add_argument(
        "--pixel-size", type=int, default=16, help="Pixel Size (default: 16)"
    )
    parser.add_argument(
        "--led-brightness",
        type=int,
        default=100,
        help="Sets brightness level (default: 100)",
    )

    parser.add_argument(
        "--shuffle",
        action="store_true",
        help="Randomize GIF file order after each complete cycle",
    )

    args = parser.parse_args()

    if not args.gif_files or (args.gif_files and len(args.gif_files) == 0):
        print("Error: No GIF files specified")
        sys.exit(1)

    gif_files = args.gif_files

    # Configuration for the matrix
    options = RGBMatrixOptions()
    options.rows = args.led_rows
    options.cols = args.led_cols
    options.pixel_size = args.pixel_size
    options.brightness = args.led_brightness

    # Create matrix
    matrix = RGBMatrix(options=options)

    # Run the animation
    run_animation(matrix, gif_files, shuffle=args.shuffle)
