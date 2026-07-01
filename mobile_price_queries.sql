-- ============================================================
-- Mobile Phone Price Classification — Feature Analysis
-- Author: Donson Hoang
-- Tool: MySQL
-- Dataset: 2,000 mobile phones with 20 hardware/connectivity specs
--
-- I used this dataset to figure out which phone specs actually
-- drive price differences. After loading both the train and test
-- splits into MySQL, I ran these queries to compute per-tier
-- averages, feature adoption rates, and correlation signals.
--
-- The short answer: RAM explains almost everything (r = 0.917).
-- Everything else is either secondary or basically noise.
--
-- Table: mobile_phones
-- Columns:
--   battery_power  INT          -- mAh
--   blue           TINYINT(1)   -- Bluetooth (0/1)
--   clock_speed    DECIMAL(3,1) -- GHz
--   dual_sim       TINYINT(1)   -- (0/1)
--   fc             TINYINT      -- front camera MP
--   four_g         TINYINT(1)   -- (0/1)
--   int_memory     TINYINT      -- internal storage GB
--   m_dep          DECIMAL(3,1) -- mobile depth cm
--   mobile_wt      SMALLINT     -- weight grams
--   n_cores        TINYINT      -- number of CPU cores
--   pc             TINYINT      -- primary camera MP
--   px_height      SMALLINT     -- pixel resolution height
--   px_width       SMALLINT     -- pixel resolution width
--   ram            SMALLINT     -- MB
--   sc_h           TINYINT      -- screen height cm
--   sc_w           TINYINT      -- screen width cm
--   talk_time      TINYINT      -- hours
--   three_g        TINYINT(1)   -- (0/1)
--   touch_screen   TINYINT(1)   -- (0/1)
--   wifi           TINYINT(1)   -- (0/1)
--   price_range    TINYINT      -- 0=Budget, 1=Mid-Range, 2=High-End, 3=Flagship
-- ============================================================


-- ────────────────────────────────────────────────────────────
-- SECTION 1: Overview KPIs
-- These numbers go in the top stat cards on the dashboard.
-- ────────────────────────────────────────────────────────────

-- Total phones and how many fall in each price tier
SELECT
    COUNT(*)                                                  AS total_phones,
    SUM(CASE WHEN price_range = 0 THEN 1 ELSE 0 END)         AS budget_count,
    SUM(CASE WHEN price_range = 1 THEN 1 ELSE 0 END)         AS mid_range_count,
    SUM(CASE WHEN price_range = 2 THEN 1 ELSE 0 END)         AS high_end_count,
    SUM(CASE WHEN price_range = 3 THEN 1 ELSE 0 END)         AS flagship_count
FROM mobile_phones;


-- Dataset is perfectly balanced — 500 in each tier
-- That makes this a cleaner classification problem than most
SELECT
    price_range,
    CASE price_range
        WHEN 0 THEN 'Budget'
        WHEN 1 THEN 'Mid-Range'
        WHEN 2 THEN 'High-End'
        WHEN 3 THEN 'Flagship'
    END                                                       AS tier_label,
    COUNT(*)                                                  AS phone_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)        AS pct_of_total
FROM mobile_phones
GROUP BY price_range
ORDER BY price_range;


-- Overall averages across the full dataset
SELECT
    ROUND(AVG(ram), 0)           AS avg_ram_mb,
    ROUND(AVG(battery_power), 0) AS avg_battery_mah,
    ROUND(AVG(int_memory), 1)    AS avg_storage_gb,
    ROUND(AVG(n_cores), 1)       AS avg_cores,
    MAX(ram)                     AS max_ram,
    MIN(ram)                     AS min_ram
FROM mobile_phones;


-- ────────────────────────────────────────────────────────────
-- SECTION 2: RAM — The Dominant Feature
-- RAM has a 0.917 Pearson correlation with price_range.
-- I ran this in Python first to confirm, then verified in SQL.
-- ────────────────────────────────────────────────────────────

-- Average RAM per price tier — the staircase pattern is striking
SELECT
    price_range,
    CASE price_range
        WHEN 0 THEN 'Budget'
        WHEN 1 THEN 'Mid-Range'
        WHEN 2 THEN 'High-End'
        WHEN 3 THEN 'Flagship'
    END                           AS tier_label,
    ROUND(AVG(ram), 0)            AS avg_ram_mb,
    MIN(ram)                      AS min_ram,
    MAX(ram)                      AS max_ram,
    ROUND(STDDEV(ram), 0)         AS stddev_ram
FROM mobile_phones
GROUP BY price_range
ORDER BY price_range;


-- RAM gap between Budget and Flagship in one number
-- The 4.4x multiplier is the headline stat
SELECT
    ROUND(
        AVG(CASE WHEN price_range = 3 THEN ram END) /
        AVG(CASE WHEN price_range = 0 THEN ram END),
    2) AS flagship_to_budget_ram_ratio,
    AVG(CASE WHEN price_range = 3 THEN ram END) -
    AVG(CASE WHEN price_range = 0 THEN ram END) AS ram_gap_mb
FROM mobile_phones;


-- How many phones in each tier have more than 2,000 MB RAM?
-- Useful for understanding where mid-range bleeds into high-end
SELECT
    price_range,
    COUNT(*)                                                          AS total,
    SUM(CASE WHEN ram > 2000 THEN 1 ELSE 0 END)                      AS above_2gb,
    ROUND(100.0 * SUM(CASE WHEN ram > 2000 THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_above_2gb
FROM mobile_phones
GROUP BY price_range
ORDER BY price_range;


-- ────────────────────────────────────────────────────────────
-- SECTION 3: Battery Power by Tier
-- Second most correlated feature (r = 0.201), but still weak
-- compared to RAM. The flagship tier does pull ahead noticeably.
-- ────────────────────────────────────────────────────────────

SELECT
    price_range,
    CASE price_range
        WHEN 0 THEN 'Budget'
        WHEN 1 THEN 'Mid-Range'
        WHEN 2 THEN 'High-End'
        WHEN 3 THEN 'Flagship'
    END                               AS tier_label,
    ROUND(AVG(battery_power), 0)      AS avg_battery_mah,
    MIN(battery_power)                AS min_battery,
    MAX(battery_power)                AS max_battery
FROM mobile_phones
GROUP BY price_range
ORDER BY price_range;


-- Battery gap: flagship vs budget
SELECT
    ROUND(
        AVG(CASE WHEN price_range = 3 THEN battery_power END) -
        AVG(CASE WHEN price_range = 0 THEN battery_power END),
    0) AS battery_gap_mah
FROM mobile_phones;


-- ────────────────────────────────────────────────────────────
-- SECTION 4: Screen Resolution by Tier
-- px_width (r=0.166) and px_height (r=0.149) are 3rd and 4th.
-- I compute total pixels as a combined resolution signal.
-- ────────────────────────────────────────────────────────────

SELECT
    price_range,
    CASE price_range
        WHEN 0 THEN 'Budget'
        WHEN 1 THEN 'Mid-Range'
        WHEN 2 THEN 'High-End'
        WHEN 3 THEN 'Flagship'
    END                                                   AS tier_label,
    ROUND(AVG(px_width), 0)                               AS avg_px_width,
    ROUND(AVG(px_height), 0)                              AS avg_px_height,
    ROUND(AVG(px_width * px_height) / 1000000.0, 2)       AS avg_megapixels_screen
FROM mobile_phones
GROUP BY price_range
ORDER BY price_range;


-- ────────────────────────────────────────────────────────────
-- SECTION 5: Connectivity Feature Adoption by Tier
-- This is where the "boring" finding lives — 4G, WiFi, BT,
-- and Dual SIM rates are nearly the same across all tiers.
-- These features don't separate expensive phones from cheap ones.
-- ────────────────────────────────────────────────────────────

SELECT
    price_range,
    CASE price_range
        WHEN 0 THEN 'Budget'
        WHEN 1 THEN 'Mid-Range'
        WHEN 2 THEN 'High-End'
        WHEN 3 THEN 'Flagship'
    END                                                                     AS tier_label,
    COUNT(*)                                                                AS total,
    ROUND(100.0 * SUM(four_g)       / COUNT(*), 1)                         AS pct_four_g,
    ROUND(100.0 * SUM(three_g)      / COUNT(*), 1)                         AS pct_three_g,
    ROUND(100.0 * SUM(blue)         / COUNT(*), 1)                         AS pct_bluetooth,
    ROUND(100.0 * SUM(wifi)         / COUNT(*), 1)                         AS pct_wifi,
    ROUND(100.0 * SUM(dual_sim)     / COUNT(*), 1)                         AS pct_dual_sim,
    ROUND(100.0 * SUM(touch_screen) / COUNT(*), 1)                         AS pct_touch_screen
FROM mobile_phones
GROUP BY price_range
ORDER BY price_range;


-- Max difference in 4G adoption between any two tiers
-- (Spoiler: it's only ~5.6 percentage points — basically noise)
SELECT
    MAX(pct_four_g) - MIN(pct_four_g) AS four_g_range_pct
FROM (
    SELECT ROUND(100.0 * SUM(four_g) / COUNT(*), 1) AS pct_four_g
    FROM mobile_phones
    GROUP BY price_range
) sub;


-- ────────────────────────────────────────────────────────────
-- SECTION 6: Camera, Cores, and Other Specs
-- These don't move the needle much. Camera barely improves
-- from budget to flagship. Clock speed is essentially random.
-- ────────────────────────────────────────────────────────────

SELECT
    price_range,
    CASE price_range
        WHEN 0 THEN 'Budget'
        WHEN 1 THEN 'Mid-Range'
        WHEN 2 THEN 'High-End'
        WHEN 3 THEN 'Flagship'
    END                              AS tier_label,
    ROUND(AVG(pc), 1)                AS avg_primary_cam_mp,
    ROUND(AVG(fc), 1)                AS avg_front_cam_mp,
    ROUND(AVG(n_cores), 1)           AS avg_cores,
    ROUND(AVG(clock_speed), 2)       AS avg_clock_ghz,
    ROUND(AVG(mobile_wt), 1)         AS avg_weight_g,
    ROUND(AVG(talk_time), 1)         AS avg_talk_time_h,
    ROUND(AVG(int_memory), 1)        AS avg_storage_gb
FROM mobile_phones
GROUP BY price_range
ORDER BY price_range;


-- Clock speed correlation check — this is the surprising one
-- Budget phones actually average faster clock speeds than high-end
-- (r = -0.007, basically zero). I expected this to matter more.
SELECT
    price_range,
    ROUND(AVG(clock_speed), 2) AS avg_clock_ghz
FROM mobile_phones
GROUP BY price_range
ORDER BY price_range;


-- ────────────────────────────────────────────────────────────
-- SECTION 7: Insight Deep Dives
-- These back the six insight cards in the dashboard.
-- ────────────────────────────────────────────────────────────

-- 1. What % of budget phones have RAM > mid-range average (1,679 MB)?
--    Overlap like this shows why RAM alone can't be used as a hard cutoff
SELECT
    COUNT(*)                                                        AS budget_total,
    SUM(CASE WHEN ram > 1679 THEN 1 ELSE 0 END)                    AS above_midrange_avg,
    ROUND(100.0 * SUM(CASE WHEN ram > 1679 THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_overlap
FROM mobile_phones
WHERE price_range = 0;


-- 2. Battery distribution — how many flagships actually have > 1,500 mAh?
--    Despite the higher average, there's still a lot of overlap
SELECT
    price_range,
    SUM(CASE WHEN battery_power > 1500 THEN 1 ELSE 0 END)          AS above_1500_mah,
    COUNT(*)                                                        AS total,
    ROUND(100.0 * SUM(CASE WHEN battery_power > 1500 THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_above_1500
FROM mobile_phones
GROUP BY price_range
ORDER BY price_range;


-- 3. Phones with high RAM but low battery — premium compromises
--    I was curious how many flagship phones sacrifice battery for RAM
SELECT COUNT(*) AS flagship_high_ram_low_battery
FROM mobile_phones
WHERE price_range = 3
  AND ram > 3000
  AND battery_power < 1000;


-- 4. Is 4G + high RAM a reliable flagship indicator?
--    Checking whether combining two features improves tier detection
SELECT
    price_range,
    COUNT(*) AS total,
    SUM(CASE WHEN four_g = 1 AND ram > 2500 THEN 1 ELSE 0 END) AS four_g_and_high_ram,
    ROUND(
        100.0 * SUM(CASE WHEN four_g = 1 AND ram > 2500 THEN 1 ELSE 0 END) / COUNT(*),
    1) AS pct_4g_high_ram
FROM mobile_phones
GROUP BY price_range
ORDER BY price_range;


-- 5. Clock speed anomaly — faster CPUs in budget tier?
--    This was an unexpected find. Budget phones average 1.6 GHz,
--    but flagship phones average only 1.5 GHz.
SELECT
    price_range,
    ROUND(AVG(clock_speed), 3)    AS avg_clock_ghz,
    SUM(CASE WHEN clock_speed >= 2.5 THEN 1 ELSE 0 END) AS high_clock_count
FROM mobile_phones
GROUP BY price_range
ORDER BY price_range;


-- 6. Multi-feature comparison: how many phones have
--    both 4G AND WiFi AND Bluetooth across tiers?
SELECT
    price_range,
    ROUND(100.0 * SUM(CASE WHEN four_g = 1 AND wifi = 1 AND blue = 1 THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_full_connectivity
FROM mobile_phones
GROUP BY price_range
ORDER BY price_range;


-- ────────────────────────────────────────────────────────────
-- SECTION 8: Phone Explorer Query
-- Powers the filterable phone browser in the dashboard.
-- Swap the WHERE values to match the user's filter selection.
-- ────────────────────────────────────────────────────────────

SELECT
    price_range,
    CASE price_range
        WHEN 0 THEN 'Budget'
        WHEN 1 THEN 'Mid-Range'
        WHEN 2 THEN 'High-End'
        WHEN 3 THEN 'Flagship'
    END         AS tier_label,
    ram,
    battery_power,
    int_memory,
    n_cores,
    pc          AS primary_cam_mp,
    fc          AS front_cam_mp,
    mobile_wt   AS weight_g,
    talk_time,
    clock_speed,
    four_g,
    three_g,
    blue        AS bluetooth,
    wifi,
    dual_sim,
    touch_screen
FROM mobile_phones
WHERE
    price_range = 3            -- 0=Budget, 1=Mid-Range, 2=High-End, 3=Flagship
    AND four_g = 1             -- has 4G
    AND ram > 3000             -- high RAM filter
ORDER BY ram DESC
LIMIT 100;
