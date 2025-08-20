--------------------------------------------------------
--  DDL for Function DATA_HORA_CONVERTER
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE FUNCTION "DATA_HORA_CONVERTER" -----------------------------------------------------------------------
-- DATA_HORA_CONVERTER
--
--   Descricao: funcao que converte um string contendo uma data no
--   formato 'DD/MM/YYYY HH24:MI'.
-----------------------------------------------------------------------
  (p_data in varchar2)
RETURN  DATE IS
--
v_data date;
--
BEGIN
  v_data := NULL;
  v_data := to_date(p_data,'dd/mm/yyyy hh24:mi');

  RETURN v_data;
--
EXCEPTION
  WHEN OTHERS THEN
    RETURN v_data;
END;

/
