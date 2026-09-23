import cv2
import numpy as np
import os
import glob
import sys

def find_horizon(img):
    # Convert to grayscale
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    height, width = gray.shape
    
    # Focus on the lower half/third
    lower_half = gray[height//2:height, :]
    
    # Edge detection
    edges = cv2.Canny(lower_half, 50, 150, apertureSize=3)
    
    # Hough line transform
    lines = cv2.HoughLinesP(edges, 1, np.pi/180, threshold=100, minLineLength=width//4, maxLineGap=20)
    
    if lines is not None:
        # Find the longest horizontal line
        longest = 0
        best_y = 0
        for line in lines:
            x1, y1, x2, y2 = line[0]
            if abs(y1 - y2) < 20: # Roughly horizontal
                length = abs(x1 - x2)
                if length > longest:
                    longest = length
                    best_y = (y1 + y2) // 2 + height // 2
        if longest > 0:
            return best_y
    
    # Fallback: Just return a generic lower-third value
    return height - (height // 3)

def compute_color_delta(img1, img2, blend_width=100):
    # Right edge of img1 and left edge of img2
    edge1 = img1[:, -blend_width:]
    edge2 = img2[:, :blend_width]
    
    mean1 = np.mean(edge1, axis=(0, 1))
    mean2 = np.mean(edge2, axis=(0, 1))
    
    # Delta E approximation (just Euclidean distance in RGB/BGR)
    delta = np.linalg.norm(mean1 - mean2)
    return delta

def stitch_segments(biome, images, blend_width=100):
    if not images:
        return
    
    h, w, c = images[0].shape
    
    # Cross fade between adjacent images
    # Total width = w + (w - blend) * (len(images) - 1)
    out_w = w + (w - blend_width) * (len(images) - 1)
    stitched = np.zeros((h, out_w, c), dtype=np.uint8)
    
    current_x = 0
    for i, img in enumerate(images):
        if i == 0:
            stitched[:, current_x:current_x + w] = img
            current_x += w - blend_width
        else:
            # Create alpha mask for blending
            alpha = np.linspace(0, 1, blend_width).reshape(1, blend_width, 1)
            alpha = np.repeat(alpha, h, axis=0)
            
            # Blend region
            blend_region1 = stitched[:, current_x:current_x + blend_width]
            blend_region2 = img[:, :blend_width]
            
            blended = blend_region1 * (1 - alpha) + blend_region2 * alpha
            stitched[:, current_x:current_x + blend_width] = blended
            
            # Paste the rest
            stitched[:, current_x + blend_width:current_x + w] = img[:, blend_width:]
            current_x += w - blend_width
            
    cv2.imwrite(f'assets/images/biomes/{biome}_stitched_preview.jpg', stitched)

def verify_biome(biome, artifact_dir):
    print(f"--- Biome: {biome} ---")
    images = []
    horizons = []
    for i in range(1, 5):
        pattern = os.path.join(artifact_dir, f"{biome}_seg{i}_*.jpg")
        matches = glob.glob(pattern)
        if not matches:
            print(f"Segment {i} not found!")
            return False
            
        img_path = matches[-1]
        img = cv2.imread(img_path)
        if img is None:
            print(f"Failed to read {img_path}")
            return False
            
        images.append(img)
        horizon = find_horizon(img)
        horizons.append(horizon)
        
        print(f"Seg {i}: {img.shape}, Horizon row: {horizon}")
        
    deltas = []
    for i in range(3):
        delta = compute_color_delta(images[i], images[i+1])
        deltas.append(delta)
        print(f"Color delta Seg {i+1}->{i+2}: {delta:.2f}")
        
    loop_delta = compute_color_delta(images[3], images[0])
    deltas.append(loop_delta)
    print(f"Color delta Seg 4->1 (Loop): {loop_delta:.2f}")
    
    stitch_segments(biome, images)
    print(f"Stitched preview saved for {biome}.")
    return True

if __name__ == "__main__":
    artifact_dir = sys.argv[1]
    verify_biome("desert", artifact_dir)
