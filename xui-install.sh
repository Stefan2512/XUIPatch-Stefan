#!/bin/bash

# ==============================================================================
# Script de instalare automată pentru XUI pe Ubuntu 22.04 (Jammy Jellyfish)
# Optimizat pentru claritate și robustețe.
# ==============================================================================

# Oprește scriptul dacă o comandă eșuează
set -e

# --- Variabile de configurare ---
XUI_ZIP_PATH="/tmp/XUI_install.zip"
XUI_DOWNLOAD_URL_PRIMARY="https://github.com/Stefan2512/XUIPatch-Stefan/releases/download/v1/XUI_1.5.12.zip"
XUI_DOWNLOAD_URL_FALLBACK="http://iptvmediapro.ro/appsdownload/XUI_1.5.12.zip"
LICENSE_URL="https://github.com/Stefan2512/XUIPatch-Stefan/raw/main/xui_license.tar.gz"
PATCH_URL="https://github.com/Stefan2512/XUIPatch-Stefan/raw/main/patch.sh"


# --- Funcții Helper ---

# Afișează un mesaj informativ
log_info() {
    echo "🔵 [INFO] $1"
}

# Afișează un mesaj de succes
log_success() {
    echo "✅ [SUCCESS] $1"
}

# Afișează un mesaj de eroare și iese din script
log_error() {
    echo "🔴 [ERROR] $1" >&2
    exit 1
}

# Verifică dacă scriptul este rulat ca root
check_root() {
    if [[ "$EUID" -ne 0 ]]; then
        log_error "Acest script trebuie rulat cu privilegii de root (sudo)."
    fi
}

# --- Funcții Principale ---

# 1. Pregătirea sistemului și instalarea dependențelor
prepare_system() {
    log_info "Pregătirea sistemului... Se actualizează pachetele și se instalează dependențele."
    apt --fix-broken install -y > /dev/null 2>&1
    apt update > /dev/null 2>&1
    apt upgrade -y > /dev/null 2>&1
    apt install -y software-properties-common dirmngr wget unzip zip curl gnupg2 ca-certificates mariadb-server mariadb-client > /dev/null 2>&1
    log_success "Sistemul este pregătit."
}


# 2. Descărcarea și instalarea panoului XUI
install_xui_panel() {
    log_info "Se descarcă panoul XUI..."
    
    # Încearcă să descarci cu wget, adăugând un User-Agent pentru a evita erori
    if ! wget --header="User-Agent: Mozilla/5.0" -O "$XUI_ZIP_PATH" "$XUI_DOWNLOAD_URL_PRIMARY"; then
        log_info "Prima sursă a eșuat. Se încearcă descărcarea cu curl de la sursa de rezervă..."
        # Dacă wget eșuează, încearcă cu curl
        if ! curl -L -A "Mozilla/5.0" -o "$XUI_ZIP_PATH" "$XUI_DOWNLOAD_URL_FALLBACK"; then
            log_error "Descărcarea panoului XUI a eșuat de la ambele surse. Verifică URL-urile și conexiunea la internet."
        fi
    fi
    
    log_success "Panoul XUI a fost descărcat."
    
    log_info "Se instalează panoul XUI..."
    cd /tmp
    unzip -o "$XUI_ZIP_PATH"
    chmod +x ./install
    ./install
    
    # Curățenie
    rm "$XUI_ZIP_PATH"
    log_success "Panoul XUI a fost instalat."
}

# 3. Instalarea licenței și aplicarea patch-ului
install_license_and_patch() {
    log_info "Se instalează licența..."
    cd /root
    # Descarcă și dezarhivează scriptul de licență
    wget -qO- "$LICENSE_URL" | tar -xzf -
    
    # Rulează scriptul de instalare al licenței
    # Acesta te va întreba de detalii dacă este necesar.
    bash ./install.sh
    
    # Curățenie
    rm ./install.sh
    log_success "Scriptul de licență a fost executat."
    
    log_info "Se aplică patch-ul final..."
    bash <(wget -qO- "$PATCH_URL")
    log_success "Patch-ul a fost aplicat."
}

# --- Execuția Scriptului ---
main() {
    clear
    echo "┌──────────────────────────────────────────┐"
    echo "│   Instalare automată XUI pentru Ubuntu 22  │"
    echo "└──────────────────────────────────────────┘"
    
    check_root
    prepare_system
    install_xui_panel
    install_license_and_patch
    
    echo
    log_success "Instalarea s-a finalizat cu succes!"
    echo "Poți accesa panoul folosind adresa IP a serverului."
}

# Punctul de intrare al scriptului
main
