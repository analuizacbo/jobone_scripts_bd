--------------------------------------------------------
--  DDL for Table PLSQL_PROFILER_RUNS
--------------------------------------------------------

  CREATE TABLE "PLSQL_PROFILER_RUNS" 
   (	"RUNID" NUMBER, 
	"RELATED_RUN" NUMBER, 
	"RUN_OWNER" VARCHAR2(32), 
	"RUN_DATE" DATE, 
	"RUN_COMMENT" VARCHAR2(2047), 
	"RUN_TOTAL_TIME" NUMBER, 
	"RUN_SYSTEM_INFO" VARCHAR2(2047), 
	"RUN_COMMENT1" VARCHAR2(2047), 
	"SPARE1" VARCHAR2(256)
   ) ;

   COMMENT ON TABLE "PLSQL_PROFILER_RUNS"  IS 'Run-specific information for the PL/SQL profiler';
