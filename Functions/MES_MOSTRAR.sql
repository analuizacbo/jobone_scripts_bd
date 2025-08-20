--------------------------------------------------------
--  DDL for Function MES_MOSTRAR
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE FUNCTION "MES_MOSTRAR" -----------------------------------------------------------------------
-- MES_MOSTRAR
--
--   Descricao: funcao que retorna o mes por extenso, dado um determinado
--   mes numerico (1 a 12). Caso o valor do mes
--   seja NULL ou zero, a funcao tambem retorna NULL.
-----------------------------------------------------------------------
  (p_mes in VARCHAR2)
RETURN  varchar2 IS
--
v_ok        integer;
v_mes       varchar2(40);
--
BEGIN
--
  SELECT DECODE(TO_NUMBER(RTRIM(p_mes)),
         1,'Janeiro',2,'Fevereiro',3,'Março',4,'Abril',
         5,'Maio',6,'Junho',7,'Julho',8,'Agosto',
         9,'Setembro',10,'Outubro',11,'Novembro',12,'Dezembro','')
    INTO v_mes
    FROM dual;
--
  RETURN v_mes;
--
EXCEPTION
  WHEN OTHERS THEN
    v_mes := '';
    RETURN v_mes;
END;

/
