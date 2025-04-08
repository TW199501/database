#!/bin/bash

echo "🔐 SSH Key 自動設定工具多節點無密碼"
echo "--------------------------------------------"

# 1. 建立 SSH Key（如尚未存在）
if [ ! -f "$HOME/.ssh/id_rsa" ]; then
  echo "🚧 未偵測到 SSH Key，開始建立..."
  ssh-keygen -t rsa -b 4096 -N "" -f "$HOME/.ssh/id_rsa"
  echo "✅ SSH Key 建立完成"
else
  echo "✅ 已偵測 SSH Key：$HOME/.ssh/id_rsa"
fi

# 2. 讓使用者輸入 IP 列表
read -p "請輸入要穿透的目標 IP（用空格分隔，如 192.168.1.10 192.168.1.11）: " -a IP_LIST

for ip in "${IP_LIST[@]}"; do
  echo "🚀 傳送公鑰至 $ip"

  # 檢查是否可連線
  if ping -c 1 -W 1 "$ip" &> /dev/null; then
    # 提示輸入對方帳號（通常為 ubuntu 或 root）
    read -p "  請輸入 $ip 的登入帳號（例如 ubuntu 或 root）: " USER

    # 傳送公鑰
    ssh-copy-id "$USER@$ip"

    if [ $? -eq 0 ]; then
      echo "✅ $ip 已完成 SSH 無密碼登入設定"
    else
      echo "❌ 無法設定 $ip，請檢查密碼與網路連線"
    fi
  else
    echo "❌ 無法連線至 $ip，跳過..."
  fi
done

echo "🎉 所有 IP 設定流程結束，可用 ssh <user>@<ip> 測試免密登入"
