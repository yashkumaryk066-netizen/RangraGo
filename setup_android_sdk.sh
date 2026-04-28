#!/bin/bash

# Script to setup a minimal Android SDK for Flutter builds without sudo
# Targeted for Linux environments

SDK_DIR="$HOME/android-sdk"
CMD_LINE_TOOLS_URL="https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip"

echo "⏳ Setting up Android SDK in $SDK_DIR..."

mkdir -p "$SDK_DIR/cmdline-tools"
cd "$SDK_DIR"

# Download command line tools if not present
if [ ! -d "cmdline-tools/latest" ]; then
    echo "📥 Downloading Android Command Line Tools..."
    curl -o cmdline-tools.zip "$CMD_LINE_TOOLS_URL"
    unzip -q cmdline-tools.zip
    mv cmdline-tools latest
    mkdir -p cmdline-tools
    mv latest cmdline-tools/
    rm cmdline-tools.zip
fi

export PATH="$PATH:$SDK_DIR/cmdline-tools/latest/bin"

echo "📜 Accepting Licenses..."
yes | sdkmanager --sdk_root="$SDK_DIR" --licenses

echo "📥 Installing Platform Tools and Build Tools..."
sdkmanager --sdk_root="$SDK_DIR" "platform-tools" "platforms;android-34" "build-tools;34.0.0"

echo "⚙️ Configuring Flutter..."
flutter config --android-sdk "$SDK_DIR"

echo "✅ Android SDK setup complete!"
echo "You can now run ./build_apk_locally.sh"
