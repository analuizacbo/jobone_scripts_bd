--------------------------------------------------------
--  DDL for Function LEFT_STRING
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE FUNCTION "LEFT_STRING" (p_string      IN  VARCHAR2,
                      p_delimitador IN  CHAR DEFAULT ',')
-----------------------------------------------------------------------
--   LEFT_STRING
--
--   Descricao: retorna o string a esquerda do delimitador.
-----------------------------------------------------------------------
RETURN VARCHAR2
IS

v_pos     INTEGER;
v_string  VARCHAR2(2000);

BEGIN
--Coloca o delimitador no final do string caso o string não tenha
  IF (RTRIM(p_string) IS NOT NULL) AND
     (SUBSTR(p_string,length(p_string)) <> p_delimitador) THEN
     v_string := RTRIM(p_string) || p_delimitador;
  ELSE
     v_string := RTRIM(p_string);
  END IF;
--
  -- localiza a posicao do primeiro delimitador no string
  v_pos := INSTR(v_string, p_delimitador, 1, 1);
--
  -- isola o grupo que vem antes do delimitador
  v_string := RTRIM(SUBSTR(v_string, 1, v_pos - 1));
--
  RETURN v_string;
END; -- PROX_VALOR_RETORNAR

/
