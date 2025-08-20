--------------------------------------------------------
--  DDL for Function HORA_VALIDAR
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE FUNCTION "HORA_VALIDAR" -----------------------------------------------------------------------
-- HORA_VALIDAR
--
--   Descricao: funcao que consiste um string contendo uma hora no
--   formato 'HH:MI'. Retorna '1' caso o string seja uma hora
--   valida, e '0' caso nao seja. Para um string igual a NULL,
--   retorna '1'.
-----------------------------------------------------------------------
  (p_hora in varchar2)
RETURN  integer IS

v_ok           integer;
v_data         date;
v_hora         VARCHAR2(20);

BEGIN
  v_ok := 0;
  v_hora := RTRIM(REPLACE(p_hora, ' ',''));
  --
  IF RTRIM(v_hora) IS NULL THEN
     v_ok := 1;
     RETURN v_ok;
  END IF;
  --
  IF LENGTH(RTRIM(v_hora)) <> 5 OR INSTR(v_hora,':') <> 3 THEN
     v_ok := 0;
     RETURN v_ok;
  END IF;
  --
  v_data := to_date(v_hora,'hh24:mi');
  v_ok := 1;
  RETURN v_ok;

EXCEPTION
  WHEN OTHERS THEN
    RETURN v_ok;
END;

/
