#!/bin/bash

# Configuration
FLUTTER_CHANNEL="stable"
FLUTTER_VERSION="latest"

# 1. Install Flutter if not already present
if [ ! -d "flutter" ]; then
  echo "Installing Flutter..."
  git clone https://github.com/flutter/flutter.git -b $FLUTTER_CHANNEL --depth 1
fi

# 2. Setup Flutter path
export PATH="$PATH:`pwd`/flutter/bin"

# 3. Verify installation
flutter --version

# 3.5 Create empty .env if missing (required for pubspec.yaml asset)
if [ ! -f ".env" ]; then
  echo "Creating dummy .env file..."
  touch .env
fi

# 4. Build the web app
echo "Building Flutter Web Application..."
flutter build web --release --base-href / --dart-define=GROQ_API_KEY=$GROQ_API_KEY

# 5. Done
echo "Build complete."
