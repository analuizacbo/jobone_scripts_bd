--------------------------------------------------------
--  DDL for Function EMAIL_VALIDAR
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE FUNCTION "EMAIL_VALIDAR" (p_email IN VARCHAR2)
-----------------------------------------------------------------------
--   EMAIL_VALIDAR
--
--   Descricao: funcao que valida email. Retorna '1' caso o string seja
--   um email num formato valido e'0' caso nao seja. Para um string
--   igual a NULL, retorna '1'.
-----------------------------------------------------------------------
RETURN  integer IS

v_letras                  VARCHAR2(255);
v_email                   VARCHAR2(255);
v_idx                     INTEGER;
v_max                     INTEGER;
v_ok                      INTEGER;
v_exception               EXCEPTION;
--
BEGIN
  v_letras := 'abcdefghijklmnopqrstuvwxyz1234567890_-.@';
  v_email := LTRIM(RTRIM(LOWER(p_email)));
  v_max := LENGTH(v_email);
  v_idx := 0;
  v_ok := 1;
--
  IF v_email IS NOT NULL THEN
     IF NOT v_email LIKE '_%@_%.__%' THEN
        RAISE v_exception;
     END IF;
     --
     -- nao aceita ponto-ponto junto
     IF INSTR(v_email,'..',1) > 0 THEN
        RAISE v_exception;
     END IF;
     --
     -- nao aceita ponto no final
     IF SUBSTR(v_email,v_max,1) = '.' THEN
        RAISE v_exception;
     END IF;
     --
     WHILE v_idx < v_max AND v_ok = 1
     LOOP
       v_idx := v_idx+ 1;
       IF NOT v_letras LIKE '%' || SUBSTR(v_email, v_idx, 1) || '%'  THEN
          v_ok := 0;
       END IF;
     END LOOP;
  END IF;
--
  RETURN v_ok;
EXCEPTION
  WHEN v_exception THEN
    v_ok := 0;
    RETURN v_ok;
  WHEN OTHERS THEN
    v_ok := 0;
    RETURN v_ok;
END;

/
