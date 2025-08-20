--------------------------------------------------------
--  DDL for Function FORMATO_RETIRAR
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE FUNCTION "FORMATO_RETIRAR" -----------------------------------------------------------------------
-- formato_retirar
--
--   Descricao: retira eventual formatação de um dado string contendo
--     numeros
-----------------------------------------------------------------------
  (p_string in varchar2)
RETURN  varchar2 IS

v_string varchar2(500);

BEGIN
  v_string := TRIM(REPLACE(p_string,'-',''));
  v_string := TRIM(REPLACE(v_string,'.',''));
  v_string := TRIM(REPLACE(v_string,' ',''));
  v_string := TRIM(REPLACE(v_string,',000000',''));
  v_string := TRIM(REPLACE(v_string,',00000',''));
  v_string := TRIM(REPLACE(v_string,',0000',''));
  v_string := TRIM(REPLACE(v_string,',000',''));
  v_string := TRIM(REPLACE(v_string,',00',''));
  v_string := TRIM(REPLACE(v_string,',0',''));
  RETURN v_string;

EXCEPTION
  WHEN OTHERS THEN
    v_string := 'ERRO string';
    RETURN v_string;
END;

/
