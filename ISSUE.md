# RSSI Indicator Issue

## Issue ID
RSSI-001

## Tiêu đề
RSSI value không được cập nhật liên tục - giá trị bị fix cứng ở 40%

## Mô tả vấn đề
RSSI indicator được thêm vào toolbar để hiển thị chất lượng tín hiệu (RC RSSI và Telemetry RSSI). Tuy nhiên, giá trị RSSI hiển thị không thay đổi khi di chuyển thiết bị hoặc thay đổi điều kiện tín hiệu.

**Hiện tượng quan sát:**
- RC RSSI value hiển thị cố định ở mức 40% 
- Không thay đổi khi di chuyển UAV hoặc GCS
- Telemetry RSSI cũng không cập nhật
- Không có dấu hiệu của signal strength thay đổi

## Nguyên nhân tiềm năng
1. **MAVLink messages không được nhận**: Vehicle có thể không nhận được RC_CHANNELS_RAW hoặc RADIO_STATUS messages từ autopilot
2. **RSSI data chưa được enable trên autopilot**: APM/PX4 firmware chưa được cấu hình để gửi RSSI data
3. **Binding QML không hoạt động**: Có thể có vấn đề với binding hoặc property notification từ Vehicle class
4. **Vehicle không được kết nối**: Nếu không có vehicle connected, dữ liệu không được cập nhật
5. **RC receiver không hoặc hỗ trợ RSSI**: Receiver không gửi RSSI data trên PWM channels

## Yêu cầu kiểm tra

### Cần xác nhận:
- [ ] Vehicle (UAV) có được kết nối thành công không?
- [ ] Autopilot firmware có gửi RC_CHANNELS_RAW messages không?
- [ ] RC receiver có hỗ trợ RSSI output không?
- [ ] Tham số `RC_RSSI_PWM_CHAN` trên autopilot có được cấu hình không?
- [ ] Console logs có in ra "RC RSSI Changed" messages không?
- [ ] Dữ liệu RSSI từ CAN bus hoặc serial link có được nhận không?

## Giải pháp tạm thời
Thêm debug logging và Connections để monitor giá trị RSSI:
- Console logs in ra khi RC RSSI hoặc Telemetry RSSI thay đổi
- Properties được thêm để track _rcRSSIValue và _telemetryLRSSI
- Dễ dàng phát hiện nếu signal không được emit

## Mức độ ưu tiên
**Medium** - Chức năng có hạn chế nhưng không ngăn chặn hoạt động chính của ứng dụng

## Liên quan đến
- `src/UI/toolbar/CombinedRSSIIndicator.qml`
- `src/Vehicle/Vehicle.h`
- `src/Vehicle/Vehicle.cc`
- `src/QmlControls/FlyViewToolBar.qml`

## Ghi chú thêm
- RSSI indicator đã được thêm vào toolbar và UI trông đẹp
- Binding QML đã được cập nhật để theo dõi giá trị
- Cần thêm thiết bị thực hoặc mock data để test cập nhật RSSI

---

# Application Crash on Pixhawk Reboot or Connection Loss

## Issue ID
CRASH-001

## Tiêu đề
Ứng dụng bị crash khi reboot Pixhawk hoặc khi mất kết nối với vehicle

## Mô tả vấn đề
Ứng dụng QGroundControl bị crash (segmentation fault hoặc null pointer exception) trong các tình huống sau:
1. Khi Pixhawk/autopilot bị reboot trong khi ứng dụng đang chạy
2. Khi kết nối MAVLink bị mất đột ngột (disconnect từ GCS side)
3. Khi vehicle reconnect sau khi bị mất kết nối

**Hiện tượng quan sát:**
- Ứng dụng tắt hoàn toàn mà không có cảnh báo
- Crash không được graceful, không có error dialog
- Không ghi log hoặc log không đầy đủ
- Phải restart ứng dụng lại

## Nguyên nhân tiềm năng
1. **Null pointer dereference**: Vehicle object bị xóa trong khi QML binding vẫn tham chiếu
2. **Dangling pointers**: Con trỏ tới vehicle/link object không được cập nhật khi disconnect
3. **Property access after delete**: Binding QML vẫn cố truy cập property của vehicle đã bị xóa
4. **Missing disconnect handlers**: Không xử lý cleanup khi vehicle disconnect
5. **Race condition**: Thread synchronization issue giữa MAVLink thread và UI thread
6. **Signal-slot mismatch**: Stale signal connections sau khi reconnect
7. **Memory corruption**: Buffer overflow hoặc invalid memory access trong MAVLink parsing

## Nghi ngờ liên quan đến RSSI Indicator
Khả năng cao vấn đề nằm ở CombinedRSSIIndicator.qml:
```qml
property var  _activeVehicle: QGroundControl.multiVehicleManager.activeVehicle
property int  _rcRSSIValue:   _activeVehicle ? _activeVehicle.rcRSSI : 0
property int  _telemetryLRSSI: _activeVehicle ? _activeVehicle.telemetryLRSSI : 0

Connections {
    target: _activeVehicle  // ← Có thể bị null khi disconnect
    ignoreUnknownSignals: true
    
    function onRcRSSIChanged(rssi) {
        console.log("RC RSSI Changed:", rssi)
    }
}
```

**Vấn đề:**
- Khi vehicle disconnect, `_activeVehicle` trở thành null
- `Connections` target vẫn tham chiếu tới object cũ
- Khi reboot/reconnect, crash xảy ra

## Yêu cầu kiểm tra

### Cần xác nhận:
- [ ] Crash có in ra stack trace hoặc error message không?
- [ ] Console log có thông báo gì khi vehicle disconnect không?
- [ ] Crash xảy ra ở component RSSI hay ở component khác?
- [ ] Có segmentation fault trong MAVLink thread không?
- [ ] Vehicle reconnect có hoạt động sau crash không?
- [ ] Có core dump file có thể analyze không?

## Giải pháp tạm thời (Urgent)

### 1. Thêm null check trên Connections
```qml
Connections {
    target: _activeVehicle
    enabled: _activeVehicle !== null  // ← Disable connection khi null
    ignoreUnknownSignals: true
    
    function onRcRSSIChanged(rssi) {
        if (_activeVehicle) {  // ← Double check
            console.log("RC RSSI Changed:", rssi)
        }
    }
}
```

### 2. Thêm exception handling
```qml
onRcRSSIChanged: {
    try {
        console.log("RC RSSI Changed:", rssi)
    } catch(e) {
        console.error("Error in RSSI handler:", e)
    }
}
```

### 3. Thêm verbose logging
- Ghi log khi vehicle connect/disconnect
- Ghi log khi binding được tạo/hủy
- Ghi log chi tiết trong signal handlers

## Mức độ ưu tiên
**🔴 CRITICAL** - Crash app làm mất dữ liệu flight log và user experience

## Liên quan đến
- `src/UI/toolbar/CombinedRSSIIndicator.qml`
- `src/QmlControls/FlyViewToolBar.qml`
- `src/Vehicle/Vehicle.h`
- `src/Vehicle/VehicleLinkManager.cc`
- `src/Comms/LinkManager.cc`

## Stack trace cần thu thập
```
(gdb) bt          # Full backtrace
(gdb) info locals # Local variables
(gdb) frame N     # Each frame to understand call flow
```

## Testing checklist
- [ ] Test disconnect während mission
- [ ] Test Pixhawk reboot während communication
- [ ] Test rapid connect/disconnect cycles
- [ ] Test with multiple vehicles
- [ ] Test with network link interruption
- [ ] Test connection loss recovery

## Ghi chú thêm
- Đây có thể là race condition phức tạp, cần careful debugging
- Có thể liên quan đến vehicle lifecycle management
- Qemu/simulator test chưa reproduce được issue này
- Cần real hardware để debug
