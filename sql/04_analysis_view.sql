---------------------------------
-- 04_analysis_view.sql
---------------------------------
-- Creates a permanent view of the combined tables for analysis (one row per hospital).
-- Requires 02_create_tables.sql and the CSV imports; run 03_verify_imports.sql first.
-- All column names from hgi are spelled out to keep the join durable if the view is recreated.
-- Schema is listed for all tables for the same reason.
-- Inner joins are used for all tables because, with inner joins, a hospital dropped
    -- from a dataset disappears and the count falls below 4,792, so it can't be
    -- mistaken for a suppression null.
-- To change the view's columns, drop it first:
-- DROP VIEW hospital_safety.communication_safety_comparison;

create or replace view hospital_safety.communication_safety_comparison as
select
	hgi.facility_id,
	hgi.facility_name,
	hgi.state,
	hgi.hospital_type,
	hgi.hospital_ownership,
	h.nurse_comm_score,
	h.doctor_comm_score,
	hai.clabsi_sir,
	hai.cauti_sir,
	p.score as psi_90_score
from hospital_safety.hospital_gen_info hgi
inner join hospital_safety.hcahps h on hgi.facility_id = h.facility_id
inner join hospital_safety.hai on hgi.facility_id = hai.facility_id
inner join hospital_safety.psi_90 p on hgi.facility_id = p.facility_id;


------ Join statement verification ---------------------

-- SOURCE TABLE ROW COUNTS (compare with the view's count below)
select COUNT(*) from hospital_safety.hospital_gen_info; -- 5432 (registry; includes the 640 psychiatric and long-term hospitals not in the other tables)
select COUNT(*) from hospital_safety.hcahps; -- 4792
select COUNT(*) from hospital_safety.hai; -- 4792
select COUNT(*) from hospital_safety.psi_90; -- 4792

-- verify total row count matches the 4792 rows for hai, hcahps and psi_90
select COUNT(*)
from hospital_safety.communication_safety_comparison;
-- 4792

-- verify no duplicate hospitals listed
select
	COUNT(*) as total_count,
	COUNT(distinct facility_id) as distinct_hospitals
from hospital_safety.communication_safety_comparison;
-- 4792 for both

-- cross-reference view values for a single hospital against source tables
select *
from hospital_safety.communication_safety_comparison
where facility_id = '010001';
-- all columns matched corresponding values in source tables

-- verify null values remain unchanged in join view
select *
from hospital_safety.communication_safety_comparison
where facility_id = '010051';
-- all values null and match corresponding values in source tables
