--------------------------------------------------------
--  DDL for Function COMPARAR_DATA
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE FUNCTION "COMPARAR_DATA"  (p_data in DATE, p_condicao in varchar2, p_constante in DATE)
-----------------------------------------------------------------------
--   COMPARAR
--
--   Descricao: funcao que compara uma data com uma constante baseado numa
--   condicao. Retorna 1 caso a comparacao seja verdadeira e 0 caso nao.
-----------------------------------------------------------------------
RETURN  integer IS

v_ok number;

BEGIN
  v_ok := 0;
  IF p_condicao = '=' THEN
     IF p_data = p_constante THEN
        v_ok := 1;
     END IF;
  ELSIF p_condicao = '>' THEN
     IF p_data > p_constante THEN
        v_ok := 1;
     END IF;
  ELSIF p_condicao = '>=' THEN
     IF p_data >= p_constante THEN
        v_ok := 1;
     END IF;
  ELSIF p_condicao = '<' THEN
     IF p_data < p_constante THEN
        v_ok := 1;
     END IF;
  ELSIF p_condicao = '<=' THEN
     IF p_data <= p_constante THEN
        v_ok := 1;
     END IF;
  ELSIF p_condicao = '<>' OR p_condicao = '!=' THEN
     IF p_data <> p_constante THEN
        v_ok := 1;
     END IF;
  END IF;

  RETURN v_ok;
EXCEPTION
  WHEN OTHERS THEN
    RETURN v_ok;
END;

/
