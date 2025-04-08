#!/bin/bash

ROLE=$1
SQLCMD="/opt/mssql-tools/bin/sqlcmd"
SA_USER="SA"
SA_PASS="$StrongP@ssw0rd"
CERT_DIR="/var/opt/mssql/hadr_cert"
CERT_NAME="HadrCertificate"
CERT_FILE="$CERT_DIR/hadr_primary_cert.cer"
PASSWORD="Your\$StrongP@ssw0rd!"

install_docker() {
  if ! command -v docker &> /dev/null; then
    echo "🚧 Docker 未安裝，開始安裝中..."
    sudo apt-get update
    sudo apt-get install -y ca-certificates curl gnupg lsb-release
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
      sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    echo "✅ Docker 安裝完成"
  else
    echo "✅ Docker 已安裝"
  fi
}

install_docker
mkdir -p "$CERT_DIR"

if [ "$ROLE" == "PRIMARY" ]; then
    echo "🔧 設定 PRIMARY 節點..."

    $SQLCMD -S localhost -U $SA_USER -P $SA_PASS -Q "
        CREATE MASTER KEY ENCRYPTION BY PASSWORD = '$PASSWORD';
        CREATE CERTIFICATE $CERT_NAME WITH SUBJECT = 'HADR Endpoint Authentication';
        BACKUP CERTIFICATE $CERT_NAME TO FILE = '$CERT_FILE';
        CREATE ENDPOINT [Hadr_endpoint]
        STATE = STARTED
        AS TCP (LISTENER_PORT = 5022)
        FOR DATA_MIRRORING (
            ROLE = ALL,
            AUTHENTICATION = CERTIFICATE $CERT_NAME,
            ENCRYPTION = REQUIRED ALGORITHM AES
        );
    "

    if [ -f "$CERT_FILE" ]; then
        echo "✅ 憑證建立成功，請手動將以下檔案複製到其他節點："
        echo "   $CERT_FILE"
    else
        echo "❌ 憑證建立失敗：$CERT_FILE 不存在"
        exit 1
    fi

elif [ "$ROLE" == "SECONDARY" ]; then
    echo "🔧 設定 SECONDARY 節點..."

    if [ ! -f "$CERT_FILE" ]; then
        echo "❌ 憑證不存在，請確認你已從 PRIMARY 手動複製檔案至：$CERT_FILE"
        exit 1
    fi

    $SQLCMD -S localhost -U $SA_USER -P $SA_PASS -Q "
        CREATE MASTER KEY ENCRYPTION BY PASSWORD = '$PASSWORD';
        CREATE CERTIFICATE $CERT_NAME FROM FILE = '$CERT_FILE';
        CREATE ENDPOINT [Hadr_endpoint]
        STATE = STARTED
        AS TCP (LISTENER_PORT = 5022)
        FOR DATA_MIRRORING (
            ROLE = ALL,
            AUTHENTICATION = CERTIFICATE $CERT_NAME,
            ENCRYPTION = REQUIRED ALGORITHM AES
        );
    "

else
    echo "❗ 用法：./setup-hadr.sh PRIMARY 或 ./setup-hadr.sh SECONDARY"
    exit 1
fi

echo "🎉 節點設定完成：$ROLE"
