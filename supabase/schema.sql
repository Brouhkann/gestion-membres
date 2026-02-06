-- ============================================
-- SCHÉMA DE BASE DE DONNÉES SUPABASE
-- Application de Gestion d'Église
-- ============================================

-- Activation des extensions nécessaires
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- 1. TABLE DES UTILISATEURS (RESPONSABLES)
-- ============================================
-- Liée à auth.users de Supabase

CREATE TABLE IF NOT EXISTS public.users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    telephone VARCHAR(20) NOT NULL UNIQUE,
    nom VARCHAR(100) NOT NULL,
    prenom VARCHAR(100) NOT NULL,
    role VARCHAR(20) NOT NULL CHECK (role IN ('pasteur', 'patriarche', 'responsable')),
    tribu_id UUID NULL,
    departement_id UUID NULL,
    photo_url TEXT NULL,
    actif BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ NULL
);

-- Index pour les recherches
CREATE INDEX idx_users_role ON public.users(role);
CREATE INDEX idx_users_tribu ON public.users(tribu_id);
CREATE INDEX idx_users_departement ON public.users(departement_id);

COMMENT ON TABLE public.users IS 'Utilisateurs de l''application (pasteur, patriarches, responsables)';

-- ============================================
-- 2. TABLE DES TRIBUS
-- ============================================

CREATE TABLE IF NOT EXISTS public.tribus (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nom VARCHAR(100) NOT NULL UNIQUE,
    description TEXT NULL,
    patriarche_id UUID NULL,
    actif BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ NULL
);

COMMENT ON TABLE public.tribus IS 'Tribus de l''église';

-- ============================================
-- 3. TABLE DES DÉPARTEMENTS
-- ============================================

CREATE TABLE IF NOT EXISTS public.departements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nom VARCHAR(100) NOT NULL UNIQUE,
    description TEXT NULL,
    responsable_id UUID NULL,
    actif BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ NULL
);

COMMENT ON TABLE public.departements IS 'Départements/ministères de l''église';

-- ============================================
-- 4. TABLE DES FIDÈLES
-- ============================================

CREATE TABLE IF NOT EXISTS public.fideles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nom VARCHAR(100) NOT NULL,
    prenom VARCHAR(100) NOT NULL,
    sexe CHAR(1) NOT NULL CHECK (sexe IN ('M', 'F')),
    jour_naissance INTEGER NULL CHECK (jour_naissance >= 1 AND jour_naissance <= 31),
    mois_naissance INTEGER NULL CHECK (mois_naissance >= 1 AND mois_naissance <= 12),
    annee_naissance INTEGER NULL,
    telephone VARCHAR(20) NULL,
    adresse TEXT NULL,
    profession VARCHAR(100) NULL,
    invite_par UUID NULL REFERENCES public.fideles(id) ON DELETE SET NULL,
    tribu_id UUID NOT NULL REFERENCES public.tribus(id) ON DELETE RESTRICT,
    photo_url TEXT NULL,
    actif BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ NULL
);

-- Index pour les recherches et filtres
CREATE INDEX idx_fideles_tribu ON public.fideles(tribu_id);
CREATE INDEX idx_fideles_actif ON public.fideles(actif);
CREATE INDEX idx_fideles_nom ON public.fideles(nom, prenom);
CREATE INDEX idx_fideles_anniversaire ON public.fideles(mois_naissance, jour_naissance);

COMMENT ON TABLE public.fideles IS 'Membres/fidèles de l''église';

-- ============================================
-- 5. TABLE DE LIAISON FIDÈLES-DÉPARTEMENTS
-- ============================================
-- Un fidèle peut appartenir à plusieurs départements

CREATE TABLE IF NOT EXISTS public.fidele_departements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    fidele_id UUID NOT NULL REFERENCES public.fideles(id) ON DELETE CASCADE,
    departement_id UUID NOT NULL REFERENCES public.departements(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(fidele_id, departement_id)
);

CREATE INDEX idx_fidele_dept_fidele ON public.fidele_departements(fidele_id);
CREATE INDEX idx_fidele_dept_dept ON public.fidele_departements(departement_id);

COMMENT ON TABLE public.fidele_departements IS 'Association fidèles-départements (N:N)';

-- ============================================
-- 6. TABLE DES SESSIONS D'APPEL
-- ============================================

CREATE TABLE IF NOT EXISTS public.sessions_appel (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    date DATE NOT NULL,
    type_groupe VARCHAR(20) NOT NULL CHECK (type_groupe IN ('tribu', 'departement')),
    groupe_id UUID NOT NULL,
    created_by UUID NOT NULL REFERENCES public.users(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(date, type_groupe, groupe_id)
);

CREATE INDEX idx_sessions_groupe ON public.sessions_appel(type_groupe, groupe_id);
CREATE INDEX idx_sessions_date ON public.sessions_appel(date DESC);

COMMENT ON TABLE public.sessions_appel IS 'Sessions d''appel (une par date/groupe)';

-- ============================================
-- 7. TABLE DES PRÉSENCES
-- ============================================

CREATE TABLE IF NOT EXISTS public.presences (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id UUID NOT NULL REFERENCES public.sessions_appel(id) ON DELETE CASCADE,
    fidele_id UUID NOT NULL REFERENCES public.fideles(id) ON DELETE CASCADE,
    statut VARCHAR(10) NOT NULL CHECK (statut IN ('present', 'absent')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(session_id, fidele_id)
);

CREATE INDEX idx_presences_session ON public.presences(session_id);
CREATE INDEX idx_presences_fidele ON public.presences(fidele_id);
CREATE INDEX idx_presences_statut ON public.presences(statut);

COMMENT ON TABLE public.presences IS 'Présences individuelles par session';

-- ============================================
-- CLÉS ÉTRANGÈRES DIFFÉRÉES
-- ============================================
-- Ajoutées après création des tables pour éviter les dépendances circulaires

ALTER TABLE public.tribus
    ADD CONSTRAINT fk_tribus_patriarche
    FOREIGN KEY (patriarche_id) REFERENCES public.fideles(id) ON DELETE SET NULL;

ALTER TABLE public.departements
    ADD CONSTRAINT fk_departements_responsable
    FOREIGN KEY (responsable_id) REFERENCES public.fideles(id) ON DELETE SET NULL;

ALTER TABLE public.users
    ADD CONSTRAINT fk_users_tribu
    FOREIGN KEY (tribu_id) REFERENCES public.tribus(id) ON DELETE SET NULL;

ALTER TABLE public.users
    ADD CONSTRAINT fk_users_departement
    FOREIGN KEY (departement_id) REFERENCES public.departements(id) ON DELETE SET NULL;

-- ============================================
-- FONCTIONS UTILITAIRES
-- ============================================

-- Fonction pour obtenir le rôle de l'utilisateur connecté
CREATE OR REPLACE FUNCTION public.get_user_role()
RETURNS TEXT AS $$
BEGIN
    RETURN (
        SELECT role FROM public.users WHERE id = auth.uid()
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Fonction pour obtenir la tribu de l'utilisateur (patriarche)
CREATE OR REPLACE FUNCTION public.get_user_tribu_id()
RETURNS UUID AS $$
BEGIN
    RETURN (
        SELECT tribu_id FROM public.users WHERE id = auth.uid()
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Fonction pour obtenir le département de l'utilisateur (responsable)
CREATE OR REPLACE FUNCTION public.get_user_departement_id()
RETURNS UUID AS $$
BEGIN
    RETURN (
        SELECT departement_id FROM public.users WHERE id = auth.uid()
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Fonction pour vérifier si l'utilisateur est pasteur
CREATE OR REPLACE FUNCTION public.is_pasteur()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN (
        SELECT role = 'pasteur' FROM public.users WHERE id = auth.uid()
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Fonction pour mettre à jour updated_at automatiquement
CREATE OR REPLACE FUNCTION public.update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- TRIGGERS
-- ============================================

-- Trigger updated_at pour users
CREATE TRIGGER trigger_users_updated_at
    BEFORE UPDATE ON public.users
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at();

-- Trigger updated_at pour tribus
CREATE TRIGGER trigger_tribus_updated_at
    BEFORE UPDATE ON public.tribus
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at();

-- Trigger updated_at pour departements
CREATE TRIGGER trigger_departements_updated_at
    BEFORE UPDATE ON public.departements
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at();

-- Trigger updated_at pour fideles
CREATE TRIGGER trigger_fideles_updated_at
    BEFORE UPDATE ON public.fideles
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at();
