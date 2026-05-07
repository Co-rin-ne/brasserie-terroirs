#!/bin/bash
# ════════════════════════════════════════════════════════════════════════════
# Script de backup de la base brasserie_db vers InfinityFree (FTP)
# ════════════════════════════════════════════════════════════════════════════
# À exécuter via crontab :
#   0 2 * * * /home/bts/backup-brasserie.sh >> /var/log/brasserie-backup.log 2>&1
# ════════════════════════════════════════════════════════════════════════════

# ── Configuration ───────────────────────────────────────────────────────────
DB_NAME="brasserie_db"
DB_USER="brasserie_user"
DB_PASSWORD="bts_brass"

FTP_HOST="ftpupload.net"            # ⚠️ À adapter (InfinityFree)
FTP_USER="votre_user_ftp"
FTP_PASS="votre_password_ftp"
FTP_DIR="/htdocs/backups"

LOCAL_DIR="/home/bts/backups"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="brasserie_backup_${DATE}.sql"

# ── Création du dossier local si absent ─────────────────────────────────────
mkdir -p "${LOCAL_DIR}"

# ── Dump MariaDB ────────────────────────────────────────────────────────────
echo "[$(date)] Démarrage du backup..."
mysqldump -u "${DB_USER}" -p"${DB_PASSWORD}" "${DB_NAME}" > "${LOCAL_DIR}/${BACKUP_FILE}"

if [ $? -ne 0 ]; then
    echo "[$(date)] ❌ Erreur mysqldump"
    exit 1
fi

# ── Compression ─────────────────────────────────────────────────────────────
gzip "${LOCAL_DIR}/${BACKUP_FILE}"
BACKUP_FILE="${BACKUP_FILE}.gz"
echo "[$(date)] ✓ Dump compressé : ${BACKUP_FILE}"

# ── Upload FTP vers InfinityFree ────────────────────────────────────────────
ftp -inv "${FTP_HOST}" <<EOF
user ${FTP_USER} ${FTP_PASS}
binary
cd ${FTP_DIR}
put ${LOCAL_DIR}/${BACKUP_FILE} ${BACKUP_FILE}
bye
EOF

if [ $? -eq 0 ]; then
    echo "[$(date)] ✓ Upload FTP OK"
else
    echo "[$(date)] ⚠️ Échec upload FTP (le fichier reste en local)"
fi

# ── Nettoyage : on garde les 7 derniers backups locaux ──────────────────────
cd "${LOCAL_DIR}" && ls -t brasserie_backup_*.sql.gz 2>/dev/null | tail -n +8 | xargs -r rm

echo "[$(date)] Backup terminé"
