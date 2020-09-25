CREATE OR REPLACE VIEW
  charge_events
AS
WITH raw AS (
  SELECT
    created AS event_timestamp,
    `data`.charge.*,
  FROM
    stripe_external.events_v1
  WHERE
    `data`.charge IS NOT NULL
  UNION ALL
  SELECT
    created AS event_timestamp,
    *,
  FROM
    stripe_external.charges_v1
  -- TODO remove this filter in favor of deleting the unwanted data from the table
  WHERE
    DATE(created) < DATE '2020-08-10'
)
SELECT
  amount,
  amount_captured,
  amount_refunded,
  STRUCT(STRUCT(billing_details.address.postal_code) AS address) AS billing_details,
  currency,
  event_timestamp,
  id,
FROM
  raw
