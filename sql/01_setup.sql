---------------------------------
-- 01_setup.sql
---------------------------------
-- Creates the schema that holds all project tables and the analysis view.
-- The database itself is created beforehand (see README).
-- Safe to run more than once.

create schema if not exists hospital_safety;