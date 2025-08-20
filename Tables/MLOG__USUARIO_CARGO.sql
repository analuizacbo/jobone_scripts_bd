--------------------------------------------------------
--  DDL for Table MLOG$_USUARIO_CARGO
--------------------------------------------------------

  CREATE TABLE "MLOG$_USUARIO_CARGO" 
   (	"M_ROW$$" VARCHAR2(255), 
	"SNAPTIME$$" DATE, 
	"DMLTYPE$$" VARCHAR2(1), 
	"OLD_NEW$$" VARCHAR2(1), 
	"CHANGE_VECTOR$$" RAW(255), 
	"XID$$" NUMBER
   ) ;

   COMMENT ON TABLE "MLOG$_USUARIO_CARGO"  IS 'snapshot log for master table JOBONE_V4_174.USUARIO_CARGO';
