#!/bin/bash

GOST_BIN="/usr/local/bin/gost"
CONFIG_FILE="gost_config.json"

function is_ipv6() {
    local ip=$1
    if [[ "$ip" =~ : ]]; then
        return 0  # 返回 0，表示是 IPv6
    else
        return 1  # 返回 1，表示不是 IPv6
    fi
}

function format_address() {
    local ip=$1
    if is_ipv6 $ip; then
        echo "[$ip]"  # IPv6 地址，添加方括号
    else
        echo "$ip"   # IPv4 地址，不变
    fi
}

function start_gost {
    local local_port=$1
    local remote_host=$(format_address $2)
    local remote_port=$3

    echo "启动 Gost TCP - 本地端口: ${local_port}, 远程地址: ${remote_host}:${remote_port}"
    nohup ${GOST_BIN} -L=tcp://:${local_port}/${remote_host}:${remote_port} &

    echo "启动 Gost UDP - 本地端口: ${local_port}, 远程地址: ${remote_host}:${remote_port}"
    nohup ${GOST_BIN} -L=udp://:${local_port}/${remote_host}:${remote_port} &

    # 保存配置到 JSON 文件
    echo "{\"local_port\": \"${local_port}\", \"remote_host\": \"${remote_host}\", \"remote_port\": \"${remote_port}\", \"protocol\": \"tcp+udp\"}" >> $CONFIG_FILE
}

function stop_gost {
    local local_port=$1

    local line=$(grep -n "\"local_port\": \"${local_port}\"" $CONFIG_FILE | cut -d: -f1)
    if [ ! -z "$line" ]; then
        # 杀死进程
        pkill -f "gost -L=tcp://:${local_port}"
        pkill -f "gost -L=udp://:${local_port}"

        sed -i "${line}d" $CONFIG_FILE
        echo "停止 Gost - 本地端口: ${local_port}"
    else
        echo "未找到运行在端口 ${local_port} 上的 Gost 实例。"
    fi
}

function interactive_mode {
    echo "欢迎使用 Gost 管理器交互模式。"
    echo "请选择您的操作："
    echo "1. 启动新的转发"
    echo "2. 停止现有的转发"
    read -p "请输入您的选择（1 或 2）: " choice

    case $choice in
        1)
            read -p "请输入需要添加转发的本地端口: " local_port
            read -p "请输入目标 IP 地址: " remote_host
            read -p "请输入目标端口: " remote_port
            start_gost $local_port $remote_host $remote_port
            ;;
        2)
            read -p "请输入需要停止转发的本地端口: " local_port
            stop_gost $local_port
            ;;
        *)
            echo "选择无效，请重新运行脚本。"
            exit 1
            ;;
    esac
}

function usage {
    echo "使用方法: $0 {start|stop|interactive}"
    echo "示例: $0 start 8080 example.com 443"
    echo "     $0 stop 8080"
    echo "     $0 interactive"
}

# 主逻辑处理
case "$1" in
    start)
        start_gost $2 $3 $4
        ;;
    stop)
        stop_gost $2
        ;;
    interactive)
        interactive_mode
        ;;
    *)
        usage
        ;;
esac
