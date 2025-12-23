DROP TABLE IF EXISTS clean.property_fy2024;


CREATE TABLE clean.property_fy2024 AS
WITH base AS (
  SELECT
    pid, gis_id, st_num, st_name, unit_num, city, zip_code, lu, lu_desc,
    regexp_replace(total_value::text, '[^0-9.\-]', '', 'g')  AS total_value_s,
    regexp_replace(living_area::text, '[^0-9.\-]', '', 'g')  AS living_area_s,
    regexp_replace(gross_tax::text,  '[^0-9.\-]', '', 'g')   AS gross_tax_s
  FROM raw.property_assessment_fy2024
),
cleaned AS (
  SELECT
    pid, gis_id, st_num, st_name, unit_num, city, zip_code, lu, lu_desc,
    CASE WHEN total_value_s  ~ '^-?\d+(\.\d+)?$' THEN total_value_s::numeric  END AS total_value,
    CASE WHEN living_area_s  ~ '^-?\d+(\.\d+)?$' THEN living_area_s::numeric  END AS living_area,
    CASE WHEN gross_tax_s    ~ '^-?\d+(\.\d+)?$' THEN gross_tax_s::numeric    END AS gross_tax
  FROM base
)
SELECT
  *,
  CASE
    WHEN living_area > 0 AND total_value IS NOT NULL
    THEN total_value / living_area
  END AS value_per_sqft
FROM cleaned;

SELECT table_schema, table_name
FROM information_schema.tables
WHERE table_name = 'property_fy2024'
ORDER BY table_schema;

SET search_path TO clean, public;

SELECT COUNT(*) FROM property_fy2024;


CREATE OR REPLACE VIEW analytics.vw_zip_lu_summary AS
SELECT
  zip_code,
  lu_desc,
  COUNT(*) AS property_count,
  SUM(total_value) AS total_assessed_value,
  percentile_cont(0.5) WITHIN GROUP (ORDER BY total_value) AS median_total_value,
  percentile_cont(0.5) WITHIN GROUP (ORDER BY value_per_sqft) AS median_value_per_sqft
FROM clean.property_fy2024
WHERE total_value IS NOT NULL
GROUP BY 1,2;

CREATE OR REPLACE VIEW analytics.vw_zip_vpsf_distribution AS
SELECT
  zip_code,
  COUNT(*) AS n,
  percentile_cont(0.25) WITHIN GROUP (ORDER BY value_per_sqft) AS p25_vpsf,
  percentile_cont(0.5)  WITHIN GROUP (ORDER BY value_per_sqft) AS median_vpsf,
  percentile_cont(0.75) WITHIN GROUP (ORDER BY value_per_sqft) AS p75_vpsf
FROM clean.property_fy2024
WHERE value_per_sqft IS NOT NULL
GROUP BY 1;

CREATE OR REPLACE VIEW analytics.vw_value_per_sqft_outliers AS
WITH ranked AS (
  SELECT
    pid, st_num, st_name, unit_num, city, zip_code, lu_desc,
    total_value, living_area, value_per_sqft,
    NTILE(100) OVER (ORDER BY value_per_sqft) AS vpsf_pct
  FROM clean.property_fy2024
  WHERE value_per_sqft IS NOT NULL
)
SELECT *
FROM ranked
WHERE vpsf_pct IN (1, 100);

SELECT COUNT(*) FROM analytics.vw_zip_lu_summary;

SELECT COUNT(*) FROM analytics.vw_value_per_sqft_outliers;


