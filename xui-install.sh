#!/bin/bash
echo "┌─────────────────────────────────────────────┐"
echo "│    Preparing for Xui - 1.5.12 Installation  │"
echo "│              Ubuntu 22.04 Fixed              │"
echo "└─────────────────────────────────────────────┘"
set -e

# 🛠️ Fix, update, install de bază
apt --fix-broken install -y
apt update && apt upgrade -y
apt install -y software-properties-common dirmngr wget unzip zip curl gnupg2 ca-certificates

# 📦 MariaDB repo & instalare pentru Ubuntu 22.04 (jammy)
curl -LsS https://mariadb.org/mariadb_release_signing_key.asc | gpg --dearmor | tee /usr/share/keyrings/mariadb-keyring.gpg > /dev/null

echo "deb [arch=amd64,arm64,ppc64el signed-by=/usr/share/keyrings/mariadb-keyring.gpg] http://mirror.lstn.net/mariadb/repo/10.6/ubuntu jammy main" > /etc/apt/sources.list.d/mariadb.list

apt update

apt-get install -y mariadb-server mariadb-client || {
    echo "Încercare cu versiune alternativă..."
    apt-get install -y mariadb-server-10.6 mariadb-client-10.6
}

# 📥 XUI download & instalare
echo "Descărcare XUI..."

# Add User-Agent to bypass 415 error
if ! wget --header="User-Agent: Mozilla/5.0" -O /tmp/XUI_1.5.12.zip "http://iptvmediapro.ro/appsdownload/XUI_1.5.12.zip"; then
    echo "Eroare la descărcarea XUI cu User-Agent, încearcă curl..."
    curl -L -A "Mozilla/5.0" -o /tmp/XUI_1.5.12.zip "http://iptvmediapro.ro/appsdownload/XUI_1.5.12.zip" || {
        echo "Nu s-a putut descărca XUI. Verifică URL-ul și conexiunea."
        exit 1
    }
fi

cd /tmp
unzip -o XUI_1.5.12.zip
chmod +x ./install
./install

# ⏱️ Mesaj licență
echo
echo "Testing new license:"
sleep 3

# 🔐 Instalare licență
cd /root
echo "Checking License key and update system"
wget -qO- https://github.com/Stefan2512/XUIPatch-Stefan/raw/main/xui_license.tar.gz | tar -xzf -
bash ./install.sh >/dev/null 2>&1

# 📝 Input utilizator
read -p "Enter Your license key: " license_key
echo "Checking the License Key"
read -p "Enter your email address: " email

# 🔧 Patch final
bash <(wget -qO- https://github.com/Stefan2512/XUIPatch-Stefan/raw/main/patch.sh)

echo "✅ Instalare completă pentru Ubuntu 22.04!"
