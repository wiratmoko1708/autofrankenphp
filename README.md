# FrankenPHP Auto Install Script

Script otomatis untuk menginstall dan mengkonfigurasi **FrankenPHP** di server Debian 12 atau Ubuntu 20.04+. Script ini menangani instalasi dependensi, database, SSL, dan konfigurasi server dalam satu kali jalan.

## Preview Instalasi

Berikut adalah tampilan proses instalasi script:

1. **Konfigurasi Firewall & Pilihan PHP**  
   ![Konfigurasi Firewall](https://github.com/wiratmoko1708/autofrankenphp/blob/main/Screenshot%202026-02-12%20at%2000.10.31.png?raw=true)

2. **Instalasi Node.js & Pilihan Database**  
   ![Instalasi Node.js](https://github.com/wiratmoko1708/autofrankenphp/blob/main/Screenshot%202026-02-12%20at%2000.11.21.png?raw=true)

3. **Download FrankenPHP & Konfigurasi Domain**  
   ![Konfigurasi FrankenPHP](https://github.com/wiratmoko1708/autofrankenphp/blob/main/Screenshot%202026-02-12%20at%2000.12.32.png?raw=true)

## Fitur

*   **Sistem**: Auto Update & Upgrade.
*   **Dependensi**: Git, Curl, Unzip, Supervisor, dll.
*   **Firewall**: Konfigurasi UFW otomatis (SSH, HTTP, HTTPS, Port DB, Port FrankenPHP).
*   **PHP**: Pilihan versi PHP 8.4 atau 8.5 (Fallback aman).
*   **Database**: Pilihan PostgreSQL atau MariaDB/MySQL.
*   **Runtime**: Composer & Node.js + NPM terbaru.
*   **Web Server Mode**:
    *   **Mode 1 (Hybrid)**: Nginx (Reverse Proxy) -> FrankenPHP. Mendukung SSL via Certbot (Let's Encrypt).
    *   **Mode 2 (Standalone)**: FrankenPHP Native (Performance tinggi, Auto SSL Caddy).
*   **Process Manager**: Konfigurasi otomatis Supervisor untuk menjalankan FrankenPHP.

## Persyaratan Sistem

*   **OS**: Debian 12 (Bookworm) atau Ubuntu 20.04/22.04/24.04 LTS.
*   **User**: Root atau user dengan akses `sudo`.
*   **Domain**: Sebuah domain atau subdomain yang sudah diarahkan (A Record) ke IP server ini.

## Cara Penggunaan

Ikuti langkah-langkah berikut untuk menggunakan script ini di VPS atau server Anda.

### 1. Download Script

Jika Anda belum memiliki file `frankenphp.sh` di server, Anda bisa membuatnya atau mengunggahnya.

Atau jika Anda copy-paste manual:
```bash
nano frankenphp.sh
# Paste kode script ke dalamnya, lalu Save (Ctrl+O, Enter) dan Exit (Ctrl+X)
```

### 2. Beri Izin Eksekusi (Chmod)

Sebelum dijalankan, script harus diberi izin agar bisa dieksekusi sebagai program. Jalankan perintah berikut:

```bash
chmod +x frankenphp.sh
```

### 3. Jalankan Script

Jalankan script dengan akses `sudo` atau sebagai `root`:

```bash
sudo ./frankenphp.sh
```

### 4. Ikuti Instruksi di Layar

Script akan berjalan secara interaktif dan meminta beberapa input dari Anda:

1.  **Pilih Versi PHP**: Ketik `1` untuk PHP 8.4 (Stabil) atau `2` untuk versi lainnya.
2.  **Pilih Database**: Ketik `1` untuk PostgreSQL atau `2` untuk MariaDB.
3.  **Nama Domain**: Masukkan domain Anda (misal: `app.example.com`).
4.  **Mode Web Server**:
    *   Pilih `1` jika Anda ingin menggunakan **Nginx** di depan FrankenPHP (Recommended jika Anda biasa pakai Nginx).
    *   Pilih `2` jika ingin **FrankenPHP Standalone** (Lebih cepat, FrankenPHP menangani langsung port 80/443).

### 5. Selesai

Setelah proses selesai, script akan menampilkan status instalasi.
Website Anda dapat diakses melalui `https://domain-anda.com`.

---

## Troubleshooting

*   **Log**: Cek log Supervisor jika FrankenPHP tidak jalan:
    ```bash
    tail -f /var/log/frankenphp-domain.com.log
    ```
*   **Port Conflict**: Jika memilih Mode Standalone, pastikan Nginx/Apache tidak menggunakan port 80/443. Script ini mencoba mematikannya otomatis di Mode 2.
*   **Firewall**: Jika tidak bisa diakses, pastikan provider VPS (AWS/GCP/Azure) juga membuka port 80, 443, dan 7844 di Security Group mereka.
