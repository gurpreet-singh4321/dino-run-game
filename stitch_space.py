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

def make_truly_seamless(arr, wrap_overlap=240):
    H, W, C = arr.shape
    K = wrap_overlap
    L = arr[:, :K, :].astype(np.float32)
    R = arr[:, W - K:, :].astype(np.float32)
    
    t = np.linspace(0, 1, K, endpoint=True)[np.newaxis, :, np.newaxis]
    alpha = (0.5 - 0.5 * np.cos(np.pi * t)).astype(np.float32)
    
    blended = (1.0 - alpha) * R + alpha * L
    middle = arr[:, K : W - K, :].astype(np.float32)
    
    return np.concatenate([blended, middle], axis=1).astype(np.uint8)

def process_one_earth_space_panorama():
    base_dir = r"C:\Users\gurpr\.gemini\antigravity-ide\brain\077f5367-1aab-439d-9e17-d894ac96da0d"
    
    # Left: Pure deep space with spiral galaxy & nebulae (No Earth)
    p_left = os.path.join(base_dir, "deep_space_left_1788289614521.jpg")
    # Center: Single magnificent Earth orbit shot
    p_center = os.path.join(base_dir, "flat_orbit_2_1788284533857.jpg")
    # Right: Pure deep space with cosmic dust & stars (No Earth)
    p_right = os.path.join(base_dir, "stylized_cosmos_3_1788261454027.jpg")
    
    target_height = 768
    
    def resize_h(img, h):
        w = int(round(img.width * (h / img.height)))
        return img.resize((w, h), Image.Resampling.LANCZOS)
    
    img_l = resize_h(Image.open(p_left).convert("RGB"), target_height)
    img_c = resize_h(Image.open(p_center).convert("RGB"), target_height)
    img_r = resize_h(Image.open(p_right).convert("RGB"), target_height)
    
    arr_l = np.array(img_l).astype(np.float32)
    arr_c = np.array(img_c).astype(np.float32)
    arr_r = np.array(img_r).astype(np.float32)
    
    H, W, C = arr_c.shape
    
    # Natural curvature fade on Earth flanks so it curves into cosmic void
    earth_mask = np.ones((H, W, 1), dtype=np.float32)
    fade_w = 380
    
    t_left = np.linspace(0, 1, fade_w)
    left_alpha = (0.5 - 0.5 * np.cos(np.pi * t_left))[np.newaxis, :, np.newaxis]
    earth_mask[:, :fade_w, :] *= left_alpha
    
    t_right = np.linspace(1, 0, fade_w)
    right_alpha = (0.5 - 0.5 * np.cos(np.pi * t_right))[np.newaxis, :, np.newaxis]
    earth_mask[:, W - fade_w:, :] *= right_alpha
    
    bg_for_center = np.zeros_like(arr_c)
    bg_for_center[:, :W//2, :] = arr_l[:, W//2:, :]
    bg_for_center[:, W//2:, :] = arr_r[:, :W//2, :]
    
    curved_earth_center = (arr_c * earth_mask + bg_for_center * (1.0 - earth_mask)).astype(np.uint8)
    
    overlap = 240
    stitched_12 = smooth_blend(arr_l.astype(np.uint8), curved_earth_center, overlap)
    stitched_all = smooth_blend(stitched_12, arr_r.astype(np.uint8), overlap)
    seamless_space = make_truly_seamless(stitched_all, wrap_overlap=240)
    
    out_dir = r"c:\Users\gurpr\OneDrive\Desktop\Projects\Flutter\Work - Freelance\Games\dino_run_epochs\assets\images"
    out_path = os.path.join(out_dir, "space_bg.jpg")
    
    final_img = Image.fromarray(seamless_space)
    final_img.save(out_path, quality=95, optimize=True)
    print(f"Saved single Earth Space Mode background to: {out_path}")
    
    pano_copy = os.path.join(out_dir, "space_bg_panorama.jpg")
    final_img.save(pano_copy, quality=95, optimize=True)
    print(f"Saved panorama copy to: {pano_copy}")

if __name__ == "__main__":
    process_one_earth_space_panorama()
