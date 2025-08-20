--------------------------------------------------------
--  DDL for Function DIG_MOD11_RETORNAR
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE FUNCTION "DIG_MOD11_RETORNAR" 
-----------------------------------------------------------------------
--   DIG_MOD11_RETORNAR
--
-- O par�metro pCodigo deve estar sem o d�gito para o c�lculo
-----------------------------------------------------------------------
(pCodigo VARCHAR2)

RETURN NUMBER
IS
lnmbSoma      NUMBER := 0;
lnmbFator     NUMBER := 9;
lnmbTamCodigo NUMBER;
BEGIN
--
  -- Seleciona o tamanho do c�digo para saber quantas vezes � necess�rio iterar no loop
  lnmbTamCodigo := LENGTH(TRIM(pCodigo));
--
  -- Loop dos c�lculos
  FOR i IN REVERSE 1..lnmbTamCodigo LOOP
    --
    IF (lnmbFator = 9) THEN
       lnmbFator := 2;
    ELSE
       lnmbFator := lnmbFator + 1;
    END IF;
    --
    lnmbSoma := lnmbSoma + (lnmbFator *
          SUBSTR(pCodigo, i, 1));
  END LOOP;
  --
  -- Se o d�gito for maior que 9, retornar zero ...
  IF (11 - (lnmbSoma MOD 11)) > 9 THEN
      RETURN 0;
  -- ... Caso contr�rio, o d�gito
  ELSE
      RETURN 11 - (lnmbSoma MOD 11);
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    RETURN 999;
--
END;

/
