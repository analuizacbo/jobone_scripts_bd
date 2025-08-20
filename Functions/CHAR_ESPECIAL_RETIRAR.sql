--------------------------------------------------------
--  DDL for Function CHAR_ESPECIAL_RETIRAR
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE FUNCTION "CHAR_ESPECIAL_RETIRAR" (
-----------------------------------------------------------------------
--   char_especial_retirar
--
--   Descricao: retira eventuais caracteres especiais de um dado string
-----------------------------------------------------------------------
  p_string in varchar2)
RETURN  varchar2 IS
--
v_string varchar2(4000);
--
BEGIN
  v_string := TRIM(p_string);
--
  v_string := TRIM(REPLACE(v_string, chr(13), ''));
  v_string := TRIM(REPLACE(v_string, chr(10), '|'));
--
  --v_string := TRIM(REPLACE(v_string, '&', '&amp;'));
  --v_string := TRIM(REPLACE(v_string, '>', '&gt;'));
  --v_string := TRIM(REPLACE(v_string, '<', '&lt;'));
  --v_string := TRIM(REPLACE(v_string, '"', '&quot;'));
--
  --v_string := TRIM(REPLACE(v_string, chr(147), '&ldquo;'));
  --v_string := TRIM(REPLACE(v_string, chr(148), '&rdquo;'));
  --v_string := TRIM(REPLACE(v_string, chr(145), '&lsquo;'));
  --v_string := TRIM(REPLACE(v_string, chr(146), '&rsquo;'));
--
  RETURN v_string;
--
EXCEPTION
  WHEN OTHERS THEN
    v_string := 'ERRO string';
    RETURN v_string;
END;

/
