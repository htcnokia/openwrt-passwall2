#!/bin/bash
PASSWALL_MAKEFILES=$(find package/ -type f -name "Makefile" -path "*/luci-app-passwall2/*")
for mk in $PASSWALL_MAKEFILES; do
  sed -i 's/+luci-app-passwall2_INCLUDE_[^ ]*/ /g' "$mk"
  #sed -i '/DEPENDS:=/c\  DEPENDS:=+xray-core +v2ray-geodata +dnsmasq-full +ip-full +ca-bundle +kmod-nft-tproxy +coreutils-timeout' "$mk"
  # 重寫硬性依賴：把 +v2ray-geodata 剔除！
  sed -i '/DEPENDS:=/c\  DEPENDS:=+xray-core +dnsmasq-full +ip-full +ca-bundle +kmod-nft-tproxy +coreutils-timeout' "$mk"
# 修正 UPX 壓縮注入邏輯
XRAY_MAKEFILES=$(find package/ -type f -name "Makefile" -path "*/xray-core/*")
for xmk in $XRAY_MAKEFILES; do
  echo "[+] Force UPX Slimming on Xray-Core Makefile: $xmk"
  # 在 Build/Compile 結束後直接對二進制檔案執行 UPX
  if ! grep -q "upx --fast" "$xmk"; then
      sed -i '/define Build\/Compile/a \	upx --fast $(PKG_BUILD_DIR)/xray || true' "$xmk"
  fi
done
find package/ -type d \( -name "sing-box" -o -name "v2ray-core" -o -name "v2ray-plugin" -o -name "hysteria" -o -name "trojan*" -o -name "naiveproxy" -o -name "chinadns-ng" \) -exec rm -rf {} + 2>/dev/null || true
