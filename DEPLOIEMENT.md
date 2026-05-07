# 🚀 Déploiement Brasserie T&S sur VM Debian 12

Guide complet de mise en production sur la VM (BTS SIO E6).

---

## 📋 Architecture

```
┌─────────────────────────────────────────────┐
│           VM Debian 12.13                    │
│                                              │
│  ┌──────────┐    ┌──────────┐   ┌──────────┐│
│  │  Apache  │───▶│   Dart   │──▶│ MariaDB  ││
│  │  :80     │    │  :8080   │   │  :3306   ││
│  └──────────┘    └──────────┘   └──────────┘│
│       │                                      │
│       └─▶ React (frontend/dist)              │
│                                              │
│  Services: SSH · Fail2Ban · GLPI · Beszel    │
└─────────────────────────────────────────────┘
```

- **Apache** sert le frontend React et fait le proxy `/api → :8080`
- **Dart** API REST tourne en service systemd
- **MariaDB** stocke les données (utilisateurs, produits, panier, commandes)

---

## 1️⃣ Prérequis sur la VM

Vous avez déjà installé : SSH, Fail2Ban, GLPI, Beszel, Crontab. ✅

Il reste à installer :

```bash
# Dart SDK (déjà fait)
ls /opt/dart-sdk/bin/dart

# Si pas encore installé :
cd /tmp
curl -L https://storage.googleapis.com/dart-archive/channels/stable/release/latest/sdk/dartsdk-linux-arm64-release.zip -o dart.zip
sudo apt-get install -y unzip
unzip -q dart.zip
sudo mv dart-sdk /opt/
echo 'export PATH="/opt/dart-sdk/bin:$PATH"' | sudo tee /etc/profile.d/dart.sh
source /etc/profile.d/dart.sh
dart --version
```

---

## 2️⃣ Récupérer le projet sur la VM

### Option A : via Git (recommandé)
```bash
cd ~
git clone https://github.com/<votre-user>/flutter_BTS.git
```

### Option B : via SCP depuis le Mac
```bash
# Sur le Mac (pas la VM)
scp -r /Users/corinnehurtaux/flutter_BTS bts@<IP-VM>:/home/bts/
```

---

## 3️⃣ Lancer le script de configuration

```bash
cd ~/flutter_BTS/deploy
sudo bash setup-vm.sh
```

Ce script installe et configure automatiquement :
- ✅ Apache + modules (rewrite, proxy)
- ✅ MariaDB + base `brasserie_db` + user `brasserie_user`
- ✅ Node.js + npm
- ✅ Virtual host Apache (proxy `/api`)
- ✅ Service systemd `brasserie-api`

⚠️ **Avant de lancer**, modifiez dans `setup-vm.sh` :
- `DB_PASSWORD` : mettez un vrai mot de passe
- `PROJECT_USER` : votre user Linux (ex: `bts`)

---

## 4️⃣ Adapter la configuration de l'API

Modifiez le mot de passe MariaDB dans :
```bash
nano ~/flutter_BTS/api/lib/database/database.dart
nano ~/flutter_BTS/api/bin/seed.dart
```

Cherchez `password: 'votre_mot_de_passe'` et remplacez.

---

## 5️⃣ Initialiser et compiler l'API

```bash
cd ~/flutter_BTS/api

# Récupérer les dépendances Dart
/opt/dart-sdk/bin/dart pub get

# Initialiser la BDD avec les données de démo (admin + produits)
/opt/dart-sdk/bin/dart run bin/seed.dart

# Compiler en exécutable natif (plus rapide au démarrage)
/opt/dart-sdk/bin/dart compile exe bin/server.dart -o api_server
chmod +x api_server
```

---

## 6️⃣ Builder le frontend

```bash
cd ~/flutter_BTS/frontend
npm install
npm run build
```

Le build crée `frontend/dist/` qui sera servi par Apache.

---

## 7️⃣ Démarrer l'API

```bash
sudo systemctl enable brasserie-api
sudo systemctl start brasserie-api
sudo systemctl status brasserie-api
```

Logs en temps réel :
```bash
sudo journalctl -u brasserie-api -f
```

---

## 8️⃣ Tester

Sur votre machine ou iPhone (même réseau) :
- **Frontend** : `http://<IP-VM>/`
- **API health** : `http://<IP-VM>/api/health`

Comptes de démonstration :
| Email | Mot de passe | Rôle |
|-------|--------------|------|
| `admin@brasserie.fr` | `admin1234` | admin |
| `marie@example.fr` | `client1234` | client |
| `paul@example.fr` | `client1234` | client |

---

## 9️⃣ Configurer le backup automatique

```bash
# Copier le script
cp ~/flutter_BTS/deploy/backup-brasserie.sh ~/backup-brasserie.sh
chmod +x ~/backup-brasserie.sh

# Adapter les identifiants InfinityFree dedans
nano ~/backup-brasserie.sh

# Ajouter au crontab (backup quotidien à 2h du matin)
crontab -e
```

Ajouter cette ligne :
```cron
0 2 * * * /home/bts/backup-brasserie.sh >> /var/log/brasserie-backup.log 2>&1
```

---

## 🔧 Commandes utiles

| Action | Commande |
|--------|----------|
| Redémarrer l'API | `sudo systemctl restart brasserie-api` |
| Voir les logs API | `sudo journalctl -u brasserie-api -f` |
| Tester Apache | `sudo apache2ctl configtest` |
| Logs Apache | `sudo tail -f /var/log/apache2/brasserie-error.log` |
| Console MariaDB | `mysql -u brasserie_user -p brasserie_db` |
| Re-seed BDD | `cd ~/flutter_BTS/api && /opt/dart-sdk/bin/dart run bin/seed.dart` |
| Re-build frontend | `cd ~/flutter_BTS/frontend && npm run build` |

---

## 📱 Ajouter à l'écran d'accueil iPhone

1. Ouvrir Safari sur iPhone
2. Aller à `http://<IP-VM>/`
3. Touche **Partager** → **"Sur l'écran d'accueil"**
4. Nommer "Brasserie T&S" → Ajouter

L'app devient une PWA installée sur le bureau ! 🎉

---

## ❓ Dépannage

**API ne démarre pas** : `sudo journalctl -u brasserie-api -n 50`

**Erreur MariaDB** : Vérifier que les mots de passe correspondent dans :
- `setup-vm.sh`
- `api/lib/database/database.dart`
- `api/bin/seed.dart`

**Page blanche frontend** : Vérifier `sudo tail /var/log/apache2/brasserie-error.log`

**CORS** : L'API a `Access-Control-Allow-Origin: *` activé.

---

## 📊 Monitoring avec Beszel

L'agent Beszel monitore déjà la VM. Vous pouvez voir :
- CPU / RAM / Disque
- Réseau
- Uptime des services

Consulter le hub Beszel pour les graphes en temps réel.
