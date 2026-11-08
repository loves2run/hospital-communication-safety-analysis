---------------------------------
-- 02_create_tables.sql
---------------------------------
-- BUILD EMPTY TABLES FOR THE DB
-- Requires 01_setup.sql (the hospital_safety schema must exist).
-- Load tables using the DBeaver import wizard in the order listed below,
    -- then run 03_verify_imports.sql.

create table hospital_safety.hospital_gen_info (
	facility_id VARCHAR(10) primary key,
	facility_name VARCHAR(255),
	state VARCHAR(2),
	hospital_type VARCHAR(100),
	hospital_ownership VARCHAR(100)
);

-- num_completed_surveys_footnote is VARCHAR(50) and listed last because the
-- DBeaver import wizard created it with that length and position.
create table hospital_safety.hcahps (
	facility_id VARCHAR(10) primary key,
	facility_name VARCHAR(255),
	nurse_comm_score NUMERIC,
	doctor_comm_score NUMERIC,
	num_completed_surveys integer,
	survey_response_rate_percent numeric,
	survey_response_rate_percent_footnote VARCHAR(20),
	num_completed_surveys_footnote VARCHAR(50)
);

create table hospital_safety.hai (
	facility_id VARCHAR(10) primary key,
	facility_name VARCHAR(255),
	clabsi_lower_confidence_limit NUMERIC,
	clabsi_upper_confidence_limit NUMERIC,
	clabsi_num_device_days INTEGER,
	clabsi_predicted_cases NUMERIC,
	clabsi_observed_cases INTEGER,
	clabsi_sir NUMERIC,
	cauti_lower_confidence_limit NUMERIC,
	cauti_upper_confidence_limit NUMERIC,
	cauti_num_device_days INTEGER,
	cauti_predicted_cases NUMERIC,
	cauti_observed_cases INTEGER,
	cauti_sir NUMERIC
);

create table hospital_safety.psi_90 (
	facility_id VARCHAR(10) primary key,
	facility_name VARCHAR(255),
	score NUMERIC,
	lower_estimate NUMERIC,
	higher_estimate NUMERIC,
	footnote VARCHAR(20)
);