--------------------------------------------------------
--  DDL for Function DIA_SEMANA_MOSTRAR
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE FUNCTION "DIA_SEMANA_MOSTRAR" (
  p_data             IN DATE,
  p_flag_extenso     IN VARCHAR2 DEFAULT 'N')
RETURN  VARCHAR2 IS
--
v_ok      INTEGER;
v_dia     VARCHAR2(30);
v_int     INTEGER;
--
BEGIN
  v_ok := 0;
  IF p_flag_extenso = 'N' THEN
     -- mostra dia da semana abreviado (default qdo o parametro nao for
     -- passado).
     SELECT  DECODE(TO_CHAR(p_data,'D'),
               '1','Dom','2','Seg','3','Ter',
               '4','Qua','5','Qui','6','Sex','7','Sab')
     INTO v_dia FROM DUAL;
  ELSE
     -- mostra dia da semana por extenso
     SELECT  DECODE(TO_CHAR(p_data,'D'),
            '1','Domingo','2','Segunda-Feira','3','Terça-Feira',
            '4','Quarta-Feira','5','Quinta-Feira','6','Sexta-Feira','7','Sábado')
     INTO v_dia FROM DUAL;
  END IF;
--
  SELECT to_char(p_data,'DD')
    INTO v_int FROM DUAL;
--
--  v_dia := TRIM(TO_CHAR(v_int,'00')) || ' (' || v_dia || ')';
--
  v_ok := 1;
  RETURN v_dia;
--
EXCEPTION
  WHEN OTHERS THEN
    v_dia := 'Erro DATA';
    RETURN v_dia;
END;

/
