import glob
import os
import sys

# Ensure the package is visible (optional, depends on installation)
sys.path.append("/workspace/src")

from depth_anything_3.api import DepthAnything3

# --- CONFIGURATION ---
INPUT_DIR = "/workspace/datasets/small_batch/images/"
OUTPUT_DIR = "/workspace/output/instant_splat_giant"

# CRITICAL: You must use 'da3-giant' or 'da3nested-giant-large'.
# 'da3-large' DOES NOT support Gaussian Splatting.
MODEL_NAME = "da3-giant"


def run_feedforward_gs():
    # 1. Find images
    extensions = ["*.jpg", "*.jpeg", "*.png", "*.JPG", "*.PNG"]
    image_paths = []
    for ext in extensions:
        image_paths.extend(glob.glob(os.path.join(INPUT_DIR, ext)))

    image_paths.sort()

    if not image_paths:
        print(f"No images found in {INPUT_DIR}")
        return

    print(f"Found {len(image_paths)} images. Loading model {MODEL_NAME}...")

    # 2. Initialize Model
    # This will download the Giant model (approx 1.4B params)
    model = DepthAnything3(model_name=MODEL_NAME).to("cuda")

    # 3. Run Inference with Gaussian Splatting enabled
    print("Running Feed-Forward Gaussian Splatting...")

    prediction = model.inference(
        image=image_paths,
        export_dir=OUTPUT_DIR,
        # Export PLY (for viewers) and NPZ (data) and GLB (mesh/points)
        export_format="gs_ply",
        # CRITICAL: This enables the Gaussian Head
        infer_gs=True,
        # Recommended settings from docs
        align_to_input_ext_scale=True,
        ref_view_strategy="saddle_balanced",
        # Optional: Render a video of the splats immediately
        # export_format="gs_ply-gs_video",
    )

    print(f"✅ Success! Results saved to: {OUTPUT_DIR}")
    print(f"   Look for 'scene.ply' or similar .ply files.")
    print(f"   Upload the .ply file to https://superspl.at/ to view it.")


if __name__ == "__main__":
    run_feedforward_gs()
