--------------------------------------------------------
--  DDL for Package Body IMPOSTO_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "IMPOSTO_PKG" IS
 --
 --
 FUNCTION valor_bruto_acum_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia       ProcessMind     DATA: 27/07/2006
  -- DESCRICAO: Retorna o valor bruto acumulado de um determinado fornecedor, num
  --   determinado mes de referencia. Nao contabiliza no acumulado o valor da propria nota.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            26/02/2008  O calculo de itens de A voltaram a ser calculados contra
  --                               a BFerraz (exceto pagos diretamente pelo cliente).
  -- Silvia            23/05/2008  Novo tipo "NF Locacao" (nao acumula imposto).
  -- Silvia            20/01/2009  Novo tipo "Negoc Bilheteria" NBI (nao acumula imposto).
  -- Silvia            18/01/2011  Novo atributo flag_pago_cliente na NF.
  -- Silvia            14/09/2011  Acumulo por raiz do CNPJ.
  -- Silvia            17/11/2011  Novos tipos de nota: NFF e RD.
  -- Silvia            08/08/2012  O acumulo de CCP passou a ser calculado contra o cliente
  --                               da NF para qualquer modalidade de contratação.
  -- Silvia            12/06/2013  Retirada de parametros flag_pago_cliente (recuperado via
  --                               select) e tipo_data_refer (usa sempre a data de vencimento)
  ------------------------------------------------------------------------------------------
  p_nota_fiscal_id IN nota_fiscal.nota_fiscal_id%TYPE
 )
 --
  RETURN NUMBER AS
  v_ret                NUMBER;
  v_data_ini           DATE;
  v_data_fim           DATE;
  v_data_refer         DATE;
  v_exception          EXCEPTION;
  v_tipo_ent_sai       nota_fiscal.tipo_ent_sai%TYPE;
  v_emp_emissora_id    nota_fiscal.emp_emissora_id%TYPE;
  v_emp_faturar_por_id nota_fiscal.emp_faturar_por_id%TYPE;
  v_cliente_id         nota_fiscal.cliente_id%TYPE;
  v_data_emissao       nota_fiscal.data_emissao%TYPE;
  v_data_pri_vencim    nota_fiscal.data_pri_vencim%TYPE;
  v_flag_pago_cliente  nota_fiscal.flag_pago_cliente%TYPE;
  v_flag_emp_scp       pessoa.flag_emp_scp%TYPE;
  v_empresa_id         pessoa.empresa_id%TYPE;
  v_modo_acumulo       VARCHAR2(60);
  --
 BEGIN
  v_ret := 0;
  --
  ------------------------------------------------------------
  -- calculo p/ notas fiscais de entrada
  ------------------------------------------------------------
  v_tipo_ent_sai := 'E';
  --
  SELECT nf.emp_faturar_por_id,
         nf.cliente_id,
         nf.emp_emissora_id,
         nf.data_emissao,
         nf.data_pri_vencim,
         nf.flag_pago_cliente,
         pf.flag_emp_scp,
         pf.empresa_id
    INTO v_emp_faturar_por_id,
         v_cliente_id,
         v_emp_emissora_id,
         v_data_emissao,
         v_data_pri_vencim,
         v_flag_pago_cliente,
         v_flag_emp_scp,
         v_empresa_id
    FROM nota_fiscal nf,
         pessoa      pf
   WHERE nf.nota_fiscal_id = p_nota_fiscal_id
     AND nf.emp_faturar_por_id = pf.pessoa_id;
  --
  -- calculos feitos com a data do 1ro vencim como referencia
  v_data_refer := v_data_pri_vencim;
  --
  v_data_ini := data_converter('01/' || to_char(v_data_refer, 'mm/yyyy'));
  v_data_fim := last_day(v_data_ini);
  --
  v_modo_acumulo := TRIM(empresa_pkg.parametro_retornar(v_empresa_id, 'MODO_ACUMULO_PCC'));
  --
  IF v_modo_acumulo NOT IN ('EMISSORA_X_CLIENTE', 'EMISSORA_X_EMPFATUR') OR
     TRIM(v_modo_acumulo) IS NULL THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- nao eh pago pelo cliente
  ------------------------------------------------------------
  IF v_flag_pago_cliente = 'N' AND v_modo_acumulo = 'EMISSORA_X_CLIENTE' THEN
   -- acumula por CNPJ raiz do cliente
   SELECT nvl(SUM(valor_bruto), 0)
     INTO v_ret
     FROM nota_fiscal nf,
          tipo_doc_nf td
    WHERE nf.emp_emissora_id = v_emp_emissora_id
      AND pessoa_pkg.cnpj_raiz_retornar(nf.cliente_id, v_empresa_id) =
          pessoa_pkg.cnpj_raiz_retornar(v_cliente_id, v_empresa_id)
      AND nf.tipo_ent_sai = v_tipo_ent_sai
      AND nf.status <> 'CANC'
      AND nf.data_pri_vencim BETWEEN v_data_ini AND v_data_fim
      AND nf.flag_pago_cliente = v_flag_pago_cliente
      AND nf.nota_fiscal_id <> nvl(p_nota_fiscal_id, 0)
      AND nf.tipo_doc_nf_id = td.tipo_doc_nf_id
      AND td.flag_ret_imposto = 'S';
  END IF;
  --
  IF v_flag_pago_cliente = 'N' AND v_modo_acumulo = 'EMISSORA_X_EMPFATUR' THEN
   IF v_flag_emp_scp = 'N' THEN
    -- nao eh sociedade por conta de participacao. Acumula por CNPJ raiz.
    SELECT nvl(SUM(valor_bruto), 0)
      INTO v_ret
      FROM nota_fiscal nf,
           tipo_doc_nf td,
           pessoa      pf
     WHERE nf.emp_emissora_id = v_emp_emissora_id
       AND pessoa_pkg.cnpj_raiz_retornar(nf.emp_faturar_por_id, v_empresa_id) =
           pessoa_pkg.cnpj_raiz_retornar(v_emp_faturar_por_id, v_empresa_id)
       AND nf.tipo_ent_sai = v_tipo_ent_sai
       AND nf.status <> 'CANC'
       AND nf.data_pri_vencim BETWEEN v_data_ini AND v_data_fim
       AND nf.flag_pago_cliente = v_flag_pago_cliente
       AND nf.nota_fiscal_id <> nvl(p_nota_fiscal_id, 0)
       AND nf.tipo_doc_nf_id = td.tipo_doc_nf_id
       AND td.flag_ret_imposto = 'S'
       AND nf.emp_faturar_por_id = pf.pessoa_id
       AND pf.flag_emp_scp = 'N';
   ELSE
    -- eh sociedade por conta de participacao. Acumula individualmente.
    SELECT nvl(SUM(valor_bruto), 0)
      INTO v_ret
      FROM nota_fiscal nf,
           tipo_doc_nf td
     WHERE nf.emp_emissora_id = v_emp_emissora_id
       AND nf.emp_faturar_por_id = v_emp_faturar_por_id
       AND nf.tipo_ent_sai = v_tipo_ent_sai
       AND nf.status <> 'CANC'
       AND nf.data_pri_vencim BETWEEN v_data_ini AND v_data_fim
       AND nf.flag_pago_cliente = v_flag_pago_cliente
       AND nf.nota_fiscal_id <> nvl(p_nota_fiscal_id, 0)
       AND nf.tipo_doc_nf_id = td.tipo_doc_nf_id
       AND td.flag_ret_imposto = 'S';
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- eh pago pelo cliente
  ------------------------------------------------------------
  IF v_flag_pago_cliente = 'S' THEN
   -- pago pelo cliente (o calcumo eh feito mas nao eh utilizado)
   SELECT nvl(SUM(valor_bruto), 0)
     INTO v_ret
     FROM nota_fiscal nf,
          tipo_doc_nf td
    WHERE nf.emp_emissora_id = v_emp_emissora_id
      AND pessoa_pkg.cnpj_raiz_retornar(nf.cliente_id, v_empresa_id) =
          pessoa_pkg.cnpj_raiz_retornar(v_cliente_id, v_empresa_id)
      AND nf.tipo_ent_sai = v_tipo_ent_sai
      AND nf.status <> 'CANC'
      AND nf.data_pri_vencim BETWEEN v_data_ini AND v_data_fim
      AND nf.flag_pago_cliente = v_flag_pago_cliente
      AND nf.nota_fiscal_id <> nvl(p_nota_fiscal_id, 0)
      AND nf.tipo_doc_nf_id = td.tipo_doc_nf_id
      AND td.flag_ret_imposto = 'S';
  END IF;
  --
  RETURN v_ret;
 EXCEPTION
  WHEN v_exception THEN
   v_ret := 99999999;
   RETURN v_ret;
  WHEN OTHERS THEN
   v_ret := 99999999;
   RETURN v_ret;
 END valor_bruto_acum_retornar;
 --
 --
 FUNCTION imposto_retido_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia       ProcessMind     DATA: 27/07/2006
  -- DESCRICAO: Retorna o imposto retido de um determinado fornecedor, num determinado
  --   mes de referencia. Nao contabiliza no acumulado a propria nota.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            26/02/2008  O calculo de itens de A voltaram a ser calculados contra
  --                               a BFerraz (exceto pagos diretamente pelo cliente).
  -- Silvia            23/05/2008  Novo tipo "NF Locacao" (nao acumula imposto).
  -- Silvia            20/01/2009  Novo tipo "Negoc Bilheteria" NBI (nao acumula imposto).
  -- Silvia            18/01/2011  Novo atributo flag_pago_cliente na NF.
  -- Silvia            14/09/2011  Acumulo por raiz do CNPJ.
  -- Silvia            17/11/2011  Novos tipos de nota: NFF e RD.
  -- Silvia            08/08/2012  O acumulo de CCP passou a ser calculado contra o cliente
  --                               da NF para qualquer modalidade de contratação.
  -- Silvia            12/06/2013  Retirada de parametros flag_pago_cliente (recuperado via
  --                               select) e tipo_data_refer (usa sempre a data de vencimento)
  ------------------------------------------------------------------------------------------
  p_fi_tipo_imposto_id IN fi_tipo_imposto.fi_tipo_imposto_id%TYPE,
  p_nota_fiscal_id     IN nota_fiscal.nota_fiscal_id%TYPE
 )
 --
  RETURN NUMBER AS
  v_ret                NUMBER;
  v_data_ini           DATE;
  v_data_fim           DATE;
  v_data_refer         DATE;
  v_exception          EXCEPTION;
  v_emp_emissora_id    nota_fiscal.emp_emissora_id%TYPE;
  v_emp_faturar_por_id nota_fiscal.emp_faturar_por_id%TYPE;
  v_cliente_id         nota_fiscal.cliente_id%TYPE;
  v_data_emissao       nota_fiscal.data_emissao%TYPE;
  v_data_pri_vencim    nota_fiscal.data_pri_vencim%TYPE;
  v_flag_pago_cliente  nota_fiscal.flag_pago_cliente%TYPE;
  v_flag_emp_scp       pessoa.flag_emp_scp%TYPE;
  v_empresa_id         pessoa.empresa_id%TYPE;
  v_modo_acumulo       VARCHAR2(60);
  --
 BEGIN
  v_ret := 0;
  --
  SELECT nf.emp_faturar_por_id,
         nf.cliente_id,
         nf.emp_emissora_id,
         nf.data_emissao,
         nf.data_pri_vencim,
         nf.flag_pago_cliente,
         pf.flag_emp_scp,
         pf.empresa_id
    INTO v_emp_faturar_por_id,
         v_cliente_id,
         v_emp_emissora_id,
         v_data_emissao,
         v_data_pri_vencim,
         v_flag_pago_cliente,
         v_flag_emp_scp,
         v_empresa_id
    FROM nota_fiscal nf,
         pessoa      pf
   WHERE nf.nota_fiscal_id = p_nota_fiscal_id
     AND nf.emp_faturar_por_id = pf.pessoa_id;
  --
  -- calculos feitos com a data do 1ro vencim como referencia
  v_data_refer := v_data_pri_vencim;
  --
  v_data_ini := data_converter('01/' || to_char(v_data_refer, 'mm/yyyy'));
  v_data_fim := last_day(v_data_ini);
  --
  v_modo_acumulo := empresa_pkg.parametro_retornar(v_empresa_id, 'MODO_ACUMULO_PCC');
  --
  IF v_modo_acumulo NOT IN ('EMISSORA_X_CLIENTE', 'EMISSORA_X_EMPFATUR') OR
     TRIM(v_modo_acumulo) IS NULL THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- nao eh pago pelo cliente
  ------------------------------------------------------------
  IF v_flag_pago_cliente = 'N' AND v_modo_acumulo = 'EMISSORA_X_CLIENTE' THEN
   -- acumula por CNPJ raiz do cliente
   SELECT nvl(SUM(im.valor_imposto), 0)
     INTO v_ret
     FROM nota_fiscal  nf,
          imposto_nota im,
          tipo_doc_nf  td
    WHERE nf.emp_emissora_id = v_emp_emissora_id
      AND pessoa_pkg.cnpj_raiz_retornar(nf.cliente_id, v_empresa_id) =
          pessoa_pkg.cnpj_raiz_retornar(v_cliente_id, v_empresa_id)
      AND nf.tipo_ent_sai = 'E'
      AND nf.status <> 'CANC'
      AND nf.data_pri_vencim BETWEEN v_data_ini AND v_data_fim
      AND nf.flag_pago_cliente = v_flag_pago_cliente
      AND nf.nota_fiscal_id = im.nota_fiscal_id
      AND im.fi_tipo_imposto_id = p_fi_tipo_imposto_id
      AND nf.nota_fiscal_id <> nvl(p_nota_fiscal_id, 0)
      AND nf.tipo_doc_nf_id = td.tipo_doc_nf_id
      AND td.flag_ret_imposto = 'S';
  END IF;
  --
  IF v_flag_pago_cliente = 'N' AND v_modo_acumulo = 'EMISSORA_X_EMPFATUR' THEN
   IF v_flag_emp_scp = 'N' THEN
    -- nao eh sociedade por conta de participacao. Acumula por CNPJ raiz.
    SELECT nvl(SUM(im.valor_imposto), 0)
      INTO v_ret
      FROM nota_fiscal  nf,
           imposto_nota im,
           tipo_doc_nf  td,
           pessoa       pf
     WHERE nf.emp_emissora_id = v_emp_emissora_id
       AND pessoa_pkg.cnpj_raiz_retornar(nf.emp_faturar_por_id, v_empresa_id) =
           pessoa_pkg.cnpj_raiz_retornar(v_emp_faturar_por_id, v_empresa_id)
       AND nf.tipo_ent_sai = 'E'
       AND nf.status <> 'CANC'
       AND nf.data_pri_vencim BETWEEN v_data_ini AND v_data_fim
       AND nf.flag_pago_cliente = v_flag_pago_cliente
       AND nf.nota_fiscal_id = im.nota_fiscal_id
       AND im.fi_tipo_imposto_id = p_fi_tipo_imposto_id
       AND nf.nota_fiscal_id <> nvl(p_nota_fiscal_id, 0)
       AND nf.tipo_doc_nf_id = td.tipo_doc_nf_id
       AND td.flag_ret_imposto = 'S'
       AND nf.emp_faturar_por_id = pf.pessoa_id
       AND pf.flag_emp_scp = 'N';
   ELSE
    -- eh sociedade por conta de participacao. Acumula individualmente.
    SELECT nvl(SUM(im.valor_imposto), 0)
      INTO v_ret
      FROM nota_fiscal  nf,
           imposto_nota im,
           tipo_doc_nf  td
     WHERE nf.emp_emissora_id = v_emp_emissora_id
       AND nf.emp_faturar_por_id = v_emp_faturar_por_id
       AND nf.tipo_ent_sai = 'E'
       AND nf.status <> 'CANC'
       AND nf.data_pri_vencim BETWEEN v_data_ini AND v_data_fim
       AND nf.flag_pago_cliente = v_flag_pago_cliente
       AND nf.nota_fiscal_id = im.nota_fiscal_id
       AND im.fi_tipo_imposto_id = p_fi_tipo_imposto_id
       AND nf.nota_fiscal_id <> nvl(p_nota_fiscal_id, 0)
       AND nf.tipo_doc_nf_id = td.tipo_doc_nf_id
       AND td.flag_ret_imposto = 'S';
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- eh pago pelo cliente
  ------------------------------------------------------------
  IF v_flag_pago_cliente = 'S' THEN
   -- pago pelo cliente (o calculo eh feito mas nao eh utilizado)
   SELECT nvl(SUM(im.valor_imposto), 0)
     INTO v_ret
     FROM nota_fiscal  nf,
          imposto_nota im,
          tipo_doc_nf  td
    WHERE nf.emp_emissora_id = v_emp_emissora_id
      AND pessoa_pkg.cnpj_raiz_retornar(nf.cliente_id, v_empresa_id) =
          pessoa_pkg.cnpj_raiz_retornar(v_cliente_id, v_empresa_id)
      AND nf.tipo_ent_sai = 'E'
      AND nf.status <> 'CANC'
      AND nf.data_pri_vencim BETWEEN v_data_ini AND v_data_fim
      AND nf.flag_pago_cliente = v_flag_pago_cliente
      AND nf.nota_fiscal_id = im.nota_fiscal_id
      AND im.fi_tipo_imposto_id = p_fi_tipo_imposto_id
      AND nf.nota_fiscal_id <> nvl(p_nota_fiscal_id, 0)
      AND nf.tipo_doc_nf_id = td.tipo_doc_nf_id
      AND td.flag_ret_imposto = 'S';
  END IF;
  --
  RETURN v_ret;
 EXCEPTION
  WHEN v_exception THEN
   v_ret := 99999999;
   RETURN v_ret;
  WHEN OTHERS THEN
   v_ret := 99999999;
   RETURN v_ret;
 END imposto_retido_retornar;
 --
--
END; --  IMPOSTO_PKG

/
