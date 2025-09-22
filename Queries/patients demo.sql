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
    p.gender,
    p.race,
    DATE_DIFF('year', CAST(s.personbirthdate AS DATE), current_date) as age,
CASE 
    WHEN DATE_DIFF('year', CAST(s.personbirthdate AS DATE), current_date) < 65 THEN '<65 Years'
    WHEN DATE_DIFF('year', CAST(s.personbirthdate AS DATE), current_date) BETWEEN 65 AND 69 THEN '65-69 Years'
    WHEN DATE_DIFF('year', CAST(s.personbirthdate AS DATE), current_date) BETWEEN 70 AND 74 THEN '70-74 Years'
    WHEN DATE_DIFF('year', CAST(s.personbirthdate AS DATE), current_date) BETWEEN 75 AND 79 THEN '75-79 Years'
    WHEN DATE_DIFF('year', CAST(s.personbirthdate AS DATE), current_date) BETWEEN 80 AND 84 THEN '80-84 Years'
    WHEN DATE_DIFF('year', CAST(s.personbirthdate AS DATE), current_date) BETWEEN 85 AND 89 THEN '85-89 Years'
    WHEN DATE_DIFF('year', CAST(s.personbirthdate AS DATE), current_date) >= 90 THEN '90+ Years'
    END as age_group,
    p.pe_name,
    p.pr_name,
    p.sf_status,
    p.date_enrolled,
    s.billingstate,
CASE 
    WHEN s.billingstate in ()
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
LEFT JOIN pts_iz 
    on p.id = pts_iz.patient_person_account__c
LEFT JOIN sf_account s
    on p.id = s.id
WHERE p.sf_status = 'Active'
AND p.date_enrolled < DATE '2025-08-01'
AND (dx1.code IN ('H35.3113', 'H35.3114', 'H35.3123', 'H35.3124', 'H35.3133', 'H35.3134')
    OR dx2.code IN ('H35.3113', 'H35.3114', 'H35.3123', 'H35.3124', 'H35.3133', 'H35.3134')
    OR dx3.code IN ('H35.3113', 'H35.3114', 'H35.3123', 'H35.3124', 'H35.3133', 'H35.3134'))
--AND tf_izervay_in_text = TRUE
ORDER BY p.id ASC
