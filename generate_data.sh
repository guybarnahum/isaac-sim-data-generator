#!/bin/bash

# ==============================================================================
#                 Isaac Sim Local Asset Data Generator
# ==============================================================================
#
# This script launches the randomize.py script with the correct environment
# and arguments. It reads its configuration from a '.env' file in the same
# directory.
#
# Usage:
#   ./generate_data.sh [--headless] [--num_frames=100]
#
# ==============================================================================

# --- Function to log errors and exit ---
log_error_and_exit() {
    echo -e "\n\033[0;31mError: $1\033[0m" >&2
    exit 1
}

# --- Load Configuration from .env file ---
# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
ENV_FILE="$SCRIPT_DIR/.env"

if [ -f "$ENV_FILE" ]; then
    # Use 'set -a' to export all variables read from the .env file
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
    log_error_and_exit "Isaac Sim path not found at the location specified in your .env file: $ISAAC_SIM_PATH"
fi
if [ -z "$PROJECT_ROOT_PATH" ]; then
    log_error_and_exit "PROJECT_ROOT_PATH is not set in your .env file."
fi
if [ ! -d "$PROJECT_ROOT_PATH" ]; then
    log_error_and_exit "Project root path not found at the location specified in your .env file: $PROJECT_ROOT_PATH"
fi

# --- Define Final Paths ---
SCRIPT_PATH="$PROJECT_ROOT_PATH/randomize.py"
ASSET_DIR="$PROJECT_ROOT_PATH/assets"
# Use default output dir if not set in .env
FINAL_OUTPUT_DIR="${OUTPUT_DIR:-$PROJECT_ROOT_PATH/output}"


# --- Default Argument Values ---
HEADLESS_FLAG=""
NUM_FRAMES=10


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
    esac
done


# --- Execution ---
# Go to Isaac Sim directory to run ./python.sh
cd "$ISAAC_SIM_PATH" || log_error_and_exit "Could not change directory to ISAAC_SIM_PATH: $ISAAC_SIM_PATH"

echo "--- Starting Data Generation ---"
echo "Project Root: ${PROJECT_ROOT_PATH}"
echo "Headless Mode: ${HEADLESS_FLAG:--no (GUI mode)}"
echo "Number of Frames: ${NUM_FRAMES}"
echo "Asset Directory: ${ASSET_DIR}"
echo "Output Directory: ${FINAL_OUTPUT_DIR}"
echo "--------------------------------"

# Execute the python script with the correctly parsed arguments
./python.sh "$SCRIPT_PATH" \
    --height 512 \
    --width 512 \
    --num_frames "$NUM_FRAMES" \
    --asset_dir "$ASSET_DIR" \
    --data_dir "$FINAL_OUTPUT_DIR" \
    $HEADLESS_FLAG

echo "--- Data Generation Script Finished ---"


