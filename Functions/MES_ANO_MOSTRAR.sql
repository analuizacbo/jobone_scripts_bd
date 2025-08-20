--------------------------------------------------------
--  DDL for Function MES_ANO_MOSTRAR
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE FUNCTION "MES_ANO_MOSTRAR" -----------------------------------------------------------------------
-- MES_ANO_MOSTRAR
--
--   Descricao: funcao que converte uma data para o formato CHAR,
--   usando a mascara de saida 'MMM/YYYY', onde MMM indica o mes
--   abreviado. So' deve ser usada em
--   colunas/variaveis do tipo DATE. Caso o valor da  coluna/variavel
--   seja NULL, a funcao tambem retorna NULL.
-----------------------------------------------------------------------
  (p_data in date)
RETURN  varchar2 IS
--
v_data varchar2(10);
--
BEGIN
  v_data := to_char(p_data,'dd/mm/yyyy');
--
  SELECT DECODE(TO_NUMBER(TO_CHAR(p_data,'mm')),
         1,'Jan',2,'Fev',3,'Mar',4,'Abr',
         5,'Mai',6,'Jun',7,'Jul',8,'Ago',
         9,'Set',10,'Out',11,'Nov',12,'Dez','') || '/' ||
         TO_CHAR(p_data,'yyyy')
    INTO v_data
    FROM dual;
--
  RETURN v_data;
--
EXCEPTION
  WHEN OTHERS THEN
    v_data := 'Erro DATA';
    RETURN v_data;
END;

/
