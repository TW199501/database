#!/bin/bash

# 顯示目前防火牆的狀態
get_firewall_status() {
  if command -v firewall-cmd &>/dev/null; then
    FIREWALL_TYPE="Firewalld"
    if sudo firewall-cmd --state &>/dev/null; then
      FIREWALL_STATUS="✔ $FIREWALL_TYPE（已啟用）"
    else
      FIREWALL_STATUS="✘ $FIREWALL_TYPE（未啟用）"
    fi
  elif command -v ufw &>/dev/null; then
    FIREWALL_TYPE="UFW"
    if [[ $(sudo ufw status | grep -i inactive) == "" ]]; then
      FIREWALL_STATUS="✔ $FIREWALL_TYPE（已啟用）"
    else
      FIREWALL_STATUS="✘ $FIREWALL_TYPE（未啟用）"
    fi
  else
    FIREWALL_STATUS="✘ 未偵測到防火牆"
  fi
}

# 檢查 IP 格式是否合法（範圍 0–255）
is_valid_ip() {
  local ip=$1
  if [[ ! $ip =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
    return 1
  fi
  IFS='.' read -r a b c d <<< "$ip"
  for octet in $a $b $c $d; do
    if ((octet < 0 || octet > 255)); then
      return 1
    fi
  done
  return 0
}

# 功能 1：設定靜態 IP
set_ip() {
  echo "🔍 目前的網路介面與 IP 設定如下："
  ip -4 addr show | awk '
  /^[0-9]+: / {
      split($2, iface, ":");
      iface_name=iface[1];
      up_status=($3 == "UP," ? "🟢 UP" : "🔴 DOWN");
  }
  /inet / {
      ip_address=$2;
      printf "  ➤ %s (%s)\n      IPv4: %s\n", iface_name, up_status, ip_address;
  }'
  echo ""

  # 自動偵測第一張 UP 的網卡（排除 lo）
  IFACE=$(ip -o link show up | awk -F: '!/lo/ {print $2; exit}' | tr -d ' ')
  echo "📡 偵測網卡：$IFACE"

  # 輸入並防呆檢查 IP
  read -p "請輸入新的靜態 IP（例如：192.168.30.70 或加上 CIDR /24）: " IPADDR_RAW
  IPADDR_RAW=$(echo "$IPADDR_RAW" | xargs)  # 移除空白
  if [[ -z "$IPADDR_RAW" ]]; then
      echo "❌ 輸入無效，IP 不可為空或空白"
      return 1
  fi

  # 自動補上 /24
  if [[ "$IPADDR_RAW" != */* ]]; then
    IPADDR="$IPADDR_RAW/24"
  else
    IPADDR="$IPADDR_RAW"
  fi

  # 分離純 IP 部分
  CHECK_IP=$(echo "$IPADDR" | cut -d/ -f1)

  # 格式合法性檢查
  if ! is_valid_ip "$CHECK_IP"; then
    echo "❌ 輸入的 IP [$CHECK_IP] 格式錯誤或超出範圍（每段 0~255）"
    return 1
  fi

  # 偵測目前 Gateway
  GATEWAY=$(ip route | awk '/default/ {print $3}')
  if [[ -z "$GATEWAY" ]]; then
    echo "❌ 無法偵測預設 Gateway，請確認系統路由表。"
    return 1
  fi

  # 檢查是否同網段
  IP_PREFIX=$(echo "$CHECK_IP" | awk -F. '{print $1"."$2"."$3}')
  GW_PREFIX=$(echo "$GATEWAY" | awk -F. '{print $1"."$2"."$3}')
  if [[ "$IP_PREFIX" != "$GW_PREFIX" ]]; then
    echo "⚠️ IP（$CHECK_IP）與 Gateway（$GATEWAY）不在同網段，請檢查"
    return 1
  fi

  # 提示合法 IP 範圍（依 Gateway 值）
  GATEWAY_LAST=$(echo "$GATEWAY" | awk -F. '{print $4}')
  if [[ "$GATEWAY_LAST" == "1" ]]; then
    echo "📌 Gateway 為 $GATEWAY，建議可用 IP：$IP_PREFIX.2 ~ $IP_PREFIX.254"
  elif [[ "$GATEWAY_LAST" == "254" ]]; then
    echo "📌 Gateway 為 $GATEWAY，建議可用 IP：$IP_PREFIX.1 ~ $IP_PREFIX.253"
  else
    echo "📌 Gateway 為 $GATEWAY，請自行確認 IP 可用範圍"
  fi

  # 檢查 IP 是否已被佔用
  echo "🔍 檢查 IP 是否已被使用：$CHECK_IP"
  if ping -c 2 -W 1 "$CHECK_IP" &>/dev/null; then
    echo "❌ 該 IP 位址已被使用，請選擇其他 IP。"
    return 1
  else
    echo "✅ 該 IP 尚未被使用，可安全設定。"
  fi

  # DNS 輸入與防呆處理
  read -p "請輸入 DNS（預設為 168.95.1.1 8.8.8.8 1.1.1.1，可空白）: " DNS
  DNS=$(echo "$DNS" | xargs)  # 移除空白
  if [[ -z "$DNS" ]]; then
    DNS="168.95.1.1,8.8.8.8,1.1.1.1"
  else
    DNS=$(echo "$DNS" | tr ' ' ',')
  fi

  # 產生 netplan 設定檔
  echo "📝 寫入 netplan 設定檔：/etc/netplan/50-cloud-init.yaml"
  cat <<EOF | sudo tee /etc/netplan/50-cloud-init.yaml > /dev/null
network:
  version: 2
  ethernets:
    $IFACE:
      dhcp4: no
      addresses: [$IPADDR]
      nameservers:
        addresses: [$DNS]
      routes:
        - to: default
          via: $GATEWAY
EOF

  sudo chmod 600 /etc/netplan/50-cloud-init.yaml
  echo "⚙️ 套用 netplan 設定..."
  if sudo netplan apply; then
    echo "✅ IP 設定完成：$IPADDR ➝ Gateway: $GATEWAY"
    echo "📡 目前介面狀態："
    ip -4 addr show "$IFACE"
    ip route
  else
    echo "⚠️ IP 設定失敗，請確認參數或檔案格式。"
    return 1
  fi
}

# 功能 2 ：防火牆設定
firewall_toolkit() {
    # ---------- UI ----------
    print_title() { echo -e "\n\e[1;36m🧱 $1\e[0m"; }
    print_success() { echo -e "\e[1;32m✔ $1\e[0m"; }
    print_warning() { echo -e "\e[1;33m⚠ $1\e[0m"; }
    print_error() { echo -e "\e[1;31m✘ $1\e[0m"; }

    # ---------- 偵測防火牆 ----------
    detect_firewall() {
        if command -v firewall-cmd &>/dev/null; then
            FIREWALL="firewalld"
        elif command -v ufw &>/dev/null; then
            FIREWALL="ufw"
        else
            print_error "未偵測到已知防火牆（Firewalld 或 UFW）"
            exit 1
        fi
    }

    # ---------- 防火牆狀態檢查 ----------
    firewall_is_active() {
        if [[ "$FIREWALL" == "firewalld" ]]; then
            if sudo firewall-cmd --state &>/dev/null; then
                return 0
            else
                print_warning "✘ Firewalld 尚未啟用"
                return 1
            fi
        else
            status=$(sudo ufw status | grep -i "Status: inactive")
            if [[ -n "$status" ]]; then
                print_warning "✘ UFW 尚未啟用"
                return 1
            else
                return 0
            fi
        fi
    }

    # ---------- 功能函數 ----------
    show_status() {
      print_title "防火牆狀態"
      if [[ "$FIREWALL" == "firewalld" ]]; then
        if sudo firewall-cmd --state &>/dev/null; then
          print_success "✔ Firewalld（已啟用）"
        else
          print_warning "✘ Firewalld（未啟用）"
        fi
      else
        ufw_output=$(sudo ufw status)
        if echo "$ufw_output" | grep -iq "inactive"; then
          print_warning "✘ UFW（未啟用）"
        else
          print_success "✔ UFW（已啟用）"
          echo "$ufw_output"
        fi
      fi
    }
    enable_firewall() {
        print_title "啟用防火牆"
        if [[ "$FIREWALL" == "firewalld" ]]; then
            sudo systemctl enable --now firewalld
        else
            sudo ufw enable
        fi
        print_success "防火牆已啟用"
    }

    disable_firewall() {
        print_title "關閉防火牆"
        if [[ "$FIREWALL" == "firewalld" ]]; then
            sudo systemctl stop firewalld
            sudo systemctl disable firewalld
        else
            sudo ufw disable
        fi
        print_success "防火牆已關閉"
    }

    show_open_ports() {
        print_title "已開放 Port 與 Service"
        if ! firewall_is_active; then
            print_warning "⚠ 防火牆尚未啟用，請先啟用防火牆（選項 2）再查看開放 port。"
            return
        fi
        if [[ "$FIREWALL" == "firewalld" ]]; then
            echo "🔥 Zone: $(sudo firewall-cmd --get-default-zone)"
            sudo firewall-cmd --list-all
        else
            sudo ufw status numbered
        fi
    }

    open_ports() {
        if ! firewall_is_active; then
            print_warning "⚠ 防火牆尚未啟用，請先啟用防火牆（選項 2）再進行開放 port 操作。"
            return
        fi
        read -p "請輸入要開放的 port（可多個，逗號分隔）:" input_ports
        IFS=',' read -ra PORTS <<< "$input_ports"
        for port in "${PORTS[@]}"; do
            port=$(echo "$port" | xargs)
            if [[ -n "$port" ]]; then
                if [[ "$FIREWALL" == "firewalld" ]]; then
                    sudo firewall-cmd --permanent --add-port=${port}/tcp
                else
                    sudo ufw allow ${port}/tcp
                fi
                print_success "已開放 ${port}/tcp"
            fi
        done
        reload_firewall
    }

    close_ports() {
        if ! firewall_is_active; then
            print_warning "⚠ 防火牆尚未啟用，請先啟用防火牆（選項 2）再進行關閉 port 操作。"
            return
        fi
        read -p "請輸入要關閉的 port（可多個，逗號分隔）:" input_ports
        IFS=',' read -ra PORTS <<< "$input_ports"
        for port in "${PORTS[@]}"; do
            port=$(echo "$port" | xargs)
            if [[ -n "$port" ]]; then
                if [[ "$FIREWALL" == "firewalld" ]]; then
                    sudo firewall-cmd --permanent --remove-port=${port}/tcp || true
                else
                    sudo ufw delete allow ${port}/tcp || true
                fi
                print_success "已關閉 ${port}/tcp"
            fi
        done
        reload_firewall
    }

    reload_firewall() {
        print_title "重新載入防火牆設定..."
        if ! firewall_is_active; then
            print_warning "⚠ 防火牆尚未啟用，無需重載設定。"
            return
        fi
        if [[ "$FIREWALL" == "firewalld" ]]; then
            sudo firewall-cmd --reload
        fi
        print_success "設定已套用"
    }

    block_internal_ip() {
        print_title "封鎖內網某 IP 存取本機"
        if [[ "$FIREWALL" != "firewalld" ]]; then
            print_warning "⚠ 此功能僅支援 firewalld，目前為 $FIREWALL"
            return
        fi
        read -p "請輸入內網 IP（如 192.168.1.100）: " ip
        sudo firewall-cmd --permanent --add-rich-rule="rule family=ipv4 source address=$ip drop"
        print_success "已封鎖 $ip 存取本機"
    }

    manage_directional_rule() {
        print_title "管理 ingress / egress 方向封鎖"
        if [[ "$FIREWALL" != "firewalld" ]]; then
            print_warning "⚠ 此功能僅支援 firewalld，目前為 $FIREWALL"
            return
        fi
        read -p "請輸入要設定的 IP（通常為外網 IP）: " ip
        echo "請選擇封鎖方向："
        echo "1) 封鎖該 IP 存取本機（Ingress）"
        echo "2) 封鎖本機存取該 IP（Egress）"
        echo "3) 同時封鎖 Ingress 與 Egress"
        echo "4) 解除所有封鎖（Ingress / Egress）"
        read -p "選擇操作（1-4）: " direction
        case $direction in
            1)
                sudo firewall-cmd --permanent --add-rich-rule="rule family=ipv4 source address=$ip drop"
                print_success "已封鎖 $ip 存取本機 (Ingress)"
                ;;
            2)
                sudo firewall-cmd --permanent --add-rich-rule="rule family=ipv4 destination address=$ip drop"
                print_success "已封鎖本機存取 $ip (Egress)"
                ;;
            3)
                sudo firewall-cmd --permanent --add-rich-rule="rule family=ipv4 source address=$ip drop"
                sudo firewall-cmd --permanent --add-rich-rule="rule family=ipv4 destination address=$ip drop"
                print_success "已完全封鎖 $ip 的 Ingress 與 Egress"
                ;;
            4)
                sudo firewall-cmd --permanent --remove-rich-rule="rule family=ipv4 source address=$ip drop" || true
                sudo firewall-cmd --permanent --remove-rich-rule="rule family=ipv4 destination address=$ip drop" || true
                print_success "已解除對 $ip 的封鎖"
                ;;
            *)
                print_warning "輸入錯誤，未執行任何操作"
                ;;
        esac
        reload_firewall
    }

    # ---------- 主流程 ----------
    detect_firewall
    while true; do
        show_menu() {
            echo ""
            echo "請選擇操作項目（⚠ 第 5、6 項需先啟用防火牆）："
            echo "1) 顯示防火牆狀態"
            echo "2) 開啟防火牆"
            echo "3) 關閉防火牆"
            echo "4) 顯示已開放的 Port / Service"
            echo "5) 開放 Port"
            echo "6) 關閉 Port"
            echo "7) 管理 ingress/egress 方向 (進階)"
            echo "8) 封鎖內網某 IP 存取本機"
            echo "0) 離開"
        }
        show_menu
        read -p "請輸入選項：" choice
        case $choice in
            1) show_status ;;
            2) enable_firewall ;;
            3) disable_firewall ;;
            4) show_open_ports ;;
            5) open_ports ;;
            6) close_ports ;;
            7) manage_directional_rule ;;
            8) block_internal_ip ;;
            0) reload_firewall; echo "Bye!" && break ;;
            *) print_warning "無效選項，請重新輸入。" ;;
        esac
        echo ""
    done
}

# 功能 3:docker檢查重新安裝
docker_setup_and_install() {
    for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do 
        sudo apt-get remove -y $pkg 
    done
    echo "🧹 自動移除舊的 Docker 套件"

    sudo apt-get update
    sudo apt-get install -y ca-certificates curl
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    echo "加入 Docker 儲存庫..."
    echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    sudo apt-get update
    echo "✅ 已成功加入 Docker 儲存庫"

    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    sudo systemctl enable docker.service
    sudo systemctl enable containerd.service
    sudo systemctl start docker.service
    echo "✅ 完成 Docker 安裝與開機啟動設定"
}

# 功能 4：SSH 免密登入
setup_ssh_key_inline() {
    echo "==== SSH 免密登入設定 ===="

    if [ ! -f ~/.ssh/id_rsa ]; then
        echo "尚未偵測到 SSH 金鑰，正在建立..."
        ssh-keygen -t rsa -b 4096 -C "deploy@$(hostname)" -f ~/.ssh/id_rsa -N ""
        echo "SSH 金鑰已建立完成。"
    else
        echo "已偵測到 SSH 金鑰，略過建立步驟。"
    fi

    read -p "請輸入遠端主機 IP（可輸入多個，以逗號分隔）: " HOST_INPUT
    IFS=',' read -ra HOSTS <<< "$HOST_INPUT"

    read -p "請輸入遠端主機使用者帳號（例如 root）: " SSH_USER
    read -p "請輸入 SSH Port（預設為 22）: " SSH_PORT
    SSH_PORT=${SSH_PORT:-22}

    for HOST in "${HOSTS[@]}"; do
        echo "傳送公鑰到 $SSH_USER@$HOST:$SSH_PORT ..."
        ssh-copy-id -p "$SSH_PORT" "$SSH_USER@$HOST"
        if [ $? -eq 0 ]; then
            echo "✅ $HOST 設定完成。"
        else
            echo "⚠️ $HOST 設定失敗，請檢查登入資訊或網路連線。"
        fi
        echo "-----------------------------"
    done

    echo "所有主機處理完成。"
}

# 功能 5：清除系統垃圾與排程清理任務
clean_system() {
    echo "🔍 開始 Linux 系統清理作業..."

    echo "🧹 清理 APT 快取..."
    sudo apt clean
    sudo apt autoclean

    echo "🧹 自動移除不需要的套件與舊核心..."
    sudo apt autoremove --purge -y

    echo "🧹 清理 journal log（保留 7 天）..."
    sudo journalctl --vacuum-time=7d

    echo "🧹 清理使用者縮圖快取..."
    rm -rf ~/.cache/thumbnails/*

    echo "🧹 清理使用者應用快取..."
    rm -rf ~/.cache/*

    echo "🛠️ 加入自動清理排程（每週日 5:00 執行）..."
    CRON_JOB="0 5 * * 0 /home/elf/linux_clear.sh"
    if ! crontab -l 2>/dev/null | grep -qF "$CRON_JOB"; then
        (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
    fi
    crontab -l

    if ! systemctl is-active --quiet cron; then
        echo "⚠️ cron 尚未啟用，正在啟用中..."
        sudo systemctl start cron
        sudo systemctl enable cron
        echo "✅ cron 服務已啟用。"
    else
        echo "✅ cron 已經在執行中。"
    fi

    echo "📊 清理完成，磁碟使用情況："
    df -h
    echo "✅ 系統清理作業完成！"
    echo "🗓️ 已加入排程任務：$CRON_JOB"
}

# 功能6.效能優化（swappiness/ZRAM/CPU/BBR）
system_optimize() {
  echo "🚀 開始 VM 專用系統效能與穩定性優化..."

# 1. 調整 swappiness（降低 swap 頻率）
echo "🧠 調整 vm.swappiness 為 10..."
sudo sysctl vm.swappiness=10
echo 'vm.swappiness=10' | sudo tee -a /etc/sysctl.conf

echo "🌐 啟用 TCP BBR 擁塞控制算法..."
sudo modprobe tcp_bbr
echo "tcp_bbr" | sudo tee -a /etc/modules-load.d/modules.conf

echo "🌐 啟用 TCP BBR 擁塞控制算法..."
{
    echo "tcp_bbr" | sudo tee -a /etc/modules-load.d/modules.conf
    echo "net.core.default_qdisc=fq"
    echo "net.ipv4.tcp_congestion_control=bbr"
} | sudo tee -a /etc/sysctl.conf >/dev/null
sudo sysctl -p
echo "✅ 擁塞控制算法：$(sysctl -n net.ipv4.tcp_congestion_control)"

sysctl -n net.ipv4.tcp_congestion_control
echo "✅ 擁塞控制算法：$(sysctl -n net.ipv4.tcp_congestion_control)"
lsmod | grep tcp_bbr   

# 3. 停用不必要的服務（常見 VM 不需）
echo "🔕 停用無用服務：bluetooth, cups, avahi-daemon..."
for svc in bluetooth cups avahi-daemon ModemManager; do
        sudo systemctl disable --now $svc 2>/dev/null
done

# 4. 可選關閉 snap（若無 GUI 需求）
if command -v snap &>/dev/null; then
    echo "❌ 移除 snapd（可選）..."
    sudo systemctl disable --now snapd.service
    sudo apt purge -y snapd
fi

# 5. 啟用自動安全更新（必要）
echo "🛡️ 啟用 unattended-upgrades（自動安全更新）..."
sudo apt install -y unattended-upgrades
sudo dpkg-reconfigure --priority=low unattended-upgrades

# 6. 檢查 cron 與 logrotate 狀態
echo "🕓 確認 cron 與 logrotate 服務啟動中..."
sudo systemctl enable --now cron
sudo systemctl enable --now logrotate.timer

# 7. 顯示當前系統記憶體與核心優化參數
echo ""
echo "📊 驗證系統優化參數："
sysctl vm.swappiness
sysctl net.ipv4.tcp_congestion_control
echo ""
echo "✅ VM 系統優化作業完成（建議重啟機器後再次確認）"
}


# 功能7.儲存系統優化（TRIM + I/O Scheduler）
optimize_storage() {
  echo "🚀 儲存系統優化作業開始..."

  echo "🔍 檢查是否為虛擬機..."
  is_vm="false"
  if grep -qEi '(hypervisor|kvm|vmware|virtualbox)' /proc/cpuinfo || hostnamectl | grep -qi "virtual"; then
      is_vm="true"
      echo "✅ 偵測為虛擬機，僅啟用 TRIM（略過 I/O 調度器設定）"
  else
      echo "✅ 偵測為實體機，執行完整優化（TRIM + I/O 調度器）"
  fi

  echo "🔧 啟用 fstrim.timer..."
  sudo systemctl enable --now fstrim.timer
  systemctl status fstrim.timer --no-pager

  if [[ "$is_vm" == "false" ]]; then
      echo "📦 執行磁碟 I/O 調度器自動設定..."

      UDEV_RULE="/etc/udev/rules.d/60-disk-ioscheduler.rules"
      sudo bash -c "echo '# 自動設定磁碟調度器規則' > $UDEV_RULE"

      for devpath in /sys/block/*; do
          dev=$(basename "$devpath")
          [[ $dev == loop* || $dev == ram* ]] && continue
          devfile="/dev/$dev"

          if [[ $dev == nvme* ]]; then
              scheduler="none"
              echo "💡 偵測到 NVMe 裝置 $dev，設定 scheduler 為 $scheduler"
          else
             rotational=$(cat "$devpath/queue/rotational")
              if [[ "$rotational" == "0" ]]; then
                  scheduler="kyber"
                  echo "💡 偵測到 SSD 裝置 $dev，設定 scheduler 為 $scheduler"
              else
                  scheduler="mq-deadline"
                  echo "💡 偵測到 HDD 裝置 $dev，設定 scheduler 為 $scheduler"
              fi
            fi

          echo "ACTION==\"add|change\", KERNEL==\"$dev\", ATTR{queue/scheduler}=\"$scheduler\"" | sudo tee -a "$UDEV_RULE" > /dev/null
      done

      echo "🔁 重新載入 udev 規則並觸發裝置..."
      sudo udevadm control --reload-rules
      sudo udevadm trigger
    fi

  echo "📊 當前磁碟 I/O 調度器狀態："
  for devpath in /sys/block/*/queue/scheduler; do
      dev=$(basename "$(dirname "$devpath")")
      sched=$(cat "$devpath")
      echo "  $dev : $sched"
  done

  echo "✅ 儲存系統優化作業完成！"
}

# 功能 8：設定時區+關閉 IPv6
set_timezone_and_network() {
  echo "🔍 目前的時區設定為：$(timedatectl show --property=Timezone --value)"
  echo "設定時區為 Asia/Taipei..."
  timedatectl set-timezone Asia/Taipei
  echo "完成時區設定。"
  echo ""
  # 關閉 IPv6
  GRUB_FILE="/etc/default/grub"
  echo "🔧 關閉 IPv6 中..."
  if grep -q '^GRUB_CMDLINE_LINUX=' "$GRUB_FILE"; then
      sed -i 's/^GRUB_CMDLINE_LINUX="/GRUB_CMDLINE_LINUX="ipv6.disable=1 /' "$GRUB_FILE"
  else
      echo 'GRUB_CMDLINE_LINUX="ipv6.disable=1"' >> "$GRUB_FILE"
  fi

  echo "✅ 已將 'ipv6.disable=1' 寫入 GRUB 設定。"

  echo "🚀 套用 GRUB 設定..."
  update-grub

  echo ""
  read -p "⚠️ 要立即重新啟動以套用設定嗎？(y/N): " confirm
  if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
      echo "🔁 即將重啟系統..."
      reboot
  else
      echo "📝 請稍後自行執行 reboot 或下次開機後 IPv6 即會停用。"
  fi
  echo "✅ IPv6 關閉完成。"
}

# 功能9 :修改hosts與hostname
set_hostname_and_hosts() {
  echo "🔧 當前主機名稱為：$(hostnamectl --static)"
  read -p "請輸入新的主機名稱（僅限英文、數字與 dash）: " NEW_HOSTNAME

  # 清理與合法性檢查
  NEW_HOSTNAME=$(echo "$NEW_HOSTNAME" | xargs)
  if [[ -z "$NEW_HOSTNAME" || ! "$NEW_HOSTNAME" =~ ^[a-zA-Z0-9-]+$ ]]; then
    echo "❌ 無效的主機名稱，請僅使用 a-z、A-Z、0-9、-"
    return 1
  fi

  OLD_HOSTNAME=$(hostnamectl --static)

  echo "📝 設定新主機名稱為：$NEW_HOSTNAME"
  sudo hostnamectl set-hostname "$NEW_HOSTNAME"

  echo "🧹 更新 /etc/hosts 中的主機對應..."

  # 備份原本 hosts
  sudo cp /etc/hosts /etc/hosts.bak.$(date +%F-%H%M%S)

  # 刪除所有 127.0.1.1 對應行（避免重複）
  sudo sed -i '/^127\.0\.1\.1/d' /etc/hosts

  # 插入新對應在 127.0.0.1 之後
  sudo awk -v newhost="$NEW_HOSTNAME" '
    /^127\.0\.0\.1/ {
      print
      print "127.0.1.1\t" newhost
      next
    }
    { print }
  ' /etc/hosts | sudo tee /etc/hosts.tmp > /dev/null && sudo mv /etc/hosts.tmp /etc/hosts

  echo "✅ 主機名稱與 hosts 更新完成"
  echo ""
  echo "🖥️ 當前主機名稱：$(hostname)"
  echo "📄 /etc/hosts 最後幾行如下："
  tail -n 6 /etc/hosts
}

# 功能 10：安裝proxmox qemu guest agent
install_qemu_guest_agent() {
  echo "📦 安裝 QEMU Guest Agent"

  if ! command -v qemu-ga &>/dev/null; then
    sudo apt update
    sudo apt install -y qemu-guest-agent
    echo "✅ QEMU Guest Agent 已安裝完成"
  else
    echo "✔ 已安裝 QEMU Guest Agent"
  fi

  echo "🔧 啟用並啟動服務..."
  sudo systemctl enable --now qemu-guest-agent

  echo "✅ 狀態如下："
  systemctl status qemu-guest-agent --no-pager
}

# 主選單
while true; do
    clear
    get_firewall_status
    echo "==== 運維 Deploy 工具 ===="
    echo -e "防火牆狀態：$FIREWALL_STATUS\n"
    echo "1. 設定靜態 IP（自動網卡/Gateway/IP 檢查）"
    echo "2. 防火牆設定（執行 firewall_toolkit）"
    echo "3. 安裝 Docker + Docker Compose"
    echo "4. SSH 免密登入設定"
    echo "5. 系統垃圾清理 + 排程設定"
    echo "6. 效能優化（swappiness/ZRAM/CPU/BBR）"
    echo "7. 儲存系統優化（TRIM + I/O Scheduler）"
    echo "8. 設定時區+關閉 IPv6"
    echo "9. 修改主機名稱與 hosts"
    echo "10. 安裝 Proxmox QEMU Guest Agent"
    echo "0. 離開"
    echo "=========================="
    read -p "請選擇操作項目: " choice

    case $choice in
        1) set_ip; read -p "按 Enter 鍵返回主選單..." ;;
        2) firewall_toolkit; read -p "按 Enter 鍵返回主選單..." ;;
        3) docker_setup_and_install; read -p "按 Enter 鍵返回主選單..." ;;
        4) setup_ssh_key_inline; read -p "按 Enter 鍵返回主選單..." ;;
        5) clean_system; read -p "按 Enter 鍵返回主選單..." ;;
        6) system_optimize; read -p "按 Enter 鍵返回主選單..." ;;
        7) optimize_storage; read -p "按 Enter 鍵返回主選單..." ;;
        8) set_timezone_and_network; read -p "按 Enter 鍵返回主選單..." ;;
        9) set_hostname_and_hosts; read -p "按 Enter 鍵返回主選單..." ;;
        10) install_qemu_guest_agent; read -p "按 Enter 鍵返回主選單..." ;;
        0) echo "離開腳本。"; break ;;
        *) echo "無效選項，請重新輸入。"; sleep 2 ;;
    esac
done