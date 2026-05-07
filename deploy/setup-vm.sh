#!/bin/bash
# ════════════════════════════════════════════════════════════════════════════
# Script de déploiement Brasserie T&S sur VM Debian 12
# ════════════════════════════════════════════════════════════════════════════
# Usage : sudo bash setup-vm.sh
# ════════════════════════════════════════════════════════════════════════════

set -e  # Arrête le script à la première erreur

# ── Configuration (à adapter avant exécution) ───────────────────────────────
DB_NAME="brasserie_db"
DB_USER="brasserie_user"
DB_PASSWORD="bts_brass"            # ⚠️ Doit correspondre à database.dart et seed.dart
PROJECT_USER="bts"                  # L'utilisateur Linux qui possède le projet
PROJECT_DIR="/home/${PROJECT_USER}/flutter_BTS"

echo "════════════════════════════════════════════════"
echo "  Déploiement Brasserie T&S"
echo "════════════════════════════════════════════════"
echo ""

# ── 1. Installation des dépendances système ─────────────────────────────────
echo "→ Installation des paquets système..."
apt-get update
apt-get install -y \
    apache2 \
    mariadb-server \
    git \
    curl \
    unzip \
    nodejs \
    npm

# ── 2. Configuration de MariaDB ─────────────────────────────────────────────
echo "→ Configuration de MariaDB..."
mysql -u root <<EOF
CREATE DATABASE IF NOT EXISTS ${DB_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';
FLUSH PRIVILEGES;
EOF
echo "  ✓ Base de données ${DB_NAME} créée"

# ── 3. Modules Apache nécessaires ────────────────────────────────────────────
echo "→ Activation des modules Apache..."
a2enmod rewrite proxy proxy_http headers
systemctl restart apache2

# ── 4. Configuration du virtual host Apache ──────────────────────────────────
echo "→ Configuration du virtual host Apache..."
cat > /etc/apache2/sites-available/brasserie.conf <<EOF
<VirtualHost *:80>
    ServerAdmin admin@brasserie.local
    DocumentRoot ${PROJECT_DIR}/frontend/dist

    <Directory ${PROJECT_DIR}/frontend/dist>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted

        # SPA fallback : toutes les routes inconnues renvoient index.html
        RewriteEngine On
        RewriteBase /
        RewriteRule ^index\\.html\$ - [L]
        RewriteCond %{REQUEST_FILENAME} !-f
        RewriteCond %{REQUEST_FILENAME} !-d
        RewriteCond %{REQUEST_URI} !^/api
        RewriteRule . /index.html [L]
    </Directory>

    # Proxy /api → API Dart (localhost:8080)
    ProxyPreserveHost On
    ProxyPass        /api  http://localhost:8080
    ProxyPassReverse /api  http://localhost:8080

    ErrorLog  \${APACHE_LOG_DIR}/brasserie-error.log
    CustomLog \${APACHE_LOG_DIR}/brasserie-access.log combined
</VirtualHost>
EOF

a2ensite brasserie.conf
a2dissite 000-default.conf || true
apache2ctl configtest
systemctl reload apache2
echo "  ✓ Apache configuré"

# ── 5. Service systemd pour l'API Dart ──────────────────────────────────────
echo "→ Création du service systemd brasserie-api..."
cat > /etc/systemd/system/brasserie-api.service <<EOF
[Unit]
Description=Brasserie T&S API (Dart)
After=network.target mariadb.service
Requires=mariadb.service

[Service]
Type=simple
User=${PROJECT_USER}
WorkingDirectory=${PROJECT_DIR}/api
ExecStart=${PROJECT_DIR}/api/api_server
Restart=always
RestartSec=5
Environment="PORT=8080"

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
echo "  ✓ Service systemd créé (pas encore démarré)"

# ── 6. Permissions ──────────────────────────────────────────────────────────
chown -R ${PROJECT_USER}:${PROJECT_USER} ${PROJECT_DIR} 2>/dev/null || true

echo ""
echo "════════════════════════════════════════════════"
echo "  ✓ Configuration système terminée !"
echo "════════════════════════════════════════════════"
echo ""
echo "Étapes suivantes (en tant que ${PROJECT_USER}):"
echo ""
echo "  1. Compiler l'API Dart :"
echo "     cd ${PROJECT_DIR}/api"
echo "     /opt/dart-sdk/bin/dart pub get"
echo "     /opt/dart-sdk/bin/dart run bin/seed.dart    # initialise la BDD"
echo "     /opt/dart-sdk/bin/dart compile exe bin/server.dart -o api_server"
echo ""
echo "  2. Builder le frontend :"
echo "     cd ${PROJECT_DIR}/frontend"
echo "     npm install"
echo "     npm run build"
echo ""
echo "  3. Démarrer l'API :"
echo "     sudo systemctl enable brasserie-api"
echo "     sudo systemctl start brasserie-api"
echo "     sudo systemctl status brasserie-api"
echo ""
echo "  4. Tester :"
echo "     http://<IP-VM>/         (frontend)"
echo "     http://<IP-VM>/api/health (API)"
echo ""
