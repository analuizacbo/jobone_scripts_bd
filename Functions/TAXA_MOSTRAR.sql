--------------------------------------------------------
--  DDL for Function TAXA_MOSTRAR
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE FUNCTION "TAXA_MOSTRAR" -----------------------------------------------------------------------
-- TAXA_MOSTRAR
--
--   Descricao: funcao que converte um number em um string no seguinte
--   formato '99999,99'. Retorna um string com o
--   valor convertido.
-----------------------------------------------------------------------
     (p_numero IN NUMBER)
RETURN  VARCHAR2
IS
v_ok         INTEGER;
v_numero     VARCHAR2(30);
BEGIN
  v_numero := NULL;
--
  v_numero := TO_CHAR(p_numero,'99990D00', 'NLS_NUMERIC_CHARACTERS = '',.'' ');
--
  RETURN v_numero;
EXCEPTION
  WHEN OTHERS THEN
    v_numero := 'ERRO';
    RETURN v_numero;
END;

/
