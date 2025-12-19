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
