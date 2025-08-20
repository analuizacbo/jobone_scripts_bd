--------------------------------------------------------
--  DDL for Function FLAG_VALIDAR
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE FUNCTION "FLAG_VALIDAR" -----------------------------------------------------------------------
-- FLAG_VALIDAR
--
--   Descricao: funcao que consiste valores validos para um atributo
--   do tipo flag.
-----------------------------------------------------------------------
  (p_flag in varchar2)
RETURN  integer IS
--
v_ok integer;
--
BEGIN
  v_ok := 0;
  IF RTRIM(p_flag) IN ('S','N') THEN
     v_ok := 1;
  END IF;
  RETURN v_ok;
--
EXCEPTION
  WHEN OTHERS THEN
    RETURN v_ok;
END;

/
