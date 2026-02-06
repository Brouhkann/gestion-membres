-- ============================================
-- POLITIQUES RLS (ROW LEVEL SECURITY)
-- Application de Gestion d'Église
-- ============================================

-- ============================================
-- ACTIVATION RLS SUR TOUTES LES TABLES
-- ============================================

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tribus ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.departements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fideles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fidele_departements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sessions_appel ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.presences ENABLE ROW LEVEL SECURITY;

-- ============================================
-- POLITIQUES POUR LA TABLE USERS
-- ============================================

-- Lecture: un utilisateur peut voir son propre profil
-- Le pasteur peut voir tous les utilisateurs
CREATE POLICY "users_select_own" ON public.users
    FOR SELECT
    USING (
        id = auth.uid()
        OR public.is_pasteur()
    );

-- Mise à jour: un utilisateur peut modifier son propre profil
-- Le pasteur peut modifier tous les utilisateurs
CREATE POLICY "users_update" ON public.users
    FOR UPDATE
    USING (
        id = auth.uid()
        OR public.is_pasteur()
    );

-- Insertion: seul le pasteur peut créer des utilisateurs
CREATE POLICY "users_insert" ON public.users
    FOR INSERT
    WITH CHECK (public.is_pasteur());

-- Suppression: seul le pasteur peut supprimer des utilisateurs
CREATE POLICY "users_delete" ON public.users
    FOR DELETE
    USING (public.is_pasteur());

-- ============================================
-- POLITIQUES POUR LA TABLE TRIBUS
-- ============================================

-- Lecture: tous les utilisateurs authentifiés peuvent voir les tribus
CREATE POLICY "tribus_select" ON public.tribus
    FOR SELECT
    USING (auth.uid() IS NOT NULL);

-- Insertion: seul le pasteur peut créer des tribus
CREATE POLICY "tribus_insert" ON public.tribus
    FOR INSERT
    WITH CHECK (public.is_pasteur());

-- Mise à jour: seul le pasteur peut modifier les tribus
CREATE POLICY "tribus_update" ON public.tribus
    FOR UPDATE
    USING (public.is_pasteur());

-- Suppression: seul le pasteur peut supprimer des tribus
CREATE POLICY "tribus_delete" ON public.tribus
    FOR DELETE
    USING (public.is_pasteur());

-- ============================================
-- POLITIQUES POUR LA TABLE DÉPARTEMENTS
-- ============================================

-- Lecture: tous les utilisateurs authentifiés peuvent voir les départements
CREATE POLICY "departements_select" ON public.departements
    FOR SELECT
    USING (auth.uid() IS NOT NULL);

-- Insertion: seul le pasteur peut créer des départements
CREATE POLICY "departements_insert" ON public.departements
    FOR INSERT
    WITH CHECK (public.is_pasteur());

-- Mise à jour: seul le pasteur peut modifier les départements
CREATE POLICY "departements_update" ON public.departements
    FOR UPDATE
    USING (public.is_pasteur());

-- Suppression: seul le pasteur peut supprimer des départements
CREATE POLICY "departements_delete" ON public.departements
    FOR DELETE
    USING (public.is_pasteur());

-- ============================================
-- POLITIQUES POUR LA TABLE FIDÈLES
-- ============================================

-- Lecture:
-- - Le pasteur voit tous les fidèles
-- - Le patriarche voit les fidèles de sa tribu
-- - Le responsable voit les fidèles de son département
CREATE POLICY "fideles_select" ON public.fideles
    FOR SELECT
    USING (
        public.is_pasteur()
        OR tribu_id = public.get_user_tribu_id()
        OR id IN (
            SELECT fd.fidele_id
            FROM public.fidele_departements fd
            WHERE fd.departement_id = public.get_user_departement_id()
        )
    );

-- Insertion:
-- - Le pasteur peut créer n'importe quel fidèle
-- - Le patriarche peut créer des fidèles dans sa tribu
CREATE POLICY "fideles_insert" ON public.fideles
    FOR INSERT
    WITH CHECK (
        public.is_pasteur()
        OR tribu_id = public.get_user_tribu_id()
    );

-- Mise à jour:
-- - Le pasteur peut modifier tous les fidèles
-- - Le patriarche peut modifier les fidèles de sa tribu
CREATE POLICY "fideles_update" ON public.fideles
    FOR UPDATE
    USING (
        public.is_pasteur()
        OR tribu_id = public.get_user_tribu_id()
    );

-- Suppression: seul le pasteur peut supprimer des fidèles
CREATE POLICY "fideles_delete" ON public.fideles
    FOR DELETE
    USING (public.is_pasteur());

-- ============================================
-- POLITIQUES POUR LA TABLE FIDELE_DEPARTEMENTS
-- ============================================

-- Lecture: mêmes règles que fidèles
CREATE POLICY "fidele_dept_select" ON public.fidele_departements
    FOR SELECT
    USING (
        public.is_pasteur()
        OR fidele_id IN (
            SELECT id FROM public.fideles WHERE tribu_id = public.get_user_tribu_id()
        )
        OR departement_id = public.get_user_departement_id()
    );

-- Insertion: pasteur ou patriarche du fidèle concerné
CREATE POLICY "fidele_dept_insert" ON public.fidele_departements
    FOR INSERT
    WITH CHECK (
        public.is_pasteur()
        OR fidele_id IN (
            SELECT id FROM public.fideles WHERE tribu_id = public.get_user_tribu_id()
        )
    );

-- Suppression: pasteur ou patriarche du fidèle concerné
CREATE POLICY "fidele_dept_delete" ON public.fidele_departements
    FOR DELETE
    USING (
        public.is_pasteur()
        OR fidele_id IN (
            SELECT id FROM public.fideles WHERE tribu_id = public.get_user_tribu_id()
        )
    );

-- ============================================
-- POLITIQUES POUR LA TABLE SESSIONS_APPEL
-- ============================================

-- Lecture:
-- - Le pasteur voit toutes les sessions
-- - Le patriarche voit les sessions de sa tribu
-- - Le responsable voit les sessions de son département
CREATE POLICY "sessions_select" ON public.sessions_appel
    FOR SELECT
    USING (
        public.is_pasteur()
        OR (type_groupe = 'tribu' AND groupe_id = public.get_user_tribu_id())
        OR (type_groupe = 'departement' AND groupe_id = public.get_user_departement_id())
    );

-- Insertion:
-- - Le patriarche peut créer des sessions pour sa tribu
-- - Le responsable peut créer des sessions pour son département
CREATE POLICY "sessions_insert" ON public.sessions_appel
    FOR INSERT
    WITH CHECK (
        public.is_pasteur()
        OR (type_groupe = 'tribu' AND groupe_id = public.get_user_tribu_id())
        OR (type_groupe = 'departement' AND groupe_id = public.get_user_departement_id())
    );

-- Suppression: seul le pasteur
CREATE POLICY "sessions_delete" ON public.sessions_appel
    FOR DELETE
    USING (public.is_pasteur());

-- ============================================
-- POLITIQUES POUR LA TABLE PRESENCES
-- ============================================

-- Lecture: via la session associée
CREATE POLICY "presences_select" ON public.presences
    FOR SELECT
    USING (
        session_id IN (
            SELECT id FROM public.sessions_appel
            WHERE public.is_pasteur()
            OR (type_groupe = 'tribu' AND groupe_id = public.get_user_tribu_id())
            OR (type_groupe = 'departement' AND groupe_id = public.get_user_departement_id())
        )
    );

-- Insertion: via la session associée
CREATE POLICY "presences_insert" ON public.presences
    FOR INSERT
    WITH CHECK (
        session_id IN (
            SELECT id FROM public.sessions_appel
            WHERE public.is_pasteur()
            OR (type_groupe = 'tribu' AND groupe_id = public.get_user_tribu_id())
            OR (type_groupe = 'departement' AND groupe_id = public.get_user_departement_id())
        )
    );

-- Mise à jour: via la session associée
CREATE POLICY "presences_update" ON public.presences
    FOR UPDATE
    USING (
        session_id IN (
            SELECT id FROM public.sessions_appel
            WHERE public.is_pasteur()
            OR (type_groupe = 'tribu' AND groupe_id = public.get_user_tribu_id())
            OR (type_groupe = 'departement' AND groupe_id = public.get_user_departement_id())
        )
    );

-- Suppression: seul le pasteur
CREATE POLICY "presences_delete" ON public.presences
    FOR DELETE
    USING (public.is_pasteur());
