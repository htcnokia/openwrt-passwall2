#!/bin/bash
# private.sh - PassWall2 極致瘦身與中文語言包注入腳本

echo "=================================================="
echo " [Private] Starting PassWall2 Slimming (REALITY)  "
echo "=================================================="

# 1. 精簡 PassWall2 主包 Makefile 並注入中文語言包依賴
PASSWALL_MAKEFILES=$(find package/ -type f -name "Makefile" -path "*/luci-app-passwall2/*")

for mk in $PASSWALL_MAKEFILES; do
    echo "[+] Processing PassWall2 Makefile: $mk"
    
    # 刪除可選模組配置
    sed -i '/config LUCI_APP_PASSWALL2_INCLUDE_/d' "$mk" 2>/dev/null || true
    sed -i '/default y if/d' "$mk" 2>/dev/null || true
    
    # 清理舊依賴，注入中文包 (同時兼容 +luci-i18n-passwall2-zh-cn 與 LUCI_LANG_zh-cn)
    sed -i 's/+luci-app-passwall2_INCLUDE_[^ ]*/ /g' "$mk"
    sed -i '/DEPENDS:=/c\  DEPENDS:=+xray-core +v2ray-geodata +dnsmasq-full +ip-full +ca-bundle +kmod-nft-tproxy +luci-i18n-passwall2-zh-cn' "$mk"
done

# 2. 精簡 Xray-Core Makefile (僅留 VLESS + REALITY 所需的 TLS/uTLS)
XRAY_MAKEFILES=$(find package/ -type f -name "Makefile" -path "*/xray-core/*")

for xmk in $XRAY_MAKEFILES; do
    echo "[+] Slimming Xray-Core Makefile: $xmk"
    
    if ! grep -q "GO_BUILD_TAGS:=" "$xmk"; then
        sed -i '/PKG_NAME:=xray-core/a GO_BUILD_LDFLAGS:=-s -w -buildid=\nGO_BUILD_TAGS:=confonly,novmess,notrojan,noshadowsocks,nossr' "$xmk"
    fi
    
    if ! grep -q "upx" "$xmk"; then
        sed -i '/define Package\/xray-core\/install/a \	upx --fast $(1)/usr/bin/xray || true' "$xmk"
    fi
done

# 3. 徹底清理多餘的核心包
echo "[+] Removing redundant core packages..."
find package/ -type d \( -name "sing-box" -o -name "v2ray-core" -o -name "v2ray-plugin" -o -name "hysteria" -o -name "trojan*" -o -name "naiveproxy" -o -name "chinadns-ng" \) -exec rm -rf {} + 2>/dev/null || true

echo "=================================================="
echo " [Private] Slimming & i18n Injection completed!   "
echo "=================================================="
