CREATE OR REPLACE VIEW
  subscription_events
AS
WITH raw AS (
  SELECT
    created AS event_timestamp,
    `data`.subscription.*,
  FROM
    stripe_external.events_v1
  WHERE
    `data`.subscription IS NOT NULL
  UNION ALL
  SELECT
    created AS event_timestamp,
    *,
  FROM
    stripe_external.subscriptions_v1
  -- TODO remove this filter in favor of deleting the unwanted data from the table
  WHERE
    DATE(created) < DATE '2020-08-10'
)
SELECT
  cancel_at_period_end,
  customer,
  ended_at,
  event_timestamp,
  id,
  metadata,
  plan.id AS plan,
  start_date,
  status,
  trial_end,
FROM
  raw
