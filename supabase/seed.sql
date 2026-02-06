-- ============================================
-- DONNÉES DE TEST / SEED
-- Application de Gestion d'Église
-- ============================================
-- ATTENTION: Exécuter APRÈS schema.sql et rls_policies.sql
-- Les IDs des users doivent correspondre aux auth.users créés via Supabase Auth

-- ============================================
-- 1. TRIBUS (créer d'abord sans patriarche)
-- ============================================

INSERT INTO public.tribus (id, nom, description) VALUES
    ('11111111-1111-1111-1111-111111111111', 'Tribu de Juda', 'Première tribu de l''église'),
    ('22222222-2222-2222-2222-222222222222', 'Tribu de Lévi', 'Tribu des louanges'),
    ('33333333-3333-3333-3333-333333333333', 'Tribu de Benjamin', 'Tribu des jeunes');

-- ============================================
-- 2. DÉPARTEMENTS (créer d'abord sans responsable)
-- ============================================

INSERT INTO public.departements (id, nom, description) VALUES
    ('aaaa1111-1111-1111-1111-111111111111', 'Chorale', 'Département de la chorale'),
    ('aaaa2222-2222-2222-2222-222222222222', 'Protocole', 'Département du protocole et accueil'),
    ('aaaa3333-3333-3333-3333-333333333333', 'Jeunesse', 'Département de la jeunesse'),
    ('aaaa4444-4444-4444-4444-444444444444', 'Intercession', 'Département de prière');

-- ============================================
-- 3. FIDÈLES
-- ============================================

-- Tribu de Juda
INSERT INTO public.fideles (id, nom, prenom, sexe, jour_naissance, mois_naissance, telephone, adresse, profession, tribu_id) VALUES
    ('f1111111-1111-1111-1111-111111111111', 'KAMGA', 'Pierre', 'M', 15, 3, '699000001', 'Douala, Akwa', 'Ingénieur', '11111111-1111-1111-1111-111111111111'),
    ('f1111111-2222-2222-2222-222222222222', 'NANA', 'Marie', 'F', 22, 7, '699000002', 'Douala, Bonanjo', 'Médecin', '11111111-1111-1111-1111-111111111111'),
    ('f1111111-3333-3333-3333-333333333333', 'FOTSO', 'Jean', 'M', 10, 12, '699000003', 'Douala, Deido', 'Comptable', '11111111-1111-1111-1111-111111111111'),
    ('f1111111-4444-4444-4444-444444444444', 'TCHAMDA', 'Esther', 'F', 5, 1, '699000004', 'Douala, Bonapriso', 'Enseignante', '11111111-1111-1111-1111-111111111111'),
    ('f1111111-5555-5555-5555-555555555555', 'MBARGA', 'Paul', 'M', 28, 9, '699000005', 'Douala, Akwa Nord', 'Commercial', '11111111-1111-1111-1111-111111111111');

-- Tribu de Lévi
INSERT INTO public.fideles (id, nom, prenom, sexe, jour_naissance, mois_naissance, telephone, adresse, profession, tribu_id) VALUES
    ('f2222222-1111-1111-1111-111111111111', 'TALLA', 'Samuel', 'M', 18, 5, '699000006', 'Douala, Bali', 'Musicien', '22222222-2222-2222-2222-222222222222'),
    ('f2222222-2222-2222-2222-222222222222', 'DJOMOU', 'Rachel', 'F', 3, 8, '699000007', 'Douala, Bonamoussadi', 'Infirmière', '22222222-2222-2222-2222-222222222222'),
    ('f2222222-3333-3333-3333-333333333333', 'KEMGANG', 'David', 'M', 12, 11, '699000008', 'Douala, Makepe', 'Pasteur associé', '22222222-2222-2222-2222-222222222222'),
    ('f2222222-4444-4444-4444-444444444444', 'MBOUDA', 'Grâce', 'F', 25, 4, '699000009', 'Douala, Logpom', 'Secrétaire', '22222222-2222-2222-2222-222222222222');

-- Tribu de Benjamin
INSERT INTO public.fideles (id, nom, prenom, sexe, jour_naissance, mois_naissance, telephone, adresse, profession, tribu_id) VALUES
    ('f3333333-1111-1111-1111-111111111111', 'NGUEMO', 'Daniel', 'M', 7, 6, '699000010', 'Douala, Kotto', 'Étudiant', '33333333-3333-3333-3333-333333333333'),
    ('f3333333-2222-2222-2222-222222222222', 'TAGNE', 'Ruth', 'F', 14, 2, '699000011', 'Douala, Ndogbong', 'Étudiante', '33333333-3333-3333-3333-333333333333'),
    ('f3333333-3333-3333-3333-333333333333', 'FOUDA', 'Emmanuel', 'M', 30, 10, '699000012', 'Douala, PK14', 'Technicien', '33333333-3333-3333-3333-333333333333');

-- ============================================
-- 4. MISE À JOUR DES PATRIARCHES
-- ============================================

UPDATE public.tribus SET patriarche_id = 'f1111111-1111-1111-1111-111111111111' WHERE id = '11111111-1111-1111-1111-111111111111';
UPDATE public.tribus SET patriarche_id = 'f2222222-1111-1111-1111-111111111111' WHERE id = '22222222-2222-2222-2222-222222222222';
UPDATE public.tribus SET patriarche_id = 'f3333333-1111-1111-1111-111111111111' WHERE id = '33333333-3333-3333-3333-333333333333';

-- ============================================
-- 5. MISE À JOUR DES RESPONSABLES DE DÉPARTEMENT
-- ============================================

UPDATE public.departements SET responsable_id = 'f2222222-1111-1111-1111-111111111111' WHERE id = 'aaaa1111-1111-1111-1111-111111111111'; -- Chorale
UPDATE public.departements SET responsable_id = 'f1111111-2222-2222-2222-222222222222' WHERE id = 'aaaa2222-2222-2222-2222-222222222222'; -- Protocole
UPDATE public.departements SET responsable_id = 'f3333333-1111-1111-1111-111111111111' WHERE id = 'aaaa3333-3333-3333-3333-333333333333'; -- Jeunesse
UPDATE public.departements SET responsable_id = 'f2222222-3333-3333-3333-333333333333' WHERE id = 'aaaa4444-4444-4444-4444-444444444444'; -- Intercession

-- ============================================
-- 6. ASSOCIATIONS FIDÈLES-DÉPARTEMENTS
-- ============================================

-- Chorale
INSERT INTO public.fidele_departements (fidele_id, departement_id) VALUES
    ('f2222222-1111-1111-1111-111111111111', 'aaaa1111-1111-1111-1111-111111111111'),
    ('f2222222-2222-2222-2222-222222222222', 'aaaa1111-1111-1111-1111-111111111111'),
    ('f1111111-4444-4444-4444-444444444444', 'aaaa1111-1111-1111-1111-111111111111'),
    ('f3333333-2222-2222-2222-222222222222', 'aaaa1111-1111-1111-1111-111111111111');

-- Protocole
INSERT INTO public.fidele_departements (fidele_id, departement_id) VALUES
    ('f1111111-2222-2222-2222-222222222222', 'aaaa2222-2222-2222-2222-222222222222'),
    ('f1111111-3333-3333-3333-333333333333', 'aaaa2222-2222-2222-2222-222222222222'),
    ('f2222222-4444-4444-4444-444444444444', 'aaaa2222-2222-2222-2222-222222222222');

-- Jeunesse
INSERT INTO public.fidele_departements (fidele_id, departement_id) VALUES
    ('f3333333-1111-1111-1111-111111111111', 'aaaa3333-3333-3333-3333-333333333333'),
    ('f3333333-2222-2222-2222-222222222222', 'aaaa3333-3333-3333-3333-333333333333'),
    ('f3333333-3333-3333-3333-333333333333', 'aaaa3333-3333-3333-3333-333333333333');

-- Intercession
INSERT INTO public.fidele_departements (fidele_id, departement_id) VALUES
    ('f2222222-3333-3333-3333-333333333333', 'aaaa4444-4444-4444-4444-444444444444'),
    ('f1111111-1111-1111-1111-111111111111', 'aaaa4444-4444-4444-4444-444444444444'),
    ('f2222222-4444-4444-4444-444444444444', 'aaaa4444-4444-4444-4444-444444444444');

-- ============================================
-- 7. EXEMPLE DE SESSION D'APPEL ET PRÉSENCES
-- ============================================
-- Note: Nécessite un user valide, donc commenté par défaut

/*
-- Exemple de session pour la tribu de Juda
INSERT INTO public.sessions_appel (id, date, type_groupe, groupe_id, created_by) VALUES
    ('s1111111-1111-1111-1111-111111111111', CURRENT_DATE - INTERVAL '7 days', 'tribu', '11111111-1111-1111-1111-111111111111', 'USER_ID_ICI');

-- Présences pour cette session
INSERT INTO public.presences (session_id, fidele_id, statut) VALUES
    ('s1111111-1111-1111-1111-111111111111', 'f1111111-1111-1111-1111-111111111111', 'present'),
    ('s1111111-1111-1111-1111-111111111111', 'f1111111-2222-2222-2222-222222222222', 'present'),
    ('s1111111-1111-1111-1111-111111111111', 'f1111111-3333-3333-3333-333333333333', 'absent'),
    ('s1111111-1111-1111-1111-111111111111', 'f1111111-4444-4444-4444-444444444444', 'present'),
    ('s1111111-1111-1111-1111-111111111111', 'f1111111-5555-5555-5555-555555555555', 'absent');
*/

-- ============================================
-- VÉRIFICATION
-- ============================================

-- Affiche le résumé des données insérées
SELECT 'Tribus' as table_name, COUNT(*) as count FROM public.tribus
UNION ALL
SELECT 'Départements', COUNT(*) FROM public.departements
UNION ALL
SELECT 'Fidèles', COUNT(*) FROM public.fideles
UNION ALL
SELECT 'Fidèle-Départements', COUNT(*) FROM public.fidele_departements;
