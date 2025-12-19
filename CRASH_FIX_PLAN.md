# CRASH-001 Fix Plan: Application Crash on Vehicle Disconnect/Reconnect

## Executive Summary
Đề xuất phương án toàn diện để fix crash khi Pixhawk reboot hoặc mất kết nối MAVLink. Crash xảy ra do null pointer dereference trong CombinedRSSIIndicator.qml khi vehicle disconnect nhưng QML Connections vẫn tham chiếu tới vehicle object cũ.

---

## Phase 1: Root Cause Analysis & Diagnosis (2-3 ngày)

### 1.1 Điều tra chi tiết
```bash
# Bước 1: Reproduce issue với debug symbols
cd build/Desktop_Qt_6_8_3-Release
cmake --build . --config Debug -j4
./Release/QGroundControl --help-all | grep log

# Bước 2: Chạy với gdb
gdb ./Release/QGroundControl
(gdb) run
# Trigger disconnect/reboot
# Capture backtrace khi crash
(gdb) bt full
(gdb) info registers
(gdb) disassemble
```

### 1.2 Kiểm tra log files
```bash
# QGC logs
cat ~/.config/QGroundControl/*.log

# System logs
journalctl -xe | grep QGround
dmesg | tail -50

# Core dump (nếu có)
coredumpctl list
coredumpctl debug <PID>
```

### 1.3 Xác định liên quan RSSI Indicator
- ✅ Thêm extensive logging vào CombinedRSSIIndicator.qml
- ✅ Monitor `activeVehicleChanged` signal
- ✅ Check Connections target lifecycle
- ✅ Verify property binding updates

**Log format:**
```qml
console.log("[RSSI] activeVehicle changed to:", _activeVehicle ? _activeVehicle.id : "null")
console.log("[RSSI] Connections target:", target)
console.log("[RSSI] _rcRSSIValue:", _rcRSSIValue, "_telemetryLRSSI:", _telemetryLRSSI)
```

---

## Phase 2: Immediate Hotfix (1-2 ngày) 🔴 URGENT

### 2.1 Fix CombinedRSSIIndicator.qml

**Problem:**
```qml
Connections {
    target: _activeVehicle  // ← NULL khi disconnect!
    ignoreUnknownSignals: true
    function onRcRSSIChanged(rssi) { ... }
}
```

**Solution A: Add enabled check (Recommended - Immediate)**
```qml
Connections {
    target: _activeVehicle
    enabled: _activeVehicle !== null  // ← Disable khi null
    ignoreUnknownSignals: true
    
    function onRcRSSIChanged(rssi) {
        if (_activeVehicle) {  // ← Double check
            console.log("[RSSI] RC RSSI changed:", rssi)
        }
    }
    
    function onTelemetryLRSSIChanged(rssi) {
        if (_activeVehicle) {
            console.log("[RSSI] Telemetry RSSI changed:", rssi)
        }
    }
}
```

**Solution B: Use try-catch (Additional safeguard)**
```qml
function onRcRSSIChanged(rssi) {
    try {
        if (!_activeVehicle) {
            console.warn("[RSSI] _activeVehicle is null in signal handler")
            return
        }
        console.log("[RSSI] RC RSSI changed:", rssi)
    } catch(e) {
        console.error("[RSSI] Exception in RC RSSI handler:", e.toString())
    }
}
```

### 2.2 Add active vehicle monitoring
```qml
Connections {
    target: QGroundControl.multiVehicleManager
    
    function onActiveVehicleChanged(vehicle) {
        console.log("[RSSI] Active vehicle changed - old:", _activeVehicle ? _activeVehicle.id : "null", 
                                                        "new:", vehicle ? vehicle.id : "null")
        if (!vehicle) {
            console.warn("[RSSI] Vehicle disconnected, disabling RSSI updates")
            _rcRSSIValue = 0
            _telemetryLRSSI = 0
        }
    }
}
```

### 2.3 Safer property binding
```qml
// BEFORE (Unsafe)
property int  _rcRSSIValue:   _activeVehicle ? _activeVehicle.rcRSSI : 0

// AFTER (Safer)
property int  _rcRSSIValue: {
    if (_activeVehicle && typeof _activeVehicle !== 'undefined') {
        try {
            return _activeVehicle.rcRSSI
        } catch(e) {
            console.error("[RSSI] Error reading rcRSSI:", e)
            return 0
        }
    }
    return 0
}
```

### 2.4 Commit hotfix
```bash
git add src/UI/toolbar/CombinedRSSIIndicator.qml
git commit -m "fix(CRASH-001): add null checks and enabled flag to RSSI Connections

- Add 'enabled: _activeVehicle !== null' to Connections
- Add try-catch in signal handlers
- Monitor activeVehicleChanged
- Prevent null pointer dereference on disconnect"
```

---

## Phase 3: Comprehensive Vehicle Lifecycle Management (3-5 ngày)

### 3.1 Create Vehicle Lifecycle Monitor Component
**File**: `src/UI/toolbar/VehicleLifecycleMonitor.qml`

```qml
import QtQuick
import QGroundControl

Item {
    id: monitor
    
    // Emitted signals
    signal vehicleConnected(var vehicle)
    signal vehicleDisconnected(var vehicle)
    signal vehicleReconnecting()
    
    property var  _activeVehicle: QGroundControl.multiVehicleManager.activeVehicle
    property bool isVehicleConnected: _activeVehicle !== null
    
    // Track vehicle state transitions
    property var _previousVehicle: null
    property int _disconnectCount: 0
    property int _reconnectAttempts: 0
    
    Connections {
        target: QGroundControl.multiVehicleManager
        
        function onActiveVehicleChanged(vehicle) {
            if (!vehicle) {
                // Vehicle disconnected
                console.log("[VehicleLifecycle] Vehicle disconnected")
                monitor.vehicleDisconnected(_previousVehicle)
                _disconnectCount++
            } else if (!_previousVehicle || vehicle.id !== _previousVehicle.id) {
                // New vehicle connected
                console.log("[VehicleLifecycle] Vehicle connected:", vehicle.id)
                monitor.vehicleConnected(vehicle)
                _reconnectAttempts++
            }
            _previousVehicle = vehicle
        }
    }
    
    // Monitor vehicle communication status
    Connections {
        target: _activeVehicle
        enabled: _activeVehicle !== null
        ignoreUnknownSignals: true
        
        function onCommunicationLostChanged() {
            if (_activeVehicle.vehicleLinkManager.communicationLost) {
                console.warn("[VehicleLifecycle] Communication lost")
                monitor.vehicleReconnecting()
            }
        }
    }
    
    // Functions for dependent components
    function isSafeToAccess() {
        return _activeVehicle !== null && 
               typeof _activeVehicle !== 'undefined' &&
               !_activeVehicle.vehicleLinkManager.communicationLost
    }
    
    function safeGetProperty(propertyName, defaultValue) {
        try {
            if (!isSafeToAccess()) return defaultValue
            return _activeVehicle[propertyName]
        } catch(e) {
            console.error("[VehicleLifecycle] Error accessing property:", propertyName, e)
            return defaultValue
        }
    }
}
```

### 3.2 Update CombinedRSSIIndicator to use lifecycle monitor
```qml
import "." as CustomControls  // Import lifecycle monitor

Item {
    // Use lifecycle monitor
    CustomControls.VehicleLifecycleMonitor {
        id: vehicleMonitor
        
        onVehicleDisconnected: {
            console.log("[RSSI] Received disconnect notification")
            _rcRSSIValue = 0
            _telemetryLRSSI = 0
        }
        
        onVehicleConnected: {
            console.log("[RSSI] Received connect notification for vehicle:", vehicle.id)
            // Reset and prepare for new vehicle
        }
        
        onVehicleReconnecting: {
            console.log("[RSSI] Vehicle reconnecting...")
            // Optionally show loading state
        }
    }
    
    // Use safe property access
    property int  _rcRSSIValue:   vehicleMonitor.safeGetProperty("rcRSSI", 0)
    property int  _telemetryLRSSI: vehicleMonitor.safeGetProperty("telemetryLRSSI", 0)
}
```

### 3.3 Add global error handler
**File**: `src/UI/ErrorHandler.qml`

```qml
import QtQuick

Item {
    id: errorHandler
    
    // Global uncaught exception handler
    property var exceptionHandler: function(exception) {
        console.error("[ErrorHandler] Uncaught exception:", exception)
        console.error("[ErrorHandler] Stack:", exception.stack || "No stack trace")
        
        // Log to file
        var logMessage = {
            timestamp: new Date().toISOString(),
            exception: exception.toString(),
            stack: exception.stack || "No stack",
            source: exception.fileName || "Unknown",
            line: exception.lineNumber || 0
        }
        
        // Send to logging service
        qmlErrorLogger.logException(logMessage)
    }
}
```

---

## Phase 4: Enhanced Testing Strategy (2-3 ngày)

### 4.1 Unit Tests
**File**: `test/UI/CombinedRSSIIndicatorTest.qml`

```qml
import QtQuick
import QtTest
import QGroundControl

TestCase {
    id: test
    name: "CombinedRSSIIndicatorTest"
    
    function test_null_vehicle_safety() {
        // Test with null vehicle
        var indicator = createObject(CombinedRSSIIndicator, {})
        indicator._activeVehicle = null
        wait(100)  // Allow async updates
        
        // Should not crash
        verify(indicator._rcRSSIValue === 0)
        verify(indicator._telemetryLRSSI === 0)
    }
    
    function test_vehicle_disconnect() {
        // Setup with vehicle
        var mockVehicle = createMockVehicle()
        indicator._activeVehicle = mockVehicle
        verify(indicator._rcRSSIValue === 40)
        
        // Disconnect
        indicator._activeVehicle = null
        
        // Should safely reset
        verify(indicator._rcRSSIValue === 0)
        // No crash!
    }
    
    function test_rapid_disconnect_reconnect() {
        for (var i = 0; i < 10; i++) {
            indicator._activeVehicle = createMockVehicle()
            wait(50)
            indicator._activeVehicle = null
            wait(50)
        }
        // No crash after rapid cycles!
    }
    
    function test_connections_signal_safety() {
        var mockVehicle = createMockVehicle()
        indicator._activeVehicle = mockVehicle
        
        // Simulate signal emit after disconnect
        mockVehicle._rcRSSIValue = 50
        indicator._activeVehicle = null
        mockVehicle.rcRSSIChanged(50)  // Should not crash!
        
        wait(100)
        verify(true)  // Test passed if no crash
    }
}
```

### 4.2 Integration Tests
```bash
# Test 1: Disconnect during normal operation
./test_vehicle_disconnect.py --mode=armed --duration=5s

# Test 2: Reboot autopilot
./test_pixhawk_reboot.py --count=5 --delay=10s

# Test 3: Rapid connect/disconnect
./test_rapid_cycles.py --cycles=20 --interval=1s

# Test 4: Network interruption
./test_network_loss.py --duration=30s --interval=5s

# Test 5: Multiple vehicles
./test_multi_vehicle.py --count=3 --disconnect_random=true
```

### 4.3 Stress Test Scenario
```bash
#!/bin/bash
# Simulates real-world harsh conditions

for i in {1..50}; do
    echo "Cycle $i: Connect -> Arm -> Disarm -> Disconnect"
    
    # Connect
    python mavproxy.py --master=/dev/ttyUSB0,57600
    
    # Let it run for 5 seconds
    sleep 5
    
    # Kill connection abruptly (no graceful shutdown)
    pkill -9 mavproxy
    
    sleep 2
done

echo "All 50 cycles completed without crash!"
```

---

## Phase 5: Prevention & Best Practices (Ongoing)

### 5.1 QML Safety Guidelines
Document `DEVELOPER_GUIDE.md`:

```markdown
## QML Vehicle Access Safety Rules

### ❌ NEVER DO THIS
```qml
property var vehicle: activeVehicle
property int rssi: vehicle.rcRSSI  // Crash if vehicle becomes null!

Connections {
    target: vehicle  // Can be null!
}
```

### ✅ ALWAYS DO THIS
```qml
property var vehicle: activeVehicle
property int rssi: vehicle ? vehicle.rcRSSI : 0

Connections {
    target: vehicle
    enabled: vehicle !== null
}
```

### ✅ BEST PRACTICE: Use wrapper
```qml
function safeAccess(property, defaultValue) {
    try {
        if (!vehicle || vehicle === undefined) return defaultValue
        return vehicle[property]
    } catch(e) {
        console.error("Safe access failed:", e)
        return defaultValue
    }
}
```
```

### 5.2 Code Review Checklist
```markdown
## CR Checklist for QML Components Using Vehicle

- [ ] All vehicle property accesses have null checks
- [ ] All Connections to vehicle have `enabled` flag
- [ ] All signal handlers have try-catch
- [ ] Component cleans up on vehicleDisconnected
- [ ] No dangling references to previous vehicle
- [ ] Tested with rapid connect/disconnect cycles
- [ ] Console logging for debugging
- [ ] Error handling graceful (no crash on error)
```

### 5.3 Automated Testing CI/CD
**File**: `.github/workflows/stability-test.yml`

```yaml
name: Stability Tests

on: [push, pull_request]

jobs:
  crash-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Build
        run: cmake --build build -j4
      
      - name: Run CRASH-001 tests
        run: |
          cd test
          python -m pytest test_vehicle_lifecycle.py -v
          python -m pytest test_rssi_stability.py -v
          python -m pytest test_disconnect_safety.py -v
      
      - name: Run stress tests
        run: |
          ./test/stress/rapid_disconnect_reconnect.sh
          ./test/stress/network_interruption.sh
      
      - name: Check for segfaults in logs
        run: |
          grep -i "segmentation\|crash\|fatal" build/logs/* && exit 1 || true
      
      - name: Archive test results
        if: always()
        uses: actions/upload-artifact@v2
        with:
          name: test-results
          path: test/results/
```

---

## Phase 6: Monitoring & Observability (2-3 ngày)

### 6.1 Crash Reporting
**File**: `src/Utilities/CrashReporter.cc`

```cpp
class CrashReporter {
private:
    static void signalHandler(int signal) {
        // Capture stack trace
        void* addrlist[32];
        int addrlen = backtrace(addrlist, 32);
        
        // Write to file
        FILE* f = fopen("/tmp/qgc_crash.log", "a");
        fprintf(f, "=== CRASH DUMP ===\n");
        fprintf(f, "Signal: %d\n", signal);
        fprintf(f, "Time: %s\n", QDateTime::currentDateTime().toString().toStdString().c_str());
        
        // Backtrace
        backtrace_symbols_fd(addrlist, addrlen, fileno(f));
        fclose(f);
        
        // Exit gracefully
        exit(signal);
    }
    
public:
    static void install() {
        signal(SIGSEGV, signalHandler);
        signal(SIGABRT, signalHandler);
        signal(SIGBUS, signalHandler);
    }
};
```

### 6.2 Telemetry / Analytics
```qml
Item {
    Connections {
        target: QGroundControl.multiVehicleManager
        
        function onActiveVehicleChanged(vehicle) {
            // Send analytics
            var event = {
                event_type: "vehicle_state_change",
                timestamp: new Date().getTime(),
                vehicle_id: vehicle ? vehicle.id : null,
                previous_vehicle_id: _lastVehicleId,
                was_armed: _wasArmed,
                was_flying: _wasFlying
            }
            
            analyticsService.logEvent(event)
            _lastVehicleId = vehicle ? vehicle.id : null
        }
    }
}
```

---

## Implementation Timeline

| Phase | Duration | Effort | Priority |
|-------|----------|--------|----------|
| **1. Root Cause Analysis** | 2-3 days | 10 hours | 🔴 CRITICAL |
| **2. Immediate Hotfix** | 1-2 days | 5 hours | 🔴 CRITICAL |
| **3. Lifecycle Manager** | 3-5 days | 20 hours | 🟠 HIGH |
| **4. Testing** | 2-3 days | 15 hours | 🟠 HIGH |
| **5. Best Practices** | 2-3 days | 10 hours | 🟡 MEDIUM |
| **6. Monitoring** | 2-3 days | 10 hours | 🟡 MEDIUM |
| **TOTAL** | **12-19 days** | **70 hours** | |

---

## Risk Assessment

### High Risk
- ✅ Phase 2 hotfix essential before Phase 3
- ✅ Requires real hardware testing
- ⚠️ Race conditions hard to reproduce

### Medium Risk
- Lifecycle manager refactor could break other components
- Requires thorough regression testing

### Low Risk
- Best practices documentation
- CI/CD automation

---

## Success Criteria

- ✅ No crash on rapid disconnect/reconnect cycles (100 cycles)
- ✅ No crash on Pixhawk reboot (10 reboots)
- ✅ No crash on network interruption (5 minutes)
- ✅ Graceful error messages in logs
- ✅ Full stack traces in crash dumps
- ✅ All unit tests passing
- ✅ All integration tests passing

---

## Rollback Plan

If unforeseen issues arise:

1. **Hotfix rollback**: `git revert <commit-hash>`
2. **Disable RSSI indicator**: Set `visible: false` in FlyViewToolBar.qml
3. **Disable logging**: Comment out console.log statements
4. **Use previous stable commit**: `git checkout <stable-tag>`

---

## Next Steps

1. **Immediate (Today)**
   - Implement Phase 2 hotfix
   - Test with rapid disconnect cycles
   - Commit and merge to main branch

2. **This Week**
   - Complete Phase 1 root cause analysis with real hardware
   - Begin Phase 3 implementation

3. **Next Week**
   - Complete testing
   - Review and merge
   - Deploy to production
