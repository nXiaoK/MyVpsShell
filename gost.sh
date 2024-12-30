#!/usr/bin/env bash
#
# Gost 转发管理脚本（基于 go-gost/gost 仓库）
# 1. 首次运行时自动检测是否安装 Gost，如无则从 GitHub 下载并安装
# 2. 使用 JSON 数组结构的配置文件、可选禁用/删除，以及 systemd 开机自启动
# 3. 支持 IPv4/IPv6
#

# ---------------------------
# 可根据需求自定义下列变量
# ---------------------------
GOST_BIN="/usr/local/bin/gost"
CONFIG_FILE="/etc/gost_config.json"
LOG_DIR="/var/log/gost"
SYSTEMD_SERVICE="/etc/systemd/system/gost_manager.service"

# GitHub 仓库：go-gost/gost
GOST_REPO_API="https://api.github.com/repos/go-gost/gost/releases"
# 你想下载的编译文件后缀。如 "linux_amd64" / "linux_arm64" / "linux_386" 等
GOST_ASSET_SUFFIX="linux_amd64"


# ---------------------------
# 1. 下载并安装 Gost
# ---------------------------
function install_gost() {
    echo "检测到系统中尚未安装 gost，现在从 GitHub(go-gost/gost)下载最新正式版本..."

    # 获取所有 release 列表，并仅过滤掉 draft==true；(若想过滤 pre-release，可加 .prerelease==false)
    local stable_release_info
    stable_release_info="$(
        curl -s "$GOST_REPO_API" \
        | jq -r '[ .[] | select(.draft==false ) ] | first'
    )"

    if [ "$stable_release_info" == "null" ] || [ -z "$stable_release_info" ]; then
        echo "仓库中未发现任何可用发布版本，请检查仓库或手动安装 gost。"
        exit 1
    fi

    # 匹配包含 $GOST_ASSET_SUFFIX 的下载链接
    local download_url
    download_url="$(
        echo "$stable_release_info" \
        | jq -r ".assets[] | select(.name | contains(\"$GOST_ASSET_SUFFIX\")) | .browser_download_url" \
        | head -n 1
    )"

    if [ -z "$download_url" ]; then
        echo "在该版本里，未找到后缀匹配 \"$GOST_ASSET_SUFFIX\" 的可执行文件。"
        echo "请手动安装 gost 或修改脚本后重试。"
        exit 1
    fi

    echo "匹配到的下载地址: $download_url"
    local tmp_dir
    tmp_dir="$(mktemp -d)"
    local tmp_file="$tmp_dir/gost_download"

    echo "正在下载文件到: $tmp_file"
    curl -L -o "$tmp_file" "$download_url"

    # 判断文件后缀并解压 (.tar.gz / .gz / 其他)
    if [[ "$download_url" =~ \.tar\.gz$ ]]; then
        echo "检测到 .tar.gz 文件，使用 tar 解压..."
        tar -xzf "$tmp_file" -C "$tmp_dir"

        # 查找解压后的 gost 文件
        local gost_path
        gost_path="$(find "$tmp_dir" -type f -name gost | head -n 1)"
        if [ -z "$gost_path" ]; then
          echo "解压后未找到 gost 文件，请检查发行包结构。"
          ls -lR "$tmp_dir"
          exit 1
        fi
        sudo mv "$gost_path" "$GOST_BIN"
    elif [[ "$download_url" =~ \.gz$ ]]; then
        echo "检测到 .gz 文件（非 .tar.gz），使用 gunzip 解压..."
        gunzip "$tmp_file"
        if [ -f "$tmp_file" ]; then
            sudo mv "$tmp_file" "$GOST_BIN"
        else
            local extracted
            extracted="$(find "$tmp_dir" -type f | head -n 1)"
            if [ -z "$extracted" ]; then
                echo "解压后找不到文件。"
                exit 1
            fi
            sudo mv "$extracted" "$GOST_BIN"
        fi
    else
        echo "未知或不支持的压缩后缀，请自行处理。"
        exit 1
    fi

    sudo chmod +x "$GOST_BIN"
    rm -rf "$tmp_dir"

    if ! command -v "$GOST_BIN" &> /dev/null; then
        echo "安装 gost 失败，请检查网络或手动安装。"
        exit 1
    fi

    echo "Gost 安装完成，版本信息：$($GOST_BIN -V)"
}

# ---------------------------
# 2. 基础工具函数
# ---------------------------
function check_or_install_gost() {
    # 若找不到 Gost 命令，则安装
    if ! command -v "$GOST_BIN" &> /dev/null; then
        install_gost
    fi
}

function is_ipv6() {
    local ip=$1
    [[ "$ip" =~ : ]]
}

function format_address() {
    local ip=$1
    if is_ipv6 "$ip"; then
        echo "[$ip]"
    else
        echo "$ip"
    fi
}

function init_config() {
    if [ ! -s "$CONFIG_FILE" ]; then
        echo "[]" | sudo tee "$CONFIG_FILE" >/dev/null
    fi
}


# ---------------------------
# 3. 启动/管理 Gost 转发
# ---------------------------
function run_gost() {
    local local_port=$1
    local remote_host=$2
    local remote_port=$3
    local protocol=$4

    case "$protocol" in
        tcp)
            echo "启动 Gost [TCP] - 本地端口: $local_port, 远程: $remote_host:$remote_port"
            nohup "$GOST_BIN" -L="tcp://:${local_port}/${remote_host}:${remote_port}" \
              >"${LOG_DIR}/gost_${local_port}_tcp.log" 2>&1 &
            ;;
        udp)
            echo "启动 Gost [UDP] - 本地端口: $local_port, 远程: $remote_host:$remote_port"
            nohup "$GOST_BIN" -L="udp://:${local_port}/${remote_host}:${remote_port}" \
              >"${LOG_DIR}/gost_${local_port}_udp.log" 2>&1 &
            ;;
        tcp+udp)
            echo "启动 Gost [TCP] - 本地端口: $local_port, 远程: $remote_host:$remote_port"
            nohup "$GOST_BIN" -L="tcp://:${local_port}/${remote_host}:${remote_port}" \
              >"${LOG_DIR}/gost_${local_port}_tcp.log" 2>&1 &
            echo "启动 Gost [UDP] - 本地端口: $local_port, 远程: $remote_host:$remote_port"
            nohup "$GOST_BIN" -L="udp://:${local_port}/${remote_host}:${remote_port}" \
              >"${LOG_DIR}/gost_${local_port}_udp.log" 2>&1 &
            ;;
        *)
            echo "未知的协议: $protocol"
            return 1
            ;;
    esac
}

function start_all() {
    init_config
    local count
    count=$(jq '. | length' "$CONFIG_FILE")
    if [ "$count" -eq 0 ]; then
        echo "未检测到任何 Gost 转发规则，配置文件为空。"
        return
    fi
    echo "开始启动已启用的 Gost 转发规则..."

    jq -c '.[]' "$CONFIG_FILE" | while IFS= read -r item; do
        local enabled
        enabled=$(echo "$item" | jq -r '.enabled')
        if [ "$enabled" == "true" ]; then
            local local_port
            local remote_host
            local remote_port
            local protocol
            local_port=$(echo "$item" | jq -r '.local_port')
            remote_host=$(echo "$item" | jq -r '.remote_host')
            remote_port=$(echo "$item" | jq -r '.remote_port')
            protocol=$(echo "$item" | jq -r '.protocol')

            remote_host=$(format_address "$remote_host")
            run_gost "$local_port" "$remote_host" "$remote_port" "$protocol"
        fi
    done
    echo "所有已启用的 Gost 转发规则启动完毕。"
}

function add_rule() {
    init_config
    local local_port=$1
    local remote_host=$2
    local remote_port=$3
    local protocol=${4:-"tcp+udp"}

    sudo jq --arg lp "$local_port" \
            --arg rh "$remote_host" \
            --arg rp "$remote_port" \
            --arg pro "$protocol" \
        '. += [{
            "local_port": $lp,
            "remote_host": $rh,
            "remote_port": $rp,
            "protocol": $pro,
            "enabled": true
        }]' "$CONFIG_FILE" > /tmp/gost_config_tmp && sudo mv /tmp/gost_config_tmp "$CONFIG_FILE"

    echo "已添加新规则: local_port=$local_port, remote=$remote_host:$remote_port, protocol=$protocol, 并已启用。"
    run_gost "$local_port" "$(format_address "$remote_host")" "$remote_port" "$protocol"
}

function toggle_rule() {
    init_config
    local local_port=$1
    local target_state=$2

    local exists
    exists=$(jq --arg lp "$local_port" '[ .[] | select(.local_port==$lp) ] | length' "$CONFIG_FILE")
    if [ "$exists" -eq 0 ]; then
        echo "未找到本地端口为 $local_port 的转发规则，无法执行操作。"
        return 1
    fi

    sudo jq --arg lp "$local_port" --arg en "$target_state" '
        .[] |= if .local_port == $lp then (.enabled = ($en | test("true"))) else . end
    ' "$CONFIG_FILE" > /tmp/gost_config_tmp && sudo mv /tmp/gost_config_tmp "$CONFIG_FILE"

    if [ "$target_state" == "false" ]; then
        echo "正在停止 Gost 转发 (local_port=$local_port)..."
        pkill -f "gost.*-L=.*:${local_port}"
        echo "已禁用并停止端口 $local_port 对应的 Gost 转发。"
    else
        echo "正在启用并启动端口 $local_port 对应的 Gost 转发..."
        local item
        item=$(jq -c --arg lp "$local_port" '.[] | select(.local_port==$lp)' "$CONFIG_FILE")
        local remote_host
        local remote_port
        local protocol
        remote_host=$(echo "$item" | jq -r '.remote_host')
        remote_port=$(echo "$item" | jq -r '.remote_port')
        protocol=$(echo "$item" | jq -r '.protocol')

        run_gost "$local_port" "$(format_address "$remote_host")" "$remote_port" "$protocol"
        echo "端口 $local_port 对应的 Gost 转发已启用。"
    fi
}

function delete_rule() {
    init_config
    local local_port=$1
    local exists
    exists=$(jq --arg lp "$local_port" '[ .[] | select(.local_port==$lp) ] | length' "$CONFIG_FILE")
    if [ "$exists" -eq 0 ]; then
        echo "未找到本地端口为 $local_port 的转发规则，无法删除。"
        return 1
    fi

    pkill -f "gost.*-L=.*:${local_port}"

    sudo jq --arg lp "$local_port" '[ .[] | select(.local_port != $lp) ]' "$CONFIG_FILE" \
        > /tmp/gost_config_tmp && sudo mv /tmp/gost_config_tmp "$CONFIG_FILE"

    echo "已删除本地端口为 $local_port 的转发规则。"
}

function list_rules() {
    init_config
    local count
    count=$(jq '. | length' "$CONFIG_FILE")
    if [ "$count" -eq 0 ]; then
        echo "暂无规则。"
        return
    fi
    jq -r '.[] | "\(.local_port) \(.remote_host):\(.remote_port) \(.protocol) enabled=\(.enabled)"' "$CONFIG_FILE"
}


# ---------------------------
# 4. systemd 开机自启动
# ---------------------------
function create_systemd_service() {
    # 1. 将当前脚本复制到 /usr/local/bin/gost.sh（如你想改名可自行修改）
    #    如果你想强制“移动”而不是“复制”，把 cp 改成 mv 即可
    if [ "$(realpath "$0")" != "/usr/local/bin/gost.sh" ]; then
        echo "正在将当前脚本复制到 /usr/local/bin/gost.sh ..."
        sudo cp "$(realpath "$0")" /usr/local/bin/gost.sh
        sudo chmod +x /usr/local/bin/gost.sh
    fi

    # 2. 生成 systemd service 文件
    if [ ! -f "$SYSTEMD_SERVICE" ]; then
        cat <<EOF | sudo tee "$SYSTEMD_SERVICE" >/dev/null
[Unit]
Description=Gost Manager - Automatically start Gost rules
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/gost.sh start-all
RemainAfterExit=true

[Install]
WantedBy=multi-user.target
EOF
        sudo systemctl daemon-reload
        sudo systemctl enable gost_manager.service
        echo "已创建 systemd service 并启用开机自启动。"
    else
        echo "systemd service 已存在：$SYSTEMD_SERVICE"
    fi
}


function usage() {
    echo "用法: $0 <命令> [参数]"
    echo
    echo "命令列表："
    echo "  start-all               - 启动所有已启用的转发规则（通常用于开机自动执行）"
    echo "  add <localPort> <ip> <port> [protocol]    - 添加并启动新的转发规则 (默认协议 tcp+udp)"
    echo "  disable <localPort>     - 停用但保留此端口的规则"
    echo "  enable <localPort>      - 启用已存在的端口规则"
    echo "  delete <localPort>      - 删除对应端口的转发规则"
    echo "  list                    - 列出所有规则"
    echo "  install-service         - 复制脚本到 /usr/local/bin/ 并创建 systemd service (开机自启动)"
    echo
    echo "示例："
    echo "  $0 add 8080 example.com 443 tcp+udp"
    echo "  $0 disable 8080"
    echo "  $0 enable 8080"
    echo "  $0 delete 8080"
    echo "  $0 list"
    echo "  $0 install-service"
}

# ---------------------------
# 主逻辑
# ---------------------------
check_or_install_gost

[ ! -d "$LOG_DIR" ] && sudo mkdir -p "$LOG_DIR" && sudo chmod 755 "$LOG_DIR"

case "$1" in
    start-all)
        start_all
        ;;
    add)
        add_rule "$2" "$3" "$4" "$5"
        ;;
    disable)
        toggle_rule "$2" "false"
        ;;
    enable)
        toggle_rule "$2" "true"
        ;;
    delete)
        delete_rule "$2"
        ;;
    list)
        list_rules
        ;;
    install-service)
        create_systemd_service
        ;;
    *)
        usage
        ;;
esac
