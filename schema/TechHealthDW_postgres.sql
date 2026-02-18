

/*******************************************************************************
   TechHealthDW (PostgreSQL)
   Script: TechHealthDW_postgres.sql
   Description: Creates and populates the TechHealthDW data warehouse (schema dw),
                including dimensions and fact tables with sample data.
   DB Server: PostgreSQL
   Author: Daniel Jane
   License: MIT (see LICENSE file in repository)
   Notes:
     - Run in order: create DB -> connect -> create schema/tables -> insert dimensions -> populate facts
     - Uses schema: dw
*******************************************************************************/

 
CREATE DATABASE techhealthdw;

 
CREATE SCHEMA IF NOT EXISTS dw;

 
-- dim_customer
 
CREATE TABLE dw.dim_customer (
    customer_sk INTEGER GENERATED ALWAYS AS IDENTITY,
    customer_id VARCHAR(20) NOT NULL,
    gender CHAR(1) NOT NULL,
    age SMALLINT NOT NULL,
    country VARCHAR(50) NOT NULL,
    subscription_type VARCHAR(50) NOT NULL,

    CONSTRAINT pk_customer_sk PRIMARY KEY (customer_sk),
    CONSTRAINT uq_customer_id UNIQUE (customer_id),
    CONSTRAINT chk_age CHECK (age > 0 AND age <= 120),
    CONSTRAINT chk_gender CHECK (gender IN ('M', 'F')),
    CONSTRAINT chk_subscription_type
        CHECK (subscription_type IN ('FREE','BASIC','PREMIUM','PRO'))
);

 
-- dim_product
 
CREATE TABLE dw.dim_product (
    product_sk INTEGER GENERATED ALWAYS AS IDENTITY,
    product_id VARCHAR(20) NOT NULL,
    product_name VARCHAR(100) NOT NULL,
    product_category VARCHAR(50) NOT NULL,
    product_type VARCHAR(50) NOT NULL,

    CONSTRAINT pk_product_sk PRIMARY KEY (product_sk),
    CONSTRAINT uq_product_id UNIQUE (product_id)
);

 
-- dim_region
 
CREATE TABLE dw.dim_region (
    region_sk INTEGER GENERATED ALWAYS AS IDENTITY,
    region_code VARCHAR(20) NOT NULL,
    region_name VARCHAR(50) NOT NULL,
    country VARCHAR(50) NOT NULL,
    market VARCHAR(50) NOT NULL,

    CONSTRAINT pk_region_sk PRIMARY KEY (region_sk),
    CONSTRAINT uq_region_code UNIQUE (region_code),
    CONSTRAINT chk_market
        CHECK (market IN ('North America','Europe','Asia','South America','Oceania'))
);

 
-- dim_date
 
CREATE TABLE dw.dim_date (
    date_sk INTEGER NOT NULL,      
    full_date DATE NOT NULL,
    calendar_day SMALLINT NOT NULL,
    calendar_month SMALLINT NOT NULL,
    calendar_month_name VARCHAR(9) NOT NULL,
    calendar_quarter SMALLINT NOT NULL,
    calendar_year SMALLINT NOT NULL,
    is_weekend BOOLEAN NOT NULL,

    CONSTRAINT pk_date_sk PRIMARY KEY (date_sk),
    CONSTRAINT uq_dim_date_full_date UNIQUE (full_date),
    CONSTRAINT chk_dim_date_calendar_day CHECK (calendar_day BETWEEN 1 AND 31),
    CONSTRAINT chk_dim_date_calendar_month CHECK (calendar_month BETWEEN 1 AND 12),
    CONSTRAINT chk_dim_date_calendar_quarter CHECK (calendar_quarter BETWEEN 1 AND 4)
);


--fact_sales 
 
CREATE TABLE dw.fact_sales (
    sales_fact_id BIGINT GENERATED ALWAYS AS IDENTITY NOT NULL,
    sale_id VARCHAR(20) NOT NULL,
    date_sk INT NOT NULL,
    customer_sk INT NOT NULL,
    product_sk INT NOT NULL,
    region_sk INT NOT NULL,
    quantity INT NOT NULL,
    unit_price NUMERIC(10,2) NOT NULL,
    discount NUMERIC(5,2) NOT NULL,
    net_amount NUMERIC(12,2) NOT NULL,

    CONSTRAINT pk_fact_sales PRIMARY KEY (sales_fact_id),

    CONSTRAINT fk_fact_sales_date
        FOREIGN KEY (date_sk) REFERENCES dw.dim_date(date_sk),

    CONSTRAINT fk_fact_sales_customer
        FOREIGN KEY (customer_sk) REFERENCES dw.dim_customer(customer_sk),

    CONSTRAINT fk_fact_sales_product
        FOREIGN KEY (product_sk) REFERENCES dw.dim_product(product_sk),

    CONSTRAINT fk_fact_sales_region
        FOREIGN KEY (region_sk) REFERENCES dw.dim_region(region_sk),

    CONSTRAINT chk_fact_sales_quantity CHECK (quantity > 0),
    CONSTRAINT chk_fact_sales_unit_price CHECK (unit_price >= 0),
    CONSTRAINT chk_fact_sales_discount CHECK (discount BETWEEN 0 AND 100),
    CONSTRAINT chk_fact_sales_net_amount CHECK (net_amount >= 0),

    CONSTRAINT uq_fact_sales_sale_product UNIQUE (sale_id, product_sk)
);

--dim_device


CREATE TABLE dw.dim_device (
    device_sk INTEGER GENERATED ALWAYS AS IDENTITY NOT NULL,
    device_id VARCHAR(30) NOT NULL,
    device_model VARCHAR(100) NOT NULL,
    device_type VARCHAR(50) NOT NULL,
    release_year SMALLINT NOT NULL,
    firmware_version VARCHAR(20) NOT NULL,
    has_gps BOOLEAN NOT NULL DEFAULT FALSE,
    has_heart_rate BOOLEAN NOT NULL DEFAULT FALSE,
    has_sleep_track BOOLEAN NOT NULL DEFAULT FALSE,

    CONSTRAINT pk_dim_device PRIMARY KEY (device_sk),

    CONSTRAINT uq_dim_device_device_id UNIQUE (device_id),

    CONSTRAINT chk_release_year 
        CHECK (release_year BETWEEN 2000 AND 2026),

    CONSTRAINT chk_device_type 
        CHECK (device_type IN (
            'Fitness Tracker',
            'Smartwatch',
            'Fitness Band',
            'Medical Device'
        ))
);


-- fact_device_usage_daily


CREATE TABLE dw.fact_device_usage_daily (
    device_usage_fact_id BIGINT GENERATED ALWAYS AS IDENTITY NOT NULL,

    date_sk INT NOT NULL,
    customer_sk INT NOT NULL,
    device_sk INT NOT NULL,

    usage_minutes INT NOT NULL,
    steps_count INT NOT NULL,
    workout_count INT NOT NULL,
    sleep_hours NUMERIC(4,2) NOT NULL,

    is_device_active BOOLEAN NOT NULL DEFAULT TRUE,

    CONSTRAINT pk_fact_device_usage_daily 
        PRIMARY KEY (device_usage_fact_id),

    CONSTRAINT fk_fact_usage_date
        FOREIGN KEY (date_sk) REFERENCES dw.dim_date(date_sk),

    CONSTRAINT fk_fact_usage_customer
        FOREIGN KEY (customer_sk) REFERENCES dw.dim_customer(customer_sk),

    CONSTRAINT fk_fact_usage_device
        FOREIGN KEY (device_sk) REFERENCES dw.dim_device(device_sk),

    CONSTRAINT uq_fact_usage_unique_day
        UNIQUE (date_sk, customer_sk, device_sk),

    CONSTRAINT chk_usage_minutes 
        CHECK (usage_minutes >= 0 AND usage_minutes <= 1440),

    CONSTRAINT chk_steps 
        CHECK (steps_count >= 0),

    CONSTRAINT chk_workout 
        CHECK (workout_count >= 0),

    CONSTRAINT chk_sleep 
        CHECK (sleep_hours >= 0 AND sleep_hours <= 24)
);

-- dim_month

CREATE TABLE dw.dim_month (
    month_sk INT NOT NULL,                  
    calendar_year SMALLINT NOT NULL,
    calendar_month SMALLINT NOT NULL,              
    month_name VARCHAR(9) NOT NULL,
    calendar_quarter SMALLINT NOT NULL,             
    month_start_date DATE NOT NULL,
    month_end_date DATE NOT NULL,

    CONSTRAINT pk_dim_month PRIMARY KEY (month_sk),
    UNIQUE (calendar_year, calendar_month),

    CONSTRAINT chk_dim_month_month 
        CHECK (calendar_month BETWEEN 1 AND 12),

    CONSTRAINT chk_dim_month_quarter 
        CHECK (calendar_quarter BETWEEN 1 AND 4)
);

-- Fact_user_engagement_monthly

CREATE TABLE dw.fact_user_engagement_monthly (
    user_engagement_fact_id BIGINT GENERATED ALWAYS AS IDENTITY NOT NULL,

    month_sk INT NOT NULL,
    customer_sk INT NOT NULL,

    active_days SMALLINT NOT NULL,
    total_usage_minutes INT NOT NULL,
    avg_daily_usage_minutes NUMERIC(10,2) NOT NULL,
    total_steps BIGINT NOT NULL,
    total_workouts INT NOT NULL,
    avg_sleep_hours NUMERIC(4,2) NOT NULL,
    is_month_active BOOLEAN NOT NULL DEFAULT TRUE,

    CONSTRAINT pk_fact_user_engagement_monthly
        PRIMARY KEY (user_engagement_fact_id),

    CONSTRAINT fk_fact_eng_month
        FOREIGN KEY (month_sk) REFERENCES dw.dim_month(month_sk),

    CONSTRAINT fk_fact_eng_customer
        FOREIGN KEY (customer_sk) REFERENCES dw.dim_customer(customer_sk),

    CONSTRAINT uq_fact_eng_month_customer
        UNIQUE (month_sk, customer_sk),

    CONSTRAINT chk_eng_active_days 
        CHECK (active_days BETWEEN 0 AND 31),

    CONSTRAINT chk_eng_total_usage 
        CHECK (total_usage_minutes >= 0),

    CONSTRAINT chk_eng_avg_daily_usage 
        CHECK (avg_daily_usage_minutes >= 0),

    CONSTRAINT chk_eng_total_steps 
        CHECK (total_steps >= 0),

    CONSTRAINT chk_eng_total_workouts 
        CHECK (total_workouts >= 0),

    CONSTRAINT chk_eng_avg_sleep 
        CHECK (avg_sleep_hours BETWEEN 0 AND 24)
);

 
 BEGIN;

 
--  DIM_REGION
 
INSERT INTO dw.dim_region (region_code, region_name, country, market)
VALUES
('NA-NE', 'Northeast', 'USA', 'North America'),
('NA-SE', 'Southeast', 'USA', 'North America'),
('NA-MW', 'Midwest',   'USA', 'North America'),
('NA-SW', 'Southwest', 'USA', 'North America'),
('NA-W',  'West',      'USA', 'North America'),
('NA-CA-ON', 'Ontario',          'CA', 'North America'),
('NA-CA-BC', 'British Columbia', 'CA', 'North America'),
('NA-CA-QC', 'Quebec',           'CA', 'North America'),
('EU-UK', 'United Kingdom', 'UK', 'Europe'),
('EU-IE', 'Ireland',        'IE', 'Europe'),
('EU-ES', 'Spain',          'ES', 'Europe'),
('EU-FR', 'France',         'FR', 'Europe'),
('EU-DE', 'Germany',        'DE', 'Europe'),
('EU-NL', 'Netherlands',    'NL', 'Europe'),
('EU-IT', 'Italy',          'IT', 'Europe'),
('EU-SE', 'Sweden',         'SE', 'Europe'),
('EU-NO', 'Norway',         'NO', 'Europe'),
('EU-DK', 'Denmark',        'DK', 'Europe'),
('EU-BE', 'Belgium',        'BE', 'Europe'),
('EU-CH', 'Switzerland',    'CH', 'Europe'),
('EU-AT', 'Austria',        'AT', 'Europe'),
('AS-SG', 'Singapore', 'SG', 'Asia'),
('AS-IN', 'India',     'IN', 'Asia'),
('AS-JP', 'Japan',     'JP', 'Asia'),
('OC-AU', 'Australia',   'AU', 'Oceania'),
('OC-NZ', 'New Zealand', 'NZ', 'Oceania'),
('SA-AR', 'Argentina', 'AR', 'South America'),
('SA-CL', 'Chile',     'CL', 'South America'),
('SA-MX', 'Mexico',    'MX', 'South America')
ON CONFLICT (region_code) DO NOTHING;


 
-- 1 DIM_PRODUCT
 
INSERT INTO dw.dim_product (product_id, product_name, product_category, product_type)
VALUES
('DEV-HT-LIT', 'HealthTrack Lite',  'Device', 'Wearable'),
('DEV-HT-PRO', 'HealthTrack Pro',   'Device', 'Wearable'),
('DEV-HT-ELT', 'HealthTrack Elite', 'Device', 'Wearable'),
('DEV-HT-AIR', 'HealthTrack Air',   'Device', 'Wearable'),
('DEV-HT-MAX', 'HealthTrack Max',   'Device', 'Wearable'),
('DEV-HT-KIDS','HealthTrack Kids',  'Device', 'Wearable'),
('DEV-MED-BP1', 'PulseCare BP Monitor',        'Device', 'Medical'),
('DEV-MED-GL1', 'GlucoSense Starter',          'Device', 'Medical'),
('DEV-MED-GL2', 'GlucoSense Advanced',         'Device', 'Medical'),
('DEV-MED-OX1', 'OxyTrack Pulse Oximeter',     'Device', 'Medical'),
('DEV-MED-ECG1','CardioPatch ECG Sensor',      'Device', 'Medical'),
('DEV-MED-TMP1','ThermoScan Smart Thermometer','Device', 'Medical'),
('SUB-FREE-M',  'Free Plan (Monthly)',      'Subscription', 'Plan'),
('SUB-BASIC-M', 'Basic Plan (Monthly)',     'Subscription', 'Plan'),
('SUB-PREM-M',  'Premium Plan (Monthly)',   'Subscription', 'Plan'),
('SUB-PRO-M',   'Pro Plan (Monthly)',       'Subscription', 'Plan'),
('SUB-BASIC-Y', 'Basic Plan (Annual)',      'Subscription', 'Plan'),
('SUB-PREM-Y',  'Premium Plan (Annual)',    'Subscription', 'Plan'),
('SUB-PRO-Y',   'Pro Plan (Annual)',        'Subscription', 'Plan'),
('SUB-ENT-Y',   'Enterprise Plan (Annual)', 'Subscription', 'Plan'),
('ADD-GPS',     'GPS Advanced Tracking Add-on', 'Subscription', 'Add-on'),
('ADD-HR',      'Heart Rate Analytics Add-on',  'Subscription', 'Add-on'),
('ADD-SLEEP',   'Sleep Insights Add-on',        'Subscription', 'Add-on'),
('ADD-COACH',   'AI Coaching Add-on',           'Subscription', 'Add-on'),
('ADD-FAMILY',  'Family Profiles Add-on',       'Subscription', 'Add-on'),
('ACC-BAND-BLK', 'Sports Band (Black)', 'Accessory', 'Band'),
('ACC-BAND-WHT', 'Sports Band (White)', 'Accessory', 'Band'),
('ACC-BAND-BLU', 'Sports Band (Blue)',  'Accessory', 'Band'),
('ACC-STRAP-LEA','Leather Strap',       'Accessory', 'Strap'),
('ACC-STRAP-MTL','Metal Strap',         'Accessory', 'Strap'),
('ACC-DOCK-STD', 'Charging Dock (Standard)', 'Accessory', 'Charger'),
('ACC-DOCK-FST', 'Charging Dock (Fast)',     'Accessory', 'Charger'),
('ACC-CBL-USBC', 'USB-C Charging Cable',     'Accessory', 'Cable'),
('ACC-ADP-20W',  'Power Adapter 20W',        'Accessory', 'Power'),
('ACC-CASE-SIL', 'Silicone Case',    'Accessory', 'Protection'),
('ACC-CASE-RGD', 'Rugged Case',      'Accessory', 'Protection'),
('ACC-SCR-GRD',  'Screen Protector', 'Accessory', 'Protection'),
('SRV-WAR-1Y',   'Extended Warranty (1 Year)', 'Service', 'Warranty'),
('SRV-WAR-2Y',   'Extended Warranty (2 Years)','Service', 'Warranty'),
('SRV-SUP-PRM',  'Premium Support',            'Service', 'Support'),
('SRV-SETUP',    'Device Setup Service',       'Service', 'Onboarding'),
('DIG-RPT-MON',  'Monthly Health Report',    'Digital', 'Report'),
('DIG-RPT-QTR',  'Quarterly Health Report',  'Digital', 'Report'),
('DIG-INS-ADV',  'Advanced Insights Pack',   'Digital', 'Insights')
ON CONFLICT (product_id) DO NOTHING;

 
-- DIM_CUSTOMER (200 rows)

INSERT INTO dw.dim_customer (customer_id, gender, age, country, subscription_type)
VALUES
('CUST-0001','M',25,'ES','FREE'),
('CUST-0002','F',31,'ES','BASIC'),
('CUST-0003','M',42,'ES','PREMIUM'),
('CUST-0004','F',29,'ES','BASIC'),
('CUST-0005','M',36,'ES','PRO'),
('CUST-0006','F',22,'ES','FREE'),
('CUST-0007','M',48,'ES','PREMIUM'),
('CUST-0008','F',34,'ES','BASIC'),
('CUST-0009','M',27,'ES','FREE'),
('CUST-0010','F',39,'ES','PREMIUM'),
('CUST-0011','M',45,'ES','PRO'),
('CUST-0012','F',30,'ES','BASIC'),
('CUST-0013','M',52,'ES','PREMIUM'),
('CUST-0014','F',41,'ES','BASIC'),
('CUST-0015','M',33,'ES','FREE'),
('CUST-0016','F',28,'US','BASIC'),
('CUST-0017','M',37,'US','PREMIUM'),
('CUST-0018','F',44,'US','PRO'),
('CUST-0019','M',23,'US','FREE'),
('CUST-0020','F',35,'US','PREMIUM'),
('CUST-0021','M',50,'US','PRO'),
('CUST-0022','F',31,'US','BASIC'),
('CUST-0023','M',29,'US','FREE'),
('CUST-0024','F',46,'US','PREMIUM'),
('CUST-0025','M',38,'US','BASIC'),
('CUST-0026','F',27,'US','FREE'),
('CUST-0027','M',41,'US','PREMIUM'),
('CUST-0028','F',53,'US','PRO'),
('CUST-0029','M',34,'US','BASIC'),
('CUST-0030','F',26,'US','FREE'),
('CUST-0031','M',32,'GB','BASIC'),
('CUST-0032','F',40,'GB','PREMIUM'),
('CUST-0033','M',36,'GB','PRO'),
('CUST-0034','F',24,'GB','FREE'),
('CUST-0035','M',47,'GB','PREMIUM'),
('CUST-0036','F',38,'IE','BASIC'),
('CUST-0037','M',28,'IE','FREE'),
('CUST-0038','F',42,'IE','PREMIUM'),
('CUST-0039','M',30,'IE','BASIC'),
('CUST-0040','F',35,'IE','PRO'),
('CUST-0041','M',39,'FR','PREMIUM'),
('CUST-0042','F',27,'FR','BASIC'),
('CUST-0043','M',45,'FR','PRO'),
('CUST-0044','F',34,'FR','FREE'),
('CUST-0045','M',50,'DE','PREMIUM'),
('CUST-0046','F',31,'DE','BASIC'),
('CUST-0047','M',29,'DE','FREE'),
('CUST-0048','F',37,'DE','PREMIUM'),
('CUST-0049','M',43,'IT','PRO'),
('CUST-0050','F',33,'IT','BASIC'),
('CUST-0051','M',28,'MX','FREE'),
('CUST-0052','F',36,'MX','BASIC'),
('CUST-0053','M',41,'MX','PREMIUM'),
('CUST-0054','F',30,'MX','FREE'),
('CUST-0055','M',47,'AR','PREMIUM'),
('CUST-0056','F',25,'AR','FREE'),
('CUST-0057','M',38,'AR','BASIC'),
('CUST-0058','F',34,'AR','PREMIUM'),
('CUST-0059','M',44,'CL','PRO'),
('CUST-0060','F',29,'CL','BASIC'),
('CUST-0061','M',33,'CA','PREMIUM'),
('CUST-0062','F',26,'CA','FREE'),
('CUST-0063','M',40,'CA','BASIC'),
('CUST-0064','F',35,'CA','PREMIUM'),
('CUST-0065','M',48,'CA','PRO'),
('CUST-0066','F',31,'SG','PREMIUM'),
('CUST-0067','M',27,'SG','BASIC'),
('CUST-0068','F',29,'IN','FREE'),
('CUST-0069','M',36,'IN','PREMIUM'),
('CUST-0070','F',42,'IN','PRO'),
('CUST-0071','M',34,'JP','PREMIUM'),
('CUST-0072','F',30,'JP','BASIC'),
('CUST-0073','M',45,'JP','PRO'),
('CUST-0074','F',32,'SE','PREMIUM'),
('CUST-0075','M',39,'SE','BASIC'),
('CUST-0076','F',44,'NO','PRO'),
('CUST-0077','M',28,'NO','FREE'),
('CUST-0078','F',36,'DK','PREMIUM'),
('CUST-0079','M',31,'AU','BASIC'),
('CUST-0080','F',27,'AU','FREE'),
('CUST-0081','M',38,'AU','PREMIUM'),
('CUST-0082','F',33,'NZ','PREMIUM'),
('CUST-0083','M',41,'NZ','PRO'),
('CUST-0084','F',29,'ES','FREE'),
('CUST-0085','M',37,'US','PREMIUM'),
('CUST-0086','F',46,'DE','PRO'),
('CUST-0087','M',34,'FR','BASIC'),
('CUST-0088','F',23,'GB','FREE'),
('CUST-0089','M',55,'US','PREMIUM'),
('CUST-0090','F',48,'CA','PRO'),
('CUST-0091','M',32,'IT','BASIC'),
('CUST-0092','F',40,'MX','PREMIUM'),
('CUST-0093','M',27,'AR','FREE'),
('CUST-0094','F',35,'JP','BASIC'),
('CUST-0095','M',44,'SG','PRO'),
('CUST-0096','F',38,'ES','PREMIUM'),
('CUST-0097','M',30,'US','BASIC'),
('CUST-0098','F',41,'FR','PREMIUM'),
('CUST-0099','M',36,'DE','FREE'),
('CUST-0100','F',49,'GB','PRO'),
('CUST-0101','M',52,'CA','PREMIUM'),
('CUST-0102','F',26,'IT','FREE'),
('CUST-0103','M',33,'ES','BASIC'),
('CUST-0104','F',45,'US','PRO'),
('CUST-0105','M',39,'AU','PREMIUM'),
('CUST-0106','F',28,'NZ','FREE'),
('CUST-0107','M',43,'SE','BASIC'),
('CUST-0108','F',34,'NO','PREMIUM'),
('CUST-0109','M',37,'DK','PRO'),
('CUST-0110','F',31,'SG','BASIC'),
('CUST-0111','M',29,'IN','FREE'),
('CUST-0112','F',42,'JP','PREMIUM'),
('CUST-0113','M',46,'CL','PRO'),
('CUST-0114','F',35,'MX','BASIC'),
('CUST-0115','M',27,'AR','FREE'),
('CUST-0116','F',38,'ES','PREMIUM'),
('CUST-0117','M',41,'US','PRO'),
('CUST-0118','F',33,'FR','BASIC'),
('CUST-0119','M',50,'DE','PREMIUM'),
('CUST-0120','F',28,'GB','FREE'),
('CUST-0121','M',34,'ES','BASIC'),
('CUST-0122','F',29,'ES','FREE'),
('CUST-0123','M',45,'ES','PREMIUM'),
('CUST-0124','F',37,'ES','PRO'),
('CUST-0125','M',31,'ES','FREE'),
('CUST-0126','F',28,'US','BASIC'),
('CUST-0127','M',39,'US','PREMIUM'),
('CUST-0128','F',47,'US','PRO'),
('CUST-0129','M',26,'US','FREE'),
('CUST-0130','F',35,'US','PREMIUM'),
('CUST-0131','M',33,'GB','BASIC'),
('CUST-0132','F',41,'GB','PREMIUM'),
('CUST-0133','M',29,'GB','FREE'),
('CUST-0134','F',44,'IE','PRO'),
('CUST-0135','M',36,'IE','BASIC'),
('CUST-0136','F',32,'FR','FREE'),
('CUST-0137','M',48,'FR','PREMIUM'),
('CUST-0138','F',27,'DE','BASIC'),
('CUST-0139','M',42,'DE','PRO'),
('CUST-0140','F',30,'IT','PREMIUM'),
('CUST-0141','M',35,'MX','BASIC'),
('CUST-0142','F',28,'MX','FREE'),
('CUST-0143','M',46,'AR','PREMIUM'),
('CUST-0144','F',39,'AR','PRO'),
('CUST-0145','M',31,'CL','BASIC'),
('CUST-0146','F',34,'CA','PREMIUM'),
('CUST-0147','M',27,'CA','FREE'),
('CUST-0148','F',43,'CA','PRO'),
('CUST-0149','M',38,'CA','BASIC'),
('CUST-0150','F',30,'CA','FREE'),
('CUST-0151','M',29,'SG','PREMIUM'),
('CUST-0152','F',36,'SG','BASIC'),
('CUST-0153','M',41,'IN','PRO'),
('CUST-0154','F',27,'IN','FREE'),
('CUST-0155','M',33,'JP','PREMIUM'),
('CUST-0156','F',45,'SE','PRO'),
('CUST-0157','M',30,'NO','BASIC'),
('CUST-0158','F',37,'DK','PREMIUM'),
('CUST-0159','M',28,'SE','FREE'),
('CUST-0160','F',42,'NO','BASIC'),
('CUST-0161','M',34,'AU','PREMIUM'),
('CUST-0162','F',26,'AU','FREE'),
('CUST-0163','M',40,'NZ','PRO'),
('CUST-0164','F',31,'NZ','BASIC'),
('CUST-0165','M',29,'AU','FREE'),
('CUST-0166','F',38,'ES','PREMIUM'),
('CUST-0167','M',44,'US','PRO'),
('CUST-0168','F',33,'FR','BASIC'),
('CUST-0169','M',27,'DE','FREE'),
('CUST-0170','F',35,'IT','PREMIUM'),
('CUST-0171','M',46,'MX','PRO'),
('CUST-0172','F',30,'AR','BASIC'),
('CUST-0173','M',28,'CL','FREE'),
('CUST-0174','F',41,'CA','PREMIUM'),
('CUST-0175','M',37,'US','BASIC'),
('CUST-0176','F',32,'GB','FREE'),
('CUST-0177','M',39,'IE','PREMIUM'),
('CUST-0178','F',45,'FR','PRO'),
('CUST-0179','M',31,'DE','BASIC'),
('CUST-0180','F',27,'IT','FREE'),
('CUST-0181','M',42,'SG','PREMIUM'),
('CUST-0182','F',34,'IN','BASIC'),
('CUST-0183','M',29,'JP','FREE'),
('CUST-0184','F',48,'SE','PRO'),
('CUST-0185','M',36,'NO','PREMIUM'),
('CUST-0186','F',30,'DK','BASIC'),
('CUST-0187','M',27,'AU','FREE'),
('CUST-0188','F',44,'NZ','PREMIUM'),
('CUST-0189','M',38,'ES','PRO'),
('CUST-0190','F',33,'US','BASIC'),
('CUST-0191','M',35,'FR','FREE'),
('CUST-0192','F',41,'DE','PREMIUM'),
('CUST-0193','M',28,'IT','BASIC'),
('CUST-0194','F',47,'MX','PRO'),
('CUST-0195','M',32,'AR','PREMIUM'),
('CUST-0196','F',26,'CL','FREE'),
('CUST-0197','M',40,'CA','BASIC'),
('CUST-0198','F',37,'GB','PREMIUM'),
('CUST-0199','M',45,'US','PRO'),
('CUST-0200','F',29,'ES','FREE')
ON CONFLICT (customer_id) DO NOTHING;




-- DIM_DATE (2024-01-01 → 2025-12-31)
 
INSERT INTO dw.dim_date
(date_sk, full_date, calendar_day, calendar_month, calendar_month_name, calendar_quarter, calendar_year, is_weekend)
SELECT
    (to_char(d, 'YYYYMMDD'))::int AS date_sk,
    d::date AS full_date,
    extract(day from d)::int AS calendar_day,
    extract(month from d)::int AS calendar_month,
    to_char(d, 'Month')::varchar(9) AS calendar_month_name,
    extract(quarter from d)::int AS calendar_quarter,
    extract(year from d)::int AS calendar_year,
    (extract(isodow from d) IN (6,7)) AS is_weekend
FROM generate_series(date '2024-01-01', date '2025-12-31', interval '1 day') AS d
ON CONFLICT (date_sk) DO NOTHING;


 
-- DIM_DEVICE
 
INSERT INTO dw.dim_device
(device_id, device_model, device_type, release_year, firmware_version, has_gps, has_heart_rate, has_sleep_track)
VALUES
('DEV-FT-001','HealthTrack Lite','Fitness Tracker',2022,'v1.0.3',FALSE,TRUE,TRUE),
('DEV-FT-002','HealthTrack Pro','Fitness Tracker',2023,'v1.2.1',TRUE,TRUE,TRUE),
('DEV-FT-003','HealthTrack Elite','Fitness Tracker',2024,'v2.0.0',TRUE,TRUE,TRUE),
('DEV-FT-004','HealthTrack Air','Fitness Tracker',2021,'v1.1.5',FALSE,TRUE,TRUE),
('DEV-FT-005','HealthTrack Max','Fitness Tracker',2025,'v2.3.2',TRUE,TRUE,TRUE),
('DEV-SW-001','PulseWatch S','Smartwatch',2023,'v3.1.0',TRUE,TRUE,TRUE),
('DEV-SW-002','PulseWatch X','Smartwatch',2024,'v3.4.2',TRUE,TRUE,TRUE),
('DEV-SW-003','PulseWatch Ultra','Smartwatch',2025,'v4.0.1',TRUE,TRUE,TRUE),
('DEV-SW-004','PulseWatch Mini','Smartwatch',2022,'v2.9.7',TRUE,TRUE,TRUE),
('DEV-FB-001','FitBand Basic','Fitness Band',2020,'v1.0.0',FALSE,TRUE,FALSE),
('DEV-FB-002','FitBand Plus','Fitness Band',2021,'v1.3.4',FALSE,TRUE,TRUE),
('DEV-FB-003','FitBand Active','Fitness Band',2023,'v2.1.2',FALSE,TRUE,TRUE),
('DEV-FB-004','FitBand Pro','Fitness Band',2024,'v2.5.0',TRUE,TRUE,TRUE),
('DEV-MD-001','GlucoSense Monitor','Medical Device',2022,'v1.8.3',FALSE,FALSE,FALSE),
('DEV-MD-002','PulseCare BP','Medical Device',2021,'v1.4.6',FALSE,TRUE,FALSE),
('DEV-MD-003','OxyTrack Sensor','Medical Device',2023,'v2.0.2',FALSE,TRUE,FALSE),
('DEV-MD-004','CardioPatch ECG','Medical Device',2024,'v2.2.1',FALSE,TRUE,FALSE),
('DEV-MD-005','ThermoScan Smart','Medical Device',2020,'v1.1.9',FALSE,FALSE,FALSE)
ON CONFLICT (device_id) DO NOTHING;

 
 
 
-- FACT_SALES   - CONSISTENT randoms per row (qty/price/discount/net_amount)
TRUNCATE TABLE dw.fact_sales RESTART IDENTITY;

WITH picks AS (
    SELECT
        gs AS n,

        d.date_sk,
        c.customer_sk,
        r.region_sk,
        p.product_sk,
        p.product_id,
        p.product_category,
        p.product_type,

        random() AS rnd_qty,
        random() AS rnd_price,
        random() AS rnd_disc
    FROM generate_series(1, 1000) gs
    -- 👇 30% 2024 (1..300), 70% 2025 (301..1000)
    CROSS JOIN LATERAL (
        SELECT date_sk
        FROM dw.dim_date
        WHERE calendar_year = CASE WHEN gs <= 300 THEN 2024 ELSE 2025 END
        ORDER BY random()
        LIMIT 1
    ) d
    CROSS JOIN LATERAL (SELECT customer_sk FROM dw.dim_customer ORDER BY random() LIMIT 1) c
    CROSS JOIN LATERAL (SELECT region_sk   FROM dw.dim_region   ORDER BY random() LIMIT 1) r
    CROSS JOIN LATERAL (
        SELECT product_sk, product_id, product_category, product_type
        FROM dw.dim_product
        ORDER BY random()
        LIMIT 1
    ) p
),
calc AS (
    SELECT
        'SALE-' || lpad(n::text, 6, '0') AS sale_id,
        date_sk,
        customer_sk,
        product_sk,
        region_sk,
        product_id,
        product_category,
        product_type,

        CASE
            WHEN product_category = 'Accessory'
                THEN 1 + floor(rnd_qty * 4)::int
            ELSE 1
        END AS quantity,

        round((
            CASE
                WHEN product_category = 'Device' AND product_type = 'Wearable'
                    THEN 79  + floor(rnd_price * 222)
                WHEN product_category = 'Device' AND product_type = 'Medical'
                    THEN 59  + floor(rnd_price * 291)

                WHEN product_category = 'Subscription' AND product_type = 'Plan' THEN
                    CASE
                        WHEN product_id LIKE 'SUB-FREE%'  THEN 0
                        WHEN product_id LIKE 'SUB-BASIC%' THEN 9.99  + floor(rnd_price * 6)
                        WHEN product_id LIKE 'SUB-PREM%'  THEN 17.99 + floor(rnd_price * 8)
                        WHEN product_id LIKE 'SUB-PRO%'   THEN 24.99 + floor(rnd_price * 16)
                        WHEN product_id LIKE 'SUB-ENT%'   THEN 199   + floor(rnd_price * 301)
                        ELSE 9.99
                    END

                WHEN product_category = 'Subscription' AND product_type = 'Add-on'
                    THEN 2.99 + floor(rnd_price * 8)

                WHEN product_category = 'Accessory' AND product_type IN ('Band','Strap')
                    THEN 9.99 + floor(rnd_price * 41)
                WHEN product_category = 'Accessory' AND product_type IN ('Charger','Cable','Power')
                    THEN 7.99 + floor(rnd_price * 32)
                WHEN product_category = 'Accessory' AND product_type = 'Protection'
                    THEN 4.99 + floor(rnd_price * 21)

                WHEN product_category = 'Service' AND product_type = 'Warranty'
                    THEN 19.99 + floor(rnd_price * 81)
                WHEN product_category = 'Service' AND product_type = 'Support'
                    THEN 9.99  + floor(rnd_price * 31)
                WHEN product_category = 'Service' AND product_type = 'Onboarding'
                    THEN 14.99 + floor(rnd_price * 46)

                WHEN product_category = 'Digital' AND product_type = 'Report'
                    THEN 3.99 + floor(rnd_price * 16)
                WHEN product_category = 'Digital' AND product_type = 'Insights'
                    THEN 7.99 + floor(rnd_price * 22)

                ELSE 9.99
            END
        )::numeric, 2) AS unit_price,

        (
            CASE floor(rnd_disc * 10)::int
                WHEN 0 THEN 5
                WHEN 1 THEN 10
                WHEN 2 THEN 15
                WHEN 3 THEN 20
                WHEN 4 THEN 25
                ELSE 0
            END
        )::numeric(5,2) AS discount
    FROM picks
)
INSERT INTO dw.fact_sales
(sale_id, date_sk, customer_sk, product_sk, region_sk, quantity, unit_price, discount, net_amount)
SELECT
    sale_id,
    date_sk,
    customer_sk,
    product_sk,
    region_sk,
    quantity,
    unit_price,
    discount,
    round((quantity::numeric * unit_price) * (1 - discount/100.0), 2)::numeric(12,2) AS net_amount
FROM calc;


 
--  FACT_DEVICE_USAGE_DAILY (5000 rows)
--    WE USE ON CONFLICT DO NOTHING TO RESPECT UNIQUE(date_sk, customer_sk, device_sk)
 
 INSERT INTO dw.fact_device_usage_daily
(date_sk, customer_sk, device_sk, usage_minutes, steps_count, workout_count, sleep_hours, is_device_active)
SELECT
    d.date_sk,
    c.customer_sk,
    dv.device_sk,
    CASE WHEN a.is_active THEN (30 + (floor(random()*271))::int) ELSE 0 END,
    CASE WHEN a.is_active THEN (1500 + (floor(random()*18501))::int) ELSE 0 END,
    CASE WHEN a.is_active THEN (floor(random()*3))::int ELSE 0 END,
    CASE WHEN a.is_active THEN round((4.50 + (floor(random()*551))/100.0)::numeric, 2) ELSE 0.00 END,
    a.is_active
FROM generate_series(1, 5000) gs
CROSS JOIN LATERAL (
    SELECT date_sk FROM dw.dim_date
    WHERE gs IS NOT NULL
    ORDER BY random() LIMIT 1
) d
CROSS JOIN LATERAL (
    SELECT customer_sk FROM dw.dim_customer
    WHERE gs IS NOT NULL
    ORDER BY random() LIMIT 1
) c
CROSS JOIN LATERAL (
    SELECT device_sk FROM dw.dim_device
    WHERE gs IS NOT NULL
    ORDER BY random() LIMIT 1
) dv
CROSS JOIN LATERAL (
    SELECT (random() < 0.8) AS is_active
) a
ON CONFLICT (date_sk, customer_sk, device_sk) DO NOTHING;


 
--   DIM_MONTH  
 
INSERT INTO dw.dim_month
(month_sk, calendar_year, calendar_month, month_name, calendar_quarter, month_start_date, month_end_date)
SELECT
    (calendar_year * 100 + calendar_month) AS month_sk,
    calendar_year,
    calendar_month,
    to_char(min(full_date), 'Month')::varchar(9) AS month_name,
    extract(quarter from min(full_date))::int AS calendar_quarter,
    min(full_date) AS month_start_date,
    max(full_date) AS month_end_date
FROM dw.dim_date
GROUP BY calendar_year, calendar_month
ON CONFLICT (month_sk) DO NOTHING;


 
--  FACT_USER_ENGAGEMENT_MONTHLY  


INSERT INTO dw.fact_user_engagement_monthly
(month_sk, customer_sk, active_days, total_usage_minutes, avg_daily_usage_minutes, total_steps, total_workouts, avg_sleep_hours, is_month_active)
SELECT
    (dd.calendar_year * 100 + dd.calendar_month) AS month_sk,
    f.customer_sk,
    SUM(CASE WHEN f.is_device_active THEN 1 ELSE 0 END)::smallint AS active_days,
    SUM(f.usage_minutes) AS total_usage_minutes,
    round(AVG(f.usage_minutes::numeric), 2) AS avg_daily_usage_minutes,
    SUM(f.steps_count::bigint) AS total_steps,
    SUM(f.workout_count) AS total_workouts,
    round(AVG(f.sleep_hours), 2) AS avg_sleep_hours,
    (SUM(CASE WHEN f.is_device_active THEN 1 ELSE 0 END) > 0) AS is_month_active
FROM dw.fact_device_usage_daily f
JOIN dw.dim_date dd ON dd.date_sk = f.date_sk
GROUP BY (dd.calendar_year * 100 + dd.calendar_month), f.customer_sk;

COMMIT;


-- FACT_SALES  
CREATE INDEX IF NOT EXISTS ix_fact_sales_date     ON dw.fact_sales(date_sk);
CREATE INDEX IF NOT EXISTS ix_fact_sales_customer ON dw.fact_sales(customer_sk);
CREATE INDEX IF NOT EXISTS ix_fact_sales_product  ON dw.fact_sales(product_sk);
CREATE INDEX IF NOT EXISTS ix_fact_sales_region   ON dw.fact_sales(region_sk);

-- FACT_DEVICE_USAGE_DAILY
 
CREATE INDEX IF NOT EXISTS ix_usage_customer_date ON dw.fact_device_usage_daily(customer_sk, date_sk);
CREATE INDEX IF NOT EXISTS ix_usage_device_date   ON dw.fact_device_usage_daily(device_sk, date_sk);

-- FACT_USER_ENGAGEMENT_MONTHLY
 
CREATE INDEX IF NOT EXISTS ix_eng_customer_month  ON dw.fact_user_engagement_monthly(customer_sk, month_sk);





