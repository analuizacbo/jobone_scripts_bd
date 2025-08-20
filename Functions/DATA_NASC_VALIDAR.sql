--------------------------------------------------------
--  DDL for Function DATA_NASC_VALIDAR
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE FUNCTION "DATA_NASC_VALIDAR" -----------------------------------------------------------------------
-- DATA_NASC_VALIDAR
--
--   Descricao: funcao que consiste um string contendo uma data no
--   formato 'DD/MM/YYYY' ou 'DD/MM'. Caso a data esteja no formato
--   DD/MM, usa-se o ano bisexto 1904 como base.
--   Retorna '1' caso o string seja uma data valida, e '0' caso nao
--   seja. Para um string igual a NULL, retorna '1'.
-----------------------------------------------------------------------
  (p_data in varchar2)
RETURN  integer IS
--
v_ok             integer;
v_data           date;
v_ano            integer;
v_data_char      varchar(30);
--
BEGIN
  v_ok := 0;
--
  IF RTRIM(p_data) IS NOT NULL AND LENGTH(RTRIM(p_data)) <= 5 THEN
     v_data_char := RTRIM(p_data) || '/1904';
  ELSE
     v_data_char := RTRIM(p_data);
  END IF;
--
  v_data := TO_DATE(v_data_char,'dd/mm/yyyy');
--
  IF RTRIM(p_data) IS NOT NULL THEN
     v_ano := TO_NUMBER(TO_CHAR(v_data,'yyyy'));
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
