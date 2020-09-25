CREATE OR REPLACE VIEW
  revenue
AS
SELECT
  DATE(event_timestamp) AS `date`,
  billing_details.address.postal_code,
  currency,
  SUM(amount) AS amount,
  SUM(amount_captured) AS amount_captured,
  SUM(amount_refunded) AS amount_refunded,
FROM
  stripe_derived.charges_v1
GROUP BY
  `date`,
  postal_code,
  currency
