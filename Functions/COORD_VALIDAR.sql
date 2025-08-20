--------------------------------------------------------
--  DDL for Function COORD_VALIDAR
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE FUNCTION "COORD_VALIDAR" (p_numero in varchar2)
RETURN    INTEGER
IS
v_ok               INTEGER;
v_numero_char      VARCHAR2(30);
v_numero           NUMBER;
v_pos              INTEGER;
BEGIN
  v_ok := 0;
--
  IF INSTR(p_numero,',') > 0 THEN
     RETURN v_ok;
  END IF;
--
  v_numero_char := RTRIM(p_numero);
--
  v_numero := to_number(v_numero_char,'99999D9999999','NLS_NUMERIC_CHARACTERS = ''.,'' ');
  v_ok := 1;
--
  RETURN v_ok;
EXCEPTION
  WHEN OTHERS THEN
    RETURN v_ok;
END;

/
