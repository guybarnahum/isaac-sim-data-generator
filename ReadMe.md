# Isaac Sim Dataset Generator
This script was adapted from an original NVIDIA working example, it has been significantly modified to remove external dependencies (like the Nucleus server) and to programmatically handle common issues in procedural content generation, such as asset scaling, orientation, and pivot point correction.

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
├── .env.example
├── assets/
│   ├── car/
│   │   ├── car_1.usdz
│   │   └── car_2.usdz
│   └── person/
│       ├── person_1.usdz
│       └── person_2.usdz
├── generate_data.sh
├── randomize.py
└── examples
    ├── kitt-dataset/
    └── yolo-dataset/

```

## Asset Location ##

To use this script, you must organize your `.usdz` asset files into subdirectories within the `assets/ folder`. The name of each subdirectory will be used as the class label for all assets within it.
Example: Place all car models in `assets/car/` and all person models in `assets/person/`.
The script will automatically detect these categories and apply the corresponding scaling rules defined in `randomize.py`.

## **Quick Start**

1.  **Clone the Repository:**
    ```bash
    git clone https://github.com/<username>/isaac-sim-data-generator.git
    cd isaac-sim-data-generator
    ```

2.  **Configure Your Environment:**
    Copy the example configuration file to a new `.env` file.
    ```bash
    cp .env.example .env
    ```
    Now, open `.env` with a text editor and set the `ISAAC_SIM_PATH` and `PROJECT_ROOT_PATH` variables to match your system's paths.

3.  **Setup Assets**
    Place all car models in `isaac-sim-data-generator/assets/car/` and all person models in `isaac-sim-data-generator/assets/person/`.
    
5.  **Run the Script:**
    Make the script executable and run it.
    ```bash
    chmod +x generate_data.sh
    ./generate_data.sh --headless --num_frames=100
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

The generated dataset will be saved in the directory specified by the OUTPUT_DIR variable in generate_data.sh. The output is formatted as a Kitti dataset, which will include folders for rgb images and potentially other data types like bounding boxes if configured. The Kitti dataset is then converted to a YOLO dataset.

## Cloud VM Setup (Google Cloud Platform)

This project can be run on any setup that supports Isaac Sim. For example a cloud VM with a compatible NVIDIA GPU. The following instructions are for setting up a VM on Google Cloud Platform (GCP), but similar steps can be applied to other cloud providers like AWS or Azure.

### Prerequisites

-   A Google Cloud Platform account with billing enabled.
-   Increased GPU quota for your desired region. You may need to request a quota increase for "NVIDIA T4 GPUs" or "NVIDIA L4 GPUs" (or similar) from the GCP console, as the default is often 0.

### 1. Create the GPU-Enabled VM

1.  **Navigate to VM Instances:** In the GCP Console, go to `Compute Engine` -> `VM instances`.
2.  **Create a New Instance:** Click `CREATE INSTANCE`.
3.  **Configure the Machine:**
    -   **Name:** Give your VM a descriptive name (e.g., `isaac-sim--gpu-vm`).
    -   **Region and Zone:** Choose a region and zone where GPUs are available (e.g., `us-central1-a`).
    -   **Machine Configuration:**
        -   **Series:** `N1` (or `G2` for newer GPUs).
        -   **Machine type:** `n1-standard-4` (4 vCPUs, 15 GB memory) is a good starting point.
    -   **GPU Configuration:**
        -   Click **GPUs**.
        -   Enable the **GPU** toggle.
        -   **GPU type:** Select `NVIDIA L4` (recommended) or `NVIDIA T4`. These are modern, cost-effective GPUs suitable for Isaac Sim.
        -   **Number of GPUs:** `1`.
        -   **IMPORTANT:** A dialog will appear stating that the NVIDIA driver will be installed automatically. **Ensure this is enabled.** This is the easiest way to get the correct drivers.
    -   **Boot Disk:**
        -   Click `Change`.
        -   **Operating system:** `Deep Learning on Linux`.
        -   **Version:** Select a recent `Deep Learning VM with M113` (or newer) that includes CUDA and NVIDIA drivers pre-installed. Using a Deep Learning VM image saves a lot of setup time.
        -   **Size (GB):** Increase the boot disk size to at least **100 GB**. Isaac Sim is a large application.
    -   **Firewall:**
        -   Allow `HTTP` and `HTTPS` traffic if you plan to use a web-based remote desktop.
4.  **Create:** Click the `Create` button. The VM will take a few minutes to provision.

### 2. Connect to the VM and Install VNC

Once the VM is running, you will need a graphical interface to run Isaac Sim in GUI mode. VNC is a robust way to achieve this.

1.  **SSH into the VM:** Use the `SSH` button in the GCP Console to open a terminal connection.
2.  **Update the System:**
    ```bash
    sudo apt-get update
    sudo apt-get upgrade -y
    ```
3.  **Install a Desktop Environment and VNC Server:**
    We will install a lightweight desktop (XFCE) and TightVNC.
    ```bash
    sudo apt-get install -y xfce4 xfce4-goodies tightvncserver
    ```
4.  **Run VNC Server for the First Time:**
    This will prompt you to create a password for your VNC connection.
    ```bash
    vncserver
    ```
    -   Enter a password (it will be truncated to 8 characters).
    -   When asked "Would you like to enter a view-only password?", press `n`.

5.  **Configure VNC:**
    We need to tell the VNC server to start the XFCE desktop environment.
    ```bash
    # Kill the initial VNC server instance
    vncserver -kill :1

    # Edit the VNC startup file
    nano ~/.vnc/xstartup
    ```
    -   Comment out all existing lines (add a `#` at the beginning of each line).
    -   Add the following lines to the end of the file:
        ```sh
        #!/bin/bash
        xrdb $HOME/.Xresources
        startxfce4 &
        ```
    -   Save the file (`Ctrl+X`, then `Y`, then `Enter`).
    -   Make the startup script executable:
        ```bash
        chmod +x ~/.vnc/xstartup
        ```
6.  **Start the VNC Server:**
    This command starts the VNC server with a specific screen resolution.
    ```bash
    vncserver -geometry 1920x1080
    ```

### 3. Connect with a VNC Client

1.  **Install a VNC Client:** On your local machine, install a VNC client like [RealVNC Viewer](https://www.realvnc.com/en/connect/download/viewer/) or [TightVNC](http://www.tightvnc.com/).
2.  **SSH Tunnel (for Security):** Open a **new local terminal** on your own computer (not the VM's SSH window) and create an SSH tunnel. This securely forwards the VNC connection. Replace `[VM_EXTERNAL_IP]` with your VM's external IP address from the GCP console.
    ```bash
    gcloud compute ssh [YOUR_VM_NAME] --zone [YOUR_VM_ZONE] -- -L 5901:localhost:5901
    ```
3.  **Connect:** Open your VNC client and connect to `localhost:5901`. Enter the VNC password you created. You should now see the XFCE desktop of your GCP VM.

### 4. Install and Verify Isaac Sim

Follow instructions online -> [Quick Install](https://docs.isaacsim.omniverse.nvidia.com/latest/installation/quick-install.html)
Install into ```/home/your_user/isaac-sim``` or similar path

**Verify the Installation:**
    The most important verification step is to ensure Isaac Sim can access the GPU correctly.
    -   Navigate to the Isaac Sim installation directory:
        ```bash
        cd /home/your_user/isaac-sim
        ```
    -   Run the `python.sh` script with a simple test that prints GPU information. Create a temporary Python file:
        ```bash
        nano gpu_test.py
        ```
    -   Paste the following code into the file:
        ```python
        import torch
        print(f"PyTorch version: {torch.__version__}")
        print(f"CUDA available: {torch.cuda.is_available()}")
        if torch.cuda.is_available():
            print(f"CUDA version: {torch.version.cuda}")
            print(f"GPU: {torch.cuda.get_device_name(0)}")
        ```
    -   Save and exit (`Ctrl+X`, `Y`, `Enter`).
    -   Now, run the test:
        ```bash
        ./python.sh gpu_test.py
        ```
    -   **Expected Output:** You should see something like this, confirming that PyTorch (used by Isaac Sim) can see the GPU:
        ```
        PyTorch version: 2.0.1+cu118
        CUDA available: True
        CUDA version: 11.8
        GPU: NVIDIA L4
        ```
    If you see `CUDA available: True` and the correct GPU name, your installation is successful and ready to run the data generation script.
