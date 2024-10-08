#!/bin/bash

# 延迟打字
print_with_delay() {
    text="$1"
    delay="$2"
    for ((i = 0; i < ${#text}; i++)); do
        echo -n "${text:$i:1}"
        sleep $delay
    done
    echo
}

# 自定义字体彩色，read 函数
red() { echo -e "\033[31m\033[01m$*\033[0m"; }  # 红色
green() { echo -e "\033[32m\033[01m$*\033[0m"; }   # 绿色
yellow() { echo -e "\033[33m\033[01m$*\033[0m"; }   # 黄色

# 信息提示
show_notice() {
    local message="$1"

    local green_bg="\e[48;5;34m"
    local white_fg="\e[97m"
    local reset="\e[0m"

    echo -e "${green_bg}${white_fg}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${reset}"
    echo -e "${white_fg}┃${reset}                                                                                             "
    echo -e "${white_fg}┃${reset}                                   ${message}                                                "
    echo -e "${white_fg}┃${reset}                                                                                             "
    echo -e "${green_bg}${white_fg}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${reset}"
}

# 作者介绍
print_with_delay "正在安装脚本中" 0.03
echo ""
echo ""

# 安装依赖
install_base() {
    local packages=("qrencode")
    for package in "${packages[@]}"; do
        if ! command -v "$package" &> /dev/null; then
            echo "正在安装 $package..."
            if [ -n "$(command -v apt)" ]; then
                sudo apt update > /dev/null 2>&1
                sudo apt install -y "$package" > /dev/null 2>&1
            elif [ -n "$(command -v yum)" ]; then
                sudo yum install -y "$package"
            elif [ -n "$(command -v dnf)" ]; then
                sudo dnf install -y "$package"
            else
                echo "无法安装 $package。请手动安装，并重新运行脚本。"
                exit 1
            fi
            echo "$package 已安装。"
        else
            echo "$package 已经安装。"
        fi
    done
}

# 下载cloudflared和sb
download_singbox() {
    arch=$(uname -m)
    # Map architecture names
    case ${arch} in
        x86_64)
            arch="amd64"
            ;;
        aarch64)
            arch="arm64"
            ;;
        armv7l)
            arch="armv7"
            ;;
    esac
    # Fetch the latest (including pre-releases) release version number from GitHub API
    latest_version_tag=$(curl -s "https://api.github.com/repos/SagerNet/sing-box/releases" | grep -Po '"tag_name": "\K.*?(?=")' | sort -V | tail -n 1)
    latest_version=${latest_version_tag#v}  # Remove 'v' prefix from version number
    # Prepare package names
    package_name="sing-box-${latest_version}-linux-${arch}"
    # Prepare download URL
    url="https://github.com/SagerNet/sing-box/releases/download/${latest_version_tag}/${package_name}.tar.gz"
    # Download the latest release package (.tar.gz) from GitHub
    curl -sLo "/root/${package_name}.tar.gz" "$url"

    # Extract the package and move the binary to /root
    tar -xzf "/root/${package_name}.tar.gz" -C /root
    mv "/root/${package_name}/sing-box" /root/sbox

    # Cleanup the package
    rm -r "/root/${package_name}.tar.gz" "/root/${package_name}"

    # Set the permissions
    chown root:root /root/sbox/sing-box
    chmod +x /root/sbox/sing-box
}

download_cloudflared() {
    arch=$(uname -m)
    # Map architecture names
    case ${arch} in
        x86_64)
            cf_arch="amd64"
            ;;
        aarch64)
            cf_arch="arm64"
            ;;
        armv7l)
            cf_arch="arm"
            ;;
    esac

    # install cloudflared linux
    cf_url="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-${cf_arch}"
    curl -sLo "/root/sbox/cloudflared-linux" "$cf_url"
    chmod +x /root/sbox/cloudflared-linux
    echo ""
}

# client configuration
show_client_configuration() {
    # 获取当前ip
    server_ip=$(grep -o "SERVER_IP='[^']*'" /root/sbox/config | awk -F"'" '{print $2}')
    
    # hy port
    hy_port=$(grep -o "HY_PORT='[^']*'" /root/sbox/config | awk -F"'" '{print $2}')
    # hy sni
    hy_server_name=$(grep -o "HY_SERVER_NAME='[^']*'" /root/sbox/config | awk -F"'" '{print $2}')
    # hy password
    hy_password=$(grep -o "HY_PASSWORD='[^']*'" /root/sbox/config | awk -F"'" '{print $2}')
    
    echo ""
    echo "" 
    show_notice "$(green "Hysteria2 通用参数")"
    echo ""
    echo "" 
    green "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━Hysteria2 客户端通用参数━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" 
    echo "" 
    echo "服务器ip: $server_ip"
    echo "端口号: $hy_port"
    echo "密码password: $hy_password"
    echo "域名SNI: $hy_server_name"
    echo "跳过证书验证（允许不安全）: True"
    echo ""
    green "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo ""
    sleep 3
}

# enable bbr
enable_bbr() {
    # temporary workaround for installing bbr
    bash <(curl -L -s https://raw.githubusercontent.com/teddysun/across/master/bbr.sh)
    echo ""
}

# 修改sb
modify_singbox() {
    # 修改hysteria2配置
    show_notice "开始修改hysteria2端口号"
    hy_current_port=$(grep -o "HY_PORT='[^']*'" /root/sbox/config | awk -F"'" '{print $2}')
    while true; do
        read -p "请输入想要修改的端口号 (当前端口号为 $hy_current_port): " hy_port
        hy_port=${hy_port:-$hy_current_port}
        if [ "$hy_port" -eq "$hy_current_port" ]; then
            break
        fi
        if ss -tuln | grep -q ":$hy_port\b"; then
            echo "端口 $hy_port 已经被占用，请选择其他端口。"
        else
            break
        fi
    done

    # 修改sing-box
    sed -i "s/HY_PORT='[^']*'/HY_PORT='$hy_port'/" /root/sbox/config

    # Restart sing-box service
    systemctl restart sing-box
}

# 创建快捷方式
create_shortcut() {
    cat > /root/sbox/nowhash.sh << EOF
#!/usr/bin/env bash
bash <(curl -fsSL https://github.com/vveg26/sing-box-reality-hysteria2/raw/main/beta.sh) \$1
EOF
    chmod +x /root/sbox/nowhash.sh
    ln -sf /root/sbox/nowhash.sh /usr/bin/nowhash
}

uninstall_singbox() {
    # Stop and disable services
    systemctl stop sing-box argo
    systemctl disable sing-box argo > /dev/null 2>&1

    # Remove service files
    rm -f /etc/systemd/system/sing-box.service
    rm -f /etc/systemd/system/argo.service

    # Remove configuration and executable files
    rm -f /root/sbox/sbconfig_server.json
    rm -f /root/sbox/sing-box
    rm -f /usr/bin/nowhash
    rm -f /root/sbox/nowhash.sh
    rm -f /root/sbox/cloudflared-linux
    rm -f /root/sbox/self-cert/private.key
    rm -f /root/sbox/self-cert/cert.pem
    rm -f /root/sbox/config

    # Remove directories
    rm -rf /root/sbox/self-cert/
    rm -rf /root/sbox/

    echo "卸载完成"
}

install_base

# Check if sing-box and related files already exist
if [ -f "/root/sbox/sbconfig_server.json" ] && [ -f "/root/sbox/cloudflared-linux" ] && [ -f "/root/sbox/sing-box" ] && [ -f "/etc/systemd/system/sing-box.service" ]; then

    echo "sing-box-reality-hysteria2已经安装"
    echo ""
    echo "请选择选项:"
    echo ""
    echo "1. 重新安装"
    echo "2. 修改配置"
    echo "3. 显示客户端配置"
    echo "4. 更新sing-box内核"
    echo "5. 重启argo隧道"
    echo "6. 重启sing-box"
    echo "7. 开启bbr"
    echo "8. 卸载"
    echo ""
    read -p "Enter your choice (1-8): " choice

    case $choice in
        1)
            show_notice "开始卸载..."
            # Uninstall previous installation
            uninstall_singbox
            ;;
        2)
            # 修改sb
            modify_singbox
            # show client configuration
            show_client_configuration
            exit 0
            ;;
        3)  
            # show client configuration
            show_client_configuration
            exit 0
            ;;		
        8)
            uninstall_singbox
            exit 0
            ;;
        4)
            show_notice "更新 Sing-box..."
            download_singbox
            # Check configuration and start the service
            if /root/sbox/sing-box check -c /root/sbox/sbconfig_server.json; then
                echo "Configuration checked successfully. Starting sing-box service..."
                systemctl restart sing-box
            fi
            echo ""  
            exit 0
            ;;
        5)
            systemctl stop argo
            systemctl start argo
            echo "重新启动完成，查看新的客户端信息"
            show_client_configuration
            exit 0
            ;;
        7)
            enable_bbr
            exit 0
            ;;
        6)
            systemctl restart sing-box
            echo "重启完成"
            exit 0
            ;;
        *)
            echo "Invalid choice. Exiting."
            exit 1
            ;;
    esac
fi

mkdir -p "/root/sbox/"

download_singbox

download_cloudflared

# hysteria2
green "开始配置hysteria2"
echo ""
# Generate hysteria necessary values
hy_password=$(/root/sbox/sing-box generate rand --hex 8)
echo "自动生成了8位随机密码"
echo ""

# Ask for listen port
while true; do
    read -p "请输入hysteria2监听端口 (default: 8443): " hy_port
    hy_port=${hy_port:-8443}

    # 检测端口是否被占用
    if ss -tuln | grep -q ":$hy_port\b"; then
        echo "端口 $hy_port 已经被占用，请选择其他端口。"
    else
        break
    fi
done
echo ""

# Ask for self-signed certificate domain
read -p "输入自签证书域名 (default: bing.com): " hy_server_name
hy_server_name=${hy_server_name:-bing.com}
mkdir -p /root/sbox/self-cert/ && openssl ecparam -genkey -name prime256v1 -out /root/sbox/self-cert/private.key && openssl req -new -x509 -days 36500 -key /root/sbox/self-cert/private.key -out /root/sbox/self-cert/cert.pem -subj "/CN=${hy_server_name}"
echo ""
echo "自签证书生成完成"
echo ""

# ip地址
server_ip=$(curl -s4m8 ip.sb -k) || server_ip=$(curl -s6m8 ip.sb -k)

# config配置文件
cat > /root/sbox/config <<EOF

# VPS ip
SERVER_IP='$server_ip'
# Singbox
# Hy2
HY_PORT='$hy_port'
HY_SERVER_NAME='$hy_server_name'
HY_PASSWORD='$hy_password'

EOF

# TODO argo开启
echo "设置argo"
cat > /etc/systemd/system/argo.service << EOF
[Unit]
Description=Cloudflare Tunnel
After=network.target

[Service]
Type=simple
NoNewPrivileges=yes
TimeoutStartSec=0
ExecStart=/bin/bash -c "/root/sbox/cloudflared-linux tunnel --url http://localhost:$hy_port --no-autoupdate --edge-ip-version auto --protocol http2>/root/sbox/argo.log 2>&1 "
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target

EOF

systemctl daemon-reload
systemctl enable argo > /dev/null 2>&1
systemctl start argo

# sbox配置文件
cat > /root/sbox/sbconfig_server.json << EOF
{
  "log": {
    "disabled": false,
    "level": "info",
    "timestamp": true
  },
  "inbounds": [
    {
      "type": "hysteria2",
      "tag": "hy2-in",
      "listen": "::",
      "listen_port": $hy_port,
      "users": [
          {
              "password": "$hy_password"
          }
      ],
      "tls": {
          "enabled": true,
          "alpn": [
              "h3"
          ],
          "certificate_path": "/root/sbox/self-cert/cert.pem",
          "key_path": "/root/sbox/self-cert/private.key"
      }
    }
  ],
  "outbounds": [
    {
      "type": "direct",
      "tag": "direct"
    },
    {
      "type": "block",
      "tag": "block"
    }
  ]
}
EOF

# Create sing-box.service
cat > /etc/systemd/system/sing-box.service <<EOF
[Unit]
After=network.target nss-lookup.target

[Service]
User=root
WorkingDirectory=/root
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
ExecStart=/root/sbox/sing-box run -c /root/sbox/sbconfig_server.json
ExecReload=/bin/kill -HUP \$MAINPID
Restart=on-failure
RestartSec=10
LimitNOFILE=infinity

[Install]
WantedBy=multi-user.target
EOF

# Check configuration and start the service
if /root/sbox/sing-box check -c /root/sbox/sbconfig_server.json; then
    echo "Configuration checked successfully. Starting sing-box service..."
    systemctl daemon-reload
    systemctl enable sing-box > /dev/null 2>&1
    systemctl start sing-box
    systemctl restart sing-box
    create_shortcut
    show_client_configuration
else
    echo "Error in configuration. Aborting"
fi
