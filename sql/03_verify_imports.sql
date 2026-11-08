---------------------------------
-- 03_verify_imports.sql
---------------------------------
-- Read-only checks to run AFTER 02_create_tables.sql and the CSV imports.
-- Nothing in the live part of this file changes data.
-- Each check shows its expected result in a comment.
-- Source-table row counts compared against the view are in 04_analysis_view.sql.
-- Build history (failed imports, renames, dropped column) is at the bottom,
    -- fully commented out.


---------------------------------
-- 1. hospital_gen_info
---------------------------------
-- Imported hospital_gen_info dataset via DBeaver import wizard
-- CONFIRM ROW COUNT AFTER IMPORT
select COUNT(*) from hospital_safety.hospital_gen_info; -- confirmed 5432 rows

-- RANDOM facility_id CHECKS
select * from hospital_safety.hospital_gen_info where facility_id = '05015F'; -- correct
select * from hospital_safety.hospital_gen_info where facility_id = '100054'; -- correct
select * from hospital_safety.hospital_gen_info where facility_id = '05022F'; -- correct
select * from hospital_safety.hospital_gen_info where facility_id = '440192'; -- correct
select * from hospital_safety.hospital_gen_info where facility_id = '381310'; -- correct


---------------------------------
-- 2. hcahps
---------------------------------
-- Imported hcahps dataset via DBeaver import wizard
-- VERIFY NULL COUNTS AGAINST TOTAL ROWS
select
	COUNT(*) as total_rows,
	COUNT(*) filter (where nurse_comm_score is null) as nurse_null,
	COUNT(*) filter (where doctor_comm_score is null) as doctor_null,
	COUNT(*) filter (where num_completed_surveys is null) as surveys_null,
	COUNT(*) filter (where survey_response_rate_percent is null) as rate_null
from hospital_safety.hcahps;
-- total_rows 4792
-- nurse_null 836
-- doctor_null 836
-- surveys_null 836
-- rate_null 836

-- SPOT-CHECK 010001
select *
from hospital_safety.hcahps
where facility_id = '010001';
-- values verified with hcahps_clean_final.csv
-- facility_name = SOUTHEAST HEALTH MEDICAL CENTER
-- nurse_comm_score = 76
-- doctor_comm_score = 80
-- num_completed_surveys = 952
-- survey_response_rate_percent = 17
-- both footnote columns = null

-- SPOT-CHECK 100001
select *
from hospital_safety.hcahps
where facility_id = '100001';
-- values verified with HCAHPS-Hospital.csv (raw data file)
-- facility_name = SHANDS JACKSONVILLE
-- nurse_comm_score = 75
-- doctor_comm_score = 77
-- num_completed_surveys = 3730
-- survey_response_rate_percent = 18
-- both footnote columns = null

-- SPOT-CHECK SUPPRESSED HOSPITAL 010051
select *
from hospital_safety.hcahps
where facility_id = '010051';
-- verified against HCAHPS-Hospital.csv (raw data file)
-- facility_name = Greene County Hospital
-- nurse_comm_score Not Applicable (this was transformed to null during cleaning)
-- doctor_comm_score Not Applicable (this was transformed to null during cleaning)
-- num_completed_surveys Not Available (this was transformed to null during cleaning)
-- survey_response_rate_percent Not Available (this was transformed to null during cleaning)
-- both footnote values = 1

-- SPOT-CHECK CAUTION-FLAG HOSPITAL 010007 (footnote 6)
select *
from hospital_safety.hcahps
where facility_id = '010007';
-- verified against HCAHPS-Hospital.csv (raw data file)
-- facility_name = Mizell Memorial Hospital
-- nurse_comm_score = 79
-- doctor_comm_score = 86
-- num_completed_surveys = 97
-- survey_response_rate_percent = 17
-- both footnote values = 6


---------------------------------
-- 3. hai
---------------------------------
-- Imported hai dataset via DBeaver import wizard
-- CONFIRM ROW COUNT AFTER IMPORT
select COUNT(*) from hospital_safety.hai; -- verified 4792 rows imported

-- SPOT-CHECK 010001
select *
from hospital_safety.hai
where facility_id = '010001';
-- clabsi_sir is 0.288, which matches raw file
-- cauti_sir is 0.195, which matches raw file

-- SPOT-CHECK 100001
select *
from hospital_safety.hai
where facility_id = '100001';
-- clabsi_sir is 0.737, which matches raw file
-- cauti_sir is 0.544, which matches raw file

-- NULL-COUNT RECONCILIATION FOR THE TWO SIR COLUMNS
select
	count(*) filter (where clabsi_sir is null and cauti_sir is null) as both_null,
	count(*) filter (where clabsi_sir is null) as clabsi_null,
	count(*) filter (where cauti_sir is null) as cauti_null,
	count(*) filter (where clabsi_sir is null or cauti_sir is null) as either_null,
	count(*) filter (where clabsi_sir is null and cauti_sir is not null) as clabsi_only_null,
	count(*) filter (where clabsi_sir is not null and cauti_sir is null) as cauti_only_null
from hospital_safety.hai;
-- both_null 2522
-- clabsi_null 2844
-- cauti_null 2552
-- either_null 2874
-- clabsi_only_null 322
-- cauti_only_null 30


---------------------------------
-- 4. psi_90
---------------------------------
-- Imported psi_90 dataset via DBeaver import wizard

-- CONFIRM ROW COUNT AFTER IMPORT
select COUNT(*)
from hospital_safety.psi_90;
-- count is 4792 as expected

-- FOOTNOTE DISTRIBUTION
select footnote, COUNT(*)
from hospital_safety.psi_90
group by footnote
order by 2 desc;
-- null count = 2841
-- 13 count = 1364
-- 1 count = 199
-- 19 count = 170
-- 5 count = 142
-- 29 count = 60
-- 23 count = 16

-- COLUMN NAMES AND TYPES
select column_name, data_type, character_maximum_length
from information_schema."columns"
where table_schema = 'hospital_safety' and table_name = 'psi_90'
order by ordinal_position;
-- facility_id		character varying	10
-- facility_name	character varying	255
-- score			numeric
-- lower_estimate	numeric
-- higher_estimate	numeric
-- footnote			character varying	20

-- NULL COUNTS
select
	count(*) filter (where score is null) as score_null,
	count(*) filter (where lower_estimate is null) as lower_null,
	count(*) filter (where higher_estimate is null) as higher_null
from hospital_safety.psi_90;
-- score_null = 1875 (matches row counts for raw Complications_and_Deaths-Hospital.csv)
-- lower_null = 1875 (matches row counts for raw Complications_and_Deaths-Hospital.csv)
-- higher_null = 1875 (matches row counts for raw Complications_and_Deaths-Hospital.csv)

-- SPOT-CHECK 010001
select *
from hospital_safety.psi_90
where facility_id = '010001';
-- facility_id = 010001
-- facility_name = SOUTHEAST HEALTH MEDICAL CENTER
-- score = 0.95
-- lower_estimate = 0.66
-- higher_estimate = 1.25
-- footnote = null


---------------------------------
-- 5. Cross-table check
---------------------------------
-- WHICH REGISTRY HOSPITALS HAVE NO HCAHPS ROW (the 640-hospital gap)
select g.hospital_type, COUNT(*)
from hospital_safety.hospital_gen_info g
left join hospital_safety.hcahps h on h.facility_id = g.facility_id
where h.facility_id is null
group by g.hospital_type
order by 2 desc;
-- Psychiatric 635, Long-term 5


---------------------------------
-- 6. BUILD HISTORY (all commented out; NOT meant to be run)
---------------------------------
-- Record of what happened while building the hcahps table. The statements below
    -- are commented out on purpose: running them would delete or alter data.

-- FIRST hcahps IMPORT ATTEMPT
-- select count(*) from hospital_safety.hcahps;
-- only 24 rows were imported
-- error message indicating a duplicate primary key on 010001

-- CLEARED hcahps AND RETRIED
-- truncate table hospital_safety.hcahps;
-- select count(*) from hospital_safety.hcahps; -- verified 0 rows
-- hcahps import did not work on second attempt
--	"Not Available" still listed in numeric column (number_of_completed_surveys)

-- CHANGED column names in hcahps table to match cleaned CSV file
-- alter table hospital_safety.hcahps rename column number_of_completed_surveys to num_completed_surveys;
-- alter table hospital_safety.hcahps rename column number_of_completed_surveys_footnote to num_completed_surveys_footnoote;
-- select COUNT(*) from hospital_safety.hcahps; -- 0

-- RAN IMPORT WIZARD for hcahps_clean_final.csv into hcahps table
-- was unaware of typo in num_completed_surveys_footnoote column
-- the wizard created a second, correctly spelled column automatically
-- verify row counts for column with typo and column automatically created that does not have typo:
-- select
-- 	COUNT(*) filter (
-- 		where num_completed_surveys_footnoote is not null
-- 		and num_completed_surveys_footnoote <> ''
-- 	) as typo_col_has_data,
-- 	COUNT(*) filter (
-- 		where num_completed_surveys_footnote is not null
-- 		and num_completed_surveys_footnote <> ''
-- 	) as real_col_has_data
-- from hospital_safety.hcahps;
-- typo_col_has_data 0
-- real_col_has_data 1709

-- DROPPED column with typo from hcahps table
-- alter table hospital_safety.hcahps drop column num_completed_surveys_footnoote;