# QGroundControl Custom Build - Comprehensive Project Analysis

## 📋 Executive Summary

**My QGroundControl Custom** is a modified and customized version of the official QGroundControl (QGC) ground control station. QGroundControl is an open-source, cross-platform application for UAV (unmanned aerial vehicle) flight control and mission planning. This custom build extends the base QGC with additional features, customizations, and optimizations for specific use cases.

**Repository**: https://github.com/ThangDuc3101/my-qgc-custom  
**Base Project**: https://github.com/mavlink/qgroundcontrol  
**Primary Language**: C++ with QML (Qt Quick) for UI  
**Framework**: Qt 6.8.3  
**Build System**: CMake (v3.25+)

---

## 🏗️ Project Structure

```
my-qgc-custom/
├── src/                          # Source code (39 MB, ~85,558 lines)
│   ├── ADSB/                     # ADS-B aircraft detection & display
│   ├── AnalyzeView/              # Log analysis and data analysis tools
│   ├── Android/                  # Android-specific implementations
│   ├── API/                       # External API interfaces
│   ├── AutoPilotPlugins/         # Firmware-specific autopilot plugins
│   ├── Camera/                   # Camera control and management
│   ├── Comms/                    # Communication/link management (TCP, UDP, Serial)
│   ├── FactSystem/               # Parameter/fact management system
│   ├── FirmwarePlugin/           # Firmware abstraction layer (APM, PX4)
│   ├── FlightDisplay/            # Flight HUD and instrument panel
│   ├── FlightMap/                # Map display and interaction
│   ├── FollowMe/                 # Follow-me mode functionality
│   ├── Gimbal/                   # Gimbal control
│   ├── GPS/                      # GPS/RTK positioning
│   ├── Joystick/                 # Joystick/gamepad input handling
│   ├── MAVLink/                  # MAVLink protocol implementation
│   ├── MissionManager/           # Mission planning and execution
│   ├── PositionManager/          # Position tracking and management
│   ├── QmlControls/              # Reusable QML components
│   ├── QtLocationPlugin/         # Qt Location provider integration
│   ├── Settings/                 # Application settings management
│   ├── Terrain/                  # Terrain data handling
│   ├── UI/                       # Main UI components and views
│   ├── Utilities/                # Utility functions and helpers
│   ├── UTMSP/                    # UTM Service Provider integration
│   ├── Vehicle/                  # Vehicle abstraction layer
│   ├── VideoManager/             # Video streaming and recording
│   ├── Viewer3D/                 # 3D visualization
│   ├── QGCApplication.{h,cc}     # Main application class
│   ├── main.cc                   # Application entry point
│   └── pch.h                     # Precompiled headers
│
├── custom-example/               # Example custom build implementation
│   ├── src/                      # Custom source code
│   ├── res/                      # Custom resources
│   ├── cmake/                    # Custom CMake modules
│   └── android/                  # Android build configuration
│
├── test/                         # Unit tests (122 test files)
│   ├── FactSystem/
│   ├── MissionManager/
│   └── ...
│
├── docs/                         # Documentation (VitePress)
│   ├── en/                       # English documentation
│   ├── zh/                       # Chinese documentation
│   ├── ko/                       # Korean documentation
│   ├── tr/                       # Turkish documentation
│   ├── assets/                   # Documentation assets
│   └── .vitepress/               # VitePress configuration
│
├── resources/                    # Application resources
│   ├── InstrumentValueIcons/    # Instrument icons
│   └── qtquickcontrols2.conf    # Qt Quick Controls configuration
│
├── deploy/                       # Deployment scripts and configs
├── android/                      # Android build resources
├── cmake/                        # CMake build configuration
│   ├── find-modules/
│   ├── install/
│   ├── modules/
│   ├── platform/
│   └── Helpers.cmake
│
├── tools/                        # Build and setup tools
├── translations/                 # i18n translation files
│
├── CMakeLists.txt               # Root CMake configuration
├── package.json                 # NPM dependencies (VitePress)
├── CHANGELOG.md                 # Version history
├── README.md                    # Setup and build instructions (Vietnamese)
├── LICENSE-APACHE               # Apache 2.0 License
├── LICENSE-GPL                  # GPL License
├── AGENTS.md                    # AI agent configuration
├── .clang-format                # Code style (Clang)
├── .clang-tidy                  # Linting configuration
├── .cmake-format                # CMake formatting rules
├── .qmlls.ini                   # QML language server config
└── ...
```

---

## 📊 Codebase Statistics

| Metric | Value |
|--------|-------|
| **Total Project Size** | ~14 GB (with build artifacts) |
| **Source Code Size** | 39 MB |
| **C++ Source Files** | 715 files (.h and .cc) |
| **QML Files** | 436 files |
| **Lines of C++ Code** | ~85,558 lines |
| **Test Files** | 122 files |
| **Git Commits** | 20,666 commits |
| **Documentation** | VitePress-based, multi-language |

---

## 🎯 Key Features & Capabilities

### Core Flight Control
- **Vehicle Management**: Support for multiple vehicle types (Copter, Plane, Rover, Sub)
- **Mission Planning**: Waypoint missions, survey patterns, corridors, polygon scanning
- **Flight Display**: Attitude indicator, heading indicator, altitude/speed instruments
- **Virtual Joystick**: Remote flight control via gamepad or virtual controls
- **Auto Missions**: Takeoff, landing, return-to-home, guided mode operations

### Communication
- **Protocol Support**: MAVLink 1 & 2, MAVLink signing enabled
- **Link Types**: Serial, TCP, UDP, Bluetooth, USB
- **Multi-Vehicle**: Simultaneous control of multiple UAVs
- **Telemetry**: Real-time vehicle state, mission progress, diagnostics

### Advanced Features
- **ADS-B Integration**: Aircraft detection and collision avoidance visualization
- **Camera Control**: Multi-camera support with zoom, focus, photo/video recording
- **Gimbal Control**: 2-axis/3-axis gimbal stabilization
- **RTK GPS**: Precision positioning with RTK correction support
- **Terrain Awareness**: Terrain collision detection and terrain-following missions
- **Video Streaming**: GStreamer support for H.264/H.265 video playback
- **Structure Scanning**: 3D structure capture missions

### Planning Tools
- **Survey Creator**: Automatic grid-based area survey generation
- **Complex Items**: Corridors, polygons, landing patterns, structure scans
- **Geofencing**: Virtual boundary definition and enforcement
- **Rally Points**: Emergency landing points
- **Terrain Profile**: 3D terrain visualization along flight path

### Firmware Support
- **PX4**: Pixhawk autopilot support with full integration
- **ArduPilot**: APM autopilot (Copter, Plane, Rover, Sub variants)
- **Custom Autopilots**: Plugin architecture for custom firmware support

### Customization & Extensibility
- **Custom Builds**: Example custom build framework for white-label applications
- **UI Theming**: Customizable color schemes and branding
- **Advanced Mode**: Toggle between simple and advanced UI modes
- **Plugin Architecture**: Extensible autopilot and custom build plugins

### Analysis & Logging
- **Log Replay**: Playback of flight logs for analysis
- **Telemetry Inspector**: Real-time MAVLink message inspection
- **Geo-tagging**: Photo metadata with GPS coordinates
- **Telemetry Forwarding**: UDP port forwarding for external analysis

---

## 🛠️ Technology Stack

### Build System & Compilation
- **CMake**: Cross-platform build configuration (3.25+)
- **Qt Creator**: Recommended IDE
- **C++17/20**: Modern C++ standards
- **Clang**: Code formatting and linting

### Framework & Libraries
- **Qt 6.8.3**: UI framework, networking, multimedia, positioning
- **MAVLink Protocol**: Autopilot communication
- **GStreamer**: Video streaming and processing
- **OpenGL/Quick3D**: 3D visualization
- **SQLite**: Local data persistence
- **QML/Qt Quick**: Declarative UI markup language

### Platform Support
- **Linux** (Ubuntu 22.04 LTS recommended)
- **macOS** (x86_64 and ARM64 universal builds)
- **Windows** (64-bit)
- **Android** (min SDK 28)
- **iOS** (experimental)

### Documentation
- **VitePress**: Static site generator for docs
- **Markdown**: Documentation source format
- **Multi-language**: English, Chinese, Korean, Turkish translations

---

## 📝 Version History & Recent Changes

### Version 5.0 (Daily Build)
- **UI Enhancement**: Combined compass + attitude instrument
- **Instrument Selection**: Context switching via click/long-press
- **MAVLink Actions**: Custom action system for flight control
- **MAVLink 2 Signing**: Enhanced security for autopilot communication
- **Battery Display**: Dynamic bars with configurable thresholds
- **Message Rate Control**: Per-message MAVLink rate adjustment

### Version 4.1
- Camera support (simple cameras with DIGICAM_CONTROL)
- Parameter management (load from file, diff dialog, selective upload)
- Video streaming image capture
- Enhanced VTOL support with transition-distance settings
- Map zoom up to level 23
- Terrain protocol for GCS terrain queries
- VTOL landing pattern support

### Earlier Versions (4.0, 3.5, 3.4)
- Comprehensive feature set with continuous improvements
- Motor test for ArduPilot
- Structure scan rewrite
- Joystick action modes
- H.265 video codec support
- Enhanced localization (Korean, Chinese fonts)

---

## 📦 Key Components Deep Dive

### 1. **MAVLink System**
- Abstraction layer for autopilot communication
- Protocol versioning (MAVLink 1 & 2)
- Message parsing and serialization
- Custom message support for extended functionality

### 2. **Vehicle Layer**
- Vehicle abstraction (common interface for all autopilot types)
- Component information management
- Parameter system (reading, writing, syncing)
- Fact groups for organized parameter access

### 3. **Firmware Plugins**
- **APM Plugin**: ArduCopter, ArduPlane, ArduRover, ArduSub
- **PX4 Plugin**: Pixhawk-based autopilots
- Plugin architecture for custom firmware integration
- Firmware-specific parameter sets and modes

### 4. **Mission System**
- Mission item abstraction
- Complex mission items (survey, corridors, landing patterns)
- Visual mission item editing
- Mission file import/export (QGC format, KML)

### 5. **Fact System**
- Hierarchical parameter organization
- Real-time parameter updates
- Parameter validation and constraints
- Undo/redo for parameter changes

### 6. **Communication Manager**
- Multiple simultaneous links
- Automatic link failover
- Link configuration and monitoring
- Vehicle discovery and connection

### 7. **UI Framework**
- QML-based responsive interface
- Custom controls (sliders, combo boxes, text fields)
- Instrument panel system
- Context-sensitive menus and dialogs

---

## 🔧 Build Configuration & Customization

### Custom Build Framework
Located in `custom-example/`, this demonstrates how to create a white-label variant:
- Brand customization (colors, logos, company info)
- Simplified UI for commercial products
- Hidden advanced settings
- Custom UI components and views
- Application behavior overrides

### CMake Options
- `QGC_CUSTOM_BUILD`: Enable custom build processing
- `QGC_BUILD_TESTING`: Include unit tests
- `QGC_ENABLE_HERELINK`: Herelink radio support
- `QGC_USE_CACHE`: CMake caching for faster builds
- Platform-specific: macOS universal builds, Android SDK targeting

---

## 🧪 Testing & Quality Assurance

- **Unit Tests**: 122 test files covering core functionality
- **Fact System Tests**: Parameter system validation
- **Mission Manager Tests**: Mission planning and execution
- **Test Framework**: Qt Test framework (gtest compatible)
- **Code Style**: Clang-format + clang-tidy enforcement
- **CI/CD**: Code coverage tracking with Codecov

---

## 📚 Documentation & Localization

### Documentation
- **VitePress-based** static site generation
- **Multi-language support**: English, Chinese, Korean, Turkish
- **Developer Guide**: Custom builds, plugin architecture, API reference
- **Setup Instructions**: Ubuntu, Qt installer, dependencies

### Translations
- **Translation Files**: `translations/qgc_*.ts` (20+ languages)
- **Crowdin Integration**: Automated localization workflow
- **Font Support**: Enhanced Korean and Chinese rendering

---

## 🚀 Build & Deployment

### Ubuntu 22.04 Setup
```bash
git clone https://github.com/ThangDuc3101/my-qgc-custom.git
cd my-qgc-custom
git submodule update --init --recursive
sudo bash ./tools/setup/install-dependencies-debian.sh
```

### Qt Requirements
- **Qt Version**: 6.8.3 (mandatory) or 6.6.3 with Herelink
- **Minimum Android SDK**: 28 (25 with Herelink)
- **macOS Deployment Target**: 12.0

### Deployment Artifacts
- **Desktop**: Standalone executables (Linux, macOS, Windows)
- **Android**: APK files (min SDK 28)
- **Installation**: CPack-based installers for all platforms
- **Signing**: MAVLink 2 signing support for security

---

## 📂 Important Configuration Files

| File | Purpose |
|------|---------|
| `.clang-format` | C++ code formatting rules |
| `.clang-tidy` | Static analysis configuration |
| `.cmake-format` | CMake formatting standards |
| `.qmlls.ini` | QML language server settings |
| `CMakeLists.txt` | Build system configuration |
| `package.json` | Documentation build dependencies |
| `CHANGELOG.md` | Version history and features |
| `.pre-commit-config.yaml` | Git hooks for code quality |

---

## 🔄 Git & Version Control

- **Repository**: https://github.com/ThangDuc3101/my-qgc-custom
- **Total Commits**: 20,666
- **Submodules**: Qt dependencies and firmware plugins
- **License**: Dual-licensed (Apache 2.0 + GPL)

---

## 💡 Development Highlights

### Strengths
1. **Modular Architecture**: Clean separation of concerns with plugin-based design
2. **Cross-Platform**: Seamless support for Windows, macOS, Linux, Android
3. **Extensibility**: Custom build framework and plugin architecture
4. **Active Development**: Frequent updates with new features
5. **Comprehensive Testing**: Unit tests and integration testing
6. **Well-Documented**: Inline code comments, external documentation, examples
7. **Community-Driven**: Based on popular open-source project

### Technical Excellence
1. **Modern C++**: Uses C++17/20 standards
2. **Qt Framework**: Industry-standard UI framework with excellent cross-platform support
3. **MAVLink Integration**: Deep integration with MAVLink protocol ecosystem
4. **Performance Optimization**: CMake caching, precompiled headers, efficient rendering
5. **Code Quality**: Clang-tidy, clang-format enforcement through pre-commit hooks

---

## 🎓 Use Cases

1. **UAV Mission Planning**: Professional-grade mission design and execution
2. **Research & Development**: Autonomous vehicle control and data collection
3. **Commercial Drones**: White-label custom builds for commercial vendors
4. **Education**: Drone programming and control system learning
5. **Search & Rescue**: Real-time vehicle telemetry and control
6. **Precision Agriculture**: Automated survey and mapping missions
7. **Industrial Inspection**: Structure scanning and terrain-aware flying

---

## 📌 Key Takeaways

- **Modern QGC Fork**: Well-maintained customization of QGroundControl with additional features
- **Production-Ready**: Suitable for commercial and professional applications
- **Highly Extensible**: Custom build framework allows white-label implementations
- **Feature-Rich**: Comprehensive autopilot support, mission planning, and analysis tools
- **Well-Maintained**: Active development with regular updates and improvements
- **Cross-Platform**: Works on desktop (Windows, macOS, Linux) and mobile (Android)

---

## 📞 Additional Resources

- **Official QGC Dev Guide**: https://dev.qgroundcontrol.com
- **MAVLink Protocol**: https://mavlink.io
- **Qt Documentation**: https://doc.qt.io
- **GitHub Issues**: For bug reports and feature requests
- **Documentation**: `/docs` folder with multi-language guides

---

*Generated: December 14, 2025*  
*Analysis includes source code structure, component architecture, feature set, technology stack, and development practices.*
