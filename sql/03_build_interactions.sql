-- THESIS REPLICATION: original assessed interaction-table definitions.
-- Recovered from SQL cleaning model panels(1).docx, paragraphs 143-454.
-- The repeated M2V3 table name is preserved because the second statement
-- overwrote the first in the original workflow. See docs/REPLICATION_SCOPE.md.

-- 1) Kullanıcı demografilerini panelle birleştir
CREATE OR REPLACE TABLE `my-dissertation-470916.podcast_primary_bucket.panel_match_only_est_M2` AS
SELECT
  p.user_id,
  p.podcast_id,
  p.chosen,
  p.listen_score_z,
  p.timecost_z,
  p.sponsor,
  p.obs_weight,
  d.age_group,
  d.gender,
  d.education,
  -- 2) Interaction değişkenleri
  p.listen_score_z * IF(d.education = 'High', 1, 0) AS listen_highEdu,
  p.timecost_z * IF(d.gender = 'Female', 1, 0)       AS time_female,
  p.sponsor * IF(d.age_group = 'Young', 1, 0)        AS sponsor_young
FROM `my-dissertation-470916.podcast_primary_bucket.panel_match_only_est` p
JOIN `my-dissertation-470916.podcast_primary_bucket.users_clean` d
USING (user_id);
CREATE OR REPLACE TABLE `my-dissertation-470916.podcast_primary_bucket.panel_match_only_est_M2V2` AS
WITH dem AS (
  SELECT
    user_id,
    LOWER(TRIM(income)) AS income_raw,
    LOWER(TRIM(listening_frequency)) AS freq_raw
  FROM `my-dissertation-470916.podcast_primary_bucket.users_clean`
),
flags AS (
  SELECT
    user_id,
    -- HighIncome: '80K+' ise 1
    CAST(IF(income_raw = '80k+', 1, 0) AS INT64) AS highIncome_flag,
    -- HighFreq: 'Every day' veya 'A few times a week' → sık dinleyen
    CAST(IF(freq_raw IN ('every day','a few times a week'), 1, 0) AS INT64) AS highFreq_flag
  FROM dem
)
SELECT
  p.user_id, p.podcast_id, p.chosen,
  p.listen_score_z, p.timecost_z, p.sponsor, p.obs_weight,
  -- interactions
  p.sponsor    * f.highIncome_flag AS sponsor_highIncome,
  p.timecost_z * f.highFreq_flag   AS time_highFreq
FROM `my-dissertation-470916.podcast_primary_bucket.panel_match_only_est` p
LEFT JOIN flags f USING (user_id);

CREATE OR REPLACE TABLE `my-dissertation-470916.podcast_primary_bucket.panel_match_only_est_M2V3` AS
WITH dem AS (
  SELECT
    user_id,
    LOWER(TRIM(age_group)) AS age_raw,
    LOWER(TRIM(preferred_bucket)) AS pref_raw
  FROM `my-dissertation-470916.podcast_primary_bucket.users_clean`
),
flags AS (
  SELECT
    user_id,
    -- Young (18–29)
    CAST(IF(REGEXP_CONTAINS(age_raw, r'18|^18–29$'), 1, 0) AS INT64) AS young_flag,
    -- Comedy & Politics flag (base diğerleri)
    CAST(IF(pref_raw='comedy', 1, 0) AS INT64)   AS pref_comedy_flag,
    CAST(IF(pref_raw='politics', 1, 0) AS INT64) AS pref_politics_flag
  FROM dem
)
SELECT
  p.user_id, p.podcast_id, p.chosen,
  p.listen_score_z, p.timecost_z, p.sponsor, p.obs_weight,
  -- interactions
  p.listen_score_z * f.young_flag        AS listen_young,
  p.sponsor        * f.pref_comedy_flag  AS sponsor_prefComedy,
  p.sponsor        * f.pref_politics_flag AS sponsor_prefPolitics
FROM `my-dissertation-470916.podcast_primary_bucket.panel_match_only_est` p
LEFT JOIN flags f USING (user_id);
CREATE OR REPLACE TABLE `my-dissertation-470916.podcast_primary_bucket.panel_match_only_est_M2V3` AS
WITH dem AS (
  SELECT
    user_id,
    LOWER(TRIM(age_group)) AS age_raw,
    LOWER(TRIM(income)) AS income_raw,
    LOWER(TRIM(listening_frequency)) AS freq_raw
  FROM `my-dissertation-470916.podcast_primary_bucket.users_clean`
),
flags AS (
  SELECT
    user_id,
    -- Young (18–29)
    CAST(IF(REGEXP_CONTAINS(age_raw, r'(^18–29$)|(^18-29$)|(^18$)|(^18 to 29$)|(^18 – 29$)'), 1, 0) AS INT64) AS young_flag,
    -- HighIncome: 80K+
    CAST(IF(income_raw = '80k+', 1, 0) AS INT64) AS highIncome_flag,
    -- HighFreq: every day / a few times a week
    CAST(IF(freq_raw IN ('every day','a few times a week'), 1, 0) AS INT64) AS highFreq_flag
  FROM dem
)
SELECT
  p.user_id,
  p.podcast_id,
  p.chosen,
  p.listen_score_z,
  p.timecost_z,
  p.sponsor,
  p.obs_weight,

  -- 0/1 bayraklar (isteğe bağlı kullanmak istersen dursun)
  f.young_flag,
  f.highIncome_flag,
  f.highFreq_flag,

  -- M2V3 etkileşimleri (numeric, NULL-safe)
  p.listen_score_z * f.young_flag      AS listen_young,
  p.timecost_z    * f.highIncome_flag  AS time_highIncome,
  p.listen_score_z * f.highFreq_flag   AS listen_highFreq

FROM `my-dissertation-470916.podcast_primary_bucket.panel_match_only_est` p
LEFT JOIN flags f USING (user_id);
CREATE OR REPLACE TABLE `my-dissertation-470916.podcast_primary_bucket.panel_match_only_est_M2V4` AS
WITH dem AS (
  SELECT
    user_id,
    LOWER(TRIM(education)) AS edu_raw,
    LOWER(TRIM(age_group)) AS age_raw,
    LOWER(TRIM(gender))    AS gender_raw
  FROM `my-dissertation-470916.podcast_primary_bucket.users_clean`
),
flags AS (
  SELECT
    user_id,
    CAST(IF(edu_raw='college+', 1, 0) AS INT64) AS highedu_flag,
    CAST(IF(REGEXP_CONTAINS(age_raw, r'18|^18–29$'), 1, 0) AS INT64) AS young_flag,
    CAST(IF(gender_raw='female', 1, 0) AS INT64) AS female_flag
  FROM dem
)
SELECT
  p.user_id, p.podcast_id, p.chosen,
  p.listen_score_z, p.timecost_z, p.sponsor, p.obs_weight,
  -- interactions
  p.listen_score_z * f.highedu_flag AS listen_highEdu,
  p.timecost_z    * f.young_flag    AS time_young,
  p.sponsor       * f.female_flag   AS sponsor_female
FROM `my-dissertation-470916.podcast_primary_bucket.panel_match_only_est` p
LEFT JOIN flags f USING (user_id);

-- M2V5: Edu×TimeCost, Income×ListenScore, Freq×Sponsor
CREATE OR REPLACE TABLE `my-dissertation-470916.podcast_primary_bucket.panel_match_only_est_M2V5` AS
WITH dem AS (
  SELECT
    user_id,
    LOWER(TRIM(education))           AS edu_raw,
    LOWER(TRIM(income))              AS income_raw,
    LOWER(TRIM(listening_frequency)) AS freq_raw
  FROM `my-dissertation-470916.podcast_primary_bucket.users_clean`
),
flags AS (
  SELECT
    user_id,
    CAST(IF(edu_raw='college+', 1, 0) AS INT64)                               AS highedu_flag,
    CAST(IF(income_raw='80k+', 1, 0) AS INT64)                                AS highincome_flag,
    CAST(IF(freq_raw IN ('every day','a few times a week'), 1, 0) AS INT64)   AS highfreq_flag
  FROM dem
)
SELECT
  p.user_id, p.podcast_id, p.chosen,
  p.listen_score_z, p.timecost_z, p.sponsor, p.obs_weight,
  -- interactions
  p.timecost_z    * f.highedu_flag   AS time_highEdu,       -- Edu × TimeCost
  p.listen_score_z* f.highincome_flag AS listen_highIncome, -- Income × ListenScore
  p.sponsor       * f.highfreq_flag  AS sponsor_highFreq    -- Freq × Sponsor
FROM `my-dissertation-470916.podcast_primary_bucket.panel_match_only_est` p
LEFT JOIN flags f USING (user_id);
-- M2V6: Edu×Sponsor, Older×TimeCost
CREATE OR REPLACE TABLE `my-dissertation-470916.podcast_primary_bucket.panel_match_only_est_M2V6` AS
WITH dem AS (
  SELECT
    user_id,
    LOWER(TRIM(education)) AS edu_raw,
    LOWER(TRIM(age_group)) AS age_raw
  FROM `my-dissertation-470916.podcast_primary_bucket.users_clean`
),
flags AS (
  SELECT
    user_id,
    CAST(IF(edu_raw='college+', 1, 0) AS INT64) AS highedu_flag,
    -- Older: 50–64 veya 65+ → 1
    CAST(IF(age_raw IN ('50–64','65+','50-64','65+'), 1, 0) AS INT64) AS older_flag
  FROM dem
)
SELECT
  p.user_id, p.podcast_id, p.chosen,
  p.listen_score_z, p.timecost_z, p.sponsor, p.obs_weight,
  -- interactions
  p.sponsor    * f.highedu_flag AS sponsor_highEdu,  -- Edu × Sponsor
  p.timecost_z * f.older_flag   AS time_older        -- Older × TimeCost
FROM `my-dissertation-470916.podcast_primary_bucket.panel_match_only_est` p
LEFT JOIN flags f USING (user_id);
-- M2V7: Older×ListenScore, Female×ListenScore
CREATE OR REPLACE TABLE `my-dissertation-470916.podcast_primary_bucket.panel_match_only_est_M2V7` AS
WITH dem AS (
  SELECT
    user_id,
    LOWER(TRIM(age_group)) AS age_raw,
    LOWER(TRIM(gender))    AS gender_raw
  FROM `my-dissertation-470916.podcast_primary_bucket.users_clean`
),
flags AS (
  SELECT
    user_id,
    -- Older: 50–64 veya 65+ → 1
    CAST(IF(age_raw IN ('50–64','65+','50-64','65+'), 1, 0) AS INT64) AS older_flag,
    -- Female: 1/0
    CAST(IF(gender_raw = 'female', 1, 0) AS INT64) AS female_flag
  FROM dem
)
SELECT
  p.user_id,
  p.podcast_id,
  p.chosen,
  p.listen_score_z,
  p.timecost_z,
  p.sponsor,
  p.obs_weight,
  -- interactions (numeric)
  p.listen_score_z * f.older_flag  AS listen_older,   -- Older × ListenScore
  p.listen_score_z * f.female_flag AS listen_female   -- Female × ListenScore
FROM `my-dissertation-470916.podcast_primary_bucket.panel_match_only_est` p
LEFT JOIN flags f USING (user_id);
-- M2V8: Sponsor × Income(Low, High) — Mid (30–79,999) referans
CREATE OR REPLACE TABLE `my-dissertation-470916.podcast_primary_bucket.panel_match_only_est_M2V8` AS
WITH dem AS (
  SELECT
    user_id,
    LOWER(TRIM(income)) AS income_raw
  FROM `my-dissertation-470916.podcast_primary_bucket.users_clean`
),
flags AS (
  SELECT
    user_id,
    -- Low: '<30K'
    CAST(IF(income_raw IN ('<30k','< 30k'), 1, 0) AS INT64) AS income_low_flag,
    -- Mid: '30K–79,999' (farklı tire/format varyantlarını yakala)
    CAST(IF(income_raw IN ('30k–79,999','30k-79,999','30–79,999','30-79,999'), 1, 0) AS INT64) AS income_mid_flag,
    -- High: '80K+'
    CAST(IF(income_raw IN ('80k+','≥80k','>=80k'), 1, 0) AS INT64) AS income_high_flag
  FROM dem
)
SELECT
  p.user_id,
  p.podcast_id,
  p.chosen,
  p.listen_score_z,
  p.timecost_z,
  p.sponsor,
  p.obs_weight,
  -- Interactionlar: Mid referans, o yüzden sadece Low ve High ile etkileşim
  (p.sponsor * f.income_low_flag)  AS sponsor_lowIncome,
  (p.sponsor * f.income_high_flag) AS sponsor_highIncome
FROM `my-dissertation-470916.podcast_primary_bucket.panel_match_only_est` p
LEFT JOIN flags f USING (user_id);
-- M2V9: Sponsor × Age groups (ref = 30–49
CREATE OR REPLACE TABLE `my-dissertation-470916.podcast_primary_bucket.panel_match_only_est_M2V9` AS
WITH dem AS (
  SELECT
    user_id,
    LOWER(TRIM(age_group)) AS age_raw
  FROM `my-dissertation-470916.podcast_primary_bucket.users_clean`
),
flags AS (
  SELECT
    user_id,
    CAST(IF(age_raw IN ('18–29','18-29'), 1, 0) AS INT64) AS age18_29_flag,
    CAST(IF(age_raw IN ('50–64','50-64'), 1, 0) AS INT64) AS age50_64_flag,
    CAST(IF(age_raw IN ('65+','65plus'), 1, 0) AS INT64)  AS age65plus_flag
    -- ref group = 30–49
  FROM dem
)
SELECT
  p.user_id,
  p.podcast_id,
  p.chosen,
  p.listen_score_z,
  p.timecost_z,
  p.sponsor,
  p.obs_weight,
  -- interactions
  (p.sponsor * f.age18_29_flag)  AS sponsor_age18_29,
  (p.sponsor * f.age50_64_flag)  AS sponsor_age50_64,
  (p.sponsor * f.age65plus_flag) AS sponsor_age65plus
FROM `my-dissertation-470916.podcast_primary_bucket.panel_match_only_est` p
LEFT JOIN flags f USING (user_id);
-- M2V10: Sponsor × Gender (Male ref)
CREATE OR REPLACE TABLE `my-dissertation-470916.podcast_primary_bucket.panel_match_only_est_M2V10` AS
WITH dem AS (
  SELECT
    user_id,
    LOWER(TRIM(gender)) AS gender_raw
  FROM `my-dissertation-470916.podcast_primary_bucket.users_clean`
),
flags AS (
  SELECT
    user_id,
    CAST(IF(gender_raw = 'female', 1, 0) AS INT64) AS female_flag
  FROM dem
)
SELECT
  p.user_id,
  p.podcast_id,
  p.chosen,
  p.listen_score_z,
  p.timecost_z,
  p.sponsor,
  p.obs_weight,
  (p.sponsor * f.female_flag) AS sponsor_female
FROM `my-dissertation-470916.podcast_primary_bucket.panel_match_only_est` p
LEFT JOIN flags f USING (user_id);
