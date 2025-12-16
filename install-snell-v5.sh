#!/usr/bin/env bash
set -e

# =================================================
#  Snell Server v5.0.1 - Minimal Installer
#  - Debian / Ubuntu
#  - One-purpose server friendly
#  - No system upgrade, no reboot
# =================================================

VERSION="v5.0.1"
URL="https://dl.nssurge.com/snell/snell-server-${VERSION}-linux-amd64.zip"

BIN="/usr/local/bin/snell-server"
CONF_DIR="/etc/snell"
CONF_FILE="${CONF_DIR}/snell-server.conf"
SERVICE="/etc/systemd/system/snell.service"

echo "== Snell v5.0.1 minimal installer =="

# -------------------------------------------------
echo "[1/6] Install dependencies"
apt update
apt install -y curl unzip wget

# -------------------------------------------------
echo "[2/6] Download snell-server ${VERSION}"
cd /tmp
rm -f snell.zip snell-server
wget -O snell.zip "${URL}"
unzip snell.zip
chmod +x snell-server
mv snell-server /usr/local/bin/

# -------------------------------------------------
echo "[3/6] Generate config via wizard"
mkdir -p "${CONF_DIR}"
snell-server --wizard -c "${CONF_FILE}"

# -------------------------------------------------
echo "[4/6] Create systemd service"
cat > "${SERVICE}" <<EOF
[Unit]
Description=Snell Server
After=network.target

[Service]
Type=simple
ExecStart=${BIN} -c ${CONF_FILE}
Restart=always
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable snell
systemctl restart snell

# -------------------------------------------------
echo "[5/6] Write Snell info to /etc/motd"

SERVER_IP=$(curl -s --connect-timeout 2 https://checkip.amazonaws.com || hostname -I | awk '{print $1}')
PORT=$(grep -E '^\s*listen' "${CONF_FILE}" | awk -F':' '{print $NF}')
PSK=$(grep -E '^\s*psk' "${CONF_FILE}" | awk -F'=' '{print $2}' | tr -d ' ')

cat > /etc/motd <<EOF
=================================================
                SNELL SERVER INFO
-------------------------------------------------
 Server IP : ${SERVER_IP}
 Port      : ${PORT}
 PSK       : ${PSK}
 Version   : ${VERSION}
-------------------------------------------------
 TCP & UDP port ${PORT} should be open.
=================================================
EOF

# -------------------------------------------------
echo "[6/6] Done"
echo
systemctl status snell --no-pager
echo
echo "Installation complete."
echo "Snell info will be shown on every SSH login."
