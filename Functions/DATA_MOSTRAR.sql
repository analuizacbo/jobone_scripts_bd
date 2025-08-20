--------------------------------------------------------
--  DDL for Function DATA_MOSTRAR
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE FUNCTION "DATA_MOSTRAR" -----------------------------------------------------------------------
-- DATA_MOSTRAR
--
--   Descricao: funcao que converte uma data para o formato CHAR,
--   usando a mascara de saida 'DD/MM/YYYY'. So' deve ser usada em
--   colunas/variaveis do tipo DATE. Caso o valor da  coluna/variavel
--   seja NULL, a funcao tambem retorna NULL.
-----------------------------------------------------------------------
  (p_data in date)
RETURN  varchar2 IS
--
v_ok integer;
v_data varchar2(10);
--
BEGIN
  v_ok := 0;
  v_data := to_char(p_data,'dd/mm/yyyy');
  v_ok := 1;
  RETURN v_data;
--
EXCEPTION
  WHEN OTHERS THEN
    v_data := 'Erro DATA';
    RETURN v_data;
END;

/
