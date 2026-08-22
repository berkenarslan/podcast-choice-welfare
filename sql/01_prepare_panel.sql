-- THESIS REPLICATION: original assessed specification.
-- Recovered from Sql kods(1).docx, paragraphs 140-256.
-- Note: timecost_z is constructed from update_frequency_hours here because
-- that is what the assessed code used. This is not silently corrected in v1.0.

CREATE OR REPLACE TABLE `podcast_primary_bucket.users_clean` AS
SELECT
  CAST(user_id AS INT64) AS user_id,
  Age_Group              AS age_group,
  Gender                 AS gender,
  Education              AS education,
  Income                 AS income,
  Preferred_Category__Pew12_ AS preferred_bucket,
  Listening_Frequency    AS listening_frequency
FROM `podcast_primary_bucket.usersdata`;

CREATE OR REPLACE TABLE `podcast_primary_bucket.metadata_clean` AS
SELECT
  CAST(podcast_id AS INT64)        AS podcast_id,
  Primary_Bucket__Pew12_           AS primary_bucket,
  has_sponsors                     AS sponsor,
  listen_score,
  listen_score_global_rank,
  update_frequency_hours,
  genres,
  title
FROM `podcast_primary_bucket.metadata_native`;

CREATE OR REPLACE TABLE `podcast_primary_bucket.metadata_features` AS
WITH base AS (
  SELECT
    podcast_id, primary_bucket, sponsor,
    listen_score, listen_score_global_rank, update_frequency_hours
  FROM `podcast_primary_bucket.metadata_clean`
),
feat AS (
  SELECT
    *,
    CASE
      WHEN listen_score IS NOT NULL THEN
        (listen_score - AVG(listen_score) OVER()) /
        NULLIF(STDDEV_POP(listen_score) OVER(), 0)
      WHEN listen_score_global_rank IS NOT NULL THEN
        - (listen_score_global_rank - AVG(listen_score_global_rank) OVER()) /
        NULLIF(STDDEV_POP(listen_score_global_rank) OVER(), 0)
      ELSE 0.0
    END AS listen_score_z,
    CASE
      WHEN update_frequency_hours IS NOT NULL THEN
        (update_frequency_hours - AVG(update_frequency_hours) OVER()) /
        NULLIF(STDDEV_POP(update_frequency_hours) OVER(), 0)
      ELSE 0.0
    END AS timecost_z
  FROM base
)
SELECT podcast_id, primary_bucket, sponsor, listen_score_z, timecost_z
FROM feat;

-- Metadata dağılımı
CREATE OR REPLACE TABLE `podcast_primary_bucket.meta_dist` AS
SELECT primary_bucket, COUNT(*) AS n_meta
FROM `podcast_primary_bucket.metadata_features`
GROUP BY primary_bucket;

-- User dağılımı
CREATE OR REPLACE TABLE `podcast_primary_bucket.user_dist` AS
SELECT preferred_bucket AS primary_bucket, COUNT(*) AS n_users
FROM `podcast_primary_bucket.users_clean`
GROUP BY primary_bucket;

-- Ağırlıklar
CREATE OR REPLACE TABLE `podcast_primary_bucket.bucket_weights` AS
WITH j AS (
  SELECT
    u.primary_bucket,
    u.n_users,
    m.n_meta,
    SAFE_DIVIDE(u.n_users, SUM(u.n_users) OVER()) AS users_share,
    SAFE_DIVIDE(m.n_meta,  SUM(m.n_meta)  OVER()) AS meta_share
  FROM `podcast_primary_bucket.user_dist` u
  LEFT JOIN `podcast_primary_bucket.meta_dist` m USING (primary_bucket)
)
SELECT
  primary_bucket,
  users_share,
  meta_share,
  CASE WHEN meta_share IS NULL OR meta_share = 0 THEN 1.0
       ELSE users_share / meta_share END AS weight_k
FROM j;

CREATE OR REPLACE TABLE `podcast_primary_bucket.panel_primary_tbl`
CLUSTER BY user_id, podcast_id AS
SELECT
  u.user_id,
  p.podcast_id,
  p.listen_score_z,
  p.timecost_z,
  p.sponsor,
  (u.preferred_bucket = p.primary_bucket) AS match,
  w.weight_k AS obs_weight
FROM `podcast_primary_bucket.users_clean` u
CROSS JOIN `podcast_primary_bucket.metadata_features` p
LEFT JOIN `podcast_primary_bucket.bucket_weights` w
  ON p.primary_bucket = w.primary_bucket;
