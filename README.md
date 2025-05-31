# PeerChat - Peer-to-Peer Chat Application

A Flutter-based peer-to-peer chat application that enables direct device-to-device communication without requiring internet connectivity or central servers.

## 🌟 Features

- **Offline Communication**: Works without internet connection
- **Peer-to-Peer**: Direct device-to-device messaging via UDP
- **Real-time Discovery**: Automatic discovery of nearby devices
- **Local Storage**: Messages stored locally using Hive
- **Material 3 Design**: Modern, beautiful UI
- **Cross-Platform**: Works on Android and iOS
- **No Servers**: Completely decentralized architecture

## 🏗️ Architecture

### Data Layer

- **LocalStorageService**: Hive-based local data persistence
- **P2PNetworkService**: UDP-based peer-to-peer networking
- **ChatRepository**: Combines local storage and network services

### Business Logic

- **ChatController**: GetX-based state management
- **User Management**: Local user creation and management
- **Message Handling**: Real-time message sending/receiving

### Presentation Layer

- **Material 3 UI**: Modern design system
- **Responsive Widgets**: Adaptive to different screen sizes
- **Real-time Updates**: Reactive UI with GetX

## 📱 Installation & Setup

### Prerequisites

- Flutter SDK (3.0+)
- Android Studio / VS Code
- Android device or emulator

### Building the APK

1. **Clone the repository**

   ```bash
   git clone <repository-url>
   cd peerchat
   ```

2. **Install dependencies**

   ```bash
   flutter pub get
   ```

3. **Generate code**

   ```bash
   flutter packages pub run build_runner build --delete-conflicting-outputs
   ```

4. **Build APK**

   ```bash
   flutter build apk --release
   ```

   Or use the provided build script:

   ```bash
   chmod +x build_apk.sh
   ./build_apk.sh
   ```

### Installing on Device

1. **Enable Developer Options**

   - Go to Settings > About Phone
   - Tap "Build Number" 7 times
   - Go back to Settings > Developer Options
   - Enable "USB Debugging"

2. **Enable Unknown Sources**

   - Settings > Security > Unknown Sources (Enable)
   - Or Settings > Apps > Special Access > Install Unknown Apps

3. **Install APK**
   - Transfer APK to device
   - Open file manager and tap the APK
   - Follow installation prompts

## 🔧 Permissions Required

The app requires the following permissions for proper functionality:

### Android Permissions

- `INTERNET` - Network access
- `ACCESS_NETWORK_STATE` - Network state monitoring
- `ACCESS_WIFI_STATE` - WiFi state access
- `CHANGE_WIFI_STATE` - WiFi state modification
- `CHANGE_NETWORK_STATE` - Network state modification
- `ACCESS_FINE_LOCATION` - Location for WiFi discovery
- `ACCESS_COARSE_LOCATION` - Coarse location access
- `WAKE_LOCK` - Keep device awake for UDP communication

### Runtime Permissions

When you first open the app, grant these permissions:

- **Location** - Required for WiFi network discovery
- **Nearby Devices** - For device discovery (Android 12+)

## 🌐 Network Requirements

### WiFi Network Setup

1. **Same Network**: All devices must be on the same WiFi network
2. **Device Communication**: Network must allow device-to-device communication
3. **UDP Ports**: Ports 8888 (discovery) and 8889 (messaging) must be open

### Network Types That Work

- ✅ Home WiFi networks
- ✅ Mobile hotspots
- ✅ Private office networks
- ✅ Guest networks (usually)

### Network Types That May Not Work

- ❌ Corporate networks with strict firewalls
- ❌ Public WiFi with client isolation
- ❌ Networks blocking UDP traffic
- ❌ VPN-protected networks

## 🚀 Usage

### First Time Setup

1. **Launch App**: Open PeerChat
2. **Enter Name**: Choose your display name
3. **Start Chatting**: Tap "Start Chatting"
4. **Grant Permissions**: Allow location and network access

### Chatting

1. **Discovery**: App automatically discovers nearby devices
2. **Send Messages**: Type and send messages
3. **Real-time**: Messages appear instantly on connected devices
4. **Offline Storage**: Messages saved locally

### Features

- **Group Chat**: Chat with all discovered users
- **Private Chat**: One-on-one conversations
- **User Status**: See who's online
- **Message Status**: Delivery indicators
- **Settings**: Customize your profile

## 🔍 Troubleshooting

### App Won't Start

**Problem**: App crashes on startup
**Solutions**:

- Clear app data and restart
- Reinstall the APK
- Check device compatibility (Android 6.0+)
- Ensure sufficient storage space

### No Users Found

**Problem**: Can't discover other devices
**Solutions**:

1. **Check Network**: Ensure all devices on same WiFi
2. **Permissions**: Grant location permissions
3. **Firewall**: Disable device firewall temporarily
4. **Router Settings**: Check if client isolation is disabled
5. **Restart**: Restart app and WiFi connection

### Messages Not Sending

**Problem**: Messages stuck in "sending" state
**Solutions**:

1. **Network Check**: Verify WiFi connection
2. **User Discovery**: Ensure target users are visible
3. **Restart App**: Close and reopen the application
4. **Network Reset**: Disconnect and reconnect to WiFi

### Connection Issues

**Problem**: Frequent disconnections
**Solutions**:

1. **WiFi Stability**: Use stable WiFi network
2. **Battery Optimization**: Disable battery optimization for app
3. **Background Restrictions**: Allow app to run in background
4. **Network Quality**: Move closer to WiFi router

### Performance Issues

**Problem**: App running slowly
**Solutions**:

1. **Clear Messages**: Delete old messages in settings
2. **Restart App**: Close and reopen application
3. **Device Memory**: Close other apps to free memory
4. **Storage Space**: Ensure sufficient device storage

## 🔧 Advanced Configuration

### Network Ports

- **Discovery Port**: 8888 (UDP)
- **Message Port**: 8889 (UDP)
- **Broadcast Address**: 255.255.255.255

### Timeout Settings

- **User Discovery**: 5 seconds interval
- **Heartbeat**: 10 seconds interval
- **User Timeout**: 30 seconds offline threshold

### Storage Locations

- **Messages**: Local Hive database
- **Users**: Local Hive database
- **Settings**: Local Hive database

## 🐛 Known Issues

### Android 12+ Restrictions

- May require "Nearby Devices" permission
- Some devices may block UDP broadcasts
- Battery optimization may affect background operation

### Network Limitations

- Corporate firewalls may block UDP traffic
- Some routers have client isolation enabled
- VPN connections may interfere with discovery

### Device Compatibility

- Minimum Android 6.0 (API 23)
- Requires WiFi capability
- May not work on devices with restricted networking

## 📊 Technical Specifications

### Networking

- **Protocol**: UDP (User Datagram Protocol)
- **Discovery**: Broadcast-based device discovery
- **Messaging**: Direct device-to-device communication
- **Encryption**: None (local network only)

### Storage

- **Database**: Hive (NoSQL)
- **Message Persistence**: Local device storage
- **User Data**: Stored locally
- **No Cloud**: All data remains on device

### Performance

- **Message Latency**: < 100ms on local network
- **Discovery Time**: 1-5 seconds
- **Concurrent Users**: Limited by network capacity
- **Message Size**: Up to 64KB per message

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

If you encounter issues:

1. **Check Troubleshooting**: Review the troubleshooting section above
2. **Network Test**: Test with different WiFi networks
3. **Device Test**: Try on different Android devices
4. **Logs**: Check device logs for error messages
5. **Issue Report**: Create an issue with detailed information

### Reporting Issues

When reporting issues, please include:

- Device model and Android version
- Network type (home/corporate/public)
- Error messages or crash logs
- Steps to reproduce the problem
- Screenshots if applicable

---

**Note**: This app is designed for local network communication and does not require internet connectivity. All communication happens directly between devices on the same WiFi network.
