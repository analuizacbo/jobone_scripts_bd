--------------------------------------------------------
--  DDL for Function NUMERO_MOSTRAR
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE FUNCTION "NUMERO_MOSTRAR" (
-----------------------------------------------------------------------
--   NUMERO_MOSTRAR
--
--   Descricao: funcao que converte um Number em um String com seguinte
--   formato '99999999999999999999,999999' (ate 6 casas decimais,
--   dependendo do numero de casas decimais especificado).
-----------------------------------------------------------------------
     p_numero                     IN NUMBER,
     p_casas_dec                  IN INTEGER,
     p_flag_milhar                IN VARCHAR2)
RETURN  VARCHAR2
IS
v_ok         INTEGER;
v_numero     VARCHAR2(30);
BEGIN
--
  IF p_casas_dec IS NULL OR p_casas_dec >= 6  OR p_casas_dec < 0 THEN
     IF p_flag_milhar = 'S' THEN
        v_numero := TO_CHAR(p_numero,'99G999G999G999G999G999G990D000000', 'NLS_NUMERIC_CHARACTERS = '',.'' ');
     ELSE
        v_numero := TO_CHAR(p_numero,'99999999999999999990D000000', 'NLS_NUMERIC_CHARACTERS = '',.'' ');
     END IF;
  ELSIF p_casas_dec = 5 THEN
     IF p_flag_milhar = 'S' THEN
        v_numero := TO_CHAR(p_numero,'99G999G999G999G999G999G990D00000', 'NLS_NUMERIC_CHARACTERS = '',.'' ');
     ELSE
        v_numero := TO_CHAR(p_numero,'99999999999999999990D00000', 'NLS_NUMERIC_CHARACTERS = '',.'' ');
     END IF;
  ELSIF p_casas_dec = 4 THEN
     IF p_flag_milhar = 'S' THEN
        v_numero := TO_CHAR(p_numero,'99G999G999G999G999G999G990D0000', 'NLS_NUMERIC_CHARACTERS = '',.'' ');
     ELSE
        v_numero := TO_CHAR(p_numero,'99999999999999999990D0000', 'NLS_NUMERIC_CHARACTERS = '',.'' ');
     END IF;
  ELSIF p_casas_dec = 3 THEN
     IF p_flag_milhar = 'S' THEN
        v_numero := TO_CHAR(p_numero,'99G999G999G999G999G999G990D000', 'NLS_NUMERIC_CHARACTERS = '',.'' ');
     ELSE
        v_numero := TO_CHAR(p_numero,'99999999999999999990D000', 'NLS_NUMERIC_CHARACTERS = '',.'' ');
     END IF;
  ELSIF p_casas_dec = 2 THEN
     IF p_flag_milhar = 'S' THEN
        v_numero := TO_CHAR(p_numero,'99G999G999G999G999G999G990D00', 'NLS_NUMERIC_CHARACTERS = '',.'' ');
     ELSE
        v_numero := TO_CHAR(p_numero,'99999999999999999990D00', 'NLS_NUMERIC_CHARACTERS = '',.'' ');
     END IF;
  ELSIF p_casas_dec = 1 THEN
     IF p_flag_milhar = 'S' THEN
        v_numero := TO_CHAR(p_numero,'99G999G999G999G999G999G990D0', 'NLS_NUMERIC_CHARACTERS = '',.'' ');
     ELSE
        v_numero := TO_CHAR(p_numero,'99999999999999999990D0', 'NLS_NUMERIC_CHARACTERS = '',.'' ');
     END IF;
  ELSIF p_casas_dec = 0 THEN
     IF p_flag_milhar = 'S' THEN
        v_numero := TO_CHAR(p_numero,'99G999G999G999G999G999G990', 'NLS_NUMERIC_CHARACTERS = '',.'' ');
     ELSE
        v_numero := TO_CHAR(p_numero,'99999999999999999990', 'NLS_NUMERIC_CHARACTERS = '',.'' ');
     END IF;
  END IF;
--
/*
  IF v_numero IS NULL THEN
     v_numero := '0';
  END IF;
*/
--
  RETURN v_numero;
EXCEPTION
  WHEN OTHERS THEN
    RETURN v_numero;
END;

/
