# Copyright (c) 2022, NVIDIA CORPORATION.  All rights reserved.
#
#  SPDX-FileCopyrightText: Copyright (c) 2022 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: MIT
# ... (copyright header)

from omni.isaac.kit import SimulationApp
import os
import argparse
import math
import numpy as np

# --- Argument Parsing ---
parser = argparse.ArgumentParser("Local Asset Dataset Generator")
parser.add_argument("--headless", action="store_true", help="Launch script in headless mode.")
parser.add_argument("--height", type=int, default=512, help="Height of the output image")
parser.add_argument("--width", type=int, default=512, help="Width of the output image")
parser.add_argument("--num_frames", type=int, default=1000, help="Number of frames to record")
parser.add_argument("--asset_dir", type=str, default="/home/guyb/isaac-headless/data/assets", help="Root directory containing class subfolders of .usdz assets")
parser.add_argument("--data_dir", type=str, default=os.getcwd() + "/local_asset_output", help="Location where data will be output")

args, unknown_args = parser.parse_known_args()

# --- Simulation Setup ---
CONFIG = {
    "renderer": "RayTracedLighting",
    "headless": args.headless,
    "width": args.width,
    "height": args.height,
}
simulation_app = SimulationApp(launch_config=CONFIG)

import random
import carb
import omni.usd
from pxr import Gf, UsdGeom
from isaacsim.core.utils.stage import get_current_stage, add_reference_to_stage
import omni.replicator.core as rep
from isaacsim.core.utils.bounds import compute_combined_aabb, create_bbox_cache
from isaacsim.core.utils.semantics import add_update_semantics

# Increase subframes for better moving-object rendering
rep.settings.carb_settings("/omni/replicator/RTSubframes", 4)

# --- Constants ---
TARGET_SIZES = {'car': 3.0, 'person': 1.7}
DEFAULT_SIZE = 1.0


# --- Helper Functions ---
def find_categorized_usdz_files(root_dir):
    categorized_files = []
    if not os.path.isdir(root_dir):
        carb.log_error(f"Asset root directory not found at: {root_dir}")
        return categorized_files

    for category in os.listdir(root_dir):
        category_path = os.path.join(root_dir, category)
        if os.path.isdir(category_path):
            for file in os.listdir(category_path):
                if file.lower().endswith(".usdz"):
                    full_path = os.path.join(category_path, file)
                    categorized_files.append((category.lower(), full_path))
    return categorized_files

def random_point_on_hemisphere(min_radius, max_radius):
    radius = random.uniform(min_radius, max_radius)
    phi = random.uniform(0, math.pi)
    theta = random.uniform(0, 2 * math.pi)
    x = radius * math.sin(phi) * math.cos(theta)
    y = radius * math.sin(phi) * math.sin(theta)
    z = abs(radius * math.cos(phi))
    return x, y, z

def generate_points_on_hemisphere(min_radius, max_radius, num_points):
    return [random_point_on_hemisphere(min_radius, max_radius) for _ in range(num_points)]

def run_orchestrator(output_dir, total_frames):
    """Starts and manages the Replicator pipeline, now with a progress indicator."""
    
    # The KittiWriter creates a specific subdirectory structure
    rgb_output_path = os.path.join(output_dir, "Camera", "rgb")
    
    # Ensure the directory exists before we start monitoring it
    os.makedirs(rgb_output_path, exist_ok=True)
    
    last_frame_count = -1

    print(f"\nStarting data generation for {total_frames} frames...")
    rep.orchestrator.run()
    while rep.orchestrator.get_is_started():
        simulation_app.update()
        
        # Check the number of files in the output directory
        try:
            # Only count .png files to be specific
            current_frame_count = len([name for name in os.listdir(rgb_output_path) if name.endswith(".png")])
            # Only print an update if a new frame has been saved
            if current_frame_count > last_frame_count:
                # Use '\r' to return to the beginning of the line and overwrite it
                print(f"\r  -> Progress: {current_frame_count}/{total_frames} frames generated...", end="")
                last_frame_count = current_frame_count
        except FileNotFoundError:
            # The directory might not be created on the very first frame, so we pass
            pass

    # Print a final newline to move past the progress indicator line
    print() 
    rep.BackendDispatch.wait_until_done()
    rep.orchestrator.stop()
    print("Data generation complete.")

# --- Main Logic ---
def main():
    stage = get_current_stage()
    bbox_cache = create_bbox_cache()
    
    # --- Scene Setup (Done Once) ---
    rep.create.plane(scale=(2000, 2000, 1), visible=True, name="GroundPlane")
    rep.create.light(light_type="Distant", name="Sun", intensity=10000, rotation=(-75, -45, 0))
    rep.create.light(light_type="Dome", name="Sky", intensity=2000, color=(0.8, 0.9, 1.0))

    for _ in range(50):
        simulation_app.update()

    # --- Asset Loading and Normalization (Done Once) ---
    categorized_assets = find_categorized_usdz_files(args.asset_dir)
    if not categorized_assets:
        return

    parent_containers = []
    for i, (asset_type, usdz_path) in enumerate(categorized_assets):
        try:
            parent_prim_path = f"/World/Asset_Container_{i}"
            container_prim = stage.DefinePrim(parent_prim_path, "Xform")

            # Add semantics to the parent container prim using the core API
            add_update_semantics(container_prim, asset_type)

            model_prim_path = f"{parent_prim_path}/model"
            add_reference_to_stage(usd_path=usdz_path, prim_path=model_prim_path)
            simulation_app.update()
            
            model_prim = stage.GetPrimAtPath(model_prim_path)
            model_xform = UsdGeom.Xformable(model_prim)
            
            # Apply a one-time corrective rotation to convert from Y-up to Z-up
            model_xform.AddRotateXOp().Set(90.0)
            simulation_app.update()

            bounds = compute_combined_aabb(bbox_cache=bbox_cache, prim_paths=[model_prim_path])
            size = bounds[3:6] - bounds[0:3]

            if all(s > 0.001 for s in size):
                # Apply scale normalization
                largest_dimension = max(size)
                desired_size = TARGET_SIZES.get(asset_type, DEFAULT_SIZE)
                scale_factor = desired_size / largest_dimension
                model_xform.AddScaleOp().Set(Gf.Vec3f(scale_factor, scale_factor, scale_factor))
                simulation_app.update()

                # Apply final pivot correction
                final_bounds = compute_combined_aabb(bbox_cache=bbox_cache, prim_paths=[model_prim_path])
                final_lowest_point_z = final_bounds[2]
                offset_vector = Gf.Vec3f(0, 0, -final_lowest_point_z)
                model_xform.AddTranslateOp().Set(offset_vector)
            else:
                carb.log_warn(f"Asset '{usdz_path}' has a zero or invalid bounding box. Skipping full normalization.")

            parent_containers.append(rep.get.prim_at_path(parent_prim_path))

        except Exception as e:
            carb.log_error(f"Could not process asset {usdz_path}. Error: {e}")
            import traceback
            traceback.print_exc()

    if not parent_containers:
        return

    # --- Per-Frame Randomization ---
    camera = rep.create.camera(clipping_range=(0.1, 1000000))
    camera_positions = generate_points_on_hemisphere(3.0, 8.0, args.num_frames * 2)

    with rep.trigger.on_frame(num_frames=args.num_frames):
        with camera:
            rep.modify.pose(position=rep.distribution.choice(camera_positions), look_at=(0, 0, 0))
        for container_handle in parent_containers:
            with container_handle:
                rep.modify.pose(
                    position=rep.distribution.uniform((-3.0, -3.0, 0.0), (3.0, 3.0, 0.0)),
                    rotation=rep.distribution.uniform((0, 0, -180), (0, 0, 180))
                )

    # --- Data Writing ---
    writer = rep.WriterRegistry.get("KittiWriter")
    writer.initialize(output_dir=args.data_dir, omit_semantic_type=True)
                      
    render_product = rep.create.render_product(camera, (args.width, args.height))
    writer.attach(render_product)

    print(f"\nStarting data generation for {args.num_frames} frames...")
    run_orchestrator(args.data_dir, args.num_frames)


if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        carb.log_error(f"An exception occurred during execution: {e}")
        import traceback
        traceback.print_exc()
    finally:
        if args.headless:
            simulation_app.close()
        else:
            print("\nGUI mode: Application will remain open for inspection.")
            while simulation_app.is_running():
                simulation_app.update()
