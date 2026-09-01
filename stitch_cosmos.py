import os
import math
import numpy as np
from PIL import Image

def smooth_blend(arr1, arr2, overlap):
    """
    Blends two numpy image arrays horizontally over an overlap width
    using a smooth cosine S-curve transition.
    arr1: Left image (H, W1, C)
    arr2: Right image (H, W2, C)
    overlap: Number of pixels to overlap and crossfade
    """
    h, w1, _ = arr1.shape
    _, w2, _ = arr2.shape
    
    # Non-overlapping left part
    left_part = arr1[:, :w1 - overlap, :]
    
    # Overlapping blend region
    overlap_left = arr1[:, w1 - overlap:, :].astype(np.float32)
    overlap_right = arr2[:, :overlap, :].astype(np.float32)
    
    # Create smooth cosine transition weights: 0.0 at left, 1.0 at right
    t = np.linspace(0, 1, overlap, endpoint=True)[np.newaxis, :, np.newaxis]
    weights = (0.5 - 0.5 * np.cos(np.pi * t)).astype(np.float32)
    
    blended_overlap = (overlap_left * (1.0 - weights) + overlap_right * weights).astype(np.uint8)
    
    # Non-overlapping right part
    right_part = arr2[:, overlap:, :]
    
    return np.concatenate([left_part, blended_overlap, right_part], axis=1)

def make_truly_seamless(arr, wrap_overlap=280):
    """
    Blends the right edge into the left edge with a smooth cosine window,
    so that when repeating horizontally, the transition across x=0 and x=W
    is completely seamless with zero line or seam.
    """
    H, W, C = arr.shape
    K = wrap_overlap
    L = arr[:, :K, :].astype(np.float32)
    R = arr[:, W - K:, :].astype(np.float32)
    
    t = np.linspace(0, 1, K, endpoint=True)[np.newaxis, :, np.newaxis]
    alpha = (0.5 - 0.5 * np.cos(np.pi * t)).astype(np.float32)
    
    blended = (1.0 - alpha) * R + alpha * L
    middle = arr[:, K : W - K, :].astype(np.float32)
    
    return np.concatenate([blended, middle], axis=1).astype(np.uint8)

def process_panorama():
    base_dir = r"C:\Users\gurpr\.gemini\antigravity-ide\brain\077f5367-1aab-439d-9e17-d894ac96da0d"
    p1_path = os.path.join(base_dir, "stylized_cosmos_1_1788261408318.jpg")
    p2_path = os.path.join(base_dir, "stylized_cosmos_2_1788261432341.jpg")
    p3_path = os.path.join(base_dir, "stylized_cosmos_3_1788261454027.jpg")
    
    target_height = 768
    
    img1 = Image.open(p1_path).convert("RGB")
    img2 = Image.open(p2_path).convert("RGB")
    img3 = Image.open(p3_path).convert("RGB")
    
    def resize_h(img, h):
        w = int(round(img.width * (h / img.height)))
        return img.resize((w, h), Image.Resampling.LANCZOS)
    
    img1 = resize_h(img1, target_height)
    img2 = resize_h(img2, target_height)
    img3 = resize_h(img3, target_height)
    
    arr1 = np.array(img1)
    arr2 = np.array(img2)
    arr3 = np.array(img3)
    
    overlap = 260
    
    print(f"Stylized Panel 1 shape: {arr1.shape}")
    print(f"Stylized Panel 2 shape: {arr2.shape}")
    print(f"Stylized Panel 3 shape: {arr3.shape}")
    
    # 1. Stitch Panel 1 -> Panel 2
    stitched_12 = smooth_blend(arr1, arr2, overlap)
    print(f"Stitched 1-2 shape: {stitched_12.shape}")
    
    # 2. Stitch (1-2) -> Panel 3
    stitched_123 = smooth_blend(stitched_12, arr3, overlap)
    print(f"Stitched 1-2-3 shape: {stitched_123.shape}")
    
    # 3. Create zero-seam wrap-around horizontal loop
    seamless_panorama = make_truly_seamless(stitched_123, wrap_overlap=280)
    print(f"Final seamless panorama shape: {seamless_panorama.shape}")
    
    final_img = Image.fromarray(seamless_panorama)
    
    out_dir = r"c:\Users\gurpr\OneDrive\Desktop\Projects\Flutter\Work - Freelance\Games\dino_run_epochs\assets\images"
    out_path = os.path.join(out_dir, "cosmos_bg.jpg")
    
    final_img.save(out_path, quality=95, optimize=True)
    print(f"Saved stylized cosmos background to: {out_path}")
    
    pano_copy = os.path.join(out_dir, "cosmos_bg_panorama.jpg")
    final_img.save(pano_copy, quality=95, optimize=True)
    print(f"Saved panorama copy to: {pano_copy}")

if __name__ == "__main__":
    process_panorama()
