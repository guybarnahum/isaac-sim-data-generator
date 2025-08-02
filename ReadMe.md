This script was adapted from an original NVIDIA working example, it has been significantly modified to remove external dependencies 
(like the Nucleus server) and to programmatically handle common issues in procedural content generation, such as asset scaling, 
orientation, and pivot point correction.

## Key Features ##

- Local Asset Loading: Loads .usdz files directly from a local directory structure, removing the need for an Omniverse Nucleus server.

- Asset Categorization: Automatically assigns a "class" to each asset based on the name of the subdirectory it's in (e.g., assets/car, assets/person).

- Automatic Y-up to Z-up Conversion: Applies a corrective rotation to all incoming assets, correctly orienting models authored in common Y-up coordinate systems (like Blender or Maya) for Isaac Sim's Z-up world.

- Class-Based Scale Normalization: Scales assets to a consistent, predefined size based on their category (e.g., all car assets are scaled to 3 meters).

- Robust Pivot Point Correction: Programmatically adjusts each asset's pivot point to ensure its base rests perfectly on the ground plane, regardless of how the model was originally authored.

- Realistic Lighting: Creates a bright, two-point "Sun and Sky" lighting setup for clear, day-lit scenes.

- Constrained Randomization: Randomizes asset positions and yaw (heading) only, ensuring they remain upright and realistically placed on the ground.

- Flexible Execution: Can be run in either GUI mode for scene inspection or headless mode for automated data generation, controlled via command-line arguments.

## Project Structure ##
```bash

.
├── assets/
│   ├── car/
│   │   ├── car_1.usdz
│   │   └── car_2.usdz
│   └── person/
│       ├── person_1.usdz
│       └── person_2.usdz
├── generate_data.sh
└── randomize.py

```

## Asset Location ##

To use this script, you must organize your .usdz asset files into subdirectories within the assets/ folder. The name of each subdirectory will be used as the class label for all assets within it.
Example: Place all car models in assets/car/ and all person models in assets/person/.
The script will automatically detect these categories and apply the corresponding scaling rules defined in randomize.py.

## Setup ##

Place the Scripts: Put randomize.py and generate_data.sh in a project directory (e.g., /home/user/isaac-project/).
Organize Assets: Create an assets directory in the same location and populate it with your categorized .usdz files as described above.
Configure Paths: Open generate_data.sh and randomize.py in a text editor and verify that the paths at the top of each file are correct for your system.
In generate_data.sh, ensure ISAAC_SIM_PATH points to your Isaac Sim installation directory.
In randomize.py, ensure the default value for --asset_dir points to your assets folder.

Make Executable: Grant execution permissions to the bash script:
```bash
chmod +x generate_data.sh
```

## Usage ##

The generate_data.sh script is the primary way to run the simulation. It accepts two optional command-line arguments.

### Running in GUI Mode (for Inspection) ###

To run the script and have the Isaac Sim application window remain open after the data is generated, simply run the script without any arguments. This is ideal for checking lighting, asset placement, and scale.

```bash
./generate_data.sh
```

You can also specify the number of frames to generate:

```bash
./generate_data.sh --num_frames=50
```

### Running in Headless Mode (for Data Generation) ###

To run the script in the background for generating large datasets, use the --headless flag. The application will automatically close when it's finished.

Generate the default number of frames (10) in headless mode:

```bash
./generate_data.sh --headless
```

Generate a large dataset of 20,000 frames in headless mode:
```bash
./generate_data.sh --headless --num_frames=20000
```

## Output ##

The generated dataset will be saved in the directory specified by the OUTPUT_DIR variable in generate_data.sh. The output format is Kitti, which will include folders for rgb images and potentially other data types like bounding boxes if configured.
