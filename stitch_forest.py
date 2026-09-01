import os
import math
import numpy as np
from PIL import Image

def smooth_blend(arr1, arr2, overlap):
    h, w1, _ = arr1.shape
    _, w2, _ = arr2.shape
    
    left_part = arr1[:, :w1 - overlap, :]
    
    overlap_left = arr1[:, w1 - overlap:, :].astype(np.float32)
    overlap_right = arr2[:, :overlap, :].astype(np.float32)
    
    t = np.linspace(0, 1, overlap, endpoint=True)[np.newaxis, :, np.newaxis]
    weights = (0.5 - 0.5 * np.cos(np.pi * t)).astype(np.float32)
    
    blended_overlap = (overlap_left * (1.0 - weights) + overlap_right * weights).astype(np.uint8)
    right_part = arr2[:, overlap:, :]
    
    return np.concatenate([left_part, blended_overlap, right_part], axis=1)

def make_truly_seamless(arr, wrap_overlap=280):
    H, W, C = arr.shape
    K = wrap_overlap
    L = arr[:, :K, :].astype(np.float32)
    R = arr[:, W - K:, :].astype(np.float32)
    
    t = np.linspace(0, 1, K, endpoint=True)[np.newaxis, :, np.newaxis]
    alpha = (0.5 - 0.5 * np.cos(np.pi * t)).astype(np.float32)
    
    blended = (1.0 - alpha) * R + alpha * L
    middle = arr[:, K : W - K, :].astype(np.float32)
    
    return np.concatenate([blended, middle], axis=1).astype(np.uint8)

def process_forest_panorama():
    base_dir = r"C:\Users\gurpr\.gemini\antigravity-ide\brain\077f5367-1aab-439d-9e17-d894ac96da0d"
    p1_path = os.path.join(base_dir, "forest_panel_1_1788280156491.jpg")
    p2_path = os.path.join(base_dir, "forest_panel_2_1788280177887.jpg")
    p3_path = os.path.join(base_dir, "forest_panel_3_alt_1788280219272.jpg")
    
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
    
    print(f"Panel 1 shape: {arr1.shape}")
    print(f"Panel 2 shape: {arr2.shape}")
    print(f"Panel 3 shape: {arr3.shape}")
    
    # 1. Stitch 1 -> 2
    stitched_12 = smooth_blend(arr1, arr2, overlap)
    # 2. Stitch 12 -> 3
    stitched_123 = smooth_blend(stitched_12, arr3, overlap)
    print(f"Stitched 3 panels shape: {stitched_123.shape}")
    
    # 3. Make wrap-around seamless
    seamless_forest = make_truly_seamless(stitched_123, wrap_overlap=280)
    print(f"Final seamless forest panorama shape: {seamless_forest.shape}")
    
    final_img = Image.fromarray(seamless_forest)
    
    out_dir = r"c:\Users\gurpr\OneDrive\Desktop\Projects\Flutter\Work - Freelance\Games\dino_run_epochs\assets\images"
    out_path = os.path.join(out_dir, "forest_bg.jpg")
    
    final_img.save(out_path, quality=95, optimize=True)
    print(f"Saved Forest background to: {out_path}")
    
    pano_copy = os.path.join(out_dir, "forest_bg_panorama.jpg")
    final_img.save(pano_copy, quality=95, optimize=True)
    print(f"Saved panorama copy to: {pano_copy}")

if __name__ == "__main__":
    process_forest_panorama()
