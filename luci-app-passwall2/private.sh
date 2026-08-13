#!/bin/bash
# private.sh - PassWall2 (VLESS + REALITY 極致瘦身腳本)

echo "=================================================="
echo " [Private] Starting PassWall2 Slimming (REALITY)  "
echo "=================================================="

# 1. 精簡 PassWall2 主包 Makefile (修剪依賴，保留完整的 Package/luci-app-passwall2 與 i18n 構建定義)
PASSWALL_MAKEFILES=$(find package/ -type f -name "Makefile" -path "*/luci-app-passwall2/*")

for mk in $PASSWALL_MAKEFILES; do
    echo "[+] Processing PassWall2 Makefile: $mk"
    
    # 清理多餘依賴，寫入極簡核心依賴 (含離線必備的 timeout)
    sed -i 's/+luci-app-passwall2_INCLUDE_[^ ]*/ /g' "$mk"
    sed -i '/DEPENDS:=/c\  DEPENDS:=+xray-core +v2ray-geodata +dnsmasq-full +ip-full +ca-bundle +kmod-nft-tproxy +coreutils-timeout' "$mk"
done

# 2. 精簡 Xray-Core Makefile (僅留 VLESS + REALITY 所需 TLS/uTLS)
XRAY_MAKEFILES=$(find package/ -type f -name "Makefile" -path "*/xray-core/*")

for xmk in $XRAY_MAKEFILES; do
    echo "[+] Slimming Xray-Core Makefile: $xmk"
    
    if ! grep -q "GO_BUILD_TAGS:=" "$xmk"; then
        sed -i '/PKG_NAME:=xray-core/a GO_BUILD_LDFLAGS:=-s -w -buildid=\nGO_BUILD_TAGS:=confonly,novmess,notrojan,noshadowsocks,nossr' "$xmk"
    fi
    
    # UPX 安全壓縮 (--fast 防 ARM64 崩潰)
    if ! grep -q "upx" "$xmk"; then
        sed -i '/define Package\/xray-core\/install/a \	upx --fast $(1)/usr/bin/xray || true' "$xmk"
    fi
done

# 3. 徹底清理多餘的核心包
echo "[+] Removing redundant core packages..."
find package/ -type d \( -name "sing-box" -o -name "v2ray-core" -o -name "v2ray-plugin" -o -name "hysteria" -o -name "trojan*" -o -name "naiveproxy" -o -name "chinadns-ng" \) -exec rm -rf {} + 2>/dev/null || true

echo "=================================================="
echo " [Private] Slimming Completed!                    "
echo "=================================================="
