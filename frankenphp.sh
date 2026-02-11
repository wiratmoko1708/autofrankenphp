#!/bin/bash

# ==========================================
# FrankenPHP Auto Install Script (Perfected)
# Supports: Debian 12 / Ubuntu 20.04+
# ==========================================

# Warna untuk output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ==========================================
# Helper Functions
# ==========================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "Script ini harus dijalankan sebagai root (sudo)."
        exit 1
    fi
}

check_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
    else
        log_error "Sistem operasi tidak didukung atau tidak terdeteksi."
        exit 1
    fi
    
    log_info "Terdeteksi OS: $OS $VER"
}

# ==========================================
# 1. Update Sistem
# ==========================================
step_update_system() {
    log_info "1. Update Sistem..."
    apt update && apt upgrade -y
    log_success "Sistem berhasil diupdate."
}

# ==========================================
# 2. Instalasi Paket Dasar
# ==========================================
step_install_basics() {
    log_info "2. Instalasi Paket Dasar..."
    apt install -y apt-transport-https ca-certificates \
        certbot curl cron git gnupg lsb-release \
        software-properties-common supervisor \
        unzip wget
    # Nginx dan python3-certbot-nginx akan diinstall di langkah Nginx jika dipilih
    log_success "Paket dasar terinstall."
}

# ==========================================
# 3 & 4. Konfigurasi Firewall
# ==========================================
step_setup_firewall() {
    log_info "3. Konfigurasi Firewall (UFW)..."
    apt install -y ufw
    
    ufw allow ssh
    ufw allow http
    ufw allow https
    ufw allow 5432 # PostgreSQL
    ufw allow 3306 # MySQL (Optional)
    ufw allow 7844 # Custom Port (sesuai request)
    
    # Enable UFW non-interactive
    echo "y" | ufw enable
    
    log_info "4. Status Firewall:"
    ufw status
}

# ==========================================
# 5. Instalasi PHP
# ==========================================
step_install_php() {
    log_info "5. Instalasi PHP..."
    echo "Pilih versi PHP yang ingin diinstall:"
    echo "1) PHP 8.4"
    echo "2) PHP 8.5 (Jika tersedia, atau fallback ke latest)"
    read -p "Masukkan pilihan (1/2): " php_choice

    # Setup Repo
    if [[ "$ID" == "ubuntu" ]]; then
        add-apt-repository -y ppa:ondrej/php
    elif [[ "$ID" == "debian" ]]; then
        curl -sSLo /usr/share/keyrings/deb.sury.org-php.gpg https://packages.sury.org/php/apt.gpg
        sh -c 'echo "deb [signed-by=/usr/share/keyrings/deb.sury.org-php.gpg] https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list'
        apt update
    fi

    case $php_choice in
        1) PHP_VER="8.4" ;;
        2) PHP_VER="8.5" ;; # Note: 8.5 might not be stable yet in all repos
        *) PHP_VER="8.4" ;;
    esac

    # Cek ketersediaan paket, jika 8.5 belum ada fallback ke 8.4
    if ! apt-cache show php$PHP_VER > /dev/null 2>&1; then
        log_warning "PHP $PHP_VER tidak ditemukan di repo. Menggunakan PHP 8.3/8.4 sebagai fallback."
        PHP_VER="8.4" 
        if ! apt-cache show php$PHP_VER > /dev/null 2>&1; then
             PHP_VER="8.3"
        fi
    fi

    log_info "Menginstall PHP $PHP_VER..."
    apt install -y php$PHP_VER php$PHP_VER-cli php$PHP_VER-common php$PHP_VER-fpm \
        php$PHP_VER-mysql php$PHP_VER-pgsql php$PHP_VER-zip php$PHP_VER-gd \
        php$PHP_VER-mbstring php$PHP_VER-curl php$PHP_VER-xml php$PHP_VER-bcmath
        
    log_success "PHP $PHP_VER berhasil diinstall."
}

# ==========================================
# 6. Instalasi Composer
# ==========================================
step_install_composer() {
    log_info "6. Instalasi Composer..."
    curl -sS https://getcomposer.org/installer | php
    mv composer.phar /usr/local/bin/composer
    chmod +x /usr/local/bin/composer
    log_success "Composer terinstall: $(composer --version)"
}

# ==========================================
# 7. Instalasi Node.js & NPM
# ==========================================
step_install_node() {
    log_info "7. Instalasi Node.js & NPM..."
    curl -fsSL https://deb.nodesource.com/setup_current.x | bash -
    apt install -y nodejs
    log_success "Node.js $(node -v) dan npm $(npm -v) terinstall."
}

# ==========================================
# 8. Instalasi Database
# ==========================================
step_install_db() {
    log_info "8. Instalasi Database..."
    echo "Pilih Database:"
    echo "1) PostgreSQL"
    echo "2) MySQL / MariaDB"
    read -p "Masukkan pilihan (1/2): " db_choice

    if [[ "$db_choice" == "1" ]]; then
        apt install -y postgresql postgresql-contrib
        systemctl enable postgresql
        systemctl start postgresql
        log_success "PostgreSQL terinstall."
    else
        apt install -y mariadb-server
        systemctl enable mariadb
        systemctl start mariadb
        log_success "MariaDB terinstall."
    fi
}

# ==========================================
# 9. Instalasi FrankenPHP
# ==========================================
step_install_frankenphp() {
    log_info "9. Instalasi FrankenPHP..."
    
    # Download binary (Fixed version v1.1.0 x86_64)
    # Menggunakan versi spesifik untuk menghindari masalah "latest" redirect
    curl -L https://github.com/dunglas/frankenphp/releases/download/v1.1.0/frankenphp-linux-x86_64 -o /usr/local/bin/frankenphp
    chmod +x /usr/local/bin/frankenphp
    
    log_success "FrankenPHP binary terinstall di /usr/local/bin/frankenphp"
}

# ==========================================
# Konfigurasi Domain & Virtual Host Logic
# ==========================================
step_configure_services() {
    echo ""
    log_info "Konfigurasi Domain dan Web Server"
    read -p "Masukkan Nama Domain (contoh: example.com): " DOMAIN_NAME
    
    if [[ -z "$DOMAIN_NAME" ]]; then
        log_error "Domain tidak boleh kosong."
        exit 1
    fi

    # Menentukan Mode Operasi
    echo "Pilih Mode Web Server:"
    echo "1) Nginx sebagai Reverse Proxy ke FrankenPHP (Recommended untuk setup hybrid)"
    echo "2) FrankenPHP Standalone (High Performance, Nginx tidak digunakan untuk port 80/443)"
    read -p "Pilihan (1/2): " WEB_MODE

    # Root directory aplikasi
    APP_DIR="/var/www/$DOMAIN_NAME"
    mkdir -p "$APP_DIR/public"
    
    # Buat file index.php test jika kosong
    if [ ! -f "$APP_DIR/public/index.php" ]; then
        echo "<?php echo 'Hello from FrankenPHP on $DOMAIN_NAME'; ?>" > "$APP_DIR/public/index.php"
        chown -R www-data:www-data "$APP_DIR"
    fi

    # 13. Konfigurasi Supervisor (Untuk menjalankan FrankenPHP)
    log_info "13. Konfigurasi Supervisor untuk FrankenPHP..."
    
    if [[ "$WEB_MODE" == "1" ]]; then
        # Mode Proxy: FrankenPHP jalan di port lokal (misal 9000 atau 8000)
        FRANKEN_PORT="9000"
        # Command: frankenphp php-server --listen :9000
        cat > /etc/supervisor/conf.d/frankenphp-$DOMAIN_NAME.conf <<EOF
[program:frankenphp-$DOMAIN_NAME]
command=/usr/local/bin/frankenphp php-server --listen :$FRANKEN_PORT --root $APP_DIR/public
autostart=true
autorestart=true
user=www-data
redirect_stderr=true
stdout_logfile=/var/log/frankenphp-$DOMAIN_NAME.log
EOF
    else
        # Mode Standalone: FrankenPHP handle 80/443 dan Auto SSL
        # Perlu allow port privilege untuk user non-root atau jalan sebagai root
        # Disini kita jalan sebagai root via supervisor atau setcap
        setcap CAP_NET_BIND_SERVICE=+eip /usr/local/bin/frankenphp
        
        cat > /etc/supervisor/conf.d/frankenphp-$DOMAIN_NAME.conf <<EOF
[program:frankenphp-$DOMAIN_NAME]
command=/usr/local/bin/frankenphp php-server --domain $DOMAIN_NAME --root $APP_DIR/public
autostart=true
autorestart=true
user=root
redirect_stderr=true
stdout_logfile=/var/log/frankenphp-$DOMAIN_NAME.log
environment=CADDY_GLOBAL_OPTIONS="email admin@$DOMAIN_NAME"
EOF
    fi

    supervisorctl reread
    supervisorctl update
    log_success "Supervisor dikonfigurasi dan direstart (Langkah 14)."

    # Logic Nginx / Certbot / PHP-FPM
    if [[ "$WEB_MODE" == "1" ]]; then
        # 11. Konfigurasi Nginx
        log_info "11. Konfigurasi Nginx (Reverse Proxy)..."
        apt install -y nginx python3-certbot-nginx
        
        cat > /etc/nginx/sites-available/$DOMAIN_NAME <<EOF
server {
    listen 80;
    server_name $DOMAIN_NAME;

    location / {
        proxy_pass http://127.0.0.1:$FRANKEN_PORT;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF
        ln -sf /etc/nginx/sites-available/$DOMAIN_NAME /etc/nginx/sites-enabled/
        rm -f /etc/nginx/sites-enabled/default
        
        # 12. Restart Nginx
        log_info "12. Restart Nginx..."
        nginx -t && systemctl restart nginx
        
        # 10. Instalasi Certbot & SSL
        log_info "10. Setup SSL dengan Certbot..."
        certbot --nginx -d $DOMAIN_NAME --non-interactive --agree-tos -m admin@$DOMAIN_NAME
        
    else
        log_info "Mode Standalone: Nginx tidak diperlukan sebagai frontend."
        log_info "SSL ditangani otomatis oleh FrankenPHP."
        # Stop nginx jika jalan agar tidak konflik port 80
        systemctl stop nginx 2>/dev/null || true
        systemctl disable nginx 2>/dev/null || true
    fi

    # 15. Konfigurasi PHP-FPM
    # Meskipun FrankenPHP tidak butuh PHP-FPM, user meminta konfigurasinya.
    # Kita akan konfigurasi standard pool tapi mungkin tidak digunakan oleh FrankenPHP.
    log_info "15. Konfigurasi PHP-FPM (Opsional/Fallback)..."
    PHP_V_NUM=${PHP_VER}
    FPM_CONF="/etc/php/$PHP_V_NUM/fpm/pool.d/$DOMAIN_NAME.conf"
    
    if [ -d "/etc/php/$PHP_V_NUM/fpm/pool.d/" ]; then
        cp /etc/php/$PHP_V_NUM/fpm/pool.d/www.conf $FPM_CONF
        sed -i "s/\[www\]/\[$DOMAIN_NAME\]/g" $FPM_CONF
        # Ganti sock file agar unik
        sed -i "s|listen = /run/php/php$PHP_V_NUM-fpm.sock|listen = /run/php/php$PHP_V_NUM-fpm-$DOMAIN_NAME.sock|g" $FPM_CONF
        
        # 16. Restart PHP-FPM
        log_info "16. Restart PHP-FPM..."
        systemctl restart php$PHP_V_NUM-fpm
    else
        log_warning "Direktori PHP-FPM tidak ditemukan, melewati konfigurasi FPM."
    fi
}

# ==========================================
# 17. Tampilkan Status
# ==========================================
step_show_status() {
    echo ""
    log_info "17. Status Instalasi:"
    echo "-----------------------------------"
    echo "FrankenPHP: $(/usr/local/bin/frankenphp --version | head -n 1)"
    echo "PHP CLI:    $(php -v | head -n 1)"
    echo "Composer:   $(composer --version | awk '{print $3}')"
    echo "Node.js:    $(node -v)"
    echo "NPM:        $(npm -v)"
    echo "Nginx:      $(nginx -v 2>&1)"
    echo "Supervisor: $(supervisord -v)"
    # Cek DB
    if systemctl is-active --quiet postgresql; then
        echo "PostgreSQL: Active"
    elif systemctl is-active --quiet mariadb; then
        echo "MariaDB: Active"
    fi
    echo "-----------------------------------"
    log_success "18. Selesai! Website Anda seharusnya sudah bisa diakses di https://$DOMAIN_NAME"
}

# ==========================================
# Main Execution
# ==========================================
check_root
check_os

step_update_system
step_install_basics
step_setup_firewall
step_install_php
step_install_composer
step_install_node
step_install_db
step_install_frankenphp
step_configure_services
step_show_status

exit 0
