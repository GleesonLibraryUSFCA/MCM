--searches 856 tag for text in url
--record location must match 'gint'
SELECT DISTINCT
    'b' || b.record_num || 'a' AS bibnumber, 
    v_856.field_content AS url,
    bibloc.location_code AS locationcode
FROM sierra_view.bib_view b
INNER JOIN sierra_view.varfield v_856 ON b.id = v_856.record_id
INNER JOIN sierra_view.bib_record_location bibloc ON b.id = bibloc.bib_record_id
WHERE bibloc.location_code = 'gint'
    AND v_856.marc_tag = '856'
--if url contains _ or %, add \ first to ESCAPE. Ex: \_ or \%
    AND v_856.field_content ILIKE '%heinonline%' ESCAPE '\'
           ;