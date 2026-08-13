#!/bin/bash
# private.sh - PassWall2 (VLESS + TCP + REALITY 專用極致瘦身與中文語言包注入腳本)

echo "=================================================="
echo " [Private] Starting PassWall2 Slimming (REALITY)  "
echo "=================================================="

# 1. 精簡 PassWall2 主包 Makefile 並注入中文語言包依賴
PASSWALL_MAKEFILES=$(find package/ -type f -name "Makefile" -path "*/luci-app-passwall2/*")

for mk in $PASSWALL_MAKEFILES; do
    echo "[+] Processing PassWall2 Makefile: $mk"
    
    # 刪除可選模組配置選項
    sed -i '/config LUCI_APP_PASSWALL2_INCLUDE_/d' "$mk" 2>/dev/null || true
    sed -i '/default y if/d' "$mk" 2>/dev/null || true
    
    # 清理舊依賴，並強制加入 +luci-i18n-passwall2-zh-cn (中文語言包)
    sed -i 's/+luci-app-passwall2_INCLUDE_[^ ]*/ /g' "$mk"
    sed -i '/DEPENDS:=/c\  DEPENDS:=+xray-core +v2ray-geodata +dnsmasq-full +ip-full +ca-bundle +kmod-nft-tproxy +luci-i18n-passwall2-zh-cn' "$mk"
done

# 2. 精簡 Xray-Core Makefile (僅留 VLESS + REALITY 所需的 TLS/uTLS，剔除其餘協定)
XRAY_MAKEFILES=$(find package/ -type f -name "Makefile" -path "*/xray-core/*")

for xmk in $XRAY_MAKEFILES; do
    echo "[+] Slimming Xray-Core Makefile: $xmk"
    
    # 注入 Tags：剪掉 VMess, Trojan, SS, SSR
    if ! grep -q "GO_BUILD_TAGS:=" "$xmk"; then
        sed -i '/PKG_NAME:=xray-core/a GO_BUILD_LDFLAGS:=-s -w -buildid=\nGO_BUILD_TAGS:=confonly,novmess,notrojan,noshadowsocks,nossr' "$xmk"
    fi
    
    # 使用安全的 UPX 參數（避免 ARM64 架構記憶體溢位崩潰）
    if ! grep -q "upx" "$xmk"; then
        sed -i '/define Package\/xray-core\/install/a \	upx --fast $(1)/usr/bin/xray || true' "$xmk"
    fi
done

# 3. 徹底清理多餘的核心包，節省 SDK 編譯時間
echo "[+] Removing redundant core packages..."
find package/ -type d \( -name "sing-box" -o -name "v2ray-core" -o -name "v2ray-plugin" -o -name "hysteria" -o -name "trojan*" -o -name "naiveproxy" -o -name "chinadns-ng" \) -exec rm -rf {} + 2>/dev/null || true

echo "=================================================="
echo " [Private] Slimming & i18n Injection completed!   "
echo "=================================================="
