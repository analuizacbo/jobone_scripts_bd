--------------------------------------------------------
--  DDL for Function MOEDA_CONVERTER
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE FUNCTION "MOEDA_CONVERTER" -----------------------------------------------------------------------
-- MOEDA_CONVERTER
--
--   Descricao: função que converte um string previamente validado
--   em moeda. O string pode estar tanto no formato
--   '99999999999999999999,99' como no formato
--   '99.999.999.999.999.999.999,99'
-----------------------------------------------------------------------
     (p_numero IN VARCHAR2)
RETURN   NUMBER
IS
v_ok            INTEGER;
v_moeda         NUMBER;
v_moeda_char    VARCHAR2(30);
--
BEGIN
  v_moeda := NULL;
  v_moeda_char := RTRIM(REPLACE(p_numero,'.',''));
--
  v_moeda := TO_NUMBER(v_moeda_char,'99999999999999999999D99', 'NLS_NUMERIC_CHARACTERS = '',.'' ');
--
  RETURN v_moeda;
EXCEPTION
  WHEN OTHERS THEN
    RETURN v_moeda;
END;

/
