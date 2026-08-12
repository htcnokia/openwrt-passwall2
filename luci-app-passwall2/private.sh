#!/bin/bash
# private.sh - 配合官方 SDK Workflow 的動態瘦身腳本

echo "=========================================="
echo " [Private] Starting PassWall2 Slimming    "
echo "=========================================="

# 1. 精簡 PassWall2 主包 Makefile
# 搜尋 SDK 內部 package/ 下所有的 luci-app-passwall2 Makefile
PASSWALL_MAKEFILES=$(find package/ -type f -name "Makefile" -path "*/luci-app-passwall2/*")

for mk in $PASSWALL_MAKEFILES; do
    echo "[+] Slimming PassWall2 Makefile: $mk"
    
    # 刪除所有可選的依賴選項配置 (INCLUDE_xxx)
    sed -i '/config LUCI_APP_PASSWALL2_INCLUDE_/d' "$mk" 2>/dev/null || true
    sed -i '/default y if/d' "$mk" 2>/dev/null || true
    
    # 徹底清理 DEPENDS 欄位，刪除所有 +luci-app-passwall2_INCLUDE_ 開頭的依賴
    # 僅保留極簡基礎依賴 + xray-core
    sed -i 's/+luci-app-passwall2_INCLUDE_[^ ]*/ /g' "$mk"
    sed -i '/DEPENDS:=/c\  DEPENDS:=+xray-core +dnsmasq-full +ip-full +ca-bundle +kmod-nft-tproxy' "$mk"
done

# 2. 精簡 Xray-Core Makefile (裁剪協議 + UPX 壓縮)
XRAY_MAKEFILES=$(find package/ -type f -name "Makefile" -path "*/xray-core/*")

for xmk in $XRAY_MAKEFILES; do
    echo "[+] Slimming & UPX Xray-Core Makefile: $xmk"
    
    # 注入 Golang 瘦身標籤 (去除 Debug 符號、移除 VMess/Trojan/SSR 等無用協議)
    if ! grep -q "GO_BUILD_TAGS:=" "$xmk"; then
        sed -i '/PKG_NAME:=xray-core/a GO_BUILD_LDFLAGS:=-s -w -buildid=\nGO_BUILD_TAGS:=confonly,noless,novmess,notrojan,noshadowsocks,nossr' "$xmk"
    fi
    
    # 注入 UPX 高倍率壓縮指令
    if ! grep -q "upx" "$xmk"; then
        sed -i '/define Package\/xray-core\/install/a \	upx --best --lzma $(1)/usr/bin/xray || true' "$xmk"
    fi
done

# 3. 刪除多餘的核心包 Makefile (避免 SDK 誤編譯 v2ray, sing-box, trojan 等)
echo "[+] Removing redundant core packages from SDK..."
find package/ -type d -name "sing-box" -o -name "v2ray-core" -o -name "v2ray-geodata" -o -name "hysteria" -o -name "trojan*" -o -name "naiveproxy" | xargs rm -rf 2>/dev/null || true

echo "=========================================="
echo " [Private] Slimming completed!            "
echo "=========================================="
