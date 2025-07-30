# My Custom QGroundControl

Đây là phiên bản QGroundControl đã được sửa đổi và tùy chỉnh. Dự án gốc có thể được tìm thấy tại [mavlink/qgroundcontrol](https://github.com/mavlink/qgroundcontrol).

---

## Hướng dẫn Thiết lập và Biên dịch

Đây là các bước cần thiết để thiết lập môi trường và biên dịch dự án trên **Ubuntu 22.04**.

### 1. Sao chép (Clone) Kho chứa

Đầu tiên, sao chép kho chứa này về máy tính của bạn.

```bash
git clone https://github.com/ThangDuc3101/my-qgc-custom.git
cd my-qgc-custom
git submodule update --init --recursive
sudo bash ./tools/setup/install-dependencies-debian.sh
```

### 2. Cài đặt QT - QTCreator
Dự án này yêu cầu một phiên bản Qt cụ thể:

- Phiên bản: Qt 6.8.3 (bắt buộc) theo hướng dẫn tại https://docs.qgroundcontrol.com/master/en/qgc-dev-guide/getting_started/index.html
- Cách cài đặt: Tải về trình cài đặt trực tuyến (Qt Online Installer) từ trang chủ của Qt.
- Lưu ý: có thể dùng mirror để tăng tốc độ tải khi dùng Qt Online Installer chi tiết hơn xem tại https://download.qt.io/static/mirrorlist/

```bash 
# Ví dụ dùng Mirror tại khu vực Nhật Bản
./qt-online-installer-linux-x64-4.10.0.run --mirror http://ftp.jaist.ac.jp/pub/qtproject
```

