# Pipeline CI/CD - API CRUD Cloud Run

API CRUD Node.js déployée automatiquement sur Google Cloud Run avec migrations de base de données Flyway.

## Architecture du Pipeline

Pipeline CI/CD complet implémenté avec GitHub Actions pour automatiser le build, les migrations et le déploiement sur Cloud Run.

---

## Étapes du Pipeline

### 1. Récupération du code

**GitHub Action** : `actions/checkout@v4`

Clone le repository GitHub dans l'environnement CI pour accéder au code source, Dockerfile et configurations.

### 2. Extraction de la version

**Méthode** : Extraction depuis les tags Git

`VERSION=${GITHUB_REF#refs/tags/v}`

- Récupère le tag Git poussé (exemple : `v1.0.0`)
- Extrait la version numérique (`1.0.0`)
- Utilisé pour versionner les images Docker

**Déclenchement** : Push d'un tag commençant par `v` (exemple : `v1.0.0`, `v2.1.5`)

### 3. Connexion à Docker Hub

**GitHub Action** : `docker/login-action@v3`

Authentification sur Docker Hub avec les credentials stockés dans les secrets GitHub :
- `DOCKER_USERNAME` : Nom d'utilisateur Docker Hub
- `DOCKER_PASSWORD` : Token d'accès Docker Hub

### 4. Build et push de l'image de l'API

**Commandes exécutées** :
`docker build -t isreak/crud-api:1.0.0 .`
`docker push isreak/crud-api:1.0.0`
`docker tag isreak/crud-api:1.0.0 isreak/crud-api:latest`
`docker push isreak/crud-api:latest`

**Résultat** :
- Image versionnée avec le tag Git (`crud-api:1.0.0`)
- Image latest mise à jour (`crud-api:latest`)
- Permet le rollback vers versions précédentes

### 5. Configuration du SDK Google Cloud

**GitHub Actions utilisées** :
- `google-github-actions/auth@v2` : Authentification Service Account
- `google-github-actions/setup-gcloud@v2` : Installation du SDK gcloud

**Secret requis** : `GCP_SA_KEY` (clé JSON du Service Account)

**Permissions Service Account nécessaires** :
- Cloud Run Admin
- Cloud SQL Client
- Service Account User

### 6. Exécution des migrations de base de données

**Outil** : Flyway 11.17.0

**Commande exécutée** :

```bash
docker run --rm
-v $(pwd)/migrations:/flyway/sql
flyway/flyway:latest
-url=jdbc:mysql://34.xxx.xxx.xxx:3306/crud_app
-user=admin
-password=***
-baselineOnMigrate=true
migrate
```

**Fichier de migration** : `migrations/V1__create_users_table.sql`

**Option clé** : `-baselineOnMigrate=true` permet d'initialiser Flyway sur une base de données existante.

**Résultat** :
- Crée/met à jour automatiquement le schéma de base de données
- Tracking des migrations dans la table `flyway_schema_history`
- Processus idempotent et reproductible

### 7. Déploiement sur Cloud Run

**Commande gcloud** :

`gcloud run deploy crud-api-service --image=isreak/crud-api:1.0.0 --region=europe-west1 --platform=managed --allow-unauthenticated --set-env-vars="DB_HOST=${{ secrets.DB_HOST }},DB_USER=${{ secrets.DB_USER }},DB_PASS=${{ secrets.DB_PASSWORD }},DB_NAME=${{ secrets.DB_NAME }}"`


**Configuration** :
- Service : `crud-api-service`
- Région : `europe-west1`
- Accès : Public (non authentifié)
- Scaling : Automatique (0 à N instances)
- Port : 8080 (automatique Cloud Run)

**Résultat** : URL publique `https://crud-api-service-mdohbywjbq-ew.a.run.app`

---

## Secrets GitHub Requis

| Secret | Description | Exemple |
|--------|-------------|---------|
| `DOCKER_USERNAME` | Nom d'utilisateur Docker Hub | `isreak` |
| `DOCKER_PASSWORD` | Token Docker Hub | `dckr_pat_xxx` |
| `GCP_SA_KEY` | Clé JSON Service Account GCP | `{"type":"service_account",...}` |
| `GCP_PROJECT_ID` | ID du projet GCP | `tp-cloud-2025-julien` |
| `DB_HOST` | Adresse IP Cloud SQL | `34.96.41.169` |
| `DB_USER` | Utilisateur MySQL | `admin` |
| `DB_PASSWORD` | Mot de passe MySQL | `admin` |
| `DB_NAME` | Nom de la base de données | `crud_app` |

---

## Utilisation

### Déclencher un déploiement

```bash
git add *
git commit -m "Update API"
git push origin main
git tag v1.0.1
git push origin v1.0.1
```


Le workflow GitHub Actions se déclenche automatiquement au push du tag.

### Tester l'API déployée

**Lister tous les utilisateurs**
`curl https://crud-api-service-mdohbywjbq-ew.a.run.app/api/users`

**Créer un utilisateur**
`curl -X POST https://crud-api-service-mdohbywjbq-ew.a.run.app/api/user -H "Content-Type: application/json" -d '{"fullname":"John Doe","study_level":"Master","age":25}'`

**Récupérer un utilisateur par UUID**
`curl https://crud-api-service-mdohbywjbq-ew.a.run.app/api/users/{uuid}`

**Modifier un utilisateur**
`curl -X PUT https://crud-api-service-mdohbywjbq-ew.a.run.app/api/users/{uuid} -H "Content-Type: application/json" -d '{"fullname":"Jane Doe","study_level":"Doctorat","age":30}'`

**Supprimer un utilisateur**
`curl -X DELETE https://crud-api-service-mdohbywjbq-ew.a.run.app/api/users/{uuid}`

---

## Schéma du Workflow

Push tag v*
↓
Checkout code
↓
Extract version (1.0.0)
↓
Docker Hub login
↓
Build & Push API image
↓
Setup GCP SDK
↓
Run Flyway migrations
↓
Deploy to Cloud Run
↓
✅ API Live


---

## Technologies Utilisées

- **Backend** : Node.js 20, Express
- **Base de données** : Google Cloud SQL (MySQL 8.0)
- **Migrations** : Flyway
- **Conteneurisation** : Docker
- **Registry** : Docker Hub
- **Déploiement** : Google Cloud Run
- **CI/CD** : GitHub Actions
- **Versioning** : Git tags

---

## État du Projet

| Composant | État |
|-----------|------|
| API CRUD Node.js | ✅ Fonctionnel |
| Dockerfile optimisé | ✅ Node.js seul |
| Pipeline CI/CD | ✅ Complet |
| Migrations Flyway | ✅ Automatiques |
| Cloud SQL MySQL | ✅ Connecté |
| Cloud Run | ✅ Déployé |
| Versioning Git | ✅ Tags v* |

---

## Structure du Projet

├── .github/
│ └── workflows/
│ └── deploy.yml # Pipeline CI/CD
├── migrations/
│ └── V1__create_users_table.sql # Migration Flyway
├── index.js # API CRUD Express
├── package.json # Dépendances Node.js
├── Dockerfile # Image Docker
└── README.md # Documentation

---

## Auteur

Julien - TP Cloud 2025
