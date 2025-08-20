--------------------------------------------------------
--  DDL for Function INTEIRO_VALIDAR
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE FUNCTION "INTEIRO_VALIDAR" -----------------------------------------------------------------------
-- INTEIRO_VALIDAR
--
--   Descricao: funcao que verifica se um string e' um numero inteiro
--   valido, com ate' 20 digitos. Retorna '1' caso seja valido, e '0'
--   caso nao seja. Para um string igual a NULL, retorna '1'.
-----------------------------------------------------------------------
  (p_numero in varchar2)
RETURN  integer IS
--
v_ok integer;
v_numero number;
--
BEGIN
  v_ok := 0;
  v_numero := to_number(p_numero);
  v_numero := to_number(p_numero,'99999999999999999999');
  v_ok := 1;
  RETURN v_ok;
--
EXCEPTION
  WHEN OTHERS THEN
    RETURN v_ok;
END;

/
