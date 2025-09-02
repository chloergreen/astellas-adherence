WITH pts_iz AS
(
SELECT
    patient_person_account__c,
    BOOL_OR(
        LOWER(coordinator_summary_of_care_call__c) LIKE '%izervay%' OR
        LOWER(patient_history_with_condition__c) LIKE '%izervay%' OR
        LOWER(patient_medication_regimen__c) LIKE '%izervay%' OR
        LOWER(encounter_summary__c) LIKE '%izervay%' OR
        LOWER(description_of_support__c) LIKE '%izervay%' OR
        LOWER(care_plan_goals__c) LIKE '%izervay%'
    ) AS tf_izervay_in_text
FROM sf_lumata_encounter
GROUP BY patient_person_account__c
)
-- no distinct because a patient could have the same barrier on multiple different encounters
SELECT 
    p.id "id_pt",
    p.pe_name,
    p.pr_name,
    p.sf_status,
    p.date_enrolled,
    p.date_unenrolled,
    p.id_primary_dx,
    p.id_secondary_dx,
    p.id_tertiary_dx,
    dx1.id "dx1_id",
    dx2.id "dx2_id",
    dx3.id "dx3_id",
    dx1.code "dx1.code",
    dx2.code "dx2.code",
    dx3.code "dx3.code",
    dx1.dx_specialty "dx1.specialty",
    dx2.dx_specialty "dx2.specialty",
    dx3.dx_specialty "dx3.specialty",
    dx1.dx_name "dx1.name",
    dx2.dx_name "dx2.name",
    dx3.dx_name "dx3.name",
    dx1.dx_short_name "dx1.short_name",
    dx2.dx_short_name "dx2.short_name",
    dx3.dx_short_name "dx3.short_name",
    pts_iz.tf_izervay_in_text,
    c.name,
CASE 
    WHEN LOWER(c.name) LIKE '%knowledge%' AND LOWER(c.name) LIKE '%deficit%' AND (LOWER(c.name) LIKE '%disease%' OR LOWER(c.name) LIKE '%AMD%' OR LOWER(c.name) LIKE '%educational materials%' OR LOWER(c.name) LIKE '%knowledge of%' OR LOWER(c.name) LIKE '%provide education%' OR LOWER(c.name) LIKE '%diagnosis%')
        THEN 'knowledge deficit of disease management'
    WHEN LOWER(c.name) LIKE '%knowledge%' AND LOWER(c.name) LIKE '%deficit%' AND LOWER(c.name) LIKE '%medication%'
        THEN 'knowledge deficit of medication management'
    WHEN LOWER(c.name) LIKE '%knowledge%' AND (LOWER(c.name) LIKE '%low%' OR LOWER(c.name) LIKE '%vision%' OR LOWER(c.name) LIKE '%low vision%')
        THEN 'knowledge deficit of functioning with low vision'
    WHEN LOWER(c.name) LIKE '%knowledge%' AND LOWER(c.name) LIKE '%treatment%'
        THEN 'knowledge deficit of need for treatment'
    WHEN (LOWER(c.name) LIKE '%educational%' OR LOWER(c.name) LIKE '%educate%' OR LOWER(c.name) LIKE '%education%')
        THEN 'education'
    WHEN ((LOWER(c.name) LIKE '%knowledge%' AND LOWER(c.name) LIKE '%deficit%') OR LOWER(c.name) LIKE '%unsure%' OR LOWER(c.name) LIKE '%doesn''t know%' OR LOWER(c.name) LIKE '%does not understand%')
        THEN 'knowledge'
    WHEN (LOWER(c.name) LIKE '%amsler%' OR LOWER(c.name) LIKE '%grid%') 
        THEN 'knowledge deficit of amsler grid'
    WHEN (LOWER(c.name) LIKE '%appointment%' OR LOWER(c.name) LIKE '%appt%' OR LOWER(c.name) LIKE '%appts%' OR LOWER(c.name) LIKE '%scheduling%' OR LOWER(c.name) LIKE '%apprehension related to testing/follow up%' ) 
        THEN 'scheduling'
    WHEN (LOWER(c.name) LIKE '%compliance%'  OR LOWER(c.name) LIKE '%difficulty%' OR LOWER(c.name) LIKE '%difficult%' OR LOWER(c.name) LIKE '%areds%' OR LOWER(c.name) LIKE '%areds 2%' OR LOWER(c.name) LIKE '%non-compliant%' OR LOWER(c.name) LIKE '%non compliant%' OR LOWER(c.name) LIKE '%refills%') 
        THEN 'prescription'
    WHEN (LOWER(c.name) LIKE '%can''t%' OR LOWER(c.name) LIKE '%transportation%' OR LOWER(c.name) LIKE '%Transportation%' OR LOWER(c.name) LIKE '%ride%' OR LOWER(c.name) LIKE '%rides%' OR LOWER(c.name) LIKE '%drive%') 
        THEN 'transportation'
    WHEN (LOWER(c.name) LIKE '%cost%' OR LOWER(c.name) LIKE '%afford%' OR LOWER(c.name) LIKE '%$%' OR LOWER(c.name) LIKE '%Cost of AREDS%' OR LOWER(c.name) LIKE '%financial%' OR LOWER(c.name) LIKE '%pay%' OR LOWER(c.name) LIKE '%coupon%' OR LOWER(c.name) LIKE '%coupons%' OR LOWER(c.name) LIKE '%expensive%' OR LOWER(c.name) LIKE '%gtts%' OR LOWER(c.name) LIKE '%drops%' OR LOWER(c.name) LIKE '%Financial Strain: Medication Cost%') 
        THEN 'financial strain'
    WHEN (LOWER(c.name) LIKE '%depression%' OR LOWER(c.name) LIKE '%confidence%' OR LOWER(c.name) LIKE '%flexibility%' OR LOWER(c.name) LIKE '%coping skills%' OR LOWER(c.name) LIKE '%motivation%' OR LOWER(c.name) LIKE '%exclusion%' OR LOWER(c.name) LIKE '%social depravation%' OR LOWER(c.name) LIKE '%mobility%' OR LOWER(c.name) LIKE '%fear%' OR LOWER(c.name) LIKE '%scared%' OR LOWER(c.name) LIKE '%loss%' OR LOWER(c.name) LIKE '%grief%' OR LOWER(c.name) LIKE '%lack of trust%' OR LOWER(c.name) LIKE '%lack of support%' OR LOWER(c.name) LIKE '%depravation%' OR LOWER(c.name) LIKE '%afraid%' OR LOWER(c.name) LIKE '%reluctance%' OR LOWER(c.name) LIKE '%resistant%' OR LOWER(c.name) LIKE '%reluctant%' OR LOWER(c.name) LIKE '%resistantance%' OR LOWER(c.name) LIKE '%poor communication%' OR LOWER(c.name)LIKE '%negative self perceptions%' OR LOWER(c.name)LIKE '%lone%' OR LOWER(c.name)LIKE '%mental health resources%') 
        THEN 'psychosocial'
    WHEN (LOWER(c.name) LIKE '%adaptive%' OR LOWER(c.name) LIKE '%equipment%')
        THEN 'lack of adaptive equipment'
    WHEN (LOWER(c.name) LIKE '%glaucoma%' OR LOWER(c.name) LIKE '%comorbidities%' OR LOWER(c.name) LIKE '%chemo%' OR LOWER(c.name) LIKE '%dm%' OR LOWER(c.name) LIKE '%glc%' OR LOWER(c.name) LIKE '%dementia%' OR LOWER(c.name) LIKE '%diabetes%' OR LOWER(c.name) LIKE '%memory%'  OR LOWER(c.name) LIKE '%cancer%' OR LOWER(c.name) LIKE '%POAG%' OR LOWER(c.name) LIKE '%parkinson''s%' OR LOWER(c.name) LIKE '%apnea%' OR LOWER(c.name) LIKE '%diabetic%' OR LOWER(c.name) LIKE '%retinopathy%' OR LOWER(c.name) LIKE '%npdr%' OR LOWER(c.name) LIKE '%wheelchair%' OR LOWER(c.name) LIKE '%surgery%' OR LOWER(c.name) LIKE '%BS%' OR LOWER(c.name) LIKE '%a1c%')
        THEN 'comorbidities'
    WHEN LOWER(c.name) LIKE '%language%' 
        THEN 'language'
    WHEN (LOWER(c.name) LIKE '%cf%' OR LOWER(c.name) LIKE '%nlp%' OR LOWER(c.name) LIKE '%low vision%'  OR LOWER(c.name) LIKE '%decreased ability to perform%' OR LOWER(c.name) LIKE '%blind%' OR LOWER(c.name) LIKE '%education%' AND (LOWER(c.name) LIKE '%decreased%' OR LOWER(c.name) LIKE '%poor%' OR LOWER(c.name) LIKE '%daily living%' OR LOWER(c.name) LIKE '%assistive%' OR LOWER(c.name) LIKE '%low vision%'))
        THEN 'low vision/ ADLs'
    WHEN LOWER(c.name) LIKE '%caregiver%' OR LOWER(c.name) LIKE '%caregiver strain%'
        THEN 'caregiver'
    WHEN LOWER(c.name) LIKE '%food%' OR LOWER(c.name) LIKE '%lack of healthy foods%' OR LOWER(c.name) LIKE '%literacy%' OR LOWER(c.name) LIKE '%lack of access to ppe%'
        THEN 'lifestyle'
    WHEN LOWER(c.name) LIKE '%provider%' OR LOWER(c.name) LIKE '%staff%'
        THEN 'trust in provider'
    WHEN LOWER(c.name) LIKE '%mvt non-adherence%' THEN 'mVT'
    ELSE 'other'
END AS category,
CASE 
        WHEN (dx1.code IN ('H35.3113', 'H35.3114', 'H35.3123', 'H35.3124', 'H35.3133', 'H35.3134')
            OR dx2.code IN ('H35.3113', 'H35.3114', 'H35.3123', 'H35.3124', 'H35.3133', 'H35.3134')
            OR dx3.code IN ('H35.3113', 'H35.3114', 'H35.3123', 'H35.3124', 'H35.3133', 'H35.3134')) 
        THEN TRUE
        ELSE FALSE
    END tf_has_ga
FROM patients_demog p
LEFT JOIN dxs as dx1 
    on p.id_primary_dx = dx1.id
LEFT JOIN dxs as dx2 
    on p.id_secondary_dx = dx2.id
LEFT JOIN dxs as dx3 
    on p.id_tertiary_dx = dx3.id
LEFT JOIN care_barriers c
    on p.id = c.id_patient
LEFT JOIN pts_iz 
    on p.id = pts_iz.patient_person_account__c
WHERE p.sf_status = 'Active'
AND p.date_enrolled < DATE '2025-08-01'
AND p.date_unenrolled IS NULL
AND (dx1.code IN ('H35.3113', 'H35.3114', 'H35.3123', 'H35.3124', 'H35.3133', 'H35.3134')
    OR dx2.code IN ('H35.3113', 'H35.3114', 'H35.3123', 'H35.3124', 'H35.3133', 'H35.3134')
    OR dx3.code IN ('H35.3113', 'H35.3114', 'H35.3123', 'H35.3124', 'H35.3133', 'H35.3134'))
ORDER BY p.id ASC
