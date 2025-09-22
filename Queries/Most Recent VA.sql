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
),

latest_visits AS (
SELECT 
    patient__c,
    MAX(createddate) as most_recent_visit_date  
FROM sf_clinic_visit
GROUP BY patient__c
),

ranked_va AS (
SELECT 
    cv.patient__c,
    cv.id as clinic_visit_id,
    cv.createddate,  
    cvo.distance_numerator__c, 
    cvo.acuity_measurement__c,
    CONCAT(cvo.distance_numerator__c, cvo.acuity_measurement__c) as va_value,
    cvo.laterality__c,
    cvo.viewing_distance_type__c,
    cvo.acuity_modifier__c,
    cvo.acuity_type__c,
    ROW_NUMBER() OVER (
        PARTITION BY cv.patient__c 
        ORDER BY cvo.distance_numerator__c ASC, cvo.laterality__c
    ) as va_rank
FROM sf_clinic_visit cv
INNER JOIN latest_visits lv ON cv.patient__c = lv.patient__c AND cv.createddate = lv.most_recent_visit_date
INNER JOIN sf_clinic_visit_outcome cvo ON cv.id = cvo.clinic_visit__c
)
SELECT 
    p.id "id_pt",
    p.pe_name,
    p.pr_name,
    p.sf_status,
    CAST(rva.createddate AS DATE) encounter_date,
    rva.clinic_visit_id as id,
    rva.distance_numerator__c, 
    rva.acuity_measurement__c,
    rva.va_value,
CASE 
    WHEN rva.va_value IN ('20/20', '20/15', '20/10') THEN '20/20 or Better'
    WHEN rva.va_value IN ('20/25', '20/30', '20/35') THEN '20/40 to <20/20'
    WHEN rva.va_value IN ('20/40', '20/45', '20/50', '20/55') THEN '20/60 to <20/40'
    WHEN rva.va_value IN ('20/60', '20/65', '20/70', '20/75') THEN '20/60 to <20/80'
    WHEN rva.va_value IN ('20/80', '20/85', '20/90', '20/95', '20/100', '20/105', '20/110', '20/115', '20/120', '20/125', 
    '20/130', '20/135', '20/140', '20/145', '20/150', '20/155', '20/160', '20/165', '20/170', '20/175', '20/180', '20/185', '20/190', '20/195') THEN '20/80 to <20/200'
    WHEN rva.va_value LIKE '20/%' 
         AND rva.va_value NOT LIKE '%[^0-9/]%'
         AND TRY_CAST(SUBSTRING(rva.va_value, 4) AS INTEGER) >= 200 THEN 'Worse than 20/200'
    ELSE rva.acuity_measurement__c
END as va_category,
    rva.laterality__c,
    rva.viewing_distance_type__c,
    rva.acuity_modifier__c,
    rva.acuity_type__c,
    p.date_enrolled,
    p.id_primary_dx,
    p.id_secondary_dx,
    p.id_tertiary_dx,
    dx1.code "dx1.code",
    dx2.code "dx2.code",
    dx3.code "dx3.code",
    pts_iz.tf_izervay_in_text,
    CASE WHEN (dx1.code IN ('H35.3113', 'H35.3114', 'H35.3123', 'H35.3124', 'H35.3133', 'H35.3134')
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
LEFT JOIN ranked_va rva
    on p.id = rva.patient__c AND rva.va_rank = 1  
WHERE p.sf_status = 'Active'
AND p.date_enrolled < DATE '2025-08-01'
AND (dx1.code IN ('H35.3113', 'H35.3114', 'H35.3123', 'H35.3124', 'H35.3133', 'H35.3134')
    OR dx2.code IN ('H35.3113', 'H35.3114', 'H35.3123', 'H35.3124', 'H35.3133', 'H35.3134')
    OR dx3.code IN ('H35.3113', 'H35.3114', 'H35.3123', 'H35.3124', 'H35.3133', 'H35.3134'))
--AND rva.acuity_measurement__c IS NOT NULL
--AND rva.acuity_type__c = 'sc'
--AND pts_iz.tf_izervay_in_text = TRUE
ORDER BY p.id ASC

