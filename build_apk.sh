#!/bin/bash

echo "🚀 Building PeerChat APK..."

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get

# Generate code (Hive adapters)
echo "🔧 Generating code..."
flutter packages pub run build_runner build --delete-conflicting-outputs

# Analyze code
echo "🔍 Analyzing code..."
flutter analyze

# Build APK
echo "🏗️ Building APK..."
flutter build apk --release

# Check if build was successful
if [ $? -eq 0 ]; then
    echo "✅ APK built successfully!"
    echo "📱 APK location: build/app/outputs/flutter-apk/app-release.apk"
    
    # Show APK info
    echo "📊 APK Information:"
    ls -lh build/app/outputs/flutter-apk/app-release.apk
    
    echo ""
    echo "🔧 Installation instructions:"
    echo "1. Enable 'Unknown sources' in Android settings"
    echo "2. Transfer APK to device"
    echo "3. Install the APK"
    echo "4. Grant required permissions (Location, Network)"
    echo ""
    echo "📋 Required permissions:"
    echo "- Location (for WiFi network discovery)"
    echo "- Network access"
    echo "- WiFi state access"
    echo ""
    echo "🌐 Network requirements:"
    echo "- Both devices must be on the same WiFi network"
    echo "- WiFi network should allow device-to-device communication"
    echo "- Some corporate/public WiFi networks may block P2P communication"
    
else
    echo "❌ APK build failed!"
    exit 1
fi 