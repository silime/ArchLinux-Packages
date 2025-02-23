#!/bin/sh
# 构建、签名并创建SELinux软件包仓库的脚本
# 使用方法：./build_repo.sh [-g] [-h] [GPG密码] [仓库名称]

set -e # 遇到错误立即退出

# 初始化全局变量
REPO_DIR="./repo"       # 仓库存储目录
PKGEXT=".pkg.tar.zst"   # 包后缀
GPG_PASSPHRASE=""       # GPG密码
REPO_NAME=""            # 仓库名称

# 切换到脚本所在目录
cd "$(dirname -- "$0")" || exit $?

# 检查root权限
if [ "$(id -u)" = 0 ]; then
    echo >&2 "错误：请勿使用root权限运行本脚本"
    exit 1
fi

# 显示帮助信息
show_help() {
    echo "Usage: $0 [OPTIONS] GPG_PASSPHRASE REPO_NAME"
    echo "选项:"
    echo "  -g    总是升级git包"
    echo "  -h    显示帮助信息"
    echo
    echo "示例:"
    echo "  $0 -g mypassword myrepo"
    exit 0
}

# 参数解析
UPGRADE_GIT_PACKAGE=false
while getopts ":gh" OPT; do
    case "$OPT" in
        h) show_help ;;
        g) UPGRADE_GIT_PACKAGE=true ;;
        \?) echo >&2 "无效选项: -$OPTARG"; exit 1 ;;
    esac
done
shift $((OPTIND-1))

# 验证必需参数
if [ $# -ne 2 ]; then
    echo >&2 "错误：需要提供GPG密码和仓库名称"
    show_help
fi
GPG_PASSPHRASE=$1
REPO_NAME=$2

# 创建仓库目录
mkdir -p "$REPO_DIR"

# 包构建顺序列表
PACKAGE_LIST=(
    "q6voiced"
    "soc-qcom-sdm845" 
    "persistent-mac"
    "linux-firmware"
    "qbootctl"
    "bootmac"
    "alsa-ucm-oneplus"
    "device-oneplus-fajita"
    "device-lenovo-q706f"
    "mkbootimg"
    "linux-firmware-lenovo-sm8250"
    "linux-sdm845"
    "linux-sm8250"
    "sensors/iio-sensor-proxy"
    "sensors/hexagonrpcd"
    "sensors/libssc"
)

# 检查包是否需要构建（复用原脚本逻辑）
# needs_install() {
#     # [原脚本中的needs_install函数实现]
#     # 此处保留原有版本检查逻辑
# }

# 增强版构建函数
build_package() {
    local pkg_dir=$1
    echo "▌正在构建 $pkg_dir..."
    
    # 清理构建环境
    rm -rf "${pkg_dir}/src" "${pkg_dir}/pkg"
    find "${pkg_dir}" -maxdepth 1 -name "*.pkg.tar.*" -delete

    # 特殊包处理示例
    # case "$pkg_dir" in
    #     "linux-sdm845"|"linux-sm8250")
    #         export KERNEL_CONFIG="selinux_defconfig" ;;
    # esac

    # 执行构建
    (cd "$pkg_dir" && makepkg -s -C --noconfirm) || {
        echo >&2 "构建 $pkg_dir 失败"
        exit 3
    }
}

# GPG签名函数
sign_package() {
    local pkg_path=$1
    echo "▌正在签名 ${pkg_path##*/}..."
    
    gpg --detach-sign --no-armor \
        --batch --yes \
        --passphrase "$GPG_PASSPHRASE" \
        --pinentry-mode loopback \
        "$pkg_path" || {
        echo >&2 "签名 $pkg_path 失败"
        exit 4
    }
}

# 添加到仓库
add_to_repo() {
    local pkg_file=$1
    echo "▌添加包到仓库: ${pkg_file##*/}"
    
    cp -f "$pkg_file" "$REPO_DIR/"
    cp -f "${pkg_file}.sig" "$REPO_DIR/"
    
    repo-add -s -v "$REPO_DIR/$REPO_NAME.db.tar.gz" \
        "$REPO_DIR/${pkg_file##*/}" || {
        echo >&2 "添加包到仓库失败"
        exit 5
    }
}

# 主构建流程
for pkg in "${PACKAGE_LIST[@]}"; do
    # 检查包目录是否存在
    if [ ! -d "$pkg" ]; then
        echo >&2 "错误：包目录 $pkg 不存在"
        exit 2
    fi

    # 版本检查
    # if ! needs_install "$pkg"; then
    #     echo "▌跳过已安装的包: $pkg"
    #     continue
    # fi

    # 构建流程
    build_package "$pkg"
    
    # 处理生成的包文件
    for pkg_file in "$pkg"/*$PKGEXT; do
        [ -f "$pkg_file" ] || continue
        
        sign_package "$pkg_file"
        add_to_repo "$pkg_file"
    done
done

echo "✔ 所有操作已完成！"
echo "仓库路径: $(pwd)/$REPO_DIR"