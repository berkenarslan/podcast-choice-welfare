-- THESIS REPLICATION: original assessed choice generator.
-- Recovered from SQL cleaning model panels(1).docx, paragraphs 49-142.
-- RAND() and the two-stage Gumbel-plus-softmax draw are preserved for audit.

-- 1) Match=1 alt panel + sponsor bool → int
CREATE OR REPLACE TABLE `my-dissertation-470916.podcast_primary_bucket.panel_match_only` AS
SELECT
  user_id,
  podcast_id,
  listen_score_z,
  timecost_z,
  CAST(sponsor AS INT64) AS sponsor_int,  -- BOOL → 0/1
  obs_weight
FROM `my-dissertation-470916.podcast_primary_bucket.panel_primary_tbl`
WHERE match = TRUE;

-- 2) Simülasyon utility'si (τ ve Gumbel ile) ve softmax p
CREATE OR REPLACE TABLE `my-dissertation-470916.podcast_primary_bucket.panel_match_only_probs` AS
WITH base AS (
  SELECT
    user_id,
    podcast_id,
    -- Küçük betalar
    (0.4*listen_score_z - 0.2*timecost_z + 0.1*sponsor_int) AS V_raw
  FROM `my-dissertation-470916.podcast_primary_bucket.panel_match_only`
),
vt AS (
  SELECT
    user_id,
    podcast_id,
    -- τ = 2.0
    V_raw / 2.0 AS V_temp,
    -- σ = 0.5, Gumbel noise
    -LOG(-LOG(GREATEST(RAND(), 1e-12))) * 0.5 AS gumbel_noise
  FROM base
),
v AS (
  SELECT
    user_id,
    podcast_id,
    (V_temp + gumbel_noise) AS V
  FROM vt
),
den AS (
  SELECT user_id, SUM(EXP(v.V)) AS denom
  FROM v
  GROUP BY user_id
)
SELECT
  v.user_id,
  v.podcast_id,
  v.V,
  EXP(v.V) / d.denom AS p_softmax
FROM v
JOIN den d USING (user_id);

-- 3) Tek seçim (inverse CDF, sıralamayı podcast_id ile sabitliyoruz)
CREATE OR REPLACE TABLE `my-dissertation-470916.podcast_primary_bucket.panel_match_only_choice` AS
WITH probs AS (
  SELECT * FROM `my-dissertation-470916.podcast_primary_bucket.panel_match_only_probs`
),
rnd AS (
  SELECT user_id, RAND() AS r
  FROM probs
  GROUP BY user_id
),
cum AS (
  SELECT
    p.user_id,
    p.podcast_id,
    p.p_softmax,
    SUM(p.p_softmax) OVER (PARTITION BY p.user_id ORDER BY p.podcast_id) AS cum_p
  FROM probs p
)
SELECT
  c.user_id,
  c.podcast_id,
  CASE 
    WHEN c.cum_p >= r.r 
         AND (c.cum_p - c.p_softmax) < r.r 
    THEN 1 ELSE 0 
  END AS chosen
FROM cum c
JOIN rnd r USING (user_id);

-- 4) Tahmin paneli: özellikler + chosen
CREATE OR REPLACE TABLE `my-dissertation-470916.podcast_primary_bucket.panel_match_only_est` AS
SELECT
  a.user_id,
  a.podcast_id,
  c.chosen,
  a.listen_score_z,
  a.timecost_z,
  a.sponsor_int AS sponsor,
  a.obs_weight
FROM `my-dissertation-470916.podcast_primary_bucket.panel_match_only` a
JOIN `my-dissertation-470916.podcast_primary_bucket.panel_match_only_choice` c
USING (user_id, podcast_id);
