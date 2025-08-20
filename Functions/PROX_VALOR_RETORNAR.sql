--------------------------------------------------------
--  DDL for Function PROX_VALOR_RETORNAR
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE FUNCTION "PROX_VALOR_RETORNAR" (p_vetor       IN OUT LONG,
                              p_delimitador IN     CHAR DEFAULT ',')
-----------------------------------------------------------------------
--   PROX_VALOR_RETORNAR
--
--   Descricao: função tem dois parâmetros de entrada, um é o delimitador dos valores
--   do vetor e outro, é o vetor que tem todos os valores separados pelo delimitador.
--   A função retorna o primeiro valor do vetor e modifica p_vetor pare que ele não tenha
--   mais o valor retornado.
--   Exemplo 1) ENTRADA : p_delimitador = ','  e  p_vetor = '1,2,3
--              SAÍDA   : return_value  = '1'  e  p_vetor = '2,3,'
--   Exemplo 2) ENTRADA : p_delimitador = ','  e  p_vetor = '2,3,'
--              SAÍDA   : return_value  = '2'  e  p_vetor = '3,'
--   Exemplo 3) ENTRADA : p_delimitador = ','  e  p_vetor = '3,'
--              SAÍDA   : return_value  = '3'  e  p_vetor = NULL
--   Exemplo 4) ENTRADA : p_delimitador = ','  e  p_vetor = NULL
--              SAÍDA   : return_value  = NULL e  p_vetor = NULL

-----------------------------------------------------------------------
RETURN LONG
IS

v_pos    INTEGER;
v_valor  LONG;

BEGIN
  -- Coloca o delimitador no final do vetor caso o vetor não tenha
  IF (RTRIM(p_vetor) IS NOT NULL) AND
     (SUBSTR(p_vetor,length(p_vetor)) <> p_delimitador) THEN
     p_vetor := RTRIM(p_vetor) || p_delimitador;
  ELSE
     p_vetor := RTRIM(p_vetor);
  END IF;
--
  -- localiza a posicao do primeiro delimitador no vetor
  v_pos := INSTR(p_vetor, p_delimitador, 1, 1);
--
  -- extrai o string que vem antes do delimitador
  v_valor := RTRIM(SUBSTR(p_vetor, 1, v_pos - 1));
--
  -- troca eventual tag de pipe pelo pipe verdadeiro
  v_valor := REPLACE(v_valor,'[pipe]','|');
--
  -- pega o string restante (apos o delimitador)
  p_vetor := SUBSTR(p_vetor, v_pos + 1);
--
  RETURN v_valor;
END; -- PROX_VALOR_RETORNAR

/
