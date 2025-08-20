--------------------------------------------------------
--  DDL for Function ZVL
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE FUNCTION "ZVL"  (p_numero in number, p_retorno in number)
-----------------------------------------------------------------------
--   ZVL
--
--   Descricao: funcao que compara um numero com zero, retornando o
--   segundo valor, caso a comparacao seja verdadeira
-----------------------------------------------------------------------
RETURN  number IS

v_ok number;

BEGIN
  v_ok := 0;
  IF p_numero = 0 THEN
     v_ok := p_retorno;
  ELSE
     v_ok := p_numero;
  END IF;

  RETURN v_ok;
EXCEPTION
  WHEN OTHERS THEN
    RETURN v_ok;
END;

/
