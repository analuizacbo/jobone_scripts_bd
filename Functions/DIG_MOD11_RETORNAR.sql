--------------------------------------------------------
--  DDL for Function DIG_MOD11_RETORNAR
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE FUNCTION "DIG_MOD11_RETORNAR" 
-----------------------------------------------------------------------
--   DIG_MOD11_RETORNAR
--
-- O parâmetro pCodigo deve estar sem o dígito para o cálculo
-----------------------------------------------------------------------
(pCodigo VARCHAR2)

RETURN NUMBER
IS
lnmbSoma      NUMBER := 0;
lnmbFator     NUMBER := 9;
lnmbTamCodigo NUMBER;
BEGIN
--
  -- Seleciona o tamanho do código para saber quantas vezes é necessário iterar no loop
  lnmbTamCodigo := LENGTH(TRIM(pCodigo));
--
  -- Loop dos cálculos
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
  -- Se o dígito for maior que 9, retornar zero ...
  IF (11 - (lnmbSoma MOD 11)) > 9 THEN
      RETURN 0;
  -- ... Caso contrário, o dígito
  ELSE
      RETURN 11 - (lnmbSoma MOD 11);
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    RETURN 999;
--
END;

/
