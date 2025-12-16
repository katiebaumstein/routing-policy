#!/usr/bin/env bash
set -e

VERSION="v5.0.1"
URL="https://dl.nssurge.com/snell/snell-server-${VERSION}-linux-amd64.zip"

BIN="/usr/local/bin/snell-server"
CONF_DIR="/etc/snell"
CONF_FILE="${CONF_DIR}/snell-server.conf"
SERVICE="/etc/systemd/system/snell.service"

echo "== Installing Snell Server ${VERSION} =="

# -------------------------------------------------
# 1. Dependencies (quiet)
# -------------------------------------------------
apt update -qq
apt install -y -qq curl unzip wget

# -------------------------------------------------
# 2. Download binary
# -------------------------------------------------
cd /tmp
rm -f snell.zip snell-server
wget -q -O snell.zip "${URL}"
unzip -q snell.zip
chmod +x snell-server
mv snell-server /usr/local/bin/

# -------------------------------------------------
# 3. Generate config (wizard, SILENT)
# -------------------------------------------------
mkdir -p "${CONF_DIR}"
if [ ! -f "${CONF_FILE}" ]; then
  yes | snell-server --wizard -c "${CONF_FILE}" >/dev/null 2>&1
fi

# -------------------------------------------------
# 4. systemd service (ALWAYS create)
# -------------------------------------------------
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
systemctl enable snell >/dev/null 2>&1
systemctl restart snell

# -------------------------------------------------
# 5. Write clean MOTD (LOGIN DISPLAY)
# -------------------------------------------------
SERVER_IP=$(curl -s --connect-timeout 2 https://checkip.amazonaws.com || hostname -I | awk '{print $1}')
PORT=$(grep -E '^\s*listen' "${CONF_FILE}" | awk -F':' '{print $NF}')
PSK=$(grep -E '^\s*psk' "${CONF_FILE}" | awk -F'=' '{print $2}' | tr -d ' ')

cat > /etc/motd <<EOF
+===========================================+
|           SNELL SERVER INFO               |
+-------------------------------------------+
| Server IP : ${SERVER_IP}
| Port      : ${PORT}
| PSK       : ${PSK}
| Version   : ${VERSION}
+-------------------------------------------+
| These will display every time you SSH in  |
+===========================================+
EOF

echo
cat /etc/motd

echo
echo "Snell installation completed successfully."
