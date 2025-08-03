#!/bin/bash

# ==============================================================================
#                 Isaac Sim Local Asset Data Generator
# ==============================================================================
#
# This script launches randomize.py to generate a Kitti dataset inside a unique,
# timestamped directory, and then converts it to the YOLO format.
#
# Usage:
#   ./generate_data.sh [--headless] [--num_frames=100] [--no-convert]
#
# ==============================================================================

# --- Function to log errors and exit ---
log_error_and_exit() {
    echo -e "\n\033[0;31mError: $1\033[0m" >&2
    exit 1
}

# --- Load Configuration from .env file ---
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
ENV_FILE="$SCRIPT_DIR/.env"

if [ -f "$ENV_FILE" ]; then
    set -a
    source "$ENV_FILE"
    set +a
else
    log_error_and_exit "Configuration file '.env' not found. Please copy '.env.example' to '.env' and fill in your paths."
fi

# --- Validate Configuration ---
if [ -z "$ISAAC_SIM_PATH" ]; then
    log_error_and_exit "ISAAC_SIM_PATH is not set in your .env file."
fi
if [ ! -d "$ISAAC_SIM_PATH" ]; then
    log_error_and_exit "Isaac Sim path not found at: $ISAAC_SIM_PATH"
fi
if [ -z "$PROJECT_ROOT_PATH" ]; then
    log_error_and_exit "PROJECT_ROOT_PATH is not set in your .env file."
fi
if [ ! -d "$PROJECT_ROOT_PATH" ]; then
    log_error_and_exit "Project root path not found at: $PROJECT_ROOT_PATH"
fi

# --- Define Base Paths ---
RANDOMIZE_SCRIPT_PATH="$PROJECT_ROOT_PATH/randomize.py"
CONVERT_SCRIPT_PATH="$PROJECT_ROOT_PATH/kitti_to_yolo.py"
ASSET_DIR="$PROJECT_ROOT_PATH/assets"
# Get the base output directory from .env or default it
BASE_OUTPUT_DIR="${OUTPUT_DIR:-$PROJECT_ROOT_PATH/output}"


# --- Default Argument Values ---
HEADLESS_FLAG=""
NUM_FRAMES=10
CONVERT_TO_YOLO=true


# --- Parse Command-Line Arguments ---
for arg in "$@"
do
    case $arg in
        --headless)
        HEADLESS_FLAG="--headless"
        shift
        ;;
        --num_frames=*)
        NUM_FRAMES="${arg#*=}"
        shift
        ;;
        --no-convert)
        CONVERT_TO_YOLO=false
        shift
        ;;
    esac
done

# --- MODIFICATION: Create a unique subdirectory for this run ---
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
FINAL_OUTPUT_DIR="$BASE_OUTPUT_DIR/run_$TIMESTAMP"

# Create the unique output directory before running anything
mkdir -p "$FINAL_OUTPUT_DIR" || log_error_and_exit "Could not create output directory: $FINAL_OUTPUT_DIR"


# --- Step 1: Data Generation ---
cd "$ISAAC_SIM_PATH" || log_error_and_exit "Could not change directory to ISAAC_SIM_PATH: $ISAAC_SIM_PATH"

echo "--- Starting Data Generation ---"
echo "Project Root: ${PROJECT_ROOT_PATH}"
echo "Headless Mode: ${HEADLESS_FLAG:--no (GUI mode)}"
echo "Number of Frames: ${NUM_FRAMES}"
echo "Asset Directory: ${ASSET_DIR}"
echo "Output Directory: ${FINAL_OUTPUT_DIR}"
echo "--------------------------------"

# Execute the Isaac Sim python script
./python.sh "$RANDOMIZE_SCRIPT_PATH" \
    --height 512 \
    --width 512 \
    --num_frames "$NUM_FRAMES" \
    --asset_dir "$ASSET_DIR" \
    --data_dir "$FINAL_OUTPUT_DIR" \
    $HEADLESS_FLAG

echo "--- Data Generation Script Finished ---"


# --- Step 2: YOLO Conversion (Conditional) ---
if [ "$CONVERT_TO_YOLO" = true ]; then
    echo -e "\n--- Starting Kitti to YOLO Conversion ---"
    
    if [ ! -f "$CONVERT_SCRIPT_PATH" ]; then
        log_error_and_exit "Converter script not found at: $CONVERT_SCRIPT_PATH"
    fi
    
    # Run the conversion script
    ./python.sh "$CONVERT_SCRIPT_PATH" --input_dir "$FINAL_OUTPUT_DIR"
    
    echo "--- YOLO Conversion Finished ---"
else
    echo -e "\n--- Skipping YOLO Conversion as requested. ---"
fi
