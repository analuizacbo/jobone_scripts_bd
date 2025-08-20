--------------------------------------------------------
--  DDL for Function TAXA_VALIDAR
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE FUNCTION "TAXA_VALIDAR" (
-----------------------------------------------------------------------
-- TAXA_VALIDAR
--
--   Descricao: funcao que verifica se um string e' uma taxa valida
--   (entre 0 e 100). Retorna '1' caso seja valida, e '0' caso
--   nao seja. Para um string igual a NULL, retorna '1'.
-----------------------------------------------------------------------
p_numero        IN  VARCHAR2)
--
RETURN  INTEGER
IS
v_ok integer;
BEGIN
  v_ok := 0;
--
  -- nao aceita ponto decimal
  IF INSTR(p_numero,'.') > 0 THEN
     RETURN v_ok;
  END IF;
--
  IF p_numero IS NULL OR
     (numero_validar(p_numero) = 1 AND numero_converter(p_numero) BETWEEN 0 AND 100) THEN
     v_ok := 1;
  END IF;
  RETURN v_ok;
EXCEPTION
  WHEN OTHERS THEN
    RETURN v_ok;
END;

/
