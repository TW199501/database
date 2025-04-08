#!/bin/bash

set -e

echo "🔍 檢查 Docker 是否已安裝..."

if command -v docker &>/dev/null; then
    echo "✅ Docker 已安裝，版本：$(docker --version)"
else
    echo "🚧 Docker 未安裝，開始安裝中..."

    # 移除舊版本
    sudo apt-get remove -y docker docker-engine docker.io containerd runc || true

    # 安裝依賴
    sudo apt-get update -y
    sudo apt-get install -y \
        ca-certificates \
        curl \
        gnupg \
        lsb-release \
        apt-transport-https

    # 加入 Docker GPG 金鑰
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
        sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg

    # 新增 APT 套件來源
    echo \
      "deb [arch=$(dpkg --print-architecture) \
      signed-by=/etc/apt/keyrings/docker.gpg] \
      https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # 安裝 Docker + Compose Plugin
    sudo apt-get update -y
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # 啟用 Docker
    sudo systemctl enable --now docker
fi

# 確認 docker compose v2 CLI 可用
echo "🔍 檢查 docker compose..."
if docker compose version &>/dev/null; then
    echo "✅ docker compose 可用：$(docker compose version)"
else
    echo "❌ docker compose 無法使用，請確認安裝狀態"
    exit 1
fi

# 建立測試 docker-compose.yml
echo "📦 建立 docker-compose 測試檔..."
TEST_DIR=$(mktemp -d)
cat <<EOF > $TEST_DIR/docker-compose.yml
services:
  web:
    image: nginx:alpine
    container_name: test_nginx_compose
    ports:
      - "8080:80"
EOF

# 啟動容器測試
echo "🧪 啟動 docker compose 測試..."
cd $TEST_DIR
docker compose up -d

# 等待幾秒讓容器穩定
sleep 3

# 測試容器狀態
docker ps | grep test_nginx_compose && echo "🎉 測試成功：Nginx 已啟動"

# 清除測試容器與映像檔
echo "🧹 清除測試容器與映像檔..."
docker compose down
docker rmi nginx:alpine -f || true

# 刪除測試資料夾
rm -rf $TEST_DIR

echo "✅ Docker + Compose v2 安裝完成，測試成功，系統已清理乾淨！"
