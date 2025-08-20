--------------------------------------------------------
--  DDL for Function ZEROS_DIR_RETIRAR
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE FUNCTION "ZEROS_DIR_RETIRAR" -----------------------------------------------------------------------
-- ZEROS_DIR_RETIRAR
--
--   Descricao: funcao que retida zeros a direita de um numero ja
--    formatado.
-----------------------------------------------------------------------
     (p_numero IN VARCHAR2)
RETURN  VARCHAR2
IS
v_ok         INTEGER;
v_numero     VARCHAR2(40);
v_pos        INTEGER;
v_ind        INTEGER;
--
BEGIN
  v_numero := p_numero;
--
  IF v_numero IS NULL THEN
     v_numero := '0';
  END IF;
--
  v_pos := INSTR(v_numero,',');
  v_ind := LENGTH(v_numero);
--
  -- retira zeros a direita da virgula.
  WHILE v_ind > v_pos AND  SUBSTR(v_numero,v_ind,1) = '0' LOOP
     v_numero := SUBSTR(v_numero,1,v_ind-1);
     v_ind := v_ind - 1;
  END LOOP;
--
  -- verifica se sobrou apenas a virgula.
  IF SUBSTR(v_numero,LENGTH(v_numero),1) = ',' THEN
     v_numero := SUBSTR(v_numero,1,LENGTH(v_numero)-1);
  END IF;
--
  RETURN v_numero;
EXCEPTION
  WHEN OTHERS THEN
    v_numero := 'ERRO';
    RETURN v_numero;
END;

/
