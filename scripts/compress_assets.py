import os
import subprocess
import sys
from PIL import Image

def get_size_kb(path):
    return os.path.getsize(path) / 1024.0

def compress_png(path):
    print(f"[*] Optimizing image: {path}")
    orig_size = get_size_kb(path)
    temp_path = path + ".tmp.png"
    try:
        # Open the image
        with Image.open(path) as img:
            # Save it with optimize=True and compression level 6 (standard)
            img.save(temp_path, optimize=True, compress_level=6)
        
        new_size = get_size_kb(temp_path)
        if new_size < orig_size:
            os.replace(temp_path, path)
            saved = orig_size - new_size
            saved_pct = (saved / orig_size) * 100
            print(f"    - Original: {orig_size:.2f} KB")
            print(f"    - Optimized: {new_size:.2f} KB")
            print(f"    - Saved: {saved:.2f} KB ({saved_pct:.1f}%)\n")
            return orig_size, new_size
        else:
            print("    - Optimized version was not smaller; keeping original.\n")
            os.remove(temp_path)
            return orig_size, orig_size
    except Exception as e:
        print(f"    [!] Error optimizing image: {e}\n")
        if os.path.exists(temp_path):
            os.remove(temp_path)
        return orig_size, orig_size


def compress_mp4(path):
    print(f"[*] Compressing video: {path}")
    orig_size = get_size_kb(path)
    temp_path = path + ".tmp.mp4"
    
    # ffmpeg settings for high-quality, lightweight mobile output
    # crf 28 is the sweet spot for clean mobile streaming without perceptual visual noise
    cmd = [
        "ffmpeg", "-y",
        "-i", path,
        "-vcodec", "libx264",
        "-crf", "28",
        "-preset", "medium",
        "-acodec", "aac",
        "-b:a", "128k",
        temp_path
    ]
    
    try:
        # Run ffmpeg process
        result = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=True)
        
        if os.path.exists(temp_path):
            new_size = get_size_kb(temp_path)
            if new_size < orig_size:
                # Replace original with the compressed version
                os.replace(temp_path, path)
                saved = orig_size - new_size
                saved_pct = (saved / orig_size) * 100
                print(f"    - Original: {orig_size:.2f} KB")
                print(f"    - Compressed: {new_size:.2f} KB")
                print(f"    - Saved: {saved:.2f} KB ({saved_pct:.1f}%)\n")
                return orig_size, new_size
            else:
                print("    - Compressed version was not smaller; keeping original.\n")
                os.remove(temp_path)
                return orig_size, orig_size
        else:
            print("    [!] Error: Temp compressed file was not generated.\n")
            return orig_size, orig_size
            
    except subprocess.CalledProcessError as e:
        print(f"    [!] ffmpeg failed with error: {e.stderr.decode('utf-8', errors='ignore')}\n")
        if os.path.exists(temp_path):
            os.remove(temp_path)
        return orig_size, orig_size
    except Exception as e:
        print(f"    [!] Error compressing video: {e}\n")
        if os.path.exists(temp_path):
            os.remove(temp_path)
        return orig_size, orig_size

def main():
    assets_dir = "assets"
    if not os.path.exists(assets_dir):
        print(f"[!] assets directory not found at: {os.path.abspath(assets_dir)}")
        sys.exit(1)
        
    print("=" * 60)
    print("         OLITUN ASSET COMPRESSION PIPELINE")
    print("=" * 60)
    
    total_orig_img = 0
    total_new_img = 0
    total_orig_vid = 0
    total_new_vid = 0
    
    # Process images
    images_path = os.path.join(assets_dir, "images")
    if os.path.exists(images_path):
        print("\n--- Processing Images ---")
        for root, _, files in os.walk(images_path):
            for file in files:
                if file.lower().endswith(".png"):
                    path = os.path.join(root, file)
                    orig, new = compress_png(path)
                    total_orig_img += orig
                    total_new_img += new
                    
    # Process videos
    videos_path = os.path.join(assets_dir, "videos")
    if os.path.exists(videos_path):
        print("\n--- Processing Videos ---")
        for root, _, files in os.walk(videos_path):
            for file in files:
                if file.lower().endswith(".mp4"):
                    path = os.path.join(root, file)
                    orig, new = compress_mp4(path)
                    total_orig_vid += orig
                    total_new_vid += new
                    
    print("=" * 60)
    print("                     SUMMARY")
    print("=" * 60)
    saved_img = total_orig_img - total_new_img
    saved_vid = total_orig_vid - total_new_vid
    
    print(f"Images: Original {total_orig_img:.2f} KB | Optimized {total_new_img:.2f} KB | Saved {saved_img:.2f} KB")
    print(f"Videos: Original {total_orig_vid:.2f} KB | Compressed {total_new_vid:.2f} KB | Saved {saved_vid:.2f} KB")
    print(f"Total Disk Footprint Savings: {(saved_img + saved_vid) / 1024.0:.2f} MB")
    print("=" * 60)

if __name__ == "__main__":
    main()
