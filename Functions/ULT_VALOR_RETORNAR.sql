--------------------------------------------------------
--  DDL for Function ULT_VALOR_RETORNAR
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE FUNCTION "ULT_VALOR_RETORNAR" (p_vetor       IN OUT VARCHAR2,
                             p_delimitador IN  CHAR DEFAULT ',')
-----------------------------------------------------------------------
--   ULT_VALOR_RETORNAR
--
--   Descricao: função tem dois parâmetros de entrada, um é o delimitador dos valores
--   do vetor e outro, é o vetor que tem todos os valores separados pelo delimitador.
--   A função retorna o ultimo valor do vetor a direita do delimitador, e modifica
--   p_vetor pare que ele não tenha mais o valor retornado.
--
--   Exemplo 1) ENTRADA : p_delimitador = ','  e  p_vetor = '1,2,3
--              SAÍDA   : return_value  = '3'  e  p_vetor = '1,2'
--
--   Exemplo 2) ENTRADA : p_delimitador = ','  e  p_vetor = '2,3,'
--              SAÍDA   : return_value  = NULL e  p_vetor = '2,3,'
--
--   Exemplo 3) ENTRADA : p_delimitador = ','  e  p_vetor = '3'
--              SAÍDA   : return_value  = NULL e  p_vetor = '3'
--
--   Exemplo 4) ENTRADA : p_delimitador = ','  e  p_vetor = NULL
--              SAÍDA   : return_value  = NULL e  p_vetor = NULL

-----------------------------------------------------------------------
RETURN VARCHAR2
IS

v_pos       INTEGER;        -- posicao do ultimo delimitador encontrado
v_valor     VARCHAR2(2000); -- valor a direita do ultimo delimitador
v_len       INTEGER;        -- tamanho total do vetor
v_ind       INTEGER;
v_achou     INTEGER;

BEGIN
  v_pos := 0;
  v_len := NVL(LENGTH(p_vetor),0);
  v_ind := v_len;
  v_achou := 0;
--
  WHILE v_achou = 0 AND v_ind > 0 LOOP
    IF SUBSTR(p_vetor,v_ind,1) = p_delimitador THEN
       v_achou := 1;
       v_pos := v_ind;
    ELSE
       v_ind := v_ind - 1;
    END IF;
  END LOOP;
--
  IF v_achou = 1 THEN
     IF v_pos = v_len THEN
        v_valor := NULL;
     ELSE
        v_valor := RTRIM(SUBSTR(p_vetor, v_pos+1));
        p_vetor := RTRIM(SUBSTR(p_vetor,1, v_pos-1));
     END IF;
  END IF;
--
  RETURN v_valor;
END; -- ULT_VALOR_RETORNAR

/
