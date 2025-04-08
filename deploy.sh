#!/bin/bash

# 功能 1：設定時區 + IP + 關閉 IPv6
set_timezone_and_network() {
    echo "設定時區為 Asia/Taipei..."
    timedatectl set-timezone Asia/Taipei
    echo "完成時區設定。"

    echo ""
    echo "開始設定 IP..."
    read -p "請輸入網卡名稱（例如：eth0）: " IFACE
    if [[ -z "$IFACE" ]]; then
        echo "網卡名稱不能為空！"
        return 1
    fi
    read -p "請輸入靜態 IP（例如：192.168.1.100/24）: " IPADDR
    read -p "請輸入閘道（Gateway，例如：192.168.1.1）: " GATEWAY
    read -p "請輸入 DNS（例如：8.8.8.8）: " DNS

    echo "建立 netplan 設定檔..."
    cat <<EOF > /etc/netplan/01-deploy.yaml
network:
  version: 2
  ethernets:
    $IFACE:
      dhcp4: no
      addresses: [$IPADDR]
      gateway4: $GATEWAY
      nameservers:
        addresses: [$DNS]
EOF

    echo "套用 netplan 設定..."
    netplan apply
    if [ $? -ne 0 ]; then
        echo "⚠️ IP 設定失敗，請檢查網卡名稱或其他設定。"
        return 1
    fi
    echo "IP 設定完成。"

    echo ""
    echo "關閉 IPv6..."
    if ! grep -q "disable_ipv6" /etc/sysctl.conf; then
        cat <<EOF >> /etc/sysctl.conf

# 關閉 IPv6
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
EOF
    fi

    sysctl -p
    echo "IPv6 已關閉。"
}

# 功能 2：防火牆設定功能
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

    # ---------- 功能函數 ----------
    show_status() {
        print_title "防火牆狀態"
        if [[ "$FIREWALL" == "firewalld" ]]; then
            sudo firewall-cmd --state || print_warning "Firewalld 尚未啟用"
        else
            sudo ufw status verbose
        fi
    }

  firewall_is_active() {
    if [[ "$FIREWALL" == "firewalld" ]]; then
      sudo firewall-cmd --state &>/dev/null
    else
      [[ $(sudo ufw status | grep -i inactive) == "" ]]
    fi
  }

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

# ---------- 功能實作 ----------
function show_status() {
  print_title "防火牆狀態"
  if [[ "$FIREWALL" == "firewalld" ]]; then
    sudo firewall-cmd --state || print_warning "Firewalld 尚未啟用"
  else
    sudo ufw status verbose
  fi
}

function enable_firewall() {
  print_title "啟用防火牆"
  if [[ "$FIREWALL" == "firewalld" ]]; then
    sudo systemctl enable --now firewalld
  else
    sudo ufw enable
  fi
  print_success "防火牆已啟用"
}

function disable_firewall() {
  print_title "關閉防火牆"
  if [[ "$FIREWALL" == "firewalld" ]]; then
    sudo systemctl stop firewalld
    sudo systemctl disable firewalld
  else
    sudo ufw disable
  fi
  print_success "防火牆已關閉"
}

function show_open_ports() {
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

function open_ports() {
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
}

function close_ports() {
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
}

function reload_firewall() {
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

function block_internal_ip() {
  print_title "封鎖內網某 IP 存取本機"
  read -p "請輸入內網 IP（如 192.168.1.100）: " ip
  sudo firewall-cmd --permanent --add-rich-rule="rule family=ipv4 source address=$ip drop"
  print_success "已封鎖 $ip 存取本機"
}

function manage_directional_rule() {
  print_title "管理 ingress / egress 方向封鎖"
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
  }
    # ---------- 主流程 ----------
    detect_firewall
    while true; do
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

# 主選單
while true; do
    clear
    get_firewall_status
    echo "==== 運維 Deploy 工具 ===="
    echo -e "防火牆狀態：$FIREWALL_STATUS\n"
    echo "1. 設定時區 + IP + 關閉 IPv6"
    echo "2. 防火牆設定（執行 firewall_toolkit）"
    echo "3. 安裝 Docker + Docker Compose"
    echo "4. SSH 免密登入設定"
    echo "5. 系統垃圾清理 + 排程設定"
    echo "6. 效能優化（swappiness/ZRAM/CPU/BBR）"
    echo "7. 儲存系統優化（TRIM + I/O Scheduler）"
    echo "0. 離開"
    echo "=========================="
    read -p "請選擇操作項目: " choice

    case $choice in
        1) set_timezone_and_network; read -p "按 Enter 鍵返回主選單..." ;;
        2) firewall_toolkit; read -p "按 Enter 鍵返回主選單..." ;;
        3) docker_setup_and_install; read -p "按 Enter 鍵返回主選單..." ;;
        4) setup_ssh_key_inline; read -p "按 Enter 鍵返回主選單..." ;;
        5) clean_system; read -p "按 Enter 鍵返回主選單..." ;;
        6) system_optimize; read -p "按 Enter 鍵返回主選單..." ;;
        7) optimize_storage; read -p "按 Enter 鍵返回主選單..." ;;
        0) echo "離開腳本。"; break ;;
        *) echo "無效選項，請重新輸入。"; sleep 2 ;;
    esac
done