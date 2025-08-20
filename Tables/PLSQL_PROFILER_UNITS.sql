--------------------------------------------------------
--  DDL for Table PLSQL_PROFILER_UNITS
--------------------------------------------------------

  CREATE TABLE "PLSQL_PROFILER_UNITS" 
   (	"RUNID" NUMBER, 
	"UNIT_NUMBER" NUMBER, 
	"UNIT_TYPE" VARCHAR2(32), 
	"UNIT_OWNER" VARCHAR2(32), 
	"UNIT_NAME" VARCHAR2(32), 
	"UNIT_TIMESTAMP" DATE, 
	"TOTAL_TIME" NUMBER DEFAULT 0, 
	"SPARE1" NUMBER, 
	"SPARE2" NUMBER
   ) ;

   COMMENT ON TABLE "PLSQL_PROFILER_UNITS"  IS 'Information about each library unit in a run';
