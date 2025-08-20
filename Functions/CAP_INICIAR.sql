--------------------------------------------------------
--  DDL for Function CAP_INICIAR
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE FUNCTION "CAP_INICIAR" -----------------------------------------------------------------------
-- cap_iniciar
--
--   Descricao: dado um string, inicializa as palavras com maiuscula,
--   com excecao das preposicoes.
-----------------------------------------------------------------------
  (p_string in varchar2)
RETURN  varchar2 IS

v_string varchar2(2000);

BEGIN
  v_string := INITCAP(p_string);
  v_string := REPLACE(v_string,' Da ',' da ');
  v_string := REPLACE(v_string,' De ',' de ');
  v_string := REPLACE(v_string,' Do ',' do ');
  v_string := REPLACE(v_string,' Das ',' das ');
  v_string := REPLACE(v_string,' Dos ',' dos ');
  v_string := REPLACE(v_string,' E ',' e ');
  v_string := REPLACE(v_string,' Em ',' em ');
  v_string := REPLACE(v_string,' No ',' no ');
  v_string := REPLACE(v_string,' Na ',' na ');
  v_string := REPLACE(v_string,' À ',' à ');
  v_string := REPLACE(v_string,' Ao ',' ao ');
  RETURN v_string;

EXCEPTION
  WHEN OTHERS THEN
    v_string := 'ERRO string';
    RETURN v_string;
END;

/
