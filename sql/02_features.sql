WITH service_counts AS (
    SELECT
        customer_id,
        (CASE WHEN online_security   = 'Yes' THEN 1 ELSE 0 END
       + CASE WHEN online_backup     = 'Yes' THEN 1 ELSE 0 END
       + CASE WHEN device_protection = 'Yes' THEN 1 ELSE 0 END
       + CASE WHEN tech_support      = 'Yes' THEN 1 ELSE 0 END
       + CASE WHEN streaming_tv      = 'Yes' THEN 1 ELSE 0 END
       + CASE WHEN streaming_movies  = 'Yes' THEN 1 ELSE 0 END) AS num_addons
    FROM services
),
base AS (
    SELECT
        c.customer_id, c.gender, c.senior_citizen, c.partner, c.dependents,
        c.city, c.state,
        sv.phone_service, sv.multiple_lines, sv.internet_service,
        sc.num_addons,
        b.tenure_months, b.contract, b.paperless_billing, b.payment_method,
        b.monthly_charges, b.total_charges,
        st.cltv, st.churn_value
    FROM customers c
    JOIN services sv       ON c.customer_id = sv.customer_id
    JOIN service_counts sc ON c.customer_id = sc.customer_id
    JOIN billing b         ON c.customer_id = b.customer_id
    JOIN status st         ON c.customer_id = st.customer_id
)
SELECT
    *,
    CASE
        WHEN tenure_months <= 12 THEN '0-12 months'
        WHEN tenure_months <= 24 THEN '13-24 months'
        WHEN tenure_months <= 48 THEN '25-48 months'
        ELSE '49+ months'
    END AS tenure_group,
    ROUND(monthly_charges / (num_addons + 1), 2) AS charge_per_service,
    CASE WHEN contract = 'Month-to-month'
          AND payment_method = 'Electronic check' THEN 1 ELSE 0
    END AS mtm_echeck_flag,
    ROUND(monthly_charges - AVG(monthly_charges) OVER (PARTITION BY contract), 2)
        AS charge_vs_contract_avg
FROM base;