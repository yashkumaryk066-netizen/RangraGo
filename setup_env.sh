#!/bin/bash

# Comprehensive Local Build Environment Setup for RangraGo
# This script installs portable JDK and Android SDK in the workspace.

BASE_DIR="$HOME/build_tools"
JDK_DIR="$BASE_DIR/jdk"
SDK_DIR="$BASE_DIR/android-sdk"

mkdir -p "$BASE_DIR"
cd "$BASE_DIR"

echo "⏳ Step 1: Downloading Portable JDK (Java 17)..."
if [ ! -d "$JDK_DIR" ]; then
    curl -L -o jdk.tar.gz "https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.10%2B7/OpenJDK17U-jdk_x64_linux_hotspot_17.0.10_7.tar.gz"
    mkdir -p "$JDK_DIR"
    tar -xzf jdk.tar.gz -C "$JDK_DIR" --strip-components=1
    rm jdk.tar.gz
fi

export JAVA_HOME="$JDK_DIR"
export PATH="$JAVA_HOME/bin:$PATH"

echo "⏳ Step 2: Downloading Android Command Line Tools..."
if [ ! -d "$SDK_DIR/cmdline-tools" ]; then
    mkdir -p "$SDK_DIR/cmdline-tools"
    curl -o cmdline-tools.zip "https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip"
    unzip -q cmdline-tools.zip
    mv cmdline-tools latest
    mv latest "$SDK_DIR/cmdline-tools/"
    rm cmdline-tools.zip
fi

export PATH="$PATH:$SDK_DIR/cmdline-tools/latest/bin"

echo "⏳ Step 3: Accepting Licenses..."
# Use yes to accept all licenses
yes | sdkmanager --sdk_root="$SDK_DIR" --licenses > /dev/null

echo "⏳ Step 4: Installing Android Platform (API 34) and Build Tools..."
sdkmanager --sdk_root="$SDK_DIR" "platform-tools" "platforms;android-34" "build-tools;34.0.0" > /dev/null

echo "⏳ Step 5: Configuring Flutter..."
flutter config --android-sdk "$SDK_DIR"
flutter config --jdk-dir "$JDK_DIR"

echo "✅ Environment setup complete!"
echo "Now you can run: ./build_apk_locally.sh"
