#!/bin/bash

# --- Configuration ---
# Path where Isaac Sim is installed
ISAAC_SIM_PATH="/home/guyb/isaacsim"
# Path to your Python script
SCRIPT_PATH="/home/guyb/isaac-headless/data/randomize.py"
# Default output directory
OUTPUT_DIR="/home/guyb/isaac-headless/data/output"


# --- Default Argument Values ---
# Default to GUI mode (headless flag is not added)
HEADLESS_FLAG=""
# Default number of frames to generate
NUM_FRAMES=10


# --- Parse Command-Line Arguments ---
# This loop goes through all arguments passed to the script
for arg in "$@"
do
    case $arg in
        --headless)
        # If --headless is found, set the Python script's flag
        HEADLESS_FLAG="--headless"
        shift # Remove --headless from the list of arguments
        ;;
        --num_frames=*)
        # If --num_frames is found, extract its value
        NUM_FRAMES="${arg#*=}"
        shift # Remove --num_frames from the list of arguments
        ;;
    esac
done


# --- Execution ---
# Check if the Isaac Sim path exists
if [ ! -d "$ISAAC_SIM_PATH" ]; then
    echo "Error: Isaac Sim path not found at $ISAAC_SIM_PATH"
    exit 1
fi

# Go to Isaac Sim directory to run ./python.sh
cd "$ISAAC_SIM_PATH"

echo "--- Starting Data Generation ---"
echo "Headless Mode: ${HEADLESS_FLAG:--no (GUI mode)}"
echo "Number of Frames: ${NUM_FRAMES}"
echo "Output Directory: ${OUTPUT_DIR}"
echo "--------------------------------"

# Execute the python script with the correctly parsed arguments
# Note: The $HEADLESS_FLAG will be empty in GUI mode, so nothing is passed.
# In headless mode, it will expand to the string "--headless".
./python.sh "$SCRIPT_PATH" \
    --height 512 \
    --width 512 \
    --num_frames "$NUM_FRAMES" \
    --data_dir "$OUTPUT_DIR" \
    $HEADLESS_FLAG

echo "--- Data Generation Script Finished ---"
