--------------------------------------------------------
--  DDL for Function BYTES_NOTACAO_RETORNAR
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE FUNCTION "BYTES_NOTACAO_RETORNAR" (
-----------------------------------------------------------------------
--   MOEDA_MOSTRAR
--
--   Descricao: retorna um string com a notacao em bytes,KB,MB,GB
-----------------------------------------------------------------------
  p_bytes                      IN NUMBER)
RETURN  VARCHAR2
IS
  TYPE t_notacao IS VARRAY(4) OF VARCHAR2(10);
  v_ok                         INTEGER;
  v_retorno                    VARCHAR2(100);
  v_numero                     NUMBER;
  v_ind                        NUMBER(10);
  v_notacao                    t_notacao;
BEGIN
--
  v_notacao := t_notacao('bytes', 'KB', 'MB', 'GB');
  v_numero := p_bytes;
  v_ind := 1;
  v_retorno := NULL;
--
  WHILE v_numero/1024 >= 1 AND v_ind < 4 LOOP
    v_numero := v_numero / 1024;
    v_ind := v_ind + 1;
  END LOOP;
--
  IF p_bytes IS NOT NULL THEN
     v_retorno := TO_CHAR(v_numero,'99999999999999999999D99', 'NLS_NUMERIC_CHARACTERS = '',.'' ') ||
                  ' ' || v_notacao(v_ind);
  END IF;
--
  RETURN v_retorno;
EXCEPTION
  WHEN OTHERS THEN
    v_retorno := 'ERRO';
    RETURN v_retorno;
END;

/
