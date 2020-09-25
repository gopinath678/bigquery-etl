CREATE OR REPLACE VIEW
  funnel
AS
WITH subscriptions AS (
  SELECT
    plan,
    status = "incomplete_expired" AS incomplete_expired,
    cancel_at_period_end
    OR "cancelled_for_customer_at" IN (SELECT key FROM UNNEST(metadata)) AS cancelled_for_customer,
    -- count subscriptions from the day after they start to the day after they end
    -- TODO: decide whether to count users at the end of the day or the beginning of the day
    DATE_ADD(DATE(start_date), INTERVAL 1 DAY) AS start_date,
    -- use day after ended_at to count cancelled and renew failed
    DATE_ADD(DATE(ended_at), INTERVAL 1 DAY) AS end_date,
    trial_end,
    MIN(DATE_ADD(DATE(start_date), INTERVAL 1 DAY)) OVER (
      PARTITION BY
        customer
    ) AS customer_start_date,
    customer,
    -- TODO: join on guardian logs and cloudSQL for mozilla vpn funnel information (attribution,
    -- client running, vpn active, waitlist)
  FROM
    stripe_derived.subscriptions_v1
  WHERE
    status != "incomplete"
),
counts AS (
  SELECT
    `date`,
    plan,
    CASE
    WHEN
      incomplete_expired
    THEN
      "failed setup"
    WHEN
      TIMESTAMP(`date`) < trial_end
    THEN
      "trialing"
    -- TODO decide whether subscriptions that go through a trial are ever counted as "new"
    -- WHEN `date` = DATE_ADD(DATE(trial_end), INTERVAL 1 DAY) THEN "new"
    WHEN
      `date` = customer_start_date
    THEN
      "new"
    WHEN
      `date` = start_date
    THEN
      "resurrected"
    WHEN
      `date` = end_date
      AND cancelled_for_customer
    THEN
      "cancelled"
    WHEN
      `date` = end_date
    THEN
      "failed renewal"
    ELSE
      "active"
    END
    AS status,
    -- TODO decide whether to count customers or subscriptions, because in a single day a customer
    -- may create multiple subscriptions that end in "failed setup"
    COUNT(DISTINCT customer) AS subscription_count,
  FROM
    subscriptions
  CROSS JOIN
    UNNEST(
      IF(
        incomplete_expired,
        [end_date],
        GENERATE_DATE_ARRAY(start_date, COALESCE(end_date, CURRENT_DATE))
      )
    ) AS `date`
  GROUP BY
    `date`,
    plan,
    status
)
SELECT
  counts.`date`,
  products_v1.name AS product,
  counts.status,
  counts.subscription_count,
FROM
  counts
LEFT JOIN
  stripe_derived.plans_v1
ON
  (counts.plan = plans_v1.id)
LEFT JOIN
  stripe_derived.products_v1
ON
  (plans_v1.product = products_v1.id)
