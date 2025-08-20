--------------------------------------------------------
--  DDL for Function MOEDA_MOSTRAR
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE FUNCTION "MOEDA_MOSTRAR" (
-----------------------------------------------------------------------
--   MOEDA_MOSTRAR
--
--   Descricao: funcao que converte um number em um string no seguinte
--   formato moeda '99999999999999999999,99'. Retorna um string com o
--   valor convertido.
-----------------------------------------------------------------------
  p_numero                     IN NUMBER,
  p_flag_milhar                IN VARCHAR2)
RETURN  VARCHAR2
IS
  v_ok                         INTEGER;
  v_moeda                      VARCHAR2(30);
BEGIN
--
  IF p_flag_milhar = 'S' THEN
     v_moeda := TO_CHAR(p_numero,'99G999G999G999G999G999G990D00', 'NLS_NUMERIC_CHARACTERS = '',.'' ');
  ELSE
     v_moeda := TO_CHAR(p_numero,'99999999999999999990D00', 'NLS_NUMERIC_CHARACTERS = '',.'' ');
  END IF;
--
/*
  IF v_moeda IS NULL THEN
     v_moeda := '0';
  END IF;
*/
--
  RETURN v_moeda;
EXCEPTION
  WHEN OTHERS THEN
    v_moeda := 'ERRO';
    RETURN v_moeda;
END;

/
