#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "Installing Flutter..."
# Clone the stable branch with a depth of 1 to save time
git clone https://github.com/flutter/flutter.git -b stable --depth 1

# Add Flutter to PATH
export PATH="$PATH:`pwd`/flutter/bin"

echo "Flutter version:"
flutter --version

echo "Getting dependencies..."
flutter pub get

echo "Building Flutter Web..."
flutter build web --release
