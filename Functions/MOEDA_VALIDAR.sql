--------------------------------------------------------
--  DDL for Function MOEDA_VALIDAR
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE FUNCTION "MOEDA_VALIDAR" (
-----------------------------------------------------------------------
--   MOEDA_VALIDAR
--
--   Descricao: funcao que consiste uma string nos seguintes
--   formatos moeda '99999999999999999999,99'.
--   Retorna 1 caso o string seja um valor valido, 0 caso nao seja.
--   Para um string igual a NULL, retorna 1.
--   (OBS: trabalha c/ virgula como decimal e nao aceita ponto como
--   separador de milhar).
-----------------------------------------------------------------------
   p_numero        IN VARCHAR2)
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
  v_numero := to_number(v_numero_char,'99999999999999999999D99','NLS_NUMERIC_CHARACTERS = '',.'' ');
  IF v_numero IS NULL OR ABS(v_numero) BETWEEN 0 AND 99999999999999999999.99 THEN
     v_ok := 1;
  END IF;
--
  RETURN v_ok;
EXCEPTION
  WHEN OTHERS THEN
    RETURN v_ok;
END;

/
