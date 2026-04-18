#!/bin/bash
# =============================================================================
# setup.sh — SCUBA Lab Husky Waypoint Navigator
# Full environment setup script for Ubuntu 22.04
# Run this once on a fresh system after installing NVIDIA drivers and ZED SDK
# Usage: bash setup.sh
# =============================================================================

set -e  # Stop the script immediately if any command fails

# --- Colors for output ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo_step() { echo -e "\n${GREEN}>>> $1${NC}"; }
echo_warn() { echo -e "${YELLOW}  $1${NC}"; }
echo_done() { echo -e "${GREEN} $1${NC}"; }

# =============================================================================
echo_step "STEP 1 — Updating system packages"
# =============================================================================
sudo apt update && sudo apt upgrade -y
echo_done "System updated."

# =============================================================================
echo_step "STEP 2 — Installing ROS 2 Humble"
# =============================================================================

# Check if ROS 2 is already installed
if [ -f /opt/ros/humble/setup.bash ]; then
    echo_warn "ROS 2 Humble already installed. Skipping."
else
    echo_step "Adding ROS 2 package sources..."
    sudo apt install software-properties-common curl -y
    sudo add-apt-repository universe -y
    sudo curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | sudo apt-key add -
    sudo sh -c 'echo "deb http://packages.ros.org/ros2/ubuntu $(lsb_release -cs) main" > /etc/apt/sources.list.d/ros2-latest.list'

    sudo apt update
    sudo apt install ros-humble-desktop -y
    echo_done "ROS 2 Humble installed."
fi

# =============================================================================
echo_step "STEP 3 — Adding ROS 2 to your terminal environment"
# =============================================================================
if ! grep -q "source /opt/ros/humble/setup.bash" ~/.bashrc; then
    echo "source /opt/ros/humble/setup.bash" >> ~/.bashrc
    echo_done "Added ROS 2 source to ~/.bashrc"
else
    echo_warn "ROS 2 already sourced in ~/.bashrc. Skipping."
fi
source /opt/ros/humble/setup.bash

# =============================================================================
echo_step "STEP 4 — Installing build tools and rosdep"
# =============================================================================
sudo apt install python3-colcon-common-extensions python3-rosdep python3-pip -y

if [ ! -f /etc/ros/rosdep/sources.list.d/20-default.list ]; then
    sudo rosdep init
else
    echo_warn "rosdep already initialized. Skipping."
fi
rosdep update
echo_done "Build tools ready."

# =============================================================================
echo_step "STEP 5 — Installing Python dependencies"
# =============================================================================
pip3 install numpy pyyaml
echo_done "Python dependencies installed."

# =============================================================================
echo_step "STEP 6 — Creating ROS 2 workspace"
# =============================================================================
if [ ! -d ~/ros2_ws/src ]; then
    mkdir -p ~/ros2_ws/src
    echo_done "Created ~/ros2_ws/src"
else
    echo_warn "Workspace ~/ros2_ws already exists. Skipping creation."
fi

# =============================================================================
echo_step "STEP 7 — Cloning ZED ROS 2 Wrapper"
# =============================================================================
if [ ! -d ~/ros2_ws/src/zed-ros2-wrapper ]; then
    cd ~/ros2_ws/src
    git clone --recurse-submodules https://github.com/stereolabs/zed-ros2-wrapper.git
    echo_done "ZED ROS 2 wrapper cloned."
else
    echo_warn "ZED ROS 2 wrapper already exists. Skipping."
fi

# =============================================================================
echo_step "STEP 8 — Cloning this repository (husky_waypoint_navigator)"
# =============================================================================
if [ ! -d ~/ros2_ws/src/husky_waypoint_navigator-Updated- ]; then
    cd ~/ros2_ws/src
    git clone https://github.com/scubabot/husky_waypoint_navigator-Updated-.git
    echo_done "Husky navigator repo cloned."
else
    echo_warn "Husky navigator repo already exists. Skipping."
fi

# =============================================================================
echo_step "STEP 9 — Installing all ROS 2 package dependencies via rosdep"
# =============================================================================
cd ~/ros2_ws
rosdep install --from-paths src --ignore-src -r -y
echo_done "ROS 2 dependencies installed."

# =============================================================================
echo_step "STEP 10 — Building the workspace"
# =============================================================================
cd ~/ros2_ws
colcon build --symlink-install --cmake-args=-DCMAKE_BUILD_TYPE=Release
echo_done "Workspace built successfully."

# =============================================================================
echo_step "STEP 11 — Adding workspace to your terminal environment"
# =============================================================================
if ! grep -q "source ~/ros2_ws/install/setup.bash" ~/.bashrc; then
    echo "source ~/ros2_ws/install/setup.bash" >> ~/.bashrc
    echo_done "Added workspace source to ~/.bashrc"
else
    echo_warn "Workspace already sourced in ~/.bashrc. Skipping."
fi
source ~/ros2_ws/install/setup.bash

# =============================================================================
echo -e "\n${GREEN}=============================================${NC}"
echo -e "${GREEN} Setup complete! Your environment is ready.${NC}"
echo -e "${GREEN}=============================================${NC}"
echo -e ""
echo -e "Next steps:"
echo -e "  1. Close and reopen your terminal (or run: source ~/.bashrc)"
echo -e "  2. To record waypoints:  ${YELLOW}bash run_recorder.sh${NC}"
echo -e "  3. To run the navigator: ${YELLOW}bash run_navigator.sh${NC}"
echo -e ""
