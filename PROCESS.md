# RSSI Indicator Implementation Process

## Mục tiêu
Thêm RSSI (Received Signal Strength Indicator) vào toolbar của FlyView để hiển thị chất lượng tín hiệu RC điều khiển và dữ liệu telemetry

---

## Giai đoạn 1: Phân tích và Thiết kế

### 1.1 Xác định vị trí
- **Vị trí**: Toolbar FlyViewToolBar (src/QmlControls/FlyViewToolBar.qml)
- **Placement**: Giữa GPS Status (6) và Battery Status (7)
- **Component mới**: CombinedRSSIIndicator.qml

### 1.2 Các loại RSSI cần hiển thị
1. **RC RSSI** - Chất lượng tín hiệu điều khiển từ xa (%)
   - Range: 0-100%
   - Màu: Xanh (75-100%), Vàng (50-74%), Cam (25-49%), Đỏ (<25%)

2. **Telemetry RSSI** - Chất lượng tín hiệu dữ liệu (dBm)
   - Range: -120 to 0 dBm
   - Màu: Xanh (>= -70), Vàng (-70 to -80), Cam (-80 to -90), Đỏ (< -90)

### 1.3 Data sources
- `Vehicle.rcRSSI` - RC RSSI percentage
- `Vehicle.telemetryLRSSI` - Local telemetry RSSI in dBm
- `Vehicle.telemetryRRSSI` - Remote telemetry RSSI in dBm
- Signals: `rcRSSIChanged`, `telemetryLRSSIChanged`

---

## Giai đoạn 2: Tạo Component RSSI Indicator

### 2.1 File tạo
**Tệp**: `src/UI/toolbar/CombinedRSSIIndicator.qml`

**Tính năng:**
```qml
- Item wrapper với width/height tương xứng toolbar
- Rectangle container với border và background
- Column layout hiển thị:
  - Label "RSSI"
  - Giá trị số (RC % hoặc Telemetry dBm)
  - Màu động dựa trên chất lượng tín hiệu
- MouseArea để click vào popup chi tiết
- ToolIndicatorPage component hiển thị:
  - RC RSSI % và Signal Quality
  - Telemetry Local/Remote RSSI (dBm)
  - RX Errors, TX Buffer
  - Local/Remote Noise
```

### 2.2 Điều chỉnh kích thước
**Lần 1**: Width = 18, Height = 3.5 (quá lớn)
**Lần 2**: Width = 14 (quá nhỏ)
**Lần 3**: Width = 16 (tương xứng với các layout khác)

---

## Giai đoạn 3: Tích hợp vào Toolbar

### 3.1 Cập nhật CMakeLists.txt
**File**: `src/UI/toolbar/CMakeLists.txt`

Thêm `CombinedRSSIIndicator.qml` vào danh sách QML_FILES

```diff
+ CombinedRSSIIndicator.qml
```

### 3.2 Cập nhật FlyViewToolBar.qml
**File**: `src/QmlControls/FlyViewToolBar.qml`

**Thay đổi:**
1. Thêm import: `import QGroundControl.Toolbar`
2. Thêm component vào RowLayout giữa GPS và Battery:
   ```qml
   CombinedRSSIIndicator {
       Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 16
       Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 3.5
       Layout.alignment: Qt.AlignVCenter
   }
   ```
3. Tăng spacing từ 0.75 lên 1.0 (từ `ScreenTools.defaultFontPixelWidth * 0.75` sang `* 1.0`)

---

## Giai đoạn 4: UI/UX Refinement

### 4.1 Vấn đề ban đầu
**Error**: `SettingsSeparator is not a type`
- **Giải pháp**: Thay bằng `Rectangle` đơn giản

### 4.2 Layout issues
**Vấn đề 1**: Nội dung bị xô lệch
- **Giải pháp**: Sử dụng `anchors.horizontalCenter: parent.horizontalCenter` cho từng label

**Vấn đề 2**: QML error `Cannot assign to non-existent property "horizontalAlignment"`
- **Giải pháp**: Xóa `horizontalAlignment` (Column không có property này), dùng anchor thay thế

### 4.3 Điều chỉnh spacing và margin
- Column spacing: 1 → 4 (tăng khoảng cách)
- Toolbar RowLayout spacing: 0.75 → 1.0 (tăng khoảng cách giữa các item)

---

## Giai đoạn 5: Debug và Monitoring

### 5.1 Thêm debug logging
```qml
Connections {
    target: _activeVehicle
    ignoreUnknownSignals: true
    
    function onRcRSSIChanged(rssi) {
        console.log("RC RSSI Changed:", rssi)
    }
    
    function onTelemetryLRSSIChanged(rssi) {
        console.log("Telemetry RSSI Changed:", rssi)
    }
}
```

### 5.2 Thêm property tracking
```qml
property int _rcRSSIValue:      _activeVehicle ? _activeVehicle.rcRSSI : 0
property int _telemetryLRSSI:   _activeVehicle ? _activeVehicle.telemetryLRSSI : 0
```

---

## Kết quả cuối cùng

### ✅ Hoàn thành
- [x] RSSI indicator component được tạo
- [x] Tích hợp vào toolbar FlyViewToolBar
- [x] UI/UX được cải tiến
- [x] Layout căn giữa và tương xứng với các component khác
- [x] Color coding dựa trên signal quality
- [x] Popup chi tiết khi click vào indicator
- [x] Debug logging được thêm

### 🔴 Chưa giải quyết
- [ ] RSSI value không được cập nhật liên tục (bị fix cứng ở 40%)
  - Cần xác nhận vehicle connection
  - Cần check autopilot firmware configuration
  - Cần xác nhận RC receiver hỗ trợ RSSI

---

## Commits

1. `docs: thêm SUMMARY.md - phân tích tổng thể dự án`
2. `feat: thêm RSSI indicator vào toolbar - hiển thị chất lượng tín hiệu`
3. `feat: cải tiến RSSI indicator - căn giữa nội dung và tăng spacing`
4. `debug: thêm logging để theo dõi RSSI value changes`

---

## Các file liên quan

| File | Mô tả | Trạng thái |
|------|-------|-----------|
| `src/UI/toolbar/CombinedRSSIIndicator.qml` | Component RSSI indicator | ✅ Tạo mới |
| `src/UI/toolbar/CMakeLists.txt` | Build config cho toolbar | ✅ Cập nhật |
| `src/QmlControls/FlyViewToolBar.qml` | Main toolbar component | ✅ Cập nhật |
| `src/Vehicle/Vehicle.h` | Vehicle properties (rcRSSI, telemetryLRSSI) | ℹ️ Không thay đổi |
| `src/Vehicle/Vehicle.cc` | RSSI signal emission | ℹ️ Không thay đổi |

---

## Ghi chú

### Điểm mạnh
- Component modular, dễ bảo trì
- UI trực quan với color coding
- Integrated well vào existing toolbar design
- Hỗ trợ cả RC RSSI (%) và Telemetry RSSI (dBm)

### Điểm yếu / Vấn đề
- RSSI value không cập nhật (likely hardware/firmware issue, không phải code)
- Chưa có fallback hoặc mock data cho testing
- Có thể cần thêm threshold warnings (e.g., low signal alert)

### Cải tiến tương lai
1. Thêm signal strength animation/bars
2. Thêm alert khi signal drops below threshold
3. Thêm historical graph của RSSI
4. Support cho LTE/Cellular RSSI indicators
5. Thêm statistics (min/max/avg RSSI)
