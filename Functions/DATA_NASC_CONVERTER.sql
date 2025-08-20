--------------------------------------------------------
--  DDL for Function DATA_NASC_CONVERTER
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE FUNCTION "DATA_NASC_CONVERTER" -----------------------------------------------------------------------
-- DATA_NASC_CONVERTER
--
--   Descricao: funcao que converte um string contendo uma data no
--   formato 'DD/MM/YYYY' ou 'DD/MM'.
-----------------------------------------------------------------------
  (p_data in varchar2)
RETURN  DATE IS
--
v_data               date;
v_data_char          varchar(30);
--
BEGIN
  v_data := NULL;
--
  IF RTRIM(p_data) IS NOT NULL AND LENGTH(RTRIM(p_data)) <= 5 THEN
     v_data_char := RTRIM(p_data) || '/1904';
  ELSE
     v_data_char := RTRIM(p_data);
  END IF;

  v_data := TO_DATE(v_data_char,'dd/mm/yyyy');

  RETURN v_data;
--
EXCEPTION
  WHEN OTHERS THEN
    RETURN v_data;
END;

/
