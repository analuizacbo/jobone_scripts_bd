--------------------------------------------------------
--  DDL for Function DATA_CONVERTER
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE FUNCTION "DATA_CONVERTER" -----------------------------------------------------------------------
-- DATA_CONVERTER
--
--   Descricao: funcao que converte um string contendo uma data no
--   formato 'DD/MM/YYYY'.
-----------------------------------------------------------------------
  (p_data in varchar2)
RETURN  DATE IS
--
v_data date;
--
BEGIN
  v_data := NULL;
  v_data := to_date(p_data,'dd/mm/yyyy');

  RETURN v_data;
--
EXCEPTION
  WHEN OTHERS THEN
    RETURN v_data;
END;

/
