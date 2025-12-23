SELECT COUNT(*) FROM analytics.vw_zip_lu_summary;

-- Create the “peer-based mispricing” audit view
CREATE OR REPLACE VIEW analytics.vw_peer_mispricing_audit AS
WITH base AS (
  SELECT
    pid, st_num, st_name, unit_num, city, zip_code, lu_desc,
    total_value, living_area, value_per_sqft,
    CASE
      WHEN living_area IS NULL THEN 'unknown'
      WHEN living_area < 800 THEN '<800'
      WHEN living_area < 1200 THEN '800-1199'
      WHEN living_area < 1800 THEN '1200-1799'
      WHEN living_area < 2500 THEN '1800-2499'
      ELSE '2500+'
    END AS size_band
  FROM clean.property_fy2024
  WHERE value_per_sqft IS NOT NULL
),
peer AS (
  SELECT
    zip_code, lu_desc, size_band,
    COUNT(*) AS peer_n,
    percentile_cont(0.5) WITHIN GROUP (ORDER BY value_per_sqft) AS peer_median_vpsf,
    percentile_cont(0.25) WITHIN GROUP (ORDER BY value_per_sqft) AS peer_p25_vpsf,
    percentile_cont(0.75) WITHIN GROUP (ORDER BY value_per_sqft) AS peer_p75_vpsf
  FROM base
  GROUP BY 1,2,3
),
scored AS (
  SELECT
    b.*,
    p.peer_n, p.peer_median_vpsf, p.peer_p25_vpsf, p.peer_p75_vpsf,
    (b.value_per_sqft - p.peer_median_vpsf) AS vpsf_delta_vs_peer_median,
    CASE
      WHEN p.peer_median_vpsf > 0 THEN (b.value_per_sqft / p.peer_median_vpsf) - 1
      ELSE NULL
    END AS vpsf_pct_vs_peer_median
  FROM base b
  JOIN peer p
    ON b.zip_code = p.zip_code
   AND b.lu_desc = p.lu_desc
   AND b.size_band = p.size_band
)
SELECT *
FROM scored
WHERE peer_n >= 30
  AND (value_per_sqft < peer_p25_vpsf OR value_per_sqft > peer_p75_vpsf);

-- Quick check
SELECT COUNT(*) FROM analytics.vw_peer_mispricing_audit;

-- Create the “high-confidence audit” view
CREATE OR REPLACE VIEW analytics.vw_peer_mispricing_high_confidence AS
SELECT *
FROM analytics.vw_peer_mispricing_audit
WHERE peer_n >= 50
  AND ABS(vpsf_pct_vs_peer_median) >= 0.20;
-- Check size
SELECT COUNT(*) 
FROM analytics.vw_peer_mispricing_high_confidence;

-- Add “direction” (undervalued vs overvalued)
CREATE OR REPLACE VIEW analytics.vw_peer_mispricing_labeled AS
SELECT
  *,
  CASE
    WHEN vpsf_pct_vs_peer_median <= -0.20 THEN 'Undervalued'
    WHEN vpsf_pct_vs_peer_median >=  0.20 THEN 'Overvalued'
    ELSE 'Neutral'
  END AS pricing_flag
FROM analytics.vw_peer_mispricing_high_confidence;

-- Final tightening (this is the last filter)
CREATE OR REPLACE VIEW analytics.vw_peer_mispricing_final AS
SELECT *
FROM analytics.vw_peer_mispricing_high_confidence
WHERE ABS(vpsf_pct_vs_peer_median) >= 0.30
  AND total_value >= 500000;

-- Check size
SELECT COUNT(*) 
FROM analytics.vw_peer_mispricing_final;

-- Label direction (final version)
CREATE OR REPLACE VIEW analytics.vw_peer_mispricing_final_labeled AS
SELECT
  *,
  CASE
    WHEN vpsf_pct_vs_peer_median <= -0.30 THEN 'Undervalued'
    WHEN vpsf_pct_vs_peer_median >=  0.30 THEN 'Overvalued'
    ELSE 'Neutral'
  END AS pricing_flag
FROM analytics.vw_peer_mispricing_final;


