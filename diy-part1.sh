#!/bin/bash
#
# Copyright (c) 2019-2020 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part1.sh
# Description: OpenWrt DIY script part 1 (Before Update feeds)
#

# 添加源配置
sed -i '1i src-git kenzo https://github.com/kenzok8/openwrt-packages' feeds.conf.default
sed -i '2i src-git small https://github.com/kenzok8/small' feeds.conf.default

# 注释掉原来的 luci 源
sed -i 's|^src-git luci https://git.openwrt.org/project/luci.git|#src-git luci https://git.openwrt.org/project/luci.git|' feeds.conf.default

# 添加新的 luci 源，指定 openwrt-23.05 分支
echo 'src-git luci https://github.com/coolsnowwolf/luci.git;openwrt-23.05' >> feeds.conf.default

# 更新 feeds 并删除不需要的包
./scripts/feeds update -a

# 删除不需要的包
rm -rf feeds/luci/applications/luci-app-mosdns
rm -rf feeds/packages/net/{alist,adguardhome,mosdns,xray*,v2ray*,sing*,smartdns}
rm -rf feeds/packages/utils/v2dat
rm -rf feeds/packages/lang/golang

# 删除不需要的 luci-app 模块，保留所需的应用
echo "删除不需要的 luci-app 模块，保留所需的应用"

# 保留的 luci-app 模块
declare -a KEEP_APPS=(
    "luci-app-autoreboot"
    "luci-app-argon-config"
    "luci-app-ddns"
    "luci-app-firewall"
    "luci-app-netdata"
    "luci-app-openclash"
    "luci-app-opkg"
    "luci-app-passwall"
    "luci-app-smartdns"
    "luci-app-ttyd"
    "luci-app-upnp"
)

# 获取当前 feeds 中的所有 luci 应用，并删除不需要的应用
cd $GITHUB_WORKSPACE/openwrt
for app in $(ls feeds/luci/applications); do
    if [[ ! " ${KEEP_APPS[@]} " =~ " ${app} " ]]; then
        echo "删除应用: $app"
        rm -rf "feeds/luci/applications/$app"
    fi
done

# 更新和安装所需的应用
./scripts/feeds install -a -f

# 克隆 golang
git clone https://github.com/kenzok8/golang feeds/packages/lang/golang

# 拉取其他需要的插件
git clone https://github.com/f8q8/luci-app-autoreboot package/luci-app-autoreboot
git clone --depth=1 -b master https://github.com/jerrykuku/luci-theme-argon package/luci-theme-argon
git clone --depth=1 -b master https://github.com/jerrykuku/luci-app-argon-config package/luci-app-argon-config

# 清理已克隆的插件目录
rm -rf feeds/luci/themes/luci-theme-argon
rm -rf feeds/luci/themes/luci-theme-Bootstrap
rm -rf feeds/luci/themes/luci-theme-BootstrapDark
rm -rf feeds/luci/themes/luci-theme-BootstrapLight

# 克隆其他必要插件
git clone https://github.com/haiibo/openwrt-packages
shopt -s extglob
rm -rf openwrt-packages/!(luci-app-netdata|luci-app-smartdns|luci-app-upnp)
cp -r openwrt-packages/{luci-app-netdata,luci-app-smartdns,luci-app-upnp} package/
rm -rf openwrt-packages

# 修改默认 IP 和主题
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' ./feeds/luci/collections/luci/Makefile
#sed -i 's/192.168.1.1/10.10.10.1/g' package/base-files/files/bin/config_generate
