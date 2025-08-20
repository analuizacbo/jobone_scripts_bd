--------------------------------------------------------
--  DDL for Function MOEDA_EXTENSO_MOSTRAR
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE FUNCTION "MOEDA_EXTENSO_MOSTRAR" (
------------------------------------------------------------------------------------------
-- DESENVOLVEDOR: Internet        OpenMind     DATA: 06/08/2002
-- DESCRICAO: retorna o valor por extenso de um numero (moeda).
--
-- ALTERADO POR      DATA        MOTIVO ALTERACAO
-- ----------------  ----------  ---------------------------------------------------------
-- xxxxxxxxxxxx      dd/mm/yyyy
------------------------------------------------------------------------------------------
  p_numero             IN  NUMBER)
RETURN   VARCHAR2 IS
--
  TYPE vetor  IS TABLE OF VARCHAR2(20) INDEX BY BINARY_INTEGER;
  TYPE vetor1 IS TABLE OF NUMBER       INDEX BY BINARY_INTEGER;
--
  SAIR_LOOP            NUMBER(3);
  CONTADOR             NUMBER(3);
  CONTA_STRING         NUMBER(3);
  pvExtenso            VARCHAR2(200);
  nResto               NUMBER; /* Resto do Numero */
  nNumero              NUMBER; /* Numero a ser analizado */
  nNumTrunc            NUMBER;
  nComplemento         NUMBER;
  nQuociente           NUMBER; /* Quociente da divisao por 10 */
  nDecimal             NUMBER;
  sDescrNumCen         vetor;
  sDescrNumDec         vetor;
  sDescrNum            vetor;
  sDescrNumExe         vetor;
  nInd                 BINARY_INTEGER;
  nInd1                BINARY_INTEGER;
  nCont                BINARY_INTEGER;
  nDigito              vetor1; /* Vetor que contem os digitos do numero */
  sNumeroExtenso       VARCHAR2(1000);
  sPrimeiroExtenso     VARCHAR2(13);
  sSegundoExtenso      VARCHAR2(13);
  sTerceiroExtenso     VARCHAR2(13);
  nCasa                NUMBER; /* Indica se digito e cen, dez ou unidade */
  nIndCen              BINARY_INTEGER;
  nIndDez              BINARY_INTEGER;
  nIndUni              BINARY_INTEGER;
  sConjuncaoCD         VARCHAR2(3); /* Conjuncao entre centena e dezena */
  sConjuncaoIn         VARCHAR2(2); /* Conjuncao inicial */
  sConjuncaoDU         VARCHAR2(3); /* Conjuncao entre dezena e unidade */
  sGrandeza            VARCHAR2(10);
  sGrandezaSing        VARCHAR2(10); /* Grandeza no singular */
  sGrandezaPlural      VARCHAR2(10); /* Grandeza em plural */
  sMoeda               VARCHAR2(10); /* Descricao da moeda */
  sCentavos            VARCHAR2(10); /* String Centavo */
  nCentavos            NUMBER; /* parte centavo do numero */
  sPreposicao          VARCHAR2(3); /* carrega preposicao DE */
  bPrimeiro            BOOLEAN; /* Indica que e o primeiro digito do numero */
  bCentavos1a9         BOOLEAN; /* Numero entre 1 a 9 centavos */
  bCentavos            BOOLEAN; /* Parte Centavos */
--
-----------------------------------
PROCEDURE CARREGA_VARIAVEIS AS
-----------------------------------
BEGIN
  /*** Centenas ***/
  sDescrNumCen(0) := NULL;
  sDescrNumCen(1) := 'cento';
  sDescrNumCen(2) := 'duzentos';
  sDescrNumCen(3) := 'trezentos';
  sDescrNumCen(4) := 'quatrocentos';
  sDescrNumCen(5) := 'quinhentos';
  sDescrNumCen(6) := 'seiscentos';
  sDescrNumCen(7) := 'setecentos';
  sDescrNumCen(8) := 'oitocentos';
  sdescrNumCen(9) := 'novecentos';
  /*** Digitos ***/
  sDescrNum(0) := NULL;
  sDescrNum(1) := 'um';
  sDescrNum(2) := 'dois';
  sDescrNum(3) := 'três';
  sDescrNum(4) := 'quatro';
  sDescrNum(5) := 'cinco';
  sDescrNum(6) := 'seis';
  sDescrNum(7) := 'sete';
  sDescrNum(8) := 'oito';
  sDescrNum(9) := 'nove';
  /*** Dezenas ***/
  sDescrNumDec(0) := NULL;
  sDescrNumDec(1) := 'dez';
  sDescrNumDec(2) := 'vinte';
  sDescrNumDec(3) := 'trinta';
  sDescrNumDec(4) := 'quarenta';
  sDescrNumDec(5) := 'cinquenta';
  sDescrNumDec(6) := 'sessenta';
  sDescrNumDec(7) := 'setenta';
  sDescrNumDec(8) := 'oitenta';
  sDescrNumDec(9) := 'noventa';
  /*** Excecoes ***/
  sDescrNumExe(0) := 'dez';
  sDescrNumExe(1) := 'onze';
  sDescrNumExe(2) := 'doze';
  sDescrNumExe(3) := 'treze';
  sDescrNumExe(4) := 'quatorze';
  sDescrNumExe(5) := 'quinze';
  sDescrNumExe(6) := 'dezesseis';
  sDescrNumExe(7) := 'dezessete';
  sDescrNumExe(8) := 'dezoito';
  sDescrNumExe(9) := 'dezenove';
END;
--
-----------------------------------
PROCEDURE VERIFICA_MOEDA AS
-----------------------------------
BEGIN
  nNumero := NVL(p_numero,0);
--
  -- Verifica Moeda */
  IF nNumero >= 1 AND nNumero < 2 THEN
     sMoeda := 'real ';
  ELSIF nNumero < 1 THEN
     sMoeda := NULL;
  ELSE
     sMoeda := 'reais ';
  END IF;
--
  nNumTrunc := TRUNC(nNumero); /* Obtem numero Inteiro */
  nCentavos := nNumero - nNumTrunc; /* Obtem Centavos */
--
  -- Verifica Centavos */
  IF nCentavos = 0.01 THEN
     sCentavos := 'centavo';
  ELSIF nCentavos = 0 THEN
     sCentavos := NULL;
  ELSE
     sCentavos := 'centavos';
  END IF;
--
  IF nCentavos >= 0.01 AND nCentavos <= 0.09 THEN /* Centavos entre 1 a 9 */
     bCentavos1a9 := true;
  END IF;
--
  nNumero := nNumero*100; /* Multiplica numero por cem */
END;
--
PROCEDURE CARREGA_DIGITOS_ARRAY AS
----------------------------------------------------------------------
-- Esta procedure divide o numero em questao por dez sucessivamente para
-- obter os digitos separadamente, carregando os em um ARRAY.
-- O resto da divisao por 10 nos da o digito atraves do comando MOD
-- nInd contera o numero de digitos
----------------------------------------------------------------------
BEGIN
  nInd := 0;
--
  LOOP
    nResto := MOD(nNumero,10);
    nInd := nInd + 1;
    nDigito(nInd) := nResto;
    nComplemento := nNumero - nResto;
    nQuociente := nComplemento/10;
--
    IF nQuociente = 0 THEN
       IF sMoeda IS NULL AND nInd = 1 THEN /* Numero de 1 a nove centavos */
          nInd := nInd + 1;
          nDigito(nInd) := 0;
       END IF;
       EXIT;
    END IF;
    nNumero := nQuociente;
  END LOOP;
END;
--
-----------------------------------
PROCEDURE TRATA_CENTENA AS
-----------------------------------
BEGIN
  nIndCen := nCont; /* Indice da Centena */
  nIndDez := nCont - 1; /* Indice da Dezena */
  nIndUni := nCont - 2; /* Indice da Unidade */
--
  -- Conjuncao entre centena e dezena
  IF nDigito(nIndDez) = 0 THEN
     sConjuncaoCD := NULL;
  ELSE
     IF nDigito(nIndCen) <> 0 THEN
        sConjuncaoCD := ' e ';
     ELSE
        sConjuncaoCD := NULL;
     END IF;
  END IF;
--
  -- Conjuncao entre dezena e unidade
  IF nDigito(nIndUni) = 0 THEN
     sConjuncaoDU := NULL;
  ELSE
     IF nDigito(nIndDez) NOT IN (1,0) THEN
        sConjuncaoDU := ' e ';
     ELSIF nDigito(nIndCen) <> 0 AND nDigito(nIndDez) = 0 THEN
        sConjuncaoDU := ' e ';
     ELSE
        sConjuncaoDU := NULL;
     END IF;
  END IF;
--
  -- Particuladares do numero um
  IF nDigito(nIndCen) = 1 AND sConjuncaoCD IS NULL AND sConjuncaoDU IS NULL THEN
     sPrimeiroExtenso := 'cem';
  ELSE
     sPrimeiroExtenso := sDescrNumCen(nDigito(nIndCen));
  END IF;
--
  IF nDigito(nIndDez) = 1 THEN
     sSegundoExtenso := sDescrNumExe(nDigito(nIndUni));
     sTerceiroExtenso := NULL;
  ELSE
     sSegundoExtenso := sDescrNumDec(nDigito(nindDez));
     sTerceiroExtenso := sDescrNum(nDigito(nIndUni));
  END IF;
--
  -- Verifica centena de zeros
  IF nDigito(nIndDez) = 0 AND nDigito(nIndCen) = 0 AND nDigito(nIndUni) = 0 THEN
     sGrandeza := NULL;
     sConjuncaoIn := NULL;
  ELSE
     IF sGrandezaPlural = ' mil ' OR sGrandezaPlural IS NULL THEN
        sPreposicao := NULL;
     END IF;
--
     IF NOT bPrimeiro THEN
        sConjuncaoIn := ', ';
     END IF;
     sGrandeza := sGrandezaPlural;
  END IF;
--
  -- Carrega Numero Extenso
  sNumeroExtenso := sNumeroExtenso||sConjuncaoIn||sPrimeiroExtenso||sConjuncaoCD||
                    sSegundoExtenso||sConjuncaoDU||sTerceiroExtenso||sGrandeza;
  nCont := nCont - 3; /* Proxima casa */
END;
--
-----------------------------------
PROCEDURE TRATA_DEZENA AS
-----------------------------------
BEGIN
  nIndDez := nCont; /* Indice da Centena */
  nIndUni := nCont - 1; /* Indicie da Unidade */
--
  -- Conjuncao entre dezena e unidade
  IF nDigito(nIndUni) = 0 THEN
     sConjuncaoDU := NULL;
  ELSE
     IF NOT bCentavos THEN /* dezena Inteira */
        IF nDigito(nIndDez) <> 1 THEN
           sConjuncaoDU := ' e ';
        ELSE
           sConjuncaoDU := NULL;
        END IF;
     ELSE /* dezena dos Centavos */
        IF nDigito(nIndDez) <> 1 AND NOT bCentavos1a9 THEN
           sConjuncaoDU := ' e ';
        ELSE
           sConjuncaoDU := NULL;
        END IF;
     END IF;
  END IF;
--
  -- Particuladares do numero um
  IF nDigito(nIndDez) = 1 THEN
     sPrimeiroExtenso := sDescrNumExe(nDigito(nIndUni));
     sSegundoExtenso := NULL;
  ELSE
     sPrimeiroExtenso := sDescrNumDec(nDigito(nIndDez));
     sSegundoExtenso := sDescrNum(nDigito(nIndUni));
  END IF;
--
  -- Carrega Numero Extenso
  sNumeroExtenso := sNumeroExtenso||sConjuncaoIn||sPrimeiroExtenso||sConjuncaoDU||
                    sSegundoExtenso||sGrandezaPlural;
  nCont := nCont - 2; /* Proxima casa */
END;
--
-----------------------------------
PROCEDURE VERIFICA_GRANDEZA AS
-----------------------------------
BEGIN
  IF nCont = 15 THEN
     sGrandezaSing := ' trilhão';
     sGrandezaPlural := ' trilhões';
     IF bPrimeiro THEN
        sPreposicao := ' de';
     END IF;
  ELSIF nCont IN (14,13,12) THEN
     sGrandezaSing := ' bilhão';
     sGrandezaPlural := ' bilhões';
     IF bPrimeiro THEN
        sPreposicao := ' de';
     END IF;
  ELSIF nCont IN (11,10,9) THEN
     sGrandezaSing := ' milhão';
     sGrandezaPlural := ' milhões';
     IF bPrimeiro THEN
        sPreposicao := ' de';
     END IF;
  ELSIF nCont IN (8,7,6) THEN
     sGrandezaSing := ' mil';
     sGrandezaPlural := ' mil';
  ELSIF ncont IN (5,4,3) THEN
     sGrandezaSing := NULL;
     sGrandezaPlural := NULL;
  END IF;
END;
--
-----------------------------------
PROCEDURE TRATA_UNIDADE AS
-----------------------------------
BEGIN
  nIndUni := nCont;
--
  IF nDigito(nIndUni) = 1 THEN
     -- sPrimeiroExtenso := 'hum';
     sPrimeiroExtenso := 'um';
     sGrandeza := sGrandezaSing;
  ELSE
     sPrimeiroExtenso := sDescrNum(nDigito(nIndUni));
     sGrandeza := sGrandezaPlural;
  END IF;
--
  -- Carrega Numero Extenso
  sNumeroExtenso := sNumeroExtenso||sPrimeiroExtenso||sGrandeza;
  nCont := nCont - 1; /* proxima casa */
END;
--
-----------------------------------
PROCEDURE CONCATENA_MOEDA AS
-----------------------------------
BEGIN
  sNumeroExtenso:= sNumeroExtenso||sPreposicao||' '||sMoeda;
END;
--
-----------------------------------
PROCEDURE CONCATENA_CENTAVOS AS
-----------------------------------
BEGIN
  sNumeroExtenso:= sNumeroExtenso||' '||sCentavos;
END;
--
PROCEDURE VERIFICA_EXTENSO AS
----------------------------------------------------------------------
-- Esta procedure varre o ARRAY que contem os digitos do numero em
-- questao. nCont contem o total de digitos. Sucessivamente nCont e
-- dividido por 3 e o resto da divisao nos possibilita determinar se o
-- a casa e uma centena, dezena ou unidade, havendo portanto
-- tratamento distintos para estes tres casos
----------------------------------------------------------------------
BEGIN
  LOOP
    IF nCont = 2 THEN /* Casa dos centavos */
       CONCATENA_MOEDA;
       IF nNumTrunc <> 0 AND nCentavos <> 0 THEN
          sConjuncaoIn := ', '; /* Conjuncao Inicial p/ centavos */
       ELSE
          sConjuncaoIn := NULL;
       END IF;
--
       bCentavos := TRUE;
       TRATA_DEZENA;
       CONCATENA_CENTAVOS;
       EXIT;
    END IF;
--
    VERIFICA_GRANDEZA;
    nCasa := MOD(nCont,3);
--
    IF nCasa = 2 THEN /* Centenas */
       TRATA_CENTENA;
    ELSIF nCasa = 1 THEN /* Dezenas */
       sConjuncaoIn := NULL;
       TRATA_DEZENA;
    ELSIF nCasa = 0 THEN /* Unidades */
       TRATA_UNIDADE;
    END IF;
--
    bPrimeiro := FALSE; /* Primeiro digito */
  END LOOP;
END;
--
--
BEGIN
   bCentavos1a9 := FALSE;
   bCentavos := FALSE;
   CARREGA_VARIAVEIS;
   VERIFICA_MOEDA;
   CARREGA_DIGITOS_ARRAY;
   sNumeroExtenso := ' ';
   nCont := nInd;
   bPrimeiro := TRUE;
   VERIFICA_EXTENSO;
   pvExtenso := LTRIM(sNumeroExtenso);
--
   CONTA_STRING := NVL(LENGTH(pvExtenso),0);
   IF CONTA_STRING > 0 THEN
      -- troca a ultima virgula por "e"
      FOR v_ind IN REVERSE 1..CONTA_STRING LOOP
          IF SUBSTR(pvExtenso,v_ind,1) = ',' THEN
             pvExtenso := SUBSTR(pvExtenso,1,v_ind-1) || ' e ' || SUBSTR(pvExtenso,v_ind+1);
             EXIT;
          END IF;
      END LOOP;
   END IF;
--
   pvExtenso := REPLACE(pvExtenso, '  ', ' ');
   RETURN pvExtenso;
EXCEPTION
   WHEN OTHERS THEN
      -- Erro: valor muito grande, negativo ou exception oracle
      pvExtenso := '##########';
      RETURN pvExtenso;
END;

/
