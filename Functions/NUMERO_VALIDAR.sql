--------------------------------------------------------
--  DDL for Function NUMERO_VALIDAR
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE FUNCTION "NUMERO_VALIDAR" -----------------------------------------------------------------------
-- NUMERO_VALIDAR
--
--   Descricao: funcao que verifica se um string e' um numero valido,
--   do tipo DOUBLE/FLOAT. Retorna '1' caso seja valido, e '0' caso
--   nao seja. Para um string igual a NULL, retorna '1'.
--   (OBS: trabalha c/ virgula como decimal e nao aceita ponto como
--   separador de milhar).
-----------------------------------------------------------------------
     (p_numero in varchar2)
RETURN    INTEGER
IS
v_ok               INTEGER;
v_numero_char      VARCHAR2(30);
v_numero           NUMBER;
v_pos              INTEGER;
BEGIN
  v_ok := 0;
--
  -- nao aceita ponto, caso a virgula nao exista
  IF INSTR(p_numero,'.') > 0 AND INSTR(p_numero,',') = 0 THEN
     RETURN v_ok;
  END IF;
--
  v_numero_char := RTRIM(REPLACE(p_numero,'.',''));
--
  v_numero := to_number(v_numero_char,'99999999999999999999D999999','NLS_NUMERIC_CHARACTERS = '',.'' ');
  v_ok := 1;
--
  RETURN v_ok;
EXCEPTION
  WHEN OTHERS THEN
    RETURN v_ok;
END;

/
