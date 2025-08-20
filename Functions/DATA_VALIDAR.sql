--------------------------------------------------------
--  DDL for Function DATA_VALIDAR
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE FUNCTION "DATA_VALIDAR" -----------------------------------------------------------------------
-- DATA_VALIDAR
--
--   Descricao: funcao que consiste um string contendo uma data no
--   formato 'DD/MM/YYYY'. Retorna '1' caso o string seja uma data
--   valida, e '0' caso nao seja. Para um string igual a NULL,
--   retorna '1'.
-----------------------------------------------------------------------
  (p_data in varchar2)
RETURN  integer IS
--
v_ok integer;
v_data date;
v_ano integer;
--
BEGIN
  v_ok := 0;
  v_data := to_date(p_data,'dd/mm/yyyy');
  IF RTRIM(p_data) IS NOT NULL THEN
     v_ano := to_number(to_char(v_data,'yyyy'));
     IF v_ano > 1000 THEN
        v_ok := 1;
     END IF;
  ELSE
     v_ok := 1;
  END IF;
  RETURN v_ok;
--
EXCEPTION
  WHEN OTHERS THEN
    RETURN v_ok;
END;

/
