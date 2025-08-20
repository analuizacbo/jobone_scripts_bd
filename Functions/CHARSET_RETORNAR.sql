--------------------------------------------------------
--  DDL for Function CHARSET_RETORNAR
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE FUNCTION "CHARSET_RETORNAR" 
-----------------------------------------------------------------------
--   charset_retornar
--
--   Descricao: retorna o charset do banco
-----------------------------------------------------------------------
RETURN  VARCHAR2 IS
--
v_string  VARCHAR2(50);
--
BEGIN
  SELECT value
    INTO v_string
    FROM nls_database_parameters
   WHERE parameter = 'NLS_CHARACTERSET';
--
  RETURN v_string;
--
EXCEPTION
  WHEN OTHERS THEN
    v_string := 'ERRO string';
    RETURN v_string;
END;

/
