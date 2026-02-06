# Configuration Supabase - Gestion d'Église

## Prérequis

1. Créer un compte sur [supabase.com](https://supabase.com)
2. Créer un nouveau projet
3. Noter les credentials (URL et anon key)

## Installation de la base de données

### Étape 1 : Créer le schéma

1. Aller dans **SQL Editor** dans le dashboard Supabase
2. Copier et exécuter le contenu de `schema.sql`
3. Vérifier que toutes les tables sont créées dans **Table Editor**

### Étape 2 : Configurer les politiques RLS

1. Dans **SQL Editor**, exécuter le contenu de `rls_policies.sql`
2. Vérifier dans **Authentication > Policies** que les politiques sont actives

### Étape 3 : Insérer les données de test (optionnel)

1. Exécuter `seed.sql` dans **SQL Editor**
2. Vérifier les données dans **Table Editor**

## Création des utilisateurs

### Via le Dashboard Supabase

1. Aller dans **Authentication > Users**
2. Cliquer sur **Add User** > **Create New User**
3. Créer les utilisateurs avec le format email : `TELEPHONE@eglise.app`
   - Exemple : `699000001@eglise.app`

### Créer les entrées dans la table users

Après avoir créé un utilisateur dans Auth, créer son profil dans la table `users` :

```sql
-- Exemple : Créer un pasteur
INSERT INTO public.users (id, telephone, nom, prenom, role)
VALUES (
    'UUID_DE_AUTH_USER',  -- Copier l'ID depuis Authentication > Users
    '699000001',
    'DUPONT',
    'Jean',
    'pasteur'
);

-- Exemple : Créer un patriarche
INSERT INTO public.users (id, telephone, nom, prenom, role, tribu_id)
VALUES (
    'UUID_DE_AUTH_USER',
    '699000002',
    'KAMGA',
    'Pierre',
    'patriarche',
    '11111111-1111-1111-1111-111111111111'  -- ID de la tribu
);

-- Exemple : Créer un responsable de département
INSERT INTO public.users (id, telephone, nom, prenom, role, departement_id)
VALUES (
    'UUID_DE_AUTH_USER',
    '699000003',
    'TALLA',
    'Samuel',
    'responsable',
    'aaaa1111-1111-1111-1111-111111111111'  -- ID du département
);
```

## Configuration de l'application Flutter

Dans `lib/main.dart`, remplacer :

```dart
await SupabaseService.initialize(
  url: 'https://VOTRE_PROJECT_ID.supabase.co',
  anonKey: 'VOTRE_ANON_KEY',
);
```

Trouver ces valeurs dans **Settings > API** :
- **Project URL** : `https://xxxxx.supabase.co`
- **anon public** key

## Structure des tables

### users
Utilisateurs de l'application (pasteur, patriarches, responsables)

| Colonne | Type | Description |
|---------|------|-------------|
| id | UUID | Lié à auth.users |
| telephone | VARCHAR(20) | Numéro unique |
| nom | VARCHAR(100) | Nom de famille |
| prenom | VARCHAR(100) | Prénom |
| role | VARCHAR(20) | pasteur/patriarche/responsable |
| tribu_id | UUID | Pour les patriarches |
| departement_id | UUID | Pour les responsables |

### tribus
| Colonne | Type | Description |
|---------|------|-------------|
| id | UUID | ID unique |
| nom | VARCHAR(100) | Nom de la tribu |
| patriarche_id | UUID | Référence fidèle |

### departements
| Colonne | Type | Description |
|---------|------|-------------|
| id | UUID | ID unique |
| nom | VARCHAR(100) | Nom du département |
| responsable_id | UUID | Référence fidèle |

### fideles
| Colonne | Type | Description |
|---------|------|-------------|
| id | UUID | ID unique |
| nom | VARCHAR(100) | Nom de famille |
| prenom | VARCHAR(100) | Prénom |
| sexe | CHAR(1) | M ou F |
| jour_naissance | INTEGER | 1-31 |
| mois_naissance | INTEGER | 1-12 |
| telephone | VARCHAR(20) | WhatsApp |
| tribu_id | UUID | Tribu obligatoire |
| actif | BOOLEAN | Statut |

### fidele_departements
Table de liaison N:N entre fidèles et départements

### sessions_appel
| Colonne | Type | Description |
|---------|------|-------------|
| id | UUID | ID unique |
| date | DATE | Date de l'appel |
| type_groupe | VARCHAR(20) | tribu/departement |
| groupe_id | UUID | ID tribu ou département |
| created_by | UUID | Utilisateur |

### presences
| Colonne | Type | Description |
|---------|------|-------------|
| id | UUID | ID unique |
| session_id | UUID | Session d'appel |
| fidele_id | UUID | Fidèle |
| statut | VARCHAR(10) | present/absent |

## Règles RLS (Row Level Security)

| Table | Pasteur | Patriarche | Responsable |
|-------|---------|------------|-------------|
| users | Tout | Son profil | Son profil |
| tribus | CRUD | Lecture | Lecture |
| departements | CRUD | Lecture | Lecture |
| fideles | Tout | Sa tribu | Son département |
| sessions_appel | Tout | Sa tribu | Son département |
| presences | Tout | Sa tribu | Son département |

## Dépannage

### Erreur RLS "new row violates row-level security policy"
- Vérifier que l'utilisateur a le bon rôle
- Vérifier que tribu_id/departement_id est bien défini pour patriarches/responsables

### Erreur "User not found"
- S'assurer que l'utilisateur existe dans auth.users ET dans public.users
- Les deux tables doivent avoir le même UUID

### Erreur de connexion
- Vérifier l'URL et la clé anon dans main.dart
- Vérifier que le projet Supabase est actif
