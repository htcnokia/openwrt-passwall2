#!/bin/bash
# private.sh - PassWall2 (VLESS + TCP + REALITY 瘦身 & 語言包完美修復)

echo "=================================================="
echo " [Private] Starting PassWall2 Slimming (REALITY)  "
echo "=================================================="

# 1. 精簡 PassWall2 主包 Makefile 並修復語言包生成
PASSWALL_MAKEFILES=$(find package/ -type f -name "Makefile" -path "*/luci-app-passwall2/*")

for mk in $PASSWALL_MAKEFILES; do
    echo "[+] Processing PassWall2 Makefile: $mk"
    
    # 刪除多餘的可選模組配置 (INCLUDE_xxx)
    sed -i '/config LUCI_APP_PASSWALL2_INCLUDE_/d' "$mk" 2>/dev/null || true
    sed -i '/default y if/d' "$mk" 2>/dev/null || true
    
    # 清理舊依賴，寫入極簡依賴
    sed -i 's/+luci-app-passwall2_INCLUDE_[^ ]*/ /g' "$mk"
    sed -i '/DEPENDS:=/c\  DEPENDS:=+xray-core +v2ray-geodata +dnsmasq-full +ip-full +ca-bundle +kmod-nft-tproxy' "$mk"

    # 【核心修復】確保 Makefile 末尾包含語言包 call BuildPackage 定義
    # 避免 Slimming 過程漏掉 i18n package
    if ! grep -q "luci-i18n-passwall2-zh-cn" "$mk"; then
        echo -e "\n\$(eval \$(call BuildPackage,luci-i18n-passwall2-zh-cn))" >> "$mk"
    fi
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

# 4. 【重點】向 SDK 的 .config 強制追加語言包編譯開關
# 這樣就算不改 build_slim.yml，也能在腳本運行時直接啟用語言包編譯！
if [ -d "package" ]; then
    echo "[+] Forcing i18n enabled in SDK .config..."
    mkdir -p tmp
    echo "CONFIG_PACKAGE_luci-i18n-passwall2-zh-cn=m" >> .config 2>/dev/null || true
    echo "CONFIG_PACKAGE_luci-i18n-passwall2-zh-tw=m" >> .config 2>/dev/null || true
fi

echo "=================================================="
echo " [Private] Slimming & i18n Fix Completed!         "
echo "=================================================="
