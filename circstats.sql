--Circ stats
SELECT 
    -- SELECT tells the database which columns we want to see in our results
    'b' || bv.record_num || 'a' AS bibnumber,  -- Create human-readable bib number like "b1234567a"
    bv.title AS title,  -- Show the title
    b.cataloging_date_gmt::date AS bib_creation_date,  -- Show only the date (YYYY-MM-DD format), not the time
    brp.publish_year AS year_published,  -- Show the publication year from the bib record
    udb.name AS bcode2_name,  -- Show the bibliographic level name (e.g., "Monograph", "Serial")
    MIN(REPLACE(REPLACE(v.field_content, '|a', ''), '|b', ' ')) AS call_number,  -- Show the first call number (alphabetically), stripping MARC subfield delimiters
    MIN(REPLACE(REPLACE(REPLACE(REPLACE(v.field_content, '|a', ''), '|b', ''), '|', ''), ' ', '')) AS call_number_sort,  -- Sortable version: strip all subfield delimiters and spaces for proper shelf order
    MAX(l.code) AS location_code,  -- Show the location code (using MAX since they're all the same)
    MAX(ln.name) AS location_name,  -- Show the full location name (using MAX since they're all the same)
    COUNT(DISTINCT i.id) AS item_count,  -- Count how many items this bib has at this location
    SUM(COALESCE(i.checkout_total, 0)) AS checkout_count_all_time,  -- Sum all checkout_total values across items (all-time checkouts); COALESCE turns NULLs into 0
    SUM(COALESCE(i.year_to_date_checkout_total, 0)) AS checkout_count_year_to_date,  -- Sum year-to-date checkouts
    SUM(COALESCE(i.last_year_to_date_checkout_total, 0)) AS checkout_count_last_year,  -- Sum last year's checkouts
    MAX(i.last_checkin_gmt)::date AS most_recent_checkin,  -- Most recent checkin date across all items on this bib; ::date strips the time portion
    CASE WHEN MAX(v583.id) IS NOT NULL THEN 'Yes' ELSE 'No' END AS has_scelc_583,  -- 'Yes' if any MARC 583 field containing "scelc" exists on this bib, 'No' if not
    CASE WHEN MAX(v962.id) IS NOT NULL THEN 'Yes' ELSE 'No' END AS has_marc_962  -- 'Yes' if any MARC 962 field exists on this bib, 'No' if not

FROM 
    -- FROM tells the database which table to start with
    sierra_view.bib_record AS b  -- Start with the bib_record table, give it a short nickname "b"
    INNER JOIN sierra_view.bib_view AS bv  -- Connect to bib_view to get the record number and title
        ON b.id = bv.id  -- Match using the internal ID
    INNER JOIN sierra_view.bib_record_property AS brp  -- Connect to bib_record_property to get publication year
        ON b.id = brp.bib_record_id  -- Match using the bib record ID
    LEFT JOIN sierra_view.user_defined_bcode2_myuser AS udb  -- Connect to the bcode2 user-defined table to get the bibliographic level name
        ON b.bcode2 = udb.code  -- Match the bcode2 code to get its name; LEFT JOIN so bibs without a bcode2 match are still included
    INNER JOIN sierra_view.varfield AS v  -- Connect to the varfield table to get call numbers
        ON b.id = v.record_id  -- Match when the bib record ID equals the varfield's record ID
        AND v.varfield_type_code = 'c'  -- Only get varfields that are call numbers (type 'c')
    LEFT JOIN sierra_view.varfield AS v583  -- Separate join back to varfield, this time looking for MARC 583 fields
        ON b.id = v583.record_id  -- Match on the bib record ID
        AND v583.varfield_type_code = 'n'  -- Only get varfields that are MARC 583 action notes (type 'n')
        AND v583.marc_tag = '583'
        AND LOWER(v583.field_content) LIKE '%scelc%'  -- Only match 583s that contain the word "scelc" (case-insensitive)
        -- LEFT JOIN so bibs without any matching 583 fields are still included in results
    LEFT JOIN sierra_view.varfield AS v962  -- Separate join back to varfield, this time looking for MARC 962 fields
        ON b.id = v962.record_id  -- Match on the bib record ID
        AND v962.varfield_type_code = 'y'  -- Only get varfields with type code 'y' (local use fields)
        AND v962.marc_tag = '962'  -- Disambiguate from other tags sharing the same type code
        -- LEFT JOIN so bibs without any 962 fields are still included in results
    INNER JOIN sierra_view.bib_record_item_record_link AS brl  -- Connect to the link table that associates bibs with items
        ON b.id = brl.bib_record_id  -- Match the bib record ID
    INNER JOIN sierra_view.item_record AS i  -- Connect to the item_record table to get item-level data
        ON brl.item_record_id = i.id  -- Match using the item record ID from the link table
    LEFT JOIN sierra_view.location AS l  -- Connect to the location table to get the location code
        ON i.location_code = l.code  -- Match the item's location code with the location table
    LEFT JOIN sierra_view.location_name AS ln  -- Connect to the location_name table to get the full location name
        ON l.id = ln.location_id  -- Match the location ID to get the full location name

WHERE 
    -- WHERE filters which rows to include based on conditions
    i.location_code = 'gmain'  -- Only include items with the location code 'gmain'
    AND b.is_suppressed = FALSE  -- Only include records that are not suppressed (visible to public)

GROUP BY 
    -- GROUP BY combines rows that have the same values in these columns into a single result row
    -- This groups all items from the same bib together so we can sum their checkouts
    bv.record_num,  -- Group by the record number from bib_view
    bv.title,  -- Group by title
    b.cataloging_date_gmt,  -- Group by creation date (full timestamp for grouping)
    brp.publish_year,  -- Group by publication year
    udb.name  -- Group by bibliographic level name

ORDER BY 
    -- ORDER BY sorts the final results
    call_number_sort;  -- Sort by the cleaned call number (no spaces or delimiters)