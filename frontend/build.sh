#!/bin/bash
echo "Installing Flutter..."
git clone https://github.com/flutter/flutter.git -b stable --depth 1
export PATH="$PATH:`pwd`/flutter/bin"

echo "Running flutter doctor..."
flutter doctor

echo "Getting packages..."
flutter pub get

echo "Building Flutter Web..."
flutter build web --release --base-href "/"
