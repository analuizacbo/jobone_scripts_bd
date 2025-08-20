--------------------------------------------------------
--  DDL for Function IDADE_CALCULAR
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE FUNCTION "IDADE_CALCULAR" -----------------------------------------------------------------------
-- IDADE_CALCULAR
--
--   Descricao: funcao que calcula o intervalo de tempo entre uma data
--   de referencia (SYSDATE) e a data de nascimento. Retorna um
--   valor numerico, em anos.
-----------------------------------------------------------------------
  (p_data_nasc in date)
RETURN  NUMBER IS

v_tot_meses number;
v_anos      number;
v_idade     number;
v_data_ref  date;

e_ERRO      exception;

BEGIN
v_anos := 0;
v_data_ref := SYSDATE;

IF v_data_ref IS NULL OR
   p_data_nasc IS NULL OR
   v_data_ref < p_data_nasc THEN
   RAISE e_ERRO;
END IF;

-- calcula intervalo de meses entre a data de referencia e a de nascimento
  v_tot_meses := nvl(months_between(v_data_ref,p_data_nasc),0);

-- transforma total de meses em anos
   v_anos := ROUND(v_tot_meses / 12,3);


  v_idade := v_anos ;
  RETURN v_idade;

EXCEPTION
  WHEN e_ERRO THEN
    v_idade := NULL;
    RETURN v_idade;
  WHEN OTHERS THEN
    v_idade := NULL;
    RETURN v_idade;
END;

/
