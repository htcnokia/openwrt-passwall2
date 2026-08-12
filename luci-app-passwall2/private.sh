#!/bin/bash
# private.sh - 用於動態修補與極致瘦身的私有構建腳本

echo "=========================================="
echo " Starting Dynamic Slimming & Modification "
echo "=========================================="

# 1. 尋找並修補 PassWall2 的 Makefile（砍掉除 xray-core 以外的所有核心依賴）
PASSWALL_MAKEFILE=$(find package/ -type f -path "*/luci-app-passwall2/Makefile" | head -n 1)

if [ -n "$PASSWALL_MAKEFILE" ]; then
    echo "[+] Modifying PassWall2 Makefile: $PASSWALL_MAKEFILE"
    
    # 移除 v2ray-core, sing-box, trojan, hysteria, haproxy 等多餘依賴
    # 僅保留 xray-core, dnsmasq, ip-full, ca-bundle, kmod-nft-tproxy
    sed -i '/INCLUDE_/d' "$PASSWALL_MAKEFILE"
    sed -i 's/+luci-app-passwall2_INCLUDE_[^ ]*/ /g' "$PASSWALL_MAKEFILE"
    
    # 強制修正依賴為極簡組合
    sed -i '/DEPENDS:=/c\  DEPENDS:=+xray-core +dnsmasq-full +ip-full +ca-bundle +kmod-nft-tproxy' "$PASSWALL_MAKEFILE"
fi

# 2. 尋找並修補 Xray-Core 的 Makefile（注入 Golang 瘦身編譯參數與 UPX 壓縮）
XRAY_MAKEFILE=$(find package/ -type f -path "*/xray-core/Makefile" | head -n 1)

if [ -n "$XRAY_MAKEFILE" ]; then
    echo "[+] Modifying Xray-Core Makefile: $XRAY_MAKEFILE"
    
    # 注入 Go 編譯參數：移除 Debug 符號 (-s -w) 並剔除無用協議標籤
    # 僅保留 VLESS / REALITY / gRPC / WS / TLS
    if ! grep -q "GO_BUILD_TAGS:=" "$XRAY_MAKEFILE"; then
        echo 'GO_BUILD_LDFLAGS:=-s -w -buildid=' >> "$XRAY_MAKEFILE"
        echo 'GO_BUILD_TAGS:=confonly,noless,novmess,notrojan,noshadowsocks,nossr' >> "$XRAY_MAKEFILE"
    fi
    
    # 注入 UPX 壓縮指令到 Install 區塊
    if grep -q "upx" "$XRAY_MAKEFILE"; then
        echo "[!] UPX rule already exists in Xray Makefile."
    else
        sed -i '/define Package\/xray-core\/install/a \	upx --best --lzma $(1)/usr/bin/xray || true' "$XRAY_MAKEFILE"
    fi
fi

# 3. 移除大體積 Geodata 依賴 (改為遠端動態下載，不打包進 ipk/apk)
find package/ -type f -name "Makefile" -path "*/v2ray-geodata/*" -exec rm -f {} \; 2>/dev/null || true

echo "=========================================="
echo " Dynamic Slimming Completed Successfully! "
echo "=========================================="
