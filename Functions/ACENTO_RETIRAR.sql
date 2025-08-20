--------------------------------------------------------
--  DDL for Function ACENTO_RETIRAR
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE FUNCTION "ACENTO_RETIRAR" (p_string in varchar2)
RETURN  varchar2 IS

v_string varchar2(32000);

BEGIN
  v_string := LTRIM(RTRIM(LOWER(p_string)));
  v_string := TRANSLATE(v_string,
              'ביםףתגךמפûאטלעשדץüח','aeiouaeiouaeiouaouc');
  RETURN v_string;

EXCEPTION
  WHEN OTHERS THEN
    v_string := 'ERRO string';
    RETURN v_string;
END;

/
