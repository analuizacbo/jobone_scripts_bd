--------------------------------------------------------
--  DDL for Function MES_ANO_VALIDAR
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE FUNCTION "MES_ANO_VALIDAR" (
-----------------------------------------------------------------------
--   MES_ANO_VALIDAR
--
--   Descricao: funcao que consiste um string contendo uma data no
--   formato 'mm/yyyy'. Retorna '1' caso o string seja ok e '0'
--   caso nao. Para um string igual a NULL, retorna '1'.
-----------------------------------------------------------------------
p_mes_ano IN VARCHAR2
)
RETURN  INTEGER IS

v_ok              INTEGER;
v_data            DATE;
v_mes_ano         VARCHAR2(20);

BEGIN
  v_ok := 0;
  --
  IF RTRIM(p_mes_ano) IS NULL THEN
     v_ok := 1;
     RETURN v_ok;
  END IF;
  --
  IF LENGTH(RTRIM(p_mes_ano)) <> 7 OR INSTR(p_mes_ano,'/') <> 3 THEN
     v_ok := 0;
     RETURN v_ok;
  END IF;
  --
  v_data := to_date('01/'||p_mes_ano,'dd/mm/yyyy');
  v_ok := 1;
  RETURN v_ok;

EXCEPTION
  WHEN OTHERS THEN
    RETURN v_ok;
END;

/
