CREATE OR REPLACE VIEW
  plan_events
AS
SELECT
  created AS event_timestamp,
  `data`.plan.*,
FROM
  stripe_external.events_v1
WHERE
  `data`.plan IS NOT NULL
UNION ALL
SELECT
  created AS event_timestamp,
  *,
FROM
  stripe_external.plans_v1
-- TODO remove this filter in favor of deleting the unwanted data from the table
WHERE
  DATE(created) < DATE '2020-08-10'
