
/*******************************************************************************
   TechHealthDW (SQL Server)
   Script: TechHealthDW_sqlserver.sql
   Description: Creates and populates the TechHealthDW data warehouse (schema dw),
                including dimensions and fact tables with sample data.
   DB Server: Microsoft SQL Server
   Author: Dani Jane
   License: MIT (see LICENSE file in repository)
   Notes:
     - Run in order: create DB -> create schema/tables -> insert dimensions -> populate facts
     - Uses schema: dw
*******************************************************************************/

 
CREATE DATABASE TechHealthDW;
GO

USE TechHealthDW;
GO

CREATE SCHEMA dw;
GO

-- dim_customer

CREATE TABLE [dw].dim_customer (
    customer_sk INT IDENTITY (1,1),
    customer_id VARCHAR(20) NOT NULL ,  
    gender CHAR(1) NOT NULL ,
    age TINYINT NOT NULL ,
    country VARCHAR(50) NOT NULL ,
    subscription_type VARCHAR(50) NOT NULL ,

    CONSTRAINT pk_customer_sk PRIMARY KEY(customer_sk),
    CONSTRAINT uq_customer_id UNIQUE(customer_id),
    CONSTRAINT chk_age CHECK(age > 0 AND age <= 120),
    CONSTRAINT chk_gender CHECK(gender IN('M' , 'F')),

    CONSTRAINT chk_subscription_type 
        CHECK(subscription_type IN('FREE','BASIC','PREMIUM','PRO'))

);

-- dim_product

CREATE TABLE [dw].dim_product (
    product_sk INT IDENTITY(1,1),
    product_id VARCHAR(20) NOT NULL ,
    product_name VARCHAR(100) NOT NULL,
    product_category VARCHAR(50) NOT NULL,
    product_type VARCHAR(50) NOT NULL,

    CONSTRAINT pk_product_sk PRIMARY KEY(product_sk),
    CONSTRAINT uq_product_id UNIQUE(product_id)

)

-- dim_region


CREATE TABLE [dw].dim_region (
    region_sk INT IDENTITY(1,1) NOT NULL,
    region_code VARCHAR(20) NOT NULL,
    region_name VARCHAR(50) NOT NULL,
    country VARCHAR(50) NOT NULL,
    market VARCHAR(50) NOT NULL,

    CONSTRAINT pk_region_sk PRIMARY KEY(region_sk),
    CONSTRAINT uq_region_code UNIQUE(region_code),

    CONSTRAINT chk_market 
        CHECK (market IN ('North America','Europe','Asia','South America','Oceania'))
);


-- dim_date

CREATE TABLE [dw].dim_date (
    date_sk    INT       NOT NULL PRIMARY KEY,   
    full_date  DATE      NOT NULL,
    calendar_day TINYINT   NOT NULL,
    calendar_month TINYINT   NOT NULL,
    month_name VARCHAR(9) NOT NULL,
    calendar_quarter TINYINT   NOT NULL,
    calendar_year SMALLINT  NOT NULL,
    is_weekend BIT NOT NULL,

    CONSTRAINT uq_dim_date_full_date UNIQUE (full_date),

    CONSTRAINT chk_dim_date_calendar_day     CHECK (calendar_day BETWEEN 1 AND 31),
    CONSTRAINT chk_dim_date_calendar_month   CHECK (calendar_month BETWEEN 1 AND 12),
    CONSTRAINT chk_dim_date_calendar_quarter CHECK (calendar_quarter BETWEEN 1 AND 4)
);


-- fact_sales 
CREATE TABLE [dw].[fact_sales] (
    sales_fact_id BIGINT IDENTITY(1,1) NOT NULL,
    sale_id VARCHAR(20) NOT NULL,
    date_sk INT NOT NULL,
    customer_sk INT NOT NULL,
    product_sk INT NOT NULL,
    region_sk INT NOT NULL,
    quantity INT NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    discount DECIMAL(5,2) NOT NULL,
    net_amount DECIMAL(12,2) NOT NULL,

    CONSTRAINT pk_fact_sales PRIMARY KEY (sales_fact_id),

    CONSTRAINT fk_fact_sales_date
        FOREIGN KEY (date_sk) REFERENCES [dw].[dim_date](date_sk),

    CONSTRAINT fk_fact_sales_customer
        FOREIGN KEY (customer_sk) REFERENCES [dw].[dim_customer](customer_sk),

    CONSTRAINT fk_fact_sales_product
        FOREIGN KEY (product_sk) REFERENCES [dw].[dim_product](product_sk),

    CONSTRAINT fk_fact_sales_region
        FOREIGN KEY (region_sk) REFERENCES [dw].[dim_region](region_sk),

    CONSTRAINT chk_fact_sales_quantity CHECK (quantity > 0),
    CONSTRAINT chk_fact_sales_unit_price CHECK (unit_price >= 0),
    CONSTRAINT chk_fact_sales_discount CHECK (discount BETWEEN 0 AND 100),
    CONSTRAINT chk_fact_sales_net_amount CHECK (net_amount >= 0),

    CONSTRAINT uq_fact_sales_sale_product UNIQUE (sale_id, product_sk)
);

 

--dim_device

CREATE TABLE [dw].[dim_device] (
    device_sk INT IDENTITY(1,1) NOT NULL,
    device_id VARCHAR(30) NOT NULL,           
    device_model VARCHAR(100) NOT NULL,
    device_type VARCHAR(50) NOT NULL,
    release_year SMALLINT NOT NULL,
    firmware_version VARCHAR(20) NOT NULL,
    has_gps BIT NOT NULL DEFAULT 0,
    has_heart_rate BIT NOT NULL DEFAULT 0,
    has_sleep_track BIT NOT NULL DEFAULT 0,

    CONSTRAINT pk_dim_device PRIMARY KEY (device_sk),

    CONSTRAINT uq_dim_device_device_id UNIQUE (device_id),

    CONSTRAINT chk_release_year CHECK (release_year BETWEEN 2000 AND 2026 ),

    CONSTRAINT chk_device_type CHECK (device_type IN ('Fitness Tracker','Smartwatch','Fitness Band','Medical Device'))

    
);


-- Fact_device_usage_daily

CREATE TABLE [dw].[fact_device_usage_daily] (
    device_usage_fact_id BIGINT IDENTITY(1,1) NOT NULL,

    date_sk INT NOT NULL,
    customer_sk INT NOT NULL,
    device_sk INT NOT NULL,

    usage_minutes INT NOT NULL,
    steps_count INT NOT NULL,
    workout_count INT NOT NULL,
    sleep_hours DECIMAL(4,2) NOT NULL,

    is_device_active BIT NOT NULL DEFAULT 1,

    CONSTRAINT pk_fact_device_usage_daily 
        PRIMARY KEY (device_usage_fact_id),

    CONSTRAINT fk_fact_usage_date
        FOREIGN KEY (date_sk) REFERENCES [dw].[dim_date](date_sk),

    CONSTRAINT fk_fact_usage_customer
        FOREIGN KEY (customer_sk) REFERENCES [dw].[dim_customer](customer_sk),

    CONSTRAINT fk_fact_usage_device
        FOREIGN KEY (device_sk) REFERENCES [dw].[dim_device](device_sk),

    CONSTRAINT uq_fact_usage_unique_day
        UNIQUE (date_sk, customer_sk, device_sk),

    CONSTRAINT chk_usage_minutes CHECK (usage_minutes >= 0 AND usage_minutes <= 1440),
    CONSTRAINT chk_steps CHECK (steps_count >= 0),
    CONSTRAINT chk_workout CHECK (workout_count >= 0),
    CONSTRAINT chk_sleep CHECK (sleep_hours >= 0 AND sleep_hours <= 24)
);


-- dim_month 


CREATE TABLE [dw].[dim_month] (
    month_sk INT NOT NULL,                
    calendar_year SMALLINT NOT NULL,
    calendar_month TINYINT NOT NULL,               
    month_name VARCHAR(9) NOT NULL,        
    calendar_quarter TINYINT NOT NULL,              
    month_start_date DATE NOT NULL,
    month_end_date DATE NOT NULL,

    CONSTRAINT pk_dim_month PRIMARY KEY (month_sk),
    UNIQUE (calendar_year, calendar_month),
    CONSTRAINT chk_dim_month_month CHECK (calendar_month BETWEEN 1 AND 12),
    CONSTRAINT chk_dim_month_quarter CHECK (calendar_quarter BETWEEN 1 AND 4)
);


-- Fact_user_engagement_monthly


CREATE TABLE [dw].[fact_user_engagement_monthly] (
    user_engagement_fact_id BIGINT IDENTITY(1,1) NOT NULL,

    month_sk INT NOT NULL,           
    customer_sk INT NOT NULL,

    active_days TINYINT NOT NULL,
    total_usage_minutes INT NOT NULL,
    avg_daily_usage_minutes DECIMAL(10,2) NOT NULL,
    total_steps BIGINT NOT NULL,
    total_workouts INT NOT NULL,
    avg_sleep_hours DECIMAL(4,2) NOT NULL,
    is_month_active BIT NOT NULL DEFAULT 1,

    CONSTRAINT pk_fact_user_engagement_monthly
        PRIMARY KEY (user_engagement_fact_id),

    CONSTRAINT fk_fact_eng_month
        FOREIGN KEY (month_sk) REFERENCES [dw].[dim_month](month_sk),

    CONSTRAINT fk_fact_eng_customer
        FOREIGN KEY (customer_sk) REFERENCES [dw].[dim_customer](customer_sk),

    CONSTRAINT uq_fact_eng_month_customer
        UNIQUE (month_sk, customer_sk),

    
    CONSTRAINT chk_eng_active_days CHECK (active_days BETWEEN 0 AND 31),
    CONSTRAINT chk_eng_total_usage CHECK (total_usage_minutes >= 0),
    CONSTRAINT chk_eng_avg_daily_usage CHECK (avg_daily_usage_minutes >= 0),
    CONSTRAINT chk_eng_total_steps CHECK (total_steps >= 0),
    CONSTRAINT chk_eng_total_workouts CHECK (total_workouts >= 0),
    CONSTRAINT chk_eng_avg_sleep CHECK (avg_sleep_hours BETWEEN 0 AND 24)
);


--------



INSERT INTO [dw].[dim_region] (region_code, region_name, country, market)
VALUES
-- North America (USA)
('NA-NE', 'Northeast', 'USA', 'North America'),
('NA-SE', 'Southeast', 'USA', 'North America'),
('NA-MW', 'Midwest',   'USA', 'North America'),
('NA-SW', 'Southwest', 'USA', 'North America'),
('NA-W',  'West',      'USA', 'North America'),

-- Canada
('NA-CA-ON', 'Ontario',           'CA', 'North America'),
('NA-CA-BC', 'British Columbia',  'CA', 'North America'),
('NA-CA-QC', 'Quebec',            'CA', 'North America'),

-- Europe
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

-- Asia
('AS-SG', 'Singapore', 'SG', 'Asia'),
('AS-IN', 'India',     'IN', 'Asia'),
('AS-JP', 'Japan',     'JP', 'Asia'),

-- Oceania
('OC-AU', 'Australia',     'AU', 'Oceania'),
('OC-NZ', 'New Zealand',   'NZ', 'Oceania'),

-- South America
('SA-AR', 'Argentina', 'AR', 'South America'),
('SA-CL', 'Chile',     'CL', 'South America'),
('SA-MX', 'Mexico',    'MX', 'South America');



INSERT INTO [dw].[dim_product] (product_id, product_name, product_category, product_type)
VALUES
 
-- DEVICES (Wearables)
 
('DEV-HT-LIT', 'HealthTrack Lite',  'Device', 'Wearable'),
('DEV-HT-PRO', 'HealthTrack Pro',   'Device', 'Wearable'),
('DEV-HT-ELT', 'HealthTrack Elite', 'Device', 'Wearable'),
('DEV-HT-AIR', 'HealthTrack Air',   'Device', 'Wearable'),
('DEV-HT-MAX', 'HealthTrack Max',   'Device', 'Wearable'),
('DEV-HT-KIDS','HealthTrack Kids',  'Device', 'Wearable'),

 
-- DEVICES (Medical)
 
('DEV-MED-BP1', 'PulseCare BP Monitor',      'Device', 'Medical'),
('DEV-MED-GL1', 'GlucoSense Starter',        'Device', 'Medical'),
('DEV-MED-GL2', 'GlucoSense Advanced',       'Device', 'Medical'),
('DEV-MED-OX1', 'OxyTrack Pulse Oximeter',   'Device', 'Medical'),
('DEV-MED-ECG1','CardioPatch ECG Sensor',    'Device', 'Medical'),
('DEV-MED-TMP1','ThermoScan Smart Thermometer','Device','Medical'),

 
-- SUBSCRIPTIONS (Plans)
 
('SUB-FREE-M',  'Free Plan (Monthly)',        'Subscription', 'Plan'),
('SUB-BASIC-M', 'Basic Plan (Monthly)',       'Subscription', 'Plan'),
('SUB-PREM-M',  'Premium Plan (Monthly)',     'Subscription', 'Plan'),
('SUB-PRO-M',   'Pro Plan (Monthly)',         'Subscription', 'Plan'),
('SUB-BASIC-Y', 'Basic Plan (Annual)',        'Subscription', 'Plan'),
('SUB-PREM-Y',  'Premium Plan (Annual)',      'Subscription', 'Plan'),
('SUB-PRO-Y',   'Pro Plan (Annual)',          'Subscription', 'Plan'),
('SUB-ENT-Y',   'Enterprise Plan (Annual)',   'Subscription', 'Plan'),

 
-- SUBSCRIPTIONS (Add-ons)
 
('ADD-GPS',     'GPS Advanced Tracking Add-on',     'Subscription', 'Add-on'),
('ADD-HR',      'Heart Rate Analytics Add-on',      'Subscription', 'Add-on'),
('ADD-SLEEP',   'Sleep Insights Add-on',            'Subscription', 'Add-on'),
('ADD-COACH',   'AI Coaching Add-on',               'Subscription', 'Add-on'),
('ADD-FAMILY',  'Family Profiles Add-on',           'Subscription', 'Add-on'),

 
-- ACCESSORIES (Bands / Straps)
 
('ACC-BAND-BLK', 'Sports Band (Black)',   'Accessory', 'Band'),
('ACC-BAND-WHT', 'Sports Band (White)',   'Accessory', 'Band'),
('ACC-BAND-BLU', 'Sports Band (Blue)',    'Accessory', 'Band'),
('ACC-STRAP-LEA','Leather Strap',         'Accessory', 'Strap'),
('ACC-STRAP-MTL','Metal Strap',           'Accessory', 'Strap'),

 
-- ACCESSORIES (Charging / Power)
 
('ACC-DOCK-STD', 'Charging Dock (Standard)',  'Accessory', 'Charger'),
('ACC-DOCK-FST', 'Charging Dock (Fast)',      'Accessory', 'Charger'),
('ACC-CBL-USBC', 'USB-C Charging Cable',      'Accessory', 'Cable'),
('ACC-ADP-20W',  'Power Adapter 20W',         'Accessory', 'Power'),

 
-- ACCESSORIES (Protection)
 
('ACC-CASE-SIL', 'Silicone Case',      'Accessory', 'Protection'),
('ACC-CASE-RGD', 'Rugged Case',        'Accessory', 'Protection'),
('ACC-SCR-GRD',  'Screen Protector',   'Accessory', 'Protection'),

 
-- SERVICES (Support / Warranty)

('SRV-WAR-1Y',   'Extended Warranty (1 Year)', 'Service', 'Warranty'),
('SRV-WAR-2Y',   'Extended Warranty (2 Years)', 'Service', 'Warranty'),
('SRV-SUP-PRM',  'Premium Support',            'Service', 'Support'),
('SRV-SETUP',    'Device Setup Service',       'Service', 'Onboarding'),

-- DIGITAL (Reports / Insights)

('DIG-RPT-MON',  'Monthly Health Report',  'Digital', 'Report'),
('DIG-RPT-QTR',  'Quarterly Health Report','Digital', 'Report'),
('DIG-INS-ADV',  'Advanced Insights Pack', 'Digital', 'Insights');



INSERT INTO [dw].[dim_customer] 
(customer_id, gender, age, country, subscription_type)
VALUES

 
-- SPAIN (EU-ES)
 
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

 
-- USA  
 
('CUST-0016','F',28,'USA','BASIC'),
('CUST-0017','M',37,'USA','PREMIUM'),
('CUST-0018','F',44,'USA','PRO'),
('CUST-0019','M',23,'USA','FREE'),
('CUST-0020','F',35,'USA','PREMIUM'),
('CUST-0021','M',50,'USA','PRO'),
('CUST-0022','F',31,'USA','BASIC'),
('CUST-0023','M',29,'USA','FREE'),
('CUST-0024','F',46,'USA','PREMIUM'),
('CUST-0025','M',38,'USA','BASIC'),
('CUST-0026','F',27,'USA','FREE'),
('CUST-0027','M',41,'USA','PREMIUM'),
('CUST-0028','F',53,'USA','PRO'),
('CUST-0029','M',34,'USA','BASIC'),
('CUST-0030','F',26,'USA','FREE'),

 
-- UK / IE
 
('CUST-0031','M',32,'UK','BASIC'),
('CUST-0032','F',40,'UK','PREMIUM'),
('CUST-0033','M',36,'UK','PRO'),
('CUST-0034','F',24,'UK','FREE'),
('CUST-0035','M',47,'UK','PREMIUM'),
('CUST-0036','F',38,'IE','BASIC'),
('CUST-0037','M',28,'IE','FREE'),
('CUST-0038','F',42,'IE','PREMIUM'),
('CUST-0039','M',30,'IE','BASIC'),
('CUST-0040','F',35,'IE','PRO'),

 
-- FR / DE / IT
 
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

 
-- LATAM
 
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

 
-- CANADA
 
('CUST-0061','M',33,'CA','PREMIUM'),
('CUST-0062','F',26,'CA','FREE'),
('CUST-0063','M',40,'CA','BASIC'),
('CUST-0064','F',35,'CA','PREMIUM'),
('CUST-0065','M',48,'CA','PRO'),

 
-- ASIA
 
('CUST-0066','F',31,'SG','PREMIUM'),
('CUST-0067','M',27,'SG','BASIC'),
('CUST-0068','F',29,'IN','FREE'),
('CUST-0069','M',36,'IN','PREMIUM'),
('CUST-0070','F',42,'IN','PRO'),
('CUST-0071','M',34,'JP','PREMIUM'),
('CUST-0072','F',30,'JP','BASIC'),
('CUST-0073','M',45,'JP','PRO'),

 
-- NORDICS
 
('CUST-0074','F',32,'SE','PREMIUM'),
('CUST-0075','M',39,'SE','BASIC'),
('CUST-0076','F',44,'NO','PRO'),
('CUST-0077','M',28,'NO','FREE'),
('CUST-0078','F',36,'DK','PREMIUM'),

 
-- AU / NZ
 
('CUST-0079','M',31,'AU','BASIC'),
('CUST-0080','F',27,'AU','FREE'),
('CUST-0081','M',38,'AU','PREMIUM'),
('CUST-0082','F',33,'NZ','PREMIUM'),
('CUST-0083','M',41,'NZ','PRO'),

 
-- EXTRA MIX  
 
('CUST-0084','F',29,'ES','FREE'),
('CUST-0085','M',37,'USA','PREMIUM'),
('CUST-0086','F',46,'DE','PRO'),
('CUST-0087','M',34,'FR','BASIC'),
('CUST-0088','F',23,'UK','FREE'),
('CUST-0089','M',55,'USA','PREMIUM'),
('CUST-0090','F',48,'CA','PRO'),
('CUST-0091','M',32,'IT','BASIC'),
('CUST-0092','F',40,'MX','PREMIUM'),
('CUST-0093','M',27,'AR','FREE'),
('CUST-0094','F',35,'JP','BASIC'),
('CUST-0095','M',44,'SG','PRO'),
('CUST-0096','F',38,'ES','PREMIUM'),
('CUST-0097','M',30,'USA','BASIC'),
('CUST-0098','F',41,'FR','PREMIUM'),
('CUST-0099','M',36,'DE','FREE'),
('CUST-0100','F',49,'UK','PRO'),
('CUST-0101','M',52,'CA','PREMIUM'),
('CUST-0102','F',26,'IT','FREE'),
('CUST-0103','M',33,'ES','BASIC'),
('CUST-0104','F',45,'USA','PRO'),
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
('CUST-0117','M',41,'USA','PRO'),
('CUST-0118','F',33,'FR','BASIC'),
('CUST-0119','M',50,'DE','PREMIUM'),
('CUST-0120','F',28,'UK','FREE'),
('CUST-0121','M',34,'ES','BASIC'),
('CUST-0122','F',29,'ES','FREE'),
('CUST-0123','M',45,'ES','PREMIUM'),
('CUST-0124','F',37,'ES','PRO'),
('CUST-0125','M',31,'ES','FREE'),
('CUST-0126','F',28,'USA','BASIC'),
('CUST-0127','M',39,'USA','PREMIUM'),
('CUST-0128','F',47,'USA','PRO'),
('CUST-0129','M',26,'USA','FREE'),
('CUST-0130','F',35,'USA','PREMIUM'),
('CUST-0131','M',33,'UK','BASIC'),
('CUST-0132','F',41,'UK','PREMIUM'),
('CUST-0133','M',29,'UK','FREE'),
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
('CUST-0167','M',44,'USA','PRO'),
('CUST-0168','F',33,'FR','BASIC'),
('CUST-0169','M',27,'DE','FREE'),
('CUST-0170','F',35,'IT','PREMIUM'),
('CUST-0171','M',46,'MX','PRO'),
('CUST-0172','F',30,'AR','BASIC'),
('CUST-0173','M',28,'CL','FREE'),
('CUST-0174','F',41,'CA','PREMIUM'),
('CUST-0175','M',37,'USA','BASIC'),
('CUST-0176','F',32,'UK','FREE'),
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
('CUST-0190','F',33,'USA','BASIC'),
('CUST-0191','M',35,'FR','FREE'),
('CUST-0192','F',41,'DE','PREMIUM'),
('CUST-0193','M',28,'IT','BASIC'),
('CUST-0194','F',47,'MX','PRO'),
('CUST-0195','M',32,'AR','PREMIUM'),
('CUST-0196','F',26,'CL','FREE'),
('CUST-0197','M',40,'CA','BASIC'),
('CUST-0198','F',37,'UK','PREMIUM'),
('CUST-0199','M',45,'USA','PRO'),
('CUST-0200','F',29,'ES','FREE');


 
-- DIM_DATE  (2024-01-01 → 2025-12-31)
 

SET NOCOUNT ON;
SET DATEFIRST 1;  -- Lunes = 1

DECLARE @StartDate DATE = '2024-01-01';
DECLARE @EndDate   DATE = '2025-12-31';

DECLARE @d DATE = @StartDate;

WHILE @d <= @EndDate
BEGIN
    IF NOT EXISTS (SELECT 1 FROM dw.dim_date WHERE full_date = @d)
    BEGIN
        INSERT INTO dw.dim_date
        (
            date_sk,
            full_date,
            calendar_day,
            calendar_month,
            month_name,
            calendar_quarter,
            calendar_year,
            is_weekend
        )
        VALUES
        (
            CAST(CONVERT(VARCHAR(8), @d, 112) AS INT),  -- YYYYMMDD
            @d,
            DAY(@d),
            MONTH(@d),
            DATENAME(MONTH, @d),
            DATEPART(QUARTER, @d),
            YEAR(@d),
            CASE WHEN DATEPART(WEEKDAY, @d) IN (6,7) THEN 1 ELSE 0 END
        );
    END;

    SET @d = DATEADD(DAY, 1, @d);
END;

 
 
-- FACT_SALES -  (50% 2024 / 50% 2025)

 
;WITH
-- 1) Generate 1..2000
N AS (
    SELECT TOP (2000)
        ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS rn
    FROM sys.all_objects a
    CROSS JOIN sys.all_objects b
),

Customers AS (
    SELECT
        customer_sk,
        ROW_NUMBER() OVER (ORDER BY customer_sk) AS n,
        COUNT(*) OVER () AS cnt
    FROM dw.dim_customer
),
Products AS (
    SELECT
        product_sk,
        product_id,
        product_category,
        product_type,
        ROW_NUMBER() OVER (ORDER BY product_sk) AS n,
        COUNT(*) OVER () AS cnt
    FROM dw.dim_product
),
Regions AS (
    SELECT
        region_sk,
        ROW_NUMBER() OVER (ORDER BY region_sk) AS n,
        COUNT(*) OVER () AS cnt
    FROM dw.dim_region
),
Dates2024 AS (
    SELECT
        date_sk,
        ROW_NUMBER() OVER (ORDER BY full_date) AS n,
        COUNT(*) OVER () AS cnt
    FROM dw.dim_date
    WHERE calendar_year = 2024
),
Dates2025 AS (
    SELECT
        date_sk,
        ROW_NUMBER() OVER (ORDER BY full_date) AS n,
        COUNT(*) OVER () AS cnt
    FROM dw.dim_date
    WHERE calendar_year = 2025
),

Pick AS (
    SELECT
        n.rn,
        CONCAT('SALE-', RIGHT(CONCAT('000000', n.rn), 6)) AS sale_id,

        CASE
            WHEN n.rn <= 1000 THEN d24.date_sk
            ELSE d25.date_sk
        END AS date_sk,

        c.customer_sk,
        r.region_sk,
        p.product_sk,
        p.product_id,
        p.product_category,
        p.product_type
    FROM N n

    JOIN Customers c
      ON c.n = ((n.rn - 1) % c.cnt) + 1

    JOIN Regions r
      ON r.n = ((n.rn - 1 + 7) % r.cnt) + 1

    JOIN Products p
      ON p.n = ((n.rn - 1 + 13) % p.cnt) + 1

    LEFT JOIN Dates2024 d24
      ON d24.n = ((n.rn - 1) % d24.cnt) + 1

    LEFT JOIN Dates2025 d25
      ON d25.n = ((n.rn - 1) % d25.cnt) + 1
),

Calc AS (
    SELECT
        p.*,

        CASE
            WHEN p.product_category = 'Accessory' THEN 1 + (p.rn % 4)
            ELSE 1
        END AS quantity,

        CAST(
            CASE (p.rn % 6)
                WHEN 0 THEN 0
                WHEN 1 THEN 5
                WHEN 2 THEN 10
                WHEN 3 THEN 15
                WHEN 4 THEN 20
                ELSE 25
            END
        AS DECIMAL(5,2)) AS discount,

        CAST(ROUND(
            CASE
                WHEN p.product_category = 'Device' AND p.product_type = 'Wearable'
                    THEN 79.00 + (p.rn % 220)
                WHEN p.product_category = 'Device' AND p.product_type = 'Medical'
                    THEN 59.00 + (p.rn % 290)

                WHEN p.product_category = 'Subscription' AND p.product_type = 'Plan'
                    THEN
                        CASE
                            WHEN p.product_id LIKE 'SUB-FREE%'  THEN 0.00
                            WHEN p.product_id LIKE 'SUB-BASIC%' THEN 9.99  + (p.rn % 5)
                            WHEN p.product_id LIKE 'SUB-PREM%'  THEN 17.99 + (p.rn % 7)
                            WHEN p.product_id LIKE 'SUB-PRO%'   THEN 24.99 + (p.rn % 15)
                            WHEN p.product_id LIKE 'SUB-ENT%'   THEN 199.00 + (p.rn % 300)
                            ELSE 9.99
                        END

                WHEN p.product_category = 'Subscription' AND p.product_type = 'Add-on'
                    THEN 2.99 + (p.rn % 7)

                WHEN p.product_category = 'Accessory' AND p.product_type IN ('Band','Strap')
                    THEN 9.99 + (p.rn % 40)
                WHEN p.product_category = 'Accessory' AND p.product_type IN ('Charger','Cable','Power')
                    THEN 7.99 + (p.rn % 30)
                WHEN p.product_category = 'Accessory' AND p.product_type = 'Protection'
                    THEN 4.99 + (p.rn % 20)

                WHEN p.product_category = 'Service' AND p.product_type = 'Warranty'
                    THEN 19.99 + (p.rn % 80)
                WHEN p.product_category = 'Service' AND p.product_type = 'Support'
                    THEN 9.99 + (p.rn % 30)
                WHEN p.product_category = 'Service' AND p.product_type = 'Onboarding'
                    THEN 14.99 + (p.rn % 45)

                WHEN p.product_category = 'Digital' AND p.product_type = 'Report'
                    THEN 3.99 + (p.rn % 15)
                WHEN p.product_category = 'Digital' AND p.product_type = 'Insights'
                    THEN 7.99 + (p.rn % 20)

                ELSE 9.99
            END
        , 2) AS DECIMAL(10,2)) AS unit_price
    FROM Pick p
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
    CAST(ROUND(quantity * unit_price * (1 - discount/100.0), 2) AS DECIMAL(12,2))
FROM Calc;




INSERT INTO [dw].[dim_device]
(device_id, device_model, device_type, release_year, firmware_version, has_gps, has_heart_rate, has_sleep_track)
VALUES

 
-- FITNESS TRACKERS
 

('DEV-FT-001','HealthTrack Lite','Fitness Tracker',2022,'v1.0.3',0,1,1),
('DEV-FT-002','HealthTrack Pro','Fitness Tracker',2023,'v1.2.1',1,1,1),
('DEV-FT-003','HealthTrack Elite','Fitness Tracker',2024,'v2.0.0',1,1,1),
('DEV-FT-004','HealthTrack Air','Fitness Tracker',2021,'v1.1.5',0,1,1),
('DEV-FT-005','HealthTrack Max','Fitness Tracker',2025,'v2.3.2',1,1,1),

 
-- SMARTWATCHES
 

('DEV-SW-001','PulseWatch S','Smartwatch',2023,'v3.1.0',1,1,1),
('DEV-SW-002','PulseWatch X','Smartwatch',2024,'v3.4.2',1,1,1),
('DEV-SW-003','PulseWatch Ultra','Smartwatch',2025,'v4.0.1',1,1,1),
('DEV-SW-004','PulseWatch Mini','Smartwatch',2022,'v2.9.7',1,1,1),

 
-- FITNESS BANDS
 

('DEV-FB-001','FitBand Basic','Fitness Band',2020,'v1.0.0',0,1,0),
('DEV-FB-002','FitBand Plus','Fitness Band',2021,'v1.3.4',0,1,1),
('DEV-FB-003','FitBand Active','Fitness Band',2023,'v2.1.2',0,1,1),
('DEV-FB-004','FitBand Pro','Fitness Band',2024,'v2.5.0',1,1,1),

 
-- MEDICAL DEVICES
 

('DEV-MD-001','GlucoSense Monitor','Medical Device',2022,'v1.8.3',0,0,0),
('DEV-MD-002','PulseCare BP','Medical Device',2021,'v1.4.6',0,1,0),
('DEV-MD-003','OxyTrack Sensor','Medical Device',2023,'v2.0.2',0,1,0),
('DEV-MD-004','CardioPatch ECG','Medical Device',2024,'v2.2.1',0,1,0),
('DEV-MD-005','ThermoScan Smart','Medical Device',2020,'v1.1.9',0,0,0);




-- FACT_DEVICE_USAGE_DAILY - Generate usage rows
 

SET NOCOUNT ON;

DECLARE @Rows INT = 5000;   
DECLARE @Inserted INT = 0;

WHILE @Inserted < @Rows
BEGIN
    DECLARE @date_sk INT;
    DECLARE @customer_sk INT;
    DECLARE @device_sk INT;

    DECLARE @is_active BIT;
    DECLARE @usage_minutes INT;
    DECLARE @steps_count INT;
    DECLARE @workout_count INT;
    DECLARE @sleep_hours DECIMAL(4,2);

    -- Random FK-safe picks
    SELECT TOP 1 @date_sk = date_sk FROM dw.dim_date ORDER BY NEWID();
    SELECT TOP 1 @customer_sk = customer_sk FROM dw.dim_customer ORDER BY NEWID();
    SELECT TOP 1 @device_sk = device_sk FROM dw.dim_device ORDER BY NEWID();

    -- Avoid UNIQUE conflicts (date_sk, customer_sk, device_sk)
    IF NOT EXISTS (
        SELECT 1
        FROM dw.fact_device_usage_daily
        WHERE date_sk = @date_sk
          AND customer_sk = @customer_sk
          AND device_sk = @device_sk
    )
    BEGIN
        -- Active vs inactive day (80% active / 20% inactive)
        SET @is_active = CASE WHEN (ABS(CHECKSUM(NEWID())) % 10) < 8 THEN 1 ELSE 0 END;

        IF @is_active = 1
        BEGIN
            -- Realistic usage
            SET @usage_minutes = 30 + (ABS(CHECKSUM(NEWID())) % 271); -- 30-300
            SET @steps_count = 1500 + (ABS(CHECKSUM(NEWID())) % 18501); -- 1500-20000
            SET @workout_count = (ABS(CHECKSUM(NEWID())) % 3); -- 0-2 workouts
            SET @sleep_hours = CAST(4.50 + (ABS(CHECKSUM(NEWID())) % 551) / 100.0 AS DECIMAL(4,2)); -- 4.50-10.00
        END
        ELSE
        BEGIN
            -- Inactive day => zeros
            SET @usage_minutes = 0;
            SET @steps_count = 0;
            SET @workout_count = 0;
            SET @sleep_hours = CAST(0.00 AS DECIMAL(4,2));
        END

        INSERT INTO dw.fact_device_usage_daily
        (date_sk, customer_sk, device_sk, usage_minutes, steps_count, workout_count, sleep_hours, is_device_active)
        VALUES
        (@date_sk, @customer_sk, @device_sk, @usage_minutes, @steps_count, @workout_count, @sleep_hours, @is_active);

        SET @Inserted += 1;
    END
END;

-- Checks
SELECT COUNT(*) AS total_usage_rows FROM dw.fact_device_usage_daily;
SELECT TOP 20 * FROM dw.fact_device_usage_daily ORDER BY device_usage_fact_id DESC;




 
-- DIM_MONTH POPULATION (from dim_date)
 

SET NOCOUNT ON;

INSERT INTO dw.dim_month
(
    month_sk,
    calendar_year,
    calendar_month,
    month_name,
    calendar_quarter,
    month_start_date,
    month_end_date
)
SELECT
    (calendar_year * 100 + calendar_month) AS month_sk,  -- YYYYMM
    calendar_year,
    calendar_month,
    DATENAME(MONTH, MIN(full_date)) AS month_name,
    DATEPART(QUARTER, MIN(full_date)) AS calendar_quarter,
    MIN(full_date) AS month_start_date,
    MAX(full_date) AS month_end_date
FROM dw.dim_date
GROUP BY calendar_year, calendar_month
ORDER BY calendar_year, calendar_month;



 
-- FACT_USER_ENGAGEMENT_MONTHLY (aggregate from daily usage)
 

SET NOCOUNT ON;

INSERT INTO dw.fact_user_engagement_monthly
(
    month_sk,
    customer_sk,
    active_days,
    total_usage_minutes,
    avg_daily_usage_minutes,
    total_steps,
    total_workouts,
    avg_sleep_hours,
    is_month_active
)
SELECT
    (d.calendar_year * 100 + d.calendar_month) AS month_sk,     -- YYYYMM
    f.customer_sk,

    CAST(SUM(CASE WHEN f.is_device_active = 1 THEN 1 ELSE 0 END) AS TINYINT) AS active_days,

    SUM(f.usage_minutes) AS total_usage_minutes,

    CAST(ROUND(AVG(CAST(f.usage_minutes AS DECIMAL(10,2))), 2) AS DECIMAL(10,2)) AS avg_daily_usage_minutes,

    SUM(CAST(f.steps_count AS BIGINT)) AS total_steps,

    SUM(f.workout_count) AS total_workouts,

    CAST(ROUND(AVG(CAST(f.sleep_hours AS DECIMAL(10,2))), 2) AS DECIMAL(4,2)) AS avg_sleep_hours,

    CASE 
        WHEN SUM(CASE WHEN f.is_device_active = 1 THEN 1 ELSE 0 END) > 0 THEN 1 
        ELSE 0 
    END AS is_month_active

FROM dw.fact_device_usage_daily f
JOIN dw.dim_date d
    ON d.date_sk = f.date_sk
GROUP BY
    (d.calendar_year * 100 + d.calendar_month),
    f.customer_sk;


--INDEX

-- fact_sales

CREATE INDEX ix_fact_sales_date_sk     ON dw.fact_sales(date_sk);
CREATE INDEX ix_fact_sales_customer_sk ON dw.fact_sales(customer_sk);
CREATE INDEX ix_fact_sales_product_sk  ON dw.fact_sales(product_sk);
CREATE INDEX ix_fact_sales_region_sk   ON dw.fact_sales(region_sk);

-- fact_device_usage_daily

CREATE INDEX ix_usage_date_sk     ON dw.fact_device_usage_daily(date_sk);
CREATE INDEX ix_usage_customer_sk ON dw.fact_device_usage_daily(customer_sk);
CREATE INDEX ix_usage_device_sk   ON dw.fact_device_usage_daily(device_sk);


-- fact_user_engagement_monthly

CREATE INDEX ix_eng_month_sk     ON dw.fact_user_engagement_monthly(month_sk);
CREATE INDEX ix_eng_customer_sk  ON dw.fact_user_engagement_monthly(customer_sk);


-- If you run a lot of “sales by month” queries

CREATE INDEX ix_dim_date_year_month
ON dw.dim_date(calendar_year, calendar_month)
INCLUDE (date_sk, full_date, is_weekend);


-- Only if you run MANY queries by customer and month range
CREATE INDEX ix_eng_customer_month
ON dw.fact_user_engagement_monthly(customer_sk, month_sk);


