--------------------------------------------------------
--  DDL for Table MLOG$_OS_ATRIBUTO_VALOR
--------------------------------------------------------

  CREATE TABLE "MLOG$_OS_ATRIBUTO_VALOR" 
   (	"M_ROW$$" VARCHAR2(255), 
	"SNAPTIME$$" DATE, 
	"DMLTYPE$$" VARCHAR2(1), 
	"OLD_NEW$$" VARCHAR2(1), 
	"CHANGE_VECTOR$$" RAW(255), 
	"XID$$" NUMBER
   ) ;

   COMMENT ON TABLE "MLOG$_OS_ATRIBUTO_VALOR"  IS 'snapshot log for master table JOBONE_V4.OS_ATRIBUTO_VALOR';
