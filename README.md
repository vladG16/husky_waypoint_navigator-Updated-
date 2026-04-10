# Husky Waypoint Navigator — SCUBA Lab

This repository contains the autonomous waypoint navigation system for the SCUBA Lab's **Clearpath Husky A200** robot. It uses a **ZED X stereo camera** for positional tracking and a custom **PD (Proportional-Derivative) controller** to drive the robot precisely between a series of user-defined waypoints.

> 🎥 **Demo Video**  
> *(To embed your robot video: drag and drop your `.mp4` into a GitHub Issue comment box, copy the generated URL, and paste it here on its own line. GitHub renders it automatically as a playable video.)*

---

## Table of Contents

1. [System Requirements](#1-system-requirements)
2. [Install ROS 2 Humble](#2-install-ros-2-humble)
3. [Install the ZED SDK](#3-install-the-zed-sdk)
4. [Set Up Your ROS 2 Workspace](#4-set-up-your-ros-2-workspace)
5. [Clone This Repository](#5-clone-this-repository)
6. [Install Dependencies](#6-install-dependencies)
7. [Build the Package](#7-build-the-package)
8. [How to Record Waypoints](#8-how-to-record-waypoints)
9. [How to Run the Navigator](#9-how-to-run-the-navigator)
10. [Tuning the PD Controller](#10-tuning-the-pd-controller)
11. [ROS Topics Reference](#11-ros-topics-reference)
12. [File Reference](#12-file-reference)
13. [Troubleshooting](#13-troubleshooting)

---

## 1. System Requirements

Before you begin, make sure your computer meets these requirements:

| Requirement | Details |
|---|---|
| **Operating System** | Ubuntu 22.04 LTS — ROS 2 Humble does not run natively on Windows or macOS |
| **ROS Version** | ROS 2 Humble Hawksbill |
| **Python** | Python 3.10 (included with Ubuntu 22.04) |
| **GPU** | NVIDIA GPU required for the ZED X camera SDK |
| **NVIDIA Driver** | Version 525 or newer |
| **Internet** | Required during installation |
| **Sudo Access** | You must be able to run `sudo` commands |

> ⚠️ **On Windows or macOS?** You will need to install Ubuntu 22.04 as a dual-boot or virtual machine before continuing. The ZED SDK also requires a physical NVIDIA GPU — a VM will likely not work for that step.

---

## 2. Install ROS 2 Humble

ROS 2 is the core framework the entire project runs on. Follow these steps in order.

### Step 2.1 — Update Your System

```bash
sudo apt update && sudo apt upgrade -y
```

### Step 2.2 — Enable the Universe Repository

```bash
sudo apt install software-properties-common -y
sudo add-apt-repository universe
```

### Step 2.3 — Add the ROS 2 Package Source

```bash
sudo apt install curl -y
sudo curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | sudo apt-key add -
sudo sh -c 'echo "deb http://packages.ros.org/ros2/ubuntu $(lsb_release -cs) main" > /etc/apt/sources.list.d/ros2-latest.list'
```

### Step 2.4 — Install ROS 2 Humble

```bash
sudo apt update
sudo apt install ros-humble-desktop -y
```

> ⏳ This may take 10–20 minutes depending on your internet speed.

### Step 2.5 — Auto-Load ROS 2 in Every Terminal

```bash
echo "source /opt/ros/humble/setup.bash" >> ~/.bashrc
source ~/.bashrc
```

### Step 2.6 — Install Build Tools

```bash
sudo apt install python3-colcon-common-extensions python3-rosdep python3-pip -y
```

### Step 2.7 — Initialize rosdep

`rosdep` automatically installs system-level dependencies for ROS packages:

```bash
sudo rosdep init
rosdep update
```

### Step 2.8 — Verify the Installation

```bash
ros2 --version
```

You should see something like `ros2 humble`. If so, ROS 2 is installed correctly.

---

## 3. Install the ZED SDK

The ZED X camera requires Stereolabs' SDK to provide the robot with positional awareness and odometry data.

### Step 3.1 — Install NVIDIA Drivers

```bash
sudo apt install ubuntu-drivers-common -y
sudo ubuntu-drivers autoinstall
sudo reboot
```

After rebooting, confirm your GPU is detected:

```bash
nvidia-smi
```

You should see your GPU and driver version listed.

### Step 3.2 — Download and Install the ZED SDK

Go to the Stereolabs download page and download the SDK for **Ubuntu 22.04**:

👉 https://www.stereolabs.com/developers/release

Then run the installer (replace the filename with the version you downloaded):

```bash
chmod +x ZED_SDK_Ubuntu22_cuda*.run
./ZED_SDK_Ubuntu22_cuda*.run
```

Follow the on-screen prompts and accept the defaults.

### Step 3.3 — Install the ZED ROS 2 Wrapper

This wrapper connects the ZED camera to ROS 2 so the navigation scripts can receive pose data:

```bash
cd ~/ros2_ws/src
git clone --recurse-submodules https://github.com/stereolabs/zed-ros2-wrapper.git
cd ~/ros2_ws
rosdep install --from-paths src --ignore-src -r -y
colcon build --symlink-install --cmake-args=-DCMAKE_BUILD_TYPE=Release
source install/setup.bash
```

---

## 4. Set Up Your ROS 2 Workspace

A ROS 2 workspace is the folder where all your packages live and get built from.

```bash
# Create the workspace
mkdir -p ~/ros2_ws/src

# Move into it and do an initial build
cd ~/ros2_ws
colcon build

# Load it into your environment
source install/setup.bash
```

Add it to your `.bashrc` so it loads automatically in every new terminal:

```bash
echo "source ~/ros2_ws/install/setup.bash" >> ~/.bashrc
source ~/.bashrc
```

---

## 5. Clone This Repository

```bash
cd ~/ros2_ws/src
git clone https://github.com/scubabot/husky_waypoint_navigator-Updated-.git
```

Your workspace should now look like this:

```
ros2_ws/
└── src/
    └── husky_waypoint_navigator-Updated-/
        ├── husky_nav_ros2/
        │   ├── waypoint_navigator_pd.py
        │   ├── manual_waypoint_recorder.py
        │   ├── navigation_simple.py
        │   └── robot_math_utils.py
        ├── resource/
        ├── test/
        ├── package.xml
        ├── setup.py
        └── README.md
```

---

## 6. Install Dependencies

### Step 6.1 — Install All ROS 2 Package Dependencies

From your workspace root, run:

```bash
cd ~/ros2_ws
rosdep install --from-paths src --ignore-src -r -y
```

This automatically installs all packages declared in `package.xml`, including:
`rclpy`, `geometry_msgs`, `sensor_msgs`, `nav_msgs`, `tf2_ros`, `tf2_geometry_msgs`, `nav2_msgs`, `std_msgs`, and more.

### Step 6.2 — Install Python Libraries

```bash
pip3 install numpy pyyaml
```

### Step 6.3 — Install the NatNet ROS 2 Bridge (OptiTrack users only)

If your lab uses an **OptiTrack** motion capture system instead of the ZED camera for pose data, you need this additional package:

```bash
cd ~/ros2_ws/src
git clone -b ros2 https://github.com/L2S-lab/natnet_ros2.git

cd ~/ros2_ws
colcon build --packages-select natnet_ros2
source install/setup.bash
```

> 💡 Skip this step if you are only using the ZED X camera.

---

## 7. Build the Package

```bash
cd ~/ros2_ws
colcon build --packages-select husky_nav_ros2
source install/setup.bash
```

> ✅ Run `source install/setup.bash` every time you rebuild. Your current terminal needs this even if `.bashrc` is already set up.

---

## 8. How to Record Waypoints

Before the robot can navigate, it needs to know **where to go**. You do this by manually driving the robot along a path while the recorder is running. It saves every position the robot visits into a file called `waypoints.csv`.

### Step 8.1 — Make Sure the Camera is Running

Open **Terminal 1** and start the ZED camera:

```bash
ros2 launch zed_wrapper zed_camera.launch.py camera_model:=zedx
```

Wait until the camera output stabilizes before continuing.

### Step 8.2 — Launch the Waypoint Recorder

Open **Terminal 2** and run:

```bash
ros2 run husky_nav_ros2 manual_waypoint_recorder
```

### Step 8.3 — Drive the Robot and Record

Use the joystick to drive the Husky along the path you want it to follow:

| Joystick Button | Action |
|---|---|
| **Button 0 (Cross / X)** | ▶️ Start recording the path |
| **Button 2 (Square)** | ⏹️ Stop recording and save to `waypoints.csv` |

Drive the robot along your desired route, then press **Square** when done. The recorder will process the path and save a clean, sparse set of waypoints to `waypoints.csv` in your working directory.

### What waypoints.csv looks like

Each line in the file represents one waypoint in the format:

```
x,y,theta
```

For example:

```
1.45,0.32,0.00
2.80,1.10,1.57
3.50,2.00,-1.57
```

Where `x` and `y` are position in meters and `theta` is the robot's target heading in radians.

> ⚠️ The `waypoints.csv` file must be present in the directory where you run the navigator node, otherwise the robot will not move.

---

## 9. How to Run the Navigator

Once waypoints are recorded, use **two terminals** to run the full navigation system.

### Terminal 1 — Start the ZED Camera

```bash
ros2 launch zed_wrapper zed_camera.launch.py camera_model:=zedx
```

### Terminal 2 — Start the PD Waypoint Navigator

```bash
ros2 run husky_nav_ros2 collection_simple
```

The robot will then work through each waypoint automatically using the following sequence for each one:

1. **Align** — rotates to face the next waypoint
2. **Move** — drives toward it in a straight line
3. **Realign** — corrects heading if it drifts while moving
4. **Final orientation** — rotates to match the saved heading at that waypoint
5. **Advance** — moves on to the next waypoint

When all waypoints are complete, the robot stops and logs `All waypoints successfully navigated!`

---

## 10. Tuning the PD Controller

If the robot overshoots, oscillates, or moves too fast, you can adjust the controller parameters inside `waypoint_navigator_pd.py`:

```python
# How close the robot needs to get before considering a point "reached"
self.goal_xy_tolerance = 0.08         # meters
self.goal_final_theta_tolerance = 0.08 # radians

# Speed limits
self.max_linear_speed = 0.15   # m/s  (forward speed)
self.max_angular_speed = 0.30  # rad/s (turning speed)

# Proportional gains — increase to react faster, decrease to reduce overshoot
self.linear_Kp = 0.5
self.angular_Kp = 0.9

# Derivative gains — increase to dampen oscillation
self.linear_Kd = 0.15
self.angular_Kd = 0.1
```

After making changes, rebuild and re-source:

```bash
colcon build --packages-select husky_nav_ros2
source install/setup.bash
```

---

## 11. ROS Topics Reference

These are the exact ROS 2 topics the package uses. If your robot setup uses different topic names, update them inside the scripts.

| Topic | Direction | Type | Purpose |
|---|---|---|---|
| `/base_link/pose` | Subscribed | `PoseStamped` | Robot's current position and orientation (from ZED or OptiTrack) |
| `/a200_1046/cmd_vel` | Published | `Twist` | Velocity commands sent to the robot |
| `/navigation_status` | Published | `String` | Live status updates from the navigator |
| `/a200_1046/joy_teleop/joy` | Subscribed | `Joy` | Joystick input for the waypoint recorder |

> 💡 If your robot uses a different namespace than `a200_1046`, update the topic names at the top of `waypoint_navigator_pd.py` and `manual_waypoint_recorder.py`.

---

## 12. File Reference

| File | What It Does |
|---|---|
| `waypoint_navigator_pd.py` | Main navigator — reads `waypoints.csv` and drives the robot to each point using a PD controller |
| `manual_waypoint_recorder.py` | Records a driven path via joystick and saves it to `waypoints.csv` |
| `navigation_simple.py` | A simpler baseline navigator without the PD controller — useful for testing |
| `robot_math_utils.py` | Shared math helpers for distance calculations, yaw extraction, and angle normalization — used internally by both scripts |
| `waypoints.csv` | Auto-generated by the recorder — stores the list of `x,y,theta` waypoints the navigator follows |
| `package.xml` | Declares all ROS 2 package dependencies |
| `dependencies.repos` | Lists external git repositories needed (NatNet for OptiTrack) |
| `setup.py` | Tells ROS 2 how to install the Python scripts in this package |

---

## 13. Troubleshooting

**Robot does not move after launching the navigator**  
Check that `waypoints.csv` exists in your working directory. Also confirm the ZED camera is publishing on `/base_link/pose` by running `ros2 topic echo /base_link/pose`.

**`package 'husky_nav_ros2' not found`**  
You need to source your workspace: `source ~/ros2_ws/install/setup.bash`

**`ros2: command not found`**  
Run `source /opt/ros/humble/setup.bash` or verify it is in your `~/.bashrc`.

**`colcon build` fails with missing packages**  
Run `rosdep install --from-paths src --ignore-src -r -y` from inside `~/ros2_ws` and rebuild.

**Camera won't launch / ZED SDK error**  
Make sure the ZED SDK installed correctly and your NVIDIA drivers are active. Run `nvidia-smi` to confirm.

**Joystick buttons not responding in recorder**  
Verify the joystick topic is publishing by running `ros2 topic echo /a200_1046/joy_teleop/joy`. If your joystick uses a different topic, update `JOYSTICK_TOPIC` at the top of `manual_waypoint_recorder.py`.

**Robot overshoots or oscillates at waypoints**  
Lower `linear_Kp` or increase `linear_Kd` in `waypoint_navigator_pd.py`. See [Section 10](#10-tuning-the-pd-controller) for details.
