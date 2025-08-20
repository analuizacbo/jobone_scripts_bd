--------------------------------------------------------
--  DDL for Function MES_ABREV_MOSTRAR
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE FUNCTION "MES_ABREV_MOSTRAR" -----------------------------------------------------------------------
-- MES_ABREV_MOSTRAR
--
--   Descricao: funcao que retorna o mes por abreviado, dado um determinado
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
         1,'Jan',2,'Fev',3,'Mar',4,'Abr',
         5,'Mai',6,'Jun',7,'Jul',8,'Ago',
         9,'Set',10,'Out',11,'Nov',12,'Dez','')
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
