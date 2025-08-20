--------------------------------------------------------
--  DDL for Function DATA_DIF_MOSTRAR
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE FUNCTION "DATA_DIF_MOSTRAR" (
-----------------------------------------------------------------------
-- DATA_DIF_MOSTRAR
--
--   Descricao: mostra a diferenca entre duas datas no formato 
--    HH:MI:SS
-----------------------------------------------------------------------
  p_data_menor              IN    DATE,
  p_data_maior              IN    DATE)
RETURN  VARCHAR2 IS
--
v_ok integer;
v_dif varchar2(20);
--
BEGIN
  IF p_data_menor IS NULL OR p_data_maior IS NULL OR
     p_data_menor > p_data_maior THEN
     v_dif := NULL;
  ELSE
     v_dif := TRIM(TO_CHAR(trunc((p_data_maior-p_data_menor) * 24),'999900')) || ':' ||
              TRIM(TO_CHAR(mod(trunc((p_data_maior-p_data_menor) * 1440), 60 ),'00')) || ':' ||
              TRIM(TO_CHAR(mod(trunc((p_data_maior-p_data_menor) * 86400), 60 ),'00'));
  END IF;
--
  RETURN v_dif;
--
EXCEPTION
  WHEN OTHERS THEN
    v_dif := 'Erro DIF';
    RETURN v_dif;
END;

/
