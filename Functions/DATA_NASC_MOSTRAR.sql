--------------------------------------------------------
--  DDL for Function DATA_NASC_MOSTRAR
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE FUNCTION "DATA_NASC_MOSTRAR" -----------------------------------------------------------------------
-- DATA_NASC_MOSTRAR
--
--   Descricao: funcao que converte uma data para o formato CHAR,
--   usando a mascara de saida 'DD/MM/YYYY' ou 'DD/MM' (caso o ano seja
--   igual a 1904).
--   So' deve ser usada em colunas/variaveis do tipo DATE. Caso o valor
--   da  coluna/variavel seja NULL, a funcao tambem retorna NULL.
-----------------------------------------------------------------------
  (p_data in date)
RETURN  varchar2 IS
--
v_ok                   integer;
v_data                 varchar2(10);
v_ano                  integer;
--
BEGIN
  v_ok := 0;
  v_ano := TO_NUMBER(TO_CHAR(p_data,'yyyy'));
--
  IF v_ano = 1904 THEN
     v_data := TO_CHAR(p_data,'dd/mm');
  ELSE
     v_data := TO_CHAR(p_data,'dd/mm/yyyy');
  END IF;
--
  v_ok := 1;
  RETURN v_data;
--
EXCEPTION
  WHEN OTHERS THEN
    v_data := 'Erro DATA';
    RETURN v_data;
END;

/
