--------------------------------------------------------
--  DDL for Function HORA_MOSTRAR
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE FUNCTION "HORA_MOSTRAR" (
-----------------------------------------------------------------------
--   Descricao: funcao que converte uma data para o formato CHAR,
--   usando a mascara de saida 'HH:MI'. So' deve ser usada
--   em colunas/variaveis do tipo DATE. Caso o valor da coluna/variavel
--   seja NULL, a funcao tambem retorna NULL.
-----------------------------------------------------------------------
p_data                        IN DATE)
RETURN  VARCHAR2
IS
v_ok                          INTEGER;
v_hora                        VARCHAR2(10);
BEGIN
  v_ok := 0;
  v_hora := to_char(p_data,'HH24:MI');
  v_ok := 1;
  RETURN v_hora;
EXCEPTION
  WHEN OTHERS THEN
    v_hora := 'Erro HORA';
    RETURN v_hora;
END;

/
