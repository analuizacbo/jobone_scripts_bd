--------------------------------------------------------
--  DDL for Table PLSQL_PROFILER_DATA
--------------------------------------------------------

  CREATE TABLE "PLSQL_PROFILER_DATA" 
   (	"RUNID" NUMBER, 
	"UNIT_NUMBER" NUMBER, 
	"LINE#" NUMBER, 
	"TOTAL_OCCUR" NUMBER, 
	"TOTAL_TIME" NUMBER, 
	"MIN_TIME" NUMBER, 
	"MAX_TIME" NUMBER, 
	"SPARE1" NUMBER, 
	"SPARE2" NUMBER, 
	"SPARE3" NUMBER, 
	"SPARE4" NUMBER
   ) ;

   COMMENT ON TABLE "PLSQL_PROFILER_DATA"  IS 'Accumulated data from all profiler runs';
