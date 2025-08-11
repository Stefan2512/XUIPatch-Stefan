#!/bin/bash
echo "┌─────────────────────────────────────────────┐"
echo "│    Preparing for Xui - 1.5.12 Installation  │"
echo "│              Ubuntu 22.04 Fixed              │"
echo "└─────────────────────────────────────────────┘"

set -e

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root (use sudo)" 
   exit 1
fi

# 🛠️ Fix, update, install basics
echo "Fixing broken packages and updating system..."
apt --fix-broken install -y
apt update && apt upgrade -y
apt install -y software-properties-common dirmngr wget unzip zip curl gnupg2 ca-certificates

# 📦 MariaDB repo & installation for Ubuntu 22.04 (jammy)
echo "Setting up MariaDB repository..."
curl -LsS https://mariadb.org/mariadb_release_signing_key.asc | gpg --dearmor | tee /usr/share/keyrings/mariadb-keyring.gpg > /dev/null
echo "deb [arch=amd64,arm64,ppc64el signed-by=/usr/share/keyrings/mariadb-keyring.gpg] http://mirror.lstn.net/mariadb/repo/10.6/ubuntu jammy main" > /etc/apt/sources.list.d/mariadb.list

echo "Installing MariaDB..."
apt update
if ! apt-get install -y mariadb-server mariadb-client; then
    echo "Trying alternative version..."
    apt-get install -y mariadb-server-10.6 mariadb-client-10.6
fi

# Start and enable MariaDB
systemctl start mariadb
systemctl enable mariadb

# 📥 XUI download & installation
echo "Downloading XUI..."
cd /tmp

# Clean up any existing files
rm -f XUI_1.5.12.zip
rm -rf XUI_1.5.12/

# Try multiple download sources
download_success=false

# Try first source with User-Agent
if wget --timeout=30 --tries=3 --header="User-Agent: Mozilla/5.0 (Linux; Ubuntu)" -O XUI_1.5.12.zip "https://mega.nz/file/Q75hBYBS#zeAjRwy6BbxQ-PXEXbDzZP8A8kihUiwJNa9OG6WFEjs" 2>/dev/null; then
    download_success=true
    echo "Downloaded from primary source"
elif curl -L --connect-timeout 30 --max-time 300 -A "Mozilla/5.0 (Linux; Ubuntu)" -o XUI_1.5.12.zip "http://iptvmediapro.ro/appsdownload/XUI_1.5.12.zip" 2>/dev/null; then
    download_success=true
    echo "Downloaded from backup source"
fi

if [ "$download_success" = false ]; then
    echo "❌ Failed to download XUI. Please check your internet connection and try again."
    exit 1
fi

# Verify the download
if [ ! -f "XUI_1.5.12.zip" ] || [ ! -s "XUI_1.5.12.zip" ]; then
    echo "❌ Downloaded file is empty or corrupted"
    exit 1
fi

echo "Extracting XUI..."
if ! unzip -o XUI_1.5.12.zip; then
    echo "❌ Failed to extract XUI archive"
    exit 1
fi

# Make install script executable and run it
if [ -f "./install" ]; then
    chmod +x ./install
    echo "Running XUI installer..."
    ./install
else
    echo "❌ Install script not found in archive"
    exit 1
fi

# ⏱️ License message
echo
echo "Testing new license..."
sleep 3

# 🔐 License installation
echo "Checking License key and updating system..."
cd /root

# Download and extract license files
if wget --timeout=30 -qO- https://github.com/Stefan2512/XUIPatch-Stefan/raw/main/xui_license.tar.gz | tar -xzf - 2>/dev/null; then
    if [ -f "./install.sh" ]; then
        echo "Installing license components..."
        bash ./install.sh >/dev/null 2>&1
    else
        echo "⚠️ License install script not found, continuing..."
    fi
else
    echo "⚠️ Could not download license files, continuing..."
fi

# 📝 User input with validation
while true; do
    read -p "Enter Your license key: " license_key
    if [ -n "$license_key" ]; then
        break
    else
        echo "License key cannot be empty. Please try again."
    fi
done

echo "Checking the License Key..."

while true; do
    read -p "Enter your email address: " email
    if [[ "$email" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
        break
    else
        echo "Please enter a valid email address."
    fi
done

# 🔧 Final patch
echo "Applying final patches..."
if ! bash <(wget --timeout=30 -qO- https://github.com/Stefan2512/XUIPatch-Stefan/raw/main/patch.sh 2>/dev/null); then
    echo "⚠️ Could not apply patches, but XUI should still work"
fi

# Clean up temporary files
cd /tmp
rm -f XUI_1.5.12.zip
rm -rf XUI_1.5.12/

echo "✅ Installation complete for Ubuntu 22.04!"
echo "📋 Next steps:"
echo "   1. Configure your firewall to allow necessary ports"
echo "   2. Set up MariaDB security (run: mysql_secure_installation)"
echo "   3. Access XUI through your web browser"
echo "   4. Check XUI logs if you encounter any issues"
