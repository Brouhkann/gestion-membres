-- ============================================
-- SCHÉMA V2 - PLATEFORME MULTI-ÉGLISES
-- Application de Gestion d'Églises
-- ============================================

-- Activation des extensions nécessaires
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- 1. TYPE ENUM POUR LES RÔLES
-- ============================================
DO $$ BEGIN
    CREATE TYPE user_role AS ENUM ('super_admin', 'pasteur', 'patriarche', 'responsable');
EXCEPTION
    WHEN duplicate_object THEN
        ALTER TYPE user_role ADD VALUE IF NOT EXISTS 'super_admin';
END $$;

-- ============================================
-- 2. TABLE DES ÉGLISES
-- ============================================
CREATE TABLE IF NOT EXISTS public.eglises (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nom VARCHAR(200) NOT NULL,
    logo_url TEXT NULL,
    adresse TEXT NULL,
    ville VARCHAR(100) NULL,
    pays VARCHAR(100) DEFAULT 'Côte d''Ivoire',
    telephone VARCHAR(20) NULL,
    email VARCHAR(200) NULL,
    description TEXT NULL,
    pasteur_id UUID NULL, -- Sera lié après création de users
    configuration_complete BOOLEAN DEFAULT false,
    actif BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ NULL
);

CREATE INDEX idx_eglises_actif ON public.eglises(actif);
CREATE INDEX idx_eglises_pasteur ON public.eglises(pasteur_id);

COMMENT ON TABLE public.eglises IS 'Églises gérées par la plateforme';

-- ============================================
-- 3. TABLE DES UTILISATEURS
-- ============================================
CREATE TABLE IF NOT EXISTS public.users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    telephone VARCHAR(20) NOT NULL UNIQUE,
    nom VARCHAR(100) NOT NULL,
    prenom VARCHAR(100) NOT NULL,
    role user_role NOT NULL,
    eglise_id UUID NULL REFERENCES public.eglises(id) ON DELETE SET NULL,
    tribu_id UUID NULL,
    departement_id UUID NULL,
    photo_url TEXT NULL,
    actif BOOLEAN DEFAULT true,
    premiere_connexion BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ NULL
);

CREATE INDEX idx_users_role ON public.users(role);
CREATE INDEX idx_users_eglise ON public.users(eglise_id);
CREATE INDEX idx_users_tribu ON public.users(tribu_id);
CREATE INDEX idx_users_departement ON public.users(departement_id);

COMMENT ON TABLE public.users IS 'Utilisateurs de la plateforme (super_admin, pasteurs, patriarches, responsables)';

-- ============================================
-- 4. TABLE DES TRIBUS
-- ============================================
CREATE TABLE IF NOT EXISTS public.tribus (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nom VARCHAR(100) NOT NULL,
    description TEXT NULL,
    eglise_id UUID NOT NULL REFERENCES public.eglises(id) ON DELETE CASCADE,
    patriarche_id UUID NULL,
    actif BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ NULL,
    UNIQUE(nom, eglise_id)
);

CREATE INDEX idx_tribus_eglise ON public.tribus(eglise_id);

COMMENT ON TABLE public.tribus IS 'Tribus par église';

-- ============================================
-- 5. TABLE DES DÉPARTEMENTS
-- ============================================
CREATE TABLE IF NOT EXISTS public.departements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nom VARCHAR(100) NOT NULL,
    description TEXT NULL,
    eglise_id UUID NOT NULL REFERENCES public.eglises(id) ON DELETE CASCADE,
    responsable_id UUID NULL,
    actif BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ NULL,
    UNIQUE(nom, eglise_id)
);

CREATE INDEX idx_departements_eglise ON public.departements(eglise_id);

COMMENT ON TABLE public.departements IS 'Départements/ministères par église';

-- ============================================
-- 6. TABLE DES FIDÈLES
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
    eglise_id UUID NOT NULL REFERENCES public.eglises(id) ON DELETE CASCADE,
    invite_par UUID NULL REFERENCES public.fideles(id) ON DELETE SET NULL,
    tribu_id UUID NULL REFERENCES public.tribus(id) ON DELETE SET NULL,
    photo_url TEXT NULL,
    actif BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ NULL
);

CREATE INDEX idx_fideles_eglise ON public.fideles(eglise_id);
CREATE INDEX idx_fideles_tribu ON public.fideles(tribu_id);
CREATE INDEX idx_fideles_actif ON public.fideles(actif);
CREATE INDEX idx_fideles_nom ON public.fideles(nom, prenom);
CREATE INDEX idx_fideles_anniversaire ON public.fideles(mois_naissance, jour_naissance);

COMMENT ON TABLE public.fideles IS 'Membres/fidèles par église';

-- ============================================
-- 7. TABLE DE LIAISON FIDÈLES-DÉPARTEMENTS
-- ============================================
CREATE TABLE IF NOT EXISTS public.fidele_departements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    fidele_id UUID NOT NULL REFERENCES public.fideles(id) ON DELETE CASCADE,
    departement_id UUID NOT NULL REFERENCES public.departements(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(fidele_id, departement_id)
);

CREATE INDEX idx_fidele_dept_fidele ON public.fidele_departements(fidele_id);
CREATE INDEX idx_fidele_dept_dept ON public.fidele_departements(departement_id);

-- ============================================
-- 8. TABLE DES SESSIONS D'APPEL
-- ============================================
CREATE TABLE IF NOT EXISTS public.sessions_appel (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    date DATE NOT NULL,
    type_groupe VARCHAR(20) NOT NULL CHECK (type_groupe IN ('tribu', 'departement', 'eglise')),
    groupe_id UUID NULL, -- NULL si type = 'eglise'
    eglise_id UUID NOT NULL REFERENCES public.eglises(id) ON DELETE CASCADE,
    created_by UUID NOT NULL REFERENCES public.users(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(date, type_groupe, groupe_id, eglise_id)
);

CREATE INDEX idx_sessions_eglise ON public.sessions_appel(eglise_id);
CREATE INDEX idx_sessions_date ON public.sessions_appel(date DESC);

-- ============================================
-- 9. TABLE DES PRÉSENCES
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

-- ============================================
-- CLÉS ÉTRANGÈRES DIFFÉRÉES
-- ============================================
ALTER TABLE public.eglises
    ADD CONSTRAINT fk_eglises_pasteur
    FOREIGN KEY (pasteur_id) REFERENCES public.users(id) ON DELETE SET NULL;

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
    RETURN (SELECT role::text FROM public.users WHERE id = auth.uid());
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Fonction pour obtenir l'église de l'utilisateur
CREATE OR REPLACE FUNCTION public.get_user_eglise_id()
RETURNS UUID AS $$
BEGIN
    RETURN (SELECT eglise_id FROM public.users WHERE id = auth.uid());
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Fonction pour vérifier si l'utilisateur est super admin
CREATE OR REPLACE FUNCTION public.is_super_admin()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN (SELECT role = 'super_admin' FROM public.users WHERE id = auth.uid());
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Fonction pour vérifier si l'utilisateur est pasteur
CREATE OR REPLACE FUNCTION public.is_pasteur()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN (SELECT role = 'pasteur' FROM public.users WHERE id = auth.uid());
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Fonction pour mettre à jour updated_at
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
DROP TRIGGER IF EXISTS trigger_users_updated_at ON public.users;
CREATE TRIGGER trigger_users_updated_at
    BEFORE UPDATE ON public.users
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

DROP TRIGGER IF EXISTS trigger_eglises_updated_at ON public.eglises;
CREATE TRIGGER trigger_eglises_updated_at
    BEFORE UPDATE ON public.eglises
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

DROP TRIGGER IF EXISTS trigger_tribus_updated_at ON public.tribus;
CREATE TRIGGER trigger_tribus_updated_at
    BEFORE UPDATE ON public.tribus
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

DROP TRIGGER IF EXISTS trigger_departements_updated_at ON public.departements;
CREATE TRIGGER trigger_departements_updated_at
    BEFORE UPDATE ON public.departements
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

DROP TRIGGER IF EXISTS trigger_fideles_updated_at ON public.fideles;
CREATE TRIGGER trigger_fideles_updated_at
    BEFORE UPDATE ON public.fideles
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

-- ============================================
-- RLS (Row Level Security)
-- ============================================
ALTER TABLE public.eglises ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tribus ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.departements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fideles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fidele_departements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sessions_appel ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.presences ENABLE ROW LEVEL SECURITY;

-- Policies pour eglises
CREATE POLICY "Super admin peut tout voir" ON public.eglises
    FOR ALL USING (public.is_super_admin());

CREATE POLICY "Pasteur voit son église" ON public.eglises
    FOR SELECT USING (id = public.get_user_eglise_id());

CREATE POLICY "Pasteur modifie son église" ON public.eglises
    FOR UPDATE USING (id = public.get_user_eglise_id());

-- Policies pour users
CREATE POLICY "Super admin gère tous les users" ON public.users
    FOR ALL USING (public.is_super_admin());

CREATE POLICY "Users voient leur église" ON public.users
    FOR SELECT USING (eglise_id = public.get_user_eglise_id() OR id = auth.uid());

CREATE POLICY "Pasteur gère users de son église" ON public.users
    FOR ALL USING (public.is_pasteur() AND eglise_id = public.get_user_eglise_id());

-- Policies pour tribus (scoped par église)
CREATE POLICY "Users voient tribus de leur église" ON public.tribus
    FOR SELECT USING (eglise_id = public.get_user_eglise_id() OR public.is_super_admin());

CREATE POLICY "Pasteur gère tribus" ON public.tribus
    FOR ALL USING (public.is_pasteur() AND eglise_id = public.get_user_eglise_id());

-- Policies pour departements (scoped par église)
CREATE POLICY "Users voient departements de leur église" ON public.departements
    FOR SELECT USING (eglise_id = public.get_user_eglise_id() OR public.is_super_admin());

CREATE POLICY "Pasteur gère departements" ON public.departements
    FOR ALL USING (public.is_pasteur() AND eglise_id = public.get_user_eglise_id());

-- Policies pour fideles (scoped par église)
CREATE POLICY "Users voient fideles de leur église" ON public.fideles
    FOR SELECT USING (eglise_id = public.get_user_eglise_id() OR public.is_super_admin());

CREATE POLICY "Pasteur gère fideles" ON public.fideles
    FOR ALL USING (public.is_pasteur() AND eglise_id = public.get_user_eglise_id());

-- Policies pour fidele_departements
CREATE POLICY "Users voient associations" ON public.fidele_departements
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM public.fideles f WHERE f.id = fidele_id AND f.eglise_id = public.get_user_eglise_id())
        OR public.is_super_admin()
    );

CREATE POLICY "Pasteur gère associations" ON public.fidele_departements
    FOR ALL USING (
        public.is_pasteur() AND
        EXISTS (SELECT 1 FROM public.fideles f WHERE f.id = fidele_id AND f.eglise_id = public.get_user_eglise_id())
    );

-- Policies pour sessions_appel
CREATE POLICY "Users voient sessions de leur église" ON public.sessions_appel
    FOR SELECT USING (eglise_id = public.get_user_eglise_id() OR public.is_super_admin());

CREATE POLICY "Users créent sessions dans leur église" ON public.sessions_appel
    FOR INSERT WITH CHECK (eglise_id = public.get_user_eglise_id());

-- Policies pour presences
CREATE POLICY "Users voient presences de leur église" ON public.presences
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM public.sessions_appel s WHERE s.id = session_id AND s.eglise_id = public.get_user_eglise_id())
        OR public.is_super_admin()
    );

CREATE POLICY "Users gèrent presences" ON public.presences
    FOR ALL USING (
        EXISTS (SELECT 1 FROM public.sessions_appel s WHERE s.id = session_id AND s.eglise_id = public.get_user_eglise_id())
    );
