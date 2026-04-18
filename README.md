<div align="center">
  <img src="scuba%20logo1.png" alt="SCUBA Lab Logo" width="300"/>
</div>

<div align="center">
  <h1>Husky Waypoint Navigator — SCUBA Lab</h1>
</div>


This repository contains the autonomous waypoint navigation system for the SCUBA Lab's **Clearpath Husky A200** robot. It uses a **ZED X stereo camera** for positional tracking and a custom **PD (Proportional-Derivative) controller** to drive the robot precisely between a series of user-defined waypoints.

<div align="center">
  <img src="huskynav-ezgif.com-cut.gif" alt="Husky Waypoint Navigation Demo" width="700"/>
</div>

---

## Table of Contents

1. [System Requirements](#1-system-requirements)
2. [Install NVIDIA Drivers](#2-install-nvidia-drivers)
3. [Install the ZED SDK](#3-install-the-zed-sdk)
4. [Install ROS 2 Humble](#4-install-ros-2-humble)
5. [Set Up Your ROS 2 Workspace](#5-set-up-your-ros-2-workspace)
6. [Clone This Repository and Install Dependencies](#6-clone-this-repository-and-install-dependencies)
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
| **ROS Version** | ROS 2 Humble |
| **Python** | Python 3.10 (included with Ubuntu 22.04) |
| **GPU** | NVIDIA GPU required for the ZED X camera SDK |
| **NVIDIA Driver** | Version 525 or newer |
| **Internet** | Required during installation |
| **Sudo Access** | You must be able to run `sudo` commands |

>  **On Windows or macOS?** You will need to install Ubuntu 22.04 as a dual-boot or virtual machine before continuing. The ZED SDK also requires a physical NVIDIA GPU — a VM will likely not work for that step.

---

## 2. Install NVIDIA Drivers

The ZED X camera requires an NVIDIA GPU with driver version **525 or newer**.

Follow NVIDIA's official driver installation guide for Ubuntu:

 **https://docs.nvidia.com/datacenter/tesla/driver-installation-guide/**

After installing, reboot your machine and verify the driver is working:

```bash
nvidia-smi
```

You should see your GPU and driver version listed. Once confirmed, continue to Step 3.

---

## 3. Install the ZED SDK

The ZED SDK provides the robot with its positional awareness and odometry data from the ZED X camera.

Follow the official Stereolabs installation guide — make sure to select **Ubuntu 22.04** and the CUDA version that matches your system:

 **https://www.stereolabs.com/developers/release**

Once the SDK is installed, continue to Step 4.

---

## 4. Install ROS 2 Humble

ROS 2 is the core framework the entire project runs on.

###  Option A — Automatic (Recommended)

If you have already cloned this repository, simply run the setup script which handles everything from this step onward:

```bash
bash setup.sh
```

Then **skip ahead to [Section 8 — How to Record Waypoints](#8-how-to-record-waypoints)**.

---

###  Option B — Manual (Step by Step)

Follow these steps if you prefer to install everything yourself.

#### Step 4.1 — Update Your System

```bash
sudo apt update && sudo apt upgrade -y
```

#### Step 4.2 — Enable the Universe Repository

```bash
sudo apt install software-properties-common -y
sudo add-apt-repository universe
```

#### Step 4.3 — Add the ROS 2 Package Source

```bash
sudo apt install curl -y
sudo curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | sudo apt-key add -
sudo sh -c 'echo "deb http://packages.ros.org/ros2/ubuntu $(lsb_release -cs) main" > /etc/apt/sources.list.d/ros2-latest.list'
```

#### Step 4.4 — Install ROS 2 Humble

```bash
sudo apt update
sudo apt install ros-humble-desktop -y
```

>  This may take 10–20 minutes depending on your internet speed.

#### Step 4.5 — Auto-Load ROS 2 in Every Terminal

```bash
echo "source /opt/ros/humble/setup.bash" >> ~/.bashrc
source ~/.bashrc
```

#### Step 4.6 — Install Build Tools

```bash
sudo apt install python3-colcon-common-extensions python3-rosdep python3-pip -y
```

#### Step 4.7 — Initialize rosdep

`rosdep` automatically installs system-level dependencies for ROS packages:

```bash
sudo rosdep init
rosdep update
```

#### Step 4.8 — Verify the Installation

```bash
ros2 --version
```

You should see `ros2 humble`. If so, ROS 2 is installed correctly.

---

## 5. Set Up Your ROS 2 Workspace

A ROS 2 workspace is the dedicated folder where all your packages live and get built from.

###  Option A — Automatic

The `setup.sh` script already handles this. If you ran it in Step 4, skip to [Section 6](#6-clone-this-repository-and-install-dependencies).

---

###  Option B — Manual

```bash
# Create the workspace
mkdir -p ~/ros2_ws/src

# Move into it and do an initial build to set it up
cd ~/ros2_ws
colcon build

# Load the workspace into your environment
source install/setup.bash
```

Add the workspace to your `.bashrc` so it loads automatically in every new terminal:

```bash
echo "source ~/ros2_ws/install/setup.bash" >> ~/.bashrc
source ~/.bashrc
```

---

## 6. Clone This Repository and Install Dependencies

###  Option A — Automatic

The `setup.sh` script already handles cloning, dependency installation, and the ZED ROS 2 wrapper. If you ran it in Step 4, skip to [Section 7](#7-build-the-package).

---

###  Option B — Manual

#### Step 6.1 — Clone This Repository

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
        ├── setup.sh
        ├── build.sh
        ├── run_navigator.sh
        ├── run_recorder.sh
        └── README.md
```

#### Step 6.2 — Install the ZED ROS 2 Wrapper

This connects the ZED camera to ROS 2 so the navigation scripts can receive pose data:

```bash
cd ~/ros2_ws/src
git clone --recurse-submodules https://github.com/stereolabs/zed-ros2-wrapper.git
cd ~/ros2_ws
rosdep install --from-paths src --ignore-src -r -y
colcon build --symlink-install --cmake-args=-DCMAKE_BUILD_TYPE=Release
source install/setup.bash
```

#### Step 6.3 — Install All ROS 2 Package Dependencies

```bash
cd ~/ros2_ws
rosdep install --from-paths src --ignore-src -r -y
```

This automatically installs all packages declared in `package.xml`, including:
`rclpy`, `geometry_msgs`, `sensor_msgs`, `nav_msgs`, `tf2_ros`, `tf2_geometry_msgs`, `nav2_msgs`, `std_msgs`, and more.

#### Step 6.4 — Install Python Libraries

```bash
pip3 install numpy pyyaml
```

#### Step 6.5 — Install the NatNet Bridge (OptiTrack users only)

If your lab uses an **OptiTrack** motion capture system instead of the ZED camera, you also need this package:

```bash
cd ~/ros2_ws/src
git clone -b ros2 https://github.com/L2S-lab/natnet_ros2.git
cd ~/ros2_ws
colcon build --packages-select natnet_ros2
source install/setup.bash
```

>  Skip this step if you are only using the ZED X camera.

---

## 7. Build the Package

###  Option A — Automatic

```bash
bash build.sh
```

This rebuilds the `husky_nav_ros2` package and sources the workspace in one step. Run this every time you make changes to the code.

---

###  Option B — Manual

```bash
cd ~/ros2_ws
colcon build --packages-select husky_nav_ros2
source install/setup.bash
```

>  You must run `source install/setup.bash` every time you rebuild. Your current terminal needs this even if `.bashrc` is already configured.

---

## 8. How to Record Waypoints

Before the robot can navigate, it needs to know where to go. You manually drive the robot along a path while the recorder captures its position, then saves it to a file called `waypoints.csv`.

###  Option A — Automatic

```bash
bash run_recorder.sh
```

This opens two terminal windows automatically — one for the ZED camera and one for the recorder — and waits for the camera to initialize before starting the recorder.

---

###  Option B — Manual

Open **Terminal 1** and start the ZED camera:

```bash
ros2 launch zed_wrapper zed_camera.launch.py camera_model:=zedx
```

Wait until the camera output stabilizes, then open **Terminal 2** and run:

```bash
ros2 run husky_nav_ros2 manual_waypoint_recorder
```

---

### Drive the Robot and Record

Once both are running, use the joystick to drive the Husky along your desired route:

| Joystick Button | Action |
|---|---|
| **Button 0 (Cross / X)** |  Start recording the path |
| **Button 2 (Square)** |  Stop recording and save to `waypoints.csv` |

When you press Square, the recorder processes the path into a clean set of waypoints and saves them automatically.

### What waypoints.csv looks like

Each line represents one waypoint in the format `x, y, theta`:

```
1.45,0.32,0.00
2.80,1.10,1.57
3.50,2.00,-1.57
```

Where `x` and `y` are position in meters and `theta` is the robot's target heading in radians.

>  The `waypoints.csv` file must be present in the directory where you launch the navigator, otherwise the robot will not move.

---

## 9. How to Run the Navigator

###  Option A — Automatic

```bash
bash run_navigator.sh
```

This checks that `waypoints.csv` exists, opens two terminal windows for the camera and navigator, and waits 5 seconds for the camera to initialize before starting the navigator.

---

###  Option B — Manual

Open **Terminal 1** and start the ZED camera:

```bash
ros2 launch zed_wrapper zed_camera.launch.py camera_model:=zedx
```

Wait until the camera output stabilizes, then open **Terminal 2** and run:

```bash
ros2 run husky_nav_ros2 collection_simple
```

---

The robot will then work through each waypoint in sequence using the following steps:

1. **Align** — rotates in place to face the next waypoint
2. **Move** — drives forward toward it
3. **Realign** — corrects heading if it drifts while moving
4. **Final orientation** — rotates to match the saved heading at that waypoint
5. **Advance** — moves on to the next waypoint

When all waypoints are complete, the robot stops and logs:
`All waypoints successfully navigated!`

---

## 10. Tuning the PD Controller

If the robot overshoots, oscillates, or moves too aggressively, adjust these parameters at the top of `waypoint_navigator_pd.py`:

```python
# How close the robot needs to get before considering a waypoint "reached"
self.goal_xy_tolerance = 0.08          # meters
self.goal_final_theta_tolerance = 0.08  # radians

# Maximum speeds
self.max_linear_speed = 0.15   # m/s   (forward speed)
self.max_angular_speed = 0.30  # rad/s (turning speed)

# Proportional gains — increase to react faster, decrease to reduce overshoot
self.linear_Kp = 0.5
self.angular_Kp = 0.9

# Derivative gains — increase to dampen oscillation
self.linear_Kd = 0.15
self.angular_Kd = 0.1
```

After any changes, rebuild with `bash build.sh` or manually with:

```bash
cd ~/ros2_ws
colcon build --packages-select husky_nav_ros2
source install/setup.bash
```

---

## 11. ROS Topics Reference

These are the exact ROS 2 topics the package uses. If your robot uses different topic names, update them at the top of the relevant script.

| Topic | Direction | Type | Purpose |
|---|---|---|---|
| `/base_link/pose` | Subscribed | `PoseStamped` | Robot's current position and orientation from the ZED camera or OptiTrack |
| `/a200_1046/cmd_vel` | Published | `Twist` | Velocity commands sent to the robot motors |
| `/navigation_status` | Published | `String` | Live status updates from the navigator node |
| `/a200_1046/joy_teleop/joy` | Subscribed | `Joy` | Joystick input used by the waypoint recorder |

>  If your robot has a different namespace than `a200_1046`, update the topic names in both `waypoint_navigator_pd.py` and `manual_waypoint_recorder.py`.

---

## 12. File Reference

| File | What It Does |
|---|---|
| `setup.sh` | **Run once on a new system.** Installs ROS 2, all dependencies, clones repos, and builds the workspace automatically |
| `build.sh` | Rebuilds the `husky_nav_ros2` package after any code changes |
| `run_navigator.sh` | Launches the ZED camera and waypoint navigator in two terminal windows automatically |
| `run_recorder.sh` | Launches the ZED camera and waypoint recorder in two terminal windows automatically |
| `waypoint_navigator_pd.py` | Main navigator — reads `waypoints.csv` and drives the robot to each point using a PD controller |
| `manual_waypoint_recorder.py` | Records a driven path via joystick and saves it to `waypoints.csv` |
| `navigation_simple.py` | A simpler baseline navigator without the PD controller — useful for testing |
| `robot_math_utils.py` | Shared math helpers for distance, yaw extraction, and angle normalization — used internally by both scripts |
| `waypoints.csv` | Auto-generated by the recorder — stores the `x,y,theta` waypoints the navigator follows |
| `package.xml` | Declares all ROS 2 package dependencies |
| `dependencies.repos` | Lists external git repositories needed (NatNet bridge for OptiTrack users) |

---

## 13. Troubleshooting

**Robot does not move after launching the navigator**  
Check that `waypoints.csv` exists in your current directory. Confirm the camera is publishing pose data: `ros2 topic echo /base_link/pose`

**`run_navigator.sh` says waypoints.csv not found**  
You need to record waypoints first. Run `bash run_recorder.sh`, drive the robot, and press Square to save.

**`package 'husky_nav_ros2' not found`**  
Source your workspace: `source ~/ros2_ws/install/setup.bash`

**`ros2: command not found`**  
Run `source /opt/ros/humble/setup.bash` or verify it is in your `~/.bashrc`.

**`colcon build` fails with missing packages**  
Run `rosdep install --from-paths src --ignore-src -r -y` from inside `~/ros2_ws` and rebuild. Or re-run `bash setup.sh` — it safely skips steps that are already done.

**Camera won't launch / ZED SDK error**  
Confirm the ZED SDK installed correctly and run `nvidia-smi` to verify your GPU is detected.

**Joystick buttons not responding in the recorder**  
Verify the joystick topic is active: `ros2 topic echo /a200_1046/joy_teleop/joy`. If your joystick uses a different topic, update it at the top of `manual_waypoint_recorder.py`.

**Robot overshoots or oscillates at waypoints**  
Lower `linear_Kp` or increase `linear_Kd` in `waypoint_navigator_pd.py`. See [Section 10](#10-tuning-the-pd-controller) for all tunable parameters. Rebuild after any changes.
