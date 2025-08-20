--------------------------------------------------------
--  DDL for Function COORD_CONVERTER
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE FUNCTION "COORD_CONVERTER" -----------------------------------------------------------------------
-- COORD_CONVERTER
--
--   Descricao: função que converte um string previamente validado
--   em numero. O string pode estar tanto no formato
--   '99999.9999999'.
-----------------------------------------------------------------------
     (p_numero IN VARCHAR2)
RETURN   NUMBER
IS
v_ok             INTEGER;
v_numero         NUMBER;
v_numero_char    VARCHAR2(30);
--
BEGIN
  v_numero := NULL;
  v_numero_char := RTRIM(REPLACE(p_numero,',',''));
--
  v_numero := TO_NUMBER(v_numero_char,'99999D9999999', 'NLS_NUMERIC_CHARACTERS = ''.,'' ');
--
  RETURN v_numero;
EXCEPTION
  WHEN OTHERS THEN
    v_numero := 99999999;
    RETURN v_numero;
END;

/
