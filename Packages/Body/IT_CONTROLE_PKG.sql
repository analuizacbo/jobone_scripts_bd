--------------------------------------------------------
--  DDL for Package Body IT_CONTROLE_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "IT_CONTROLE_PKG" IS
 --
 --
 PROCEDURE integrar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 09/06/2011
  -- DESCRICAO: procedure de controle da integracao do JobOne com outros sistemas.
  --  Para o ponto de integracao passado pelo parametro, faz um loop para executar a
  --  integracao com todos os sistemas externos definidos para esse ponto.
  --
  --  Exemplo de chamadas para o sistema externo ADNNET, ponto JOB_ADICIONAR:
  --    IT_CONTROLE_PKG ->
  --    IT_ADNNET_PKG.job_integrar -> IT_ADNNET.adnnet_executar -> WEBSERVICE_PKG.chamar
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            25/07/2017  Porto Seguro (comunicacao visual).
  -- Silvia            20/02/2020  ADN Bullet (estimativa)
  -- Silvia            10/12/2020  Integracao Protheus
  -- Silvia            26/10/2022  Uso do flag_ativo do sistema externo no cursor
  -- Silvia            27/06/2023  Integracao de contrato/adnnet
  -- Silvia            30/06/2023  Integracao de faturamento/adnnet
  -- Joel Dias         20/09/2023  Inclusão do JOBONE_SELF e integrações de Oportunidade
  -- Ana Luiza         27/02/2025  Inclusao de flag_commit em JOBONE_SELF
  ------------------------------------------------------------------------------------------
 (
  p_ponto_integracao IN ponto_integracao.codigo%TYPE,
  p_empresa_id       IN empresa.empresa_id%TYPE,
  p_objeto_id        IN NUMBER,
  p_parametros       IN VARCHAR2,
  p_erro_cod         OUT VARCHAR2,
  p_erro_msg         OUT VARCHAR2
 ) IS
  v_qt                  INTEGER;
  v_exception           EXCEPTION;
  v_cod_acao            VARCHAR2(10);
  v_objeto              VARCHAR2(2000);
  v_objeto_ant          VARCHAR2(2000);
  v_cod_ext_objeto_ant  VARCHAR2(100);
  v_delimitador         CHAR(1);
  v_parametros          VARCHAR2(2000);
  v_recup_param         INTEGER;
  v_ponto_integracao_id ponto_integracao.ponto_integracao_id%TYPE;
  v_empresa_id          empresa.empresa_id%TYPE;
  v_pessoa_id           pessoa.pessoa_id%TYPE;
  v_cod_ext_pessoa      pessoa_sist_ext.cod_ext_pessoa%TYPE;
  v_nome_pessoa_ant     pessoa.nome%TYPE;
  v_nome_pessoa_atu     pessoa.nome%TYPE;
  v_job_id              job.job_id%TYPE;
  v_cod_ext_job         job.cod_ext_job%TYPE;
  v_status_job          job.status%TYPE;
  v_nota_fiscal_id      nota_fiscal.nota_fiscal_id%TYPE;
  v_cod_ext_nf          nota_fiscal.cod_ext_nf%TYPE;
  v_faturamento_id      faturamento.faturamento_id%TYPE;
  v_cod_ext_fatur       faturamento.cod_ext_fatur%TYPE;
  v_produto_cliente_id  produto_cliente.produto_cliente_id%TYPE;
  v_cod_ext_produto     VARCHAR2(100);
  v_ordem_servico_id    ordem_servico.ordem_servico_id%TYPE;
  v_status_os           ordem_servico.status%TYPE;
  v_cod_ext_os          ordem_servico.cod_ext_os%TYPE;
  v_status_integracao   tipo_os.status_integracao%TYPE;
  v_carta_acordo_id     carta_acordo.carta_acordo_id%TYPE;
  v_cod_ext_carta       carta_acordo.cod_ext_carta%TYPE;
  v_tipo_produto_id     tipo_produto.tipo_produto_id%TYPE;
  v_forca_integracao    VARCHAR2(10);
  v_flag_pago_cliente   item.flag_pago_cliente%TYPE;
  v_erro_msg            VARCHAR2(1000);
  v_orcamento_id        orcamento.orcamento_id%TYPE;
  v_cod_ext_orcam       orcamento.cod_ext_orcam%TYPE;
  v_status_orcam        orcamento.status%TYPE;
  v_flag_despesa        orcamento.flag_despesa%TYPE;
  v_valor_aprovado      item.valor_aprovado%TYPE;
  v_cod_tipo_job        tipo_job.codigo%TYPE;
  v_comentario_id       comentario.comentario_id%TYPE;
  v_coment_obj_id       comentario.objeto_id%TYPE;
  v_cod_tipo_obj        tipo_objeto.codigo%TYPE;
  v_contrato_servico_id contrato_servico.contrato_servico_id%TYPE;
  v_cod_ext_ctrser      contrato_servico.cod_ext_ctrser%TYPE;
  v_status_parcel       contrato.status_parcel%TYPE;
  v_contrato_id         contrato.contrato_id%TYPE;
  v_cod_ext_contrato    contrato.cod_ext_contrato%TYPE;
  v_oportunidade_id     oportunidade.oportunidade_id%TYPE;
  v_tipo_cli            NUMBER(5);
  v_tipo_for            NUMBER(5);
  v_tipo_est            NUMBER(5);
  v_dados_ok            NUMBER(5);
  v_tipo_fat            VARCHAR2(20);
  v_flag_commit         VARCHAR2(10);
  --
  CURSOR c_sis IS
   SELECT DISTINCT se.sistema_externo_id,
                   ti.codigo AS tipo_integr
     FROM sist_ext_ponto_int sp,
          sistema_externo    se,
          tipo_integracao    ti
    WHERE sp.ponto_integracao_id = v_ponto_integracao_id
      AND sp.empresa_id = p_empresa_id
      AND sp.sistema_externo_id = se.sistema_externo_id
      AND se.tipo_integracao_id = ti.tipo_integracao_id
      AND se.flag_ativo = 'S';
  --
 BEGIN
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  --
  SELECT MAX(ponto_integracao_id)
    INTO v_ponto_integracao_id
    FROM ponto_integracao
   WHERE codigo = p_ponto_integracao;
  --
  IF v_ponto_integracao_id IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse ponto de integração não existe (' || p_ponto_integracao || ').';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- chama a procedure de integracao
  ------------------------------------------------------------
  v_delimitador := ',';
  v_parametros  := p_parametros;
  v_recup_param := 0;
  --
  FOR r_sis IN c_sis
  LOOP
   v_erro_msg := NULL;
   --
   IF p_ponto_integracao LIKE 'PESSOA_%'
   THEN
    v_pessoa_id := p_objeto_id;
   ELSIF p_ponto_integracao LIKE 'PRODUTO_CLIENTE_%'
   THEN
    v_produto_cliente_id := p_objeto_id;
   ELSIF p_ponto_integracao LIKE 'JOB_%'
   THEN
    v_job_id := p_objeto_id;
   ELSIF p_ponto_integracao LIKE 'NOTA_FISCAL_%'
   THEN
    v_nota_fiscal_id := p_objeto_id;
   ELSIF p_ponto_integracao LIKE 'FATURAMENTO_%'
   THEN
    v_faturamento_id := p_objeto_id;
   ELSIF p_ponto_integracao LIKE 'ORDEM_SERVICO_%'
   THEN
    v_ordem_servico_id := p_objeto_id;
   ELSIF p_ponto_integracao LIKE 'CARTA_ACORDO_%'
   THEN
    v_carta_acordo_id := p_objeto_id;
   ELSIF p_ponto_integracao LIKE 'TIPO_PRODUTO_%'
   THEN
    v_tipo_produto_id := p_objeto_id;
   ELSIF p_ponto_integracao LIKE 'ORCAMENTO_%'
   THEN
    v_orcamento_id := p_objeto_id;
   ELSIF p_ponto_integracao LIKE 'COMENTARIO_%'
   THEN
    v_comentario_id := p_objeto_id;
   ELSIF p_ponto_integracao LIKE 'CONTRATO_SERVICO_%'
   THEN
    v_contrato_servico_id := p_objeto_id;
   ELSIF p_ponto_integracao LIKE 'CONTRATO_%'
   THEN
    v_contrato_id := p_objeto_id;
   ELSIF p_ponto_integracao LIKE 'OPORTUNIDADE_%'
   THEN
    v_oportunidade_id := p_objeto_id;
   END IF;
   --
   ------------------------------------------------------------
   --  ****************** JOBONE_SELF **************************
   ------------------------------------------------------------
   --
   IF r_sis.tipo_integr = 'JOBONE_SELF'
   THEN
    ---------------------------------------------------------
    -- pontos de integracao de OPORTUNIDADE
    ---------------------------------------------------------
    IF p_ponto_integracao = 'OPORTUNIDADE_JOB_ADICIONAR'
    THEN
     v_flag_commit := prox_valor_retornar(v_parametros, v_delimitador);
     SELECT COUNT(*)
       INTO v_qt
       FROM oportunidade
      WHERE oportunidade_id = v_oportunidade_id;
     IF v_qt > 0
     THEN
      --ALCBO_270225 
      it_jobone_self_pkg.oportunidade_job_adicionar(v_oportunidade_id,
                                                    v_flag_commit,
                                                    p_erro_cod,
                                                    p_erro_msg);
      IF p_erro_cod <> '00000'
      THEN
       RAISE v_exception;
      END IF;
     ELSE
      p_erro_cod := '90000';
      p_erro_msg := 'Esta Oportunidade não existe.';
      RAISE v_exception;
     END IF;
    END IF; --ponto_integracao OPORTUNIDADE_JOB_ADICIONAR
    IF p_ponto_integracao = 'OPORTUNIDADE_JOB_STATUS_ATUALIZAR'
    THEN
     SELECT COUNT(*)
       INTO v_qt
       FROM oportunidade
      WHERE oportunidade_id = v_oportunidade_id;
     IF v_qt > 0
     THEN
      it_jobone_self_pkg.oportunidade_job_status_atu(v_oportunidade_id, p_erro_cod, p_erro_msg);
      IF p_erro_cod <> '00000'
      THEN
       RAISE v_exception;
      END IF;
     ELSE
      p_erro_cod := '90000';
      p_erro_msg := 'Esta Oportunidade não existe.';
      RAISE v_exception;
     END IF;
    END IF; --ponto_integracao OPORTUNIDADE_JOB_STATUS_ATUALIZAR
   END IF; --tipo_integracao JOBONE_SELF
   --
   ------------------------------------------------------------
   --  ******************* ADNNET **************************
   ------------------------------------------------------------
   IF r_sis.tipo_integr = 'ADNNET'
   THEN
    --
    ---------------------------------------------------------
    -- pontos de integracao de PESSOA
    ---------------------------------------------------------
    IF p_ponto_integracao = 'PESSOA_ATUALIZAR_OPCIONAL'
    THEN
     -- atualiza dados no sistema externo se ja integrado, ou inclui caso ainda
     -- nao esteja integrado, desde que o cadastro no JobOne esteja completo.
     --
     SELECT apelido
       INTO v_objeto
       FROM pessoa
      WHERE pessoa_id = v_pessoa_id;
     --
     SELECT MAX(rtrim(cod_ext_pessoa))
       INTO v_cod_ext_pessoa
       FROM pessoa_sist_ext
      WHERE sistema_externo_id = r_sis.sistema_externo_id
        AND pessoa_id = v_pessoa_id;
     --
     IF v_cod_ext_pessoa IS NOT NULL
     THEN
      -- cliente/fornecedor ja integrado. Pode mandar p/ o ADN Net.
      it_adnnet_pkg.pessoa_integrar(r_sis.sistema_externo_id,
                                    p_empresa_id,
                                    v_pessoa_id,
                                    'A',
                                    p_erro_cod,
                                    p_erro_msg);
      --
      IF p_erro_cod <> '00000'
      THEN
       RAISE v_exception;
      END IF;
     ELSIF pessoa_pkg.dados_integr_verificar(v_pessoa_id) = 1
     THEN
      -- cliente/fornecedor com dados completos. Tanta mandar p/ o ADN Net como inclusao.
      it_adnnet_pkg.pessoa_integrar(r_sis.sistema_externo_id,
                                    p_empresa_id,
                                    v_pessoa_id,
                                    'I',
                                    p_erro_cod,
                                    p_erro_msg);
      --
      IF p_erro_cod <> '00000'
      THEN
       -- deu erro. Tenta mandar como alteracao.
       -- salva a mensagem retornada.
       v_erro_msg := p_erro_msg;
       --
       it_adnnet_pkg.pessoa_integrar(r_sis.sistema_externo_id,
                                     p_empresa_id,
                                     v_pessoa_id,
                                     'A',
                                     p_erro_cod,
                                     p_erro_msg);
       --
       IF p_erro_cod <> '00000'
       THEN
        p_erro_msg := v_erro_msg || ' ; ' || p_erro_msg;
        RAISE v_exception;
       END IF;
      END IF;
     END IF;
    END IF; -- fim de PESSOA_ATUALIZAR_OPCIONAL
    --
    --
    IF p_ponto_integracao = 'PESSOA_ATUALIZAR'
    THEN
     -- atualiza dados no sistema externo se ja integrado, ou inclui caso ainda
     -- nao esteja integrado.
     --
     SELECT apelido
       INTO v_objeto
       FROM pessoa
      WHERE pessoa_id = v_pessoa_id;
     --
     SELECT MAX(rtrim(cod_ext_pessoa))
       INTO v_cod_ext_pessoa
       FROM pessoa_sist_ext
      WHERE sistema_externo_id = r_sis.sistema_externo_id
        AND pessoa_id = v_pessoa_id;
     --
     IF pessoa_pkg.dados_integr_verificar(v_pessoa_id) = 0
     THEN
      p_erro_cod := '90000';
      p_erro_msg := 'Os dados da empresa estão incompletos ou inconsistentes ' ||
                    'para integração com o ADN Net (' || v_objeto || ').';
      RAISE v_exception;
     END IF;
     --
     IF v_cod_ext_pessoa IS NOT NULL
     THEN
      -- cliente/fornecedor ja integrado. Pode mandar p/ o ADN Net.
      it_adnnet_pkg.pessoa_integrar(r_sis.sistema_externo_id,
                                    p_empresa_id,
                                    v_pessoa_id,
                                    'A',
                                    p_erro_cod,
                                    p_erro_msg);
      --
      IF p_erro_cod <> '00000'
      THEN
       RAISE v_exception;
      END IF;
     ELSE
      -- cliente/fornecedor com dados completos. Tanta mandar p/ o ADN Net como inclusao.
      it_adnnet_pkg.pessoa_integrar(r_sis.sistema_externo_id,
                                    p_empresa_id,
                                    v_pessoa_id,
                                    'I',
                                    p_erro_cod,
                                    p_erro_msg);
      --
      IF p_erro_cod <> '00000'
      THEN
       -- deu erro. Tenta mandar como alteracao.
       -- salva a mensagem retornada.
       v_erro_msg := p_erro_msg;
       --
       it_adnnet_pkg.pessoa_integrar(r_sis.sistema_externo_id,
                                     p_empresa_id,
                                     v_pessoa_id,
                                     'A',
                                     p_erro_cod,
                                     p_erro_msg);
       --
       IF p_erro_cod <> '00000'
       THEN
        p_erro_msg := v_erro_msg || ' ; ' || p_erro_msg;
        RAISE v_exception;
       END IF;
      END IF;
     END IF;
    END IF; -- fim de PESSOA_ATUALIZAR
    --
    --
    IF p_ponto_integracao = 'PESSOA_EXCLUIR'
    THEN
     -- exclui dados do sistema externo se ja estiver integrado.
     --
     SELECT apelido
       INTO v_objeto
       FROM pessoa
      WHERE pessoa_id = v_pessoa_id;
     --
     SELECT MAX(rtrim(cod_ext_pessoa))
       INTO v_cod_ext_pessoa
       FROM pessoa_sist_ext
      WHERE sistema_externo_id = r_sis.sistema_externo_id
        AND pessoa_id = v_pessoa_id;
     --
     IF v_cod_ext_pessoa IS NOT NULL
     THEN
      -- pessoa ja integrada. Precisa excluir no sistema externo.
      it_adnnet_pkg.pessoa_integrar(r_sis.sistema_externo_id,
                                    p_empresa_id,
                                    v_pessoa_id,
                                    'E',
                                    p_erro_cod,
                                    p_erro_msg);
      --
      IF p_erro_cod <> '00000'
      THEN
       RAISE v_exception;
      END IF;
     END IF;
    END IF; -- fim de PESSOA_EXCLUIR
    --
    ---------------------------------------------------------
    -- pontos de integracao de JOB
    ---------------------------------------------------------
    IF p_ponto_integracao = 'JOB_ADICIONAR'
    THEN
     -- envia dados para o sistema externo
     --
     SELECT numero
       INTO v_objeto
       FROM job
      WHERE job_id = v_job_id;
     --
     it_adnnet_pkg.job_integrar(r_sis.sistema_externo_id,
                                p_empresa_id,
                                v_job_id,
                                'I',
                                p_erro_cod,
                                p_erro_msg);
     --
     IF p_erro_cod <> '00000'
     THEN
      RAISE v_exception;
     END IF;
    END IF; -- fim de JOB_ADICIONAR
    --
    --
    IF p_ponto_integracao IN ('JOB_ATUALIZAR', 'JOB_APROV_ORCAM_ENVIAR')
    THEN
     -- atualiza dados no sistema externo se ja integrado, ou inclui caso ainda
     -- nao esteja integrado.
     --
     SELECT numero,
            rtrim(cod_ext_job)
       INTO v_objeto,
            v_cod_ext_job
       FROM job
      WHERE job_id = v_job_id;
     --
     IF v_cod_ext_job IS NOT NULL
     THEN
      it_adnnet_pkg.job_integrar(r_sis.sistema_externo_id,
                                 p_empresa_id,
                                 v_job_id,
                                 'A',
                                 p_erro_cod,
                                 p_erro_msg);
      --
      IF p_erro_cod <> '00000'
      THEN
       RAISE v_exception;
      END IF;
     ELSE
      it_adnnet_pkg.job_integrar(r_sis.sistema_externo_id,
                                 p_empresa_id,
                                 v_job_id,
                                 'I',
                                 p_erro_cod,
                                 p_erro_msg);
      --
      IF p_erro_cod <> '00000'
      THEN
       RAISE v_exception;
      END IF;
     END IF;
    END IF; -- fim de JOB_ATUALIZAR
    --
    --
    IF p_ponto_integracao = 'JOB_EXCLUIR'
    THEN
     -- exclui dados do sistema externo se ja estiver integrado.
     --
     SELECT numero,
            rtrim(cod_ext_job)
       INTO v_objeto,
            v_cod_ext_job
       FROM job
      WHERE job_id = v_job_id;
     --
     IF v_cod_ext_job IS NOT NULL
     THEN
      -- job ja integrado. Precisa excluir no sistema externo.
      it_adnnet_pkg.job_integrar(r_sis.sistema_externo_id,
                                 p_empresa_id,
                                 v_job_id,
                                 'E',
                                 p_erro_cod,
                                 p_erro_msg);
      --
      IF p_erro_cod <> '00000'
      THEN
       RAISE v_exception;
      END IF;
     END IF;
    END IF; -- fim de JOB_EXCLUIR
    --
    ---------------------------------------------------------
    -- pontos de integracao de ORCAMENTO (integra como job/projeto)
    ---------------------------------------------------------
    IF p_ponto_integracao IN ('ORCAMENTO_ADICIONAR', 'ORCAMENTO_ATUALIZAR', 'ORCAMENTO_EXCLUIR')
    THEN
     --
     SELECT decode(p_ponto_integracao,
                   'ORCAMENTO_ADICIONAR',
                   'I',
                   'ORCAMENTO_ATUALIZAR',
                   'A',
                   'ORCAMENTO_EXCLUIR',
                   'E')
       INTO v_cod_acao
       FROM dual;
     --
     SELECT cod_ext_orcam
       INTO v_cod_ext_orcam
       FROM orcamento
      WHERE orcamento_id = v_orcamento_id;
     --
     IF v_cod_ext_orcam IS NULL AND v_cod_acao IN ('E')
     THEN
      -- exclusao de orcamento nao integrado. Pula o processamento.
      NULL;
     ELSE
      IF v_cod_ext_orcam IS NULL AND v_cod_acao = 'A'
      THEN
       -- alteracao de orcamento nao integrado. Envia como inclusao.
       v_cod_acao := 'I';
      END IF;
      --
      it_adnnet_pkg.orcamento_integrar(r_sis.sistema_externo_id,
                                       p_empresa_id,
                                       v_orcamento_id,
                                       v_cod_acao,
                                       p_erro_cod,
                                       p_erro_msg);
      --
      IF p_erro_cod <> '00000'
      THEN
       RAISE v_exception;
      END IF;
     END IF;
    END IF; -- fim de ORCAMENTO
    --
    ---------------------------------------------------------
    -- pontos de integracao de CONTRATO
    ---------------------------------------------------------
    IF p_ponto_integracao = 'CONTRATO_ADICIONAR'
    THEN
     -- envia dados para o sistema externo
     --
     SELECT numero,
            rtrim(cod_ext_contrato)
       INTO v_objeto,
            v_cod_ext_contrato
       FROM contrato
      WHERE contrato_id = v_contrato_id;
     --
     IF v_cod_ext_contrato IS NOT NULL
     THEN
      it_adnnet_pkg.contrato_integrar(r_sis.sistema_externo_id,
                                      p_empresa_id,
                                      v_contrato_id,
                                      'A',
                                      p_erro_cod,
                                      p_erro_msg);
      --
      IF p_erro_cod <> '00000'
      THEN
       RAISE v_exception;
      END IF;
     ELSE
      it_adnnet_pkg.contrato_integrar(r_sis.sistema_externo_id,
                                      p_empresa_id,
                                      v_contrato_id,
                                      'I',
                                      p_erro_cod,
                                      p_erro_msg);
      --
      IF p_erro_cod <> '00000'
      THEN
       RAISE v_exception;
      END IF;
     END IF;
    END IF; -- fim de CONTRATO_ADICIONAR
    --
    --
    IF p_ponto_integracao IN ('CONTRATO_ATUALIZAR')
    THEN
     -- atualiza dados no sistema externo se ja integrado
     --
     SELECT numero,
            rtrim(cod_ext_contrato)
       INTO v_objeto,
            v_cod_ext_contrato
       FROM contrato
      WHERE contrato_id = v_contrato_id;
     --
     IF v_cod_ext_contrato IS NOT NULL
     THEN
      it_adnnet_pkg.contrato_integrar(r_sis.sistema_externo_id,
                                      p_empresa_id,
                                      v_contrato_id,
                                      'A',
                                      p_erro_cod,
                                      p_erro_msg);
      --
      IF p_erro_cod <> '00000'
      THEN
       RAISE v_exception;
      END IF;
     END IF;
    END IF; -- fim de CONTRATO_ATUALIZAR
    --
    --
    IF p_ponto_integracao = 'CONTRATO_EXCLUIR'
    THEN
     -- exclui dados do sistema externo se ja estiver integrado.
     --
     SELECT numero,
            rtrim(cod_ext_contrato)
       INTO v_objeto,
            v_cod_ext_contrato
       FROM contrato
      WHERE contrato_id = v_contrato_id;
     --
     IF v_cod_ext_contrato IS NOT NULL
     THEN
      -- contrato ja integrado. Precisa excluir no sistema externo.
      it_adnnet_pkg.contrato_integrar(r_sis.sistema_externo_id,
                                      p_empresa_id,
                                      v_contrato_id,
                                      'E',
                                      p_erro_cod,
                                      p_erro_msg);
      --
      IF p_erro_cod <> '00000'
      THEN
       RAISE v_exception;
      END IF;
     END IF;
    END IF; -- fim de CONTRATO_EXCLUIR
    --
    ---------------------------------------------------------
    -- pontos de integracao de NOTA_FISCAL de ENTRADA
    ---------------------------------------------------------
    IF p_ponto_integracao = 'NOTA_FISCAL_ENT_ADICIONAR'
    THEN
     -- envia dados para o sistema externo.
     --
     SELECT num_doc || ' ' || serie
       INTO v_objeto
       FROM nota_fiscal
      WHERE nota_fiscal_id = v_nota_fiscal_id;
     --
     it_adnnet_pkg.nf_entrada_integrar(r_sis.sistema_externo_id,
                                       p_empresa_id,
                                       v_nota_fiscal_id,
                                       'I',
                                       p_erro_cod,
                                       p_erro_msg);
     --
     IF p_erro_cod <> '00000'
     THEN
      RAISE v_exception;
     END IF;
    END IF; -- fim de NOTA_FISCAL_ENT_ADICIONAR
    --
    --
    IF p_ponto_integracao = 'NOTA_FISCAL_ENT_EXCLUIR'
    THEN
     -- exclui dados do sistema externo se ja estiver integrado.
     --
     SELECT num_doc || ' ' || serie,
            rtrim(cod_ext_nf)
       INTO v_objeto,
            v_cod_ext_nf
       FROM nota_fiscal
      WHERE nota_fiscal_id = v_nota_fiscal_id;
     --
     IF v_cod_ext_nf IS NOT NULL
     THEN
      -- NF ja integrado. Precisa excluir no sistema externo.
      it_adnnet_pkg.nf_entrada_integrar(r_sis.sistema_externo_id,
                                        p_empresa_id,
                                        v_nota_fiscal_id,
                                        'E',
                                        p_erro_cod,
                                        p_erro_msg);
      --
      IF p_erro_cod <> '00000'
      THEN
       RAISE v_exception;
      END IF;
     END IF;
    END IF; -- fim de NOTA_FISCAL_ENT_EXCLUIR
    --
    ---------------------------------------------------------
    -- pontos de integracao de FATURAMENTO
    ---------------------------------------------------------
    IF p_ponto_integracao IN ('FATURAMENTO_ADICIONAR', 'FATURAMENTO_EXCLUIR')
    THEN
     --
     SELECT decode(p_ponto_integracao, 'FATURAMENTO_ADICIONAR', 'I', 'FATURAMENTO_EXCLUIR', 'E')
       INTO v_cod_acao
       FROM dual;
     --
     IF v_recup_param = 0
     THEN
      -- so recupera os parametros na primeira vez
      v_tipo_fat    := prox_valor_retornar(v_parametros, v_delimitador);
      v_recup_param := 1;
     END IF;
     --
     IF v_tipo_fat = 'JOB'
     THEN
      -- eh faturamento de job
      SELECT MAX(cod_ext_fatur)
        INTO v_cod_ext_fatur
        FROM faturamento
       WHERE faturamento_id = v_faturamento_id;
     ELSE
      -- eh faturamento de contrato
      SELECT MAX(cod_ext_fatur)
        INTO v_cod_ext_fatur
        FROM faturamento_ctr
       WHERE faturamento_ctr_id = v_faturamento_id;
     END IF;
     --
     IF v_cod_ext_fatur IS NULL AND v_cod_acao = 'E'
     THEN
      -- exclusao de faturamento nao integrado. Pula o processamento.
      NULL;
     ELSE
      IF v_tipo_fat = 'JOB'
      THEN
       it_adnnet_pkg.faturamento_integrar(r_sis.sistema_externo_id,
                                          p_empresa_id,
                                          v_faturamento_id,
                                          v_cod_acao,
                                          p_erro_cod,
                                          p_erro_msg);
       IF p_erro_cod <> '00000'
       THEN
        RAISE v_exception;
       END IF;
      ELSIF v_tipo_fat = 'CONTRATO'
      THEN
       it_adnnet_pkg.faturamento_ctr_integrar(r_sis.sistema_externo_id,
                                              p_empresa_id,
                                              v_faturamento_id,
                                              v_cod_acao,
                                              p_erro_cod,
                                              p_erro_msg);
       IF p_erro_cod <> '00000'
       THEN
        RAISE v_exception;
       END IF;
      END IF;
     END IF; -- fim do teste de exclusao
    END IF; -- fim de FATURAMENTO
   END IF; -- fim do ADNNET
   --
   --
   --
   ------------------------------------------------------------
   --  ****************** PROTHEUS **************************
   ------------------------------------------------------------
   IF r_sis.tipo_integr = 'PROTHEUS'
   THEN
    SELECT MAX(rtrim(cod_ext_pessoa))
      INTO v_cod_ext_pessoa
      FROM pessoa_sist_ext
     WHERE sistema_externo_id = r_sis.sistema_externo_id
       AND pessoa_id = v_pessoa_id;
    --
    ---------------------------------------------------------
    -- pontos de integracao de PESSOA
    ---------------------------------------------------------
    IF p_ponto_integracao = 'PESSOA_EXCLUIR'
    THEN
     IF v_cod_ext_pessoa IS NOT NULL
     THEN
      p_erro_cod := '90000';
      p_erro_msg := 'Essa pessoa não pode ser excluída pois está integrada ' || 'com o sistema ' ||
                    r_sis.tipo_integr || ' com o código: ' || v_cod_ext_pessoa || '.';
      RAISE v_exception;
     END IF;
    END IF;
    --
    IF p_ponto_integracao IN ('PESSOA_ATUALIZAR_OPCIONAL', 'PESSOA_ATUALIZAR')
    THEN
     SELECT apelido,
            nome,
            pessoa_pkg.tipo_verificar(pessoa_id, 'CLIENTE'),
            pessoa_pkg.tipo_verificar(pessoa_id, 'FORNECEDOR'),
            pessoa_pkg.tipo_verificar(pessoa_id, 'ESTRANGEIRO'),
            pessoa_pkg.dados_integr_verificar(pessoa_id)
       INTO v_objeto,
            v_nome_pessoa_atu,
            v_tipo_cli,
            v_tipo_for,
            v_tipo_est,
            v_dados_ok
       FROM pessoa
      WHERE pessoa_id = v_pessoa_id;
     --
     IF v_recup_param = 0
     THEN
      -- so recupera os parametros na primeira vez
      v_nome_pessoa_ant := prox_valor_retornar(v_parametros, v_delimitador);
      v_recup_param     := 1;
     END IF;
     --
     IF v_nome_pessoa_ant = 'OPCIONAL'
     THEN
      -- pula a integracao de pessoa pois a transacao principal
      -- eh de outro objeto (estimativa de custo, contrato, etc)
      v_tipo_cli := 0;
      v_tipo_for := 0;
      v_tipo_est := 0;
     END IF;
     --
     -----------------------------
     -- consistencia de pessoa no
     -- estrangeiro ja integrada
     -----------------------------
     IF v_tipo_est = 1 AND v_nome_pessoa_ant <> v_nome_pessoa_atu AND v_cod_ext_pessoa IS NOT NULL
     THEN
      p_erro_cod := '90000';
      p_erro_msg := 'A razão rocial dessa pessoa não pode ser alterada pois está integrada ' ||
                    'com o sistema ' || r_sis.tipo_integr || '.';
      RAISE v_exception;
     END IF;
     --
     -----------------------------
     -- integracao de cliente
     -----------------------------
     IF v_tipo_cli = 1
     THEN
      SELECT COUNT(*)
        INTO v_qt
        FROM pessoa_sist_ext ps,
             tipo_pessoa     ti
       WHERE ps.sistema_externo_id = r_sis.sistema_externo_id
         AND ps.pessoa_id = v_pessoa_id
         AND ps.tipo_pessoa_id = ti.tipo_pessoa_id
         AND ti.codigo = 'CLIENTE';
      --
      IF v_qt > 0
      THEN
       -- cliente ja integrado. Manda como alteracao
       it_protheus_pkg.pessoa_cli_integrar(r_sis.sistema_externo_id,
                                           p_empresa_id,
                                           v_pessoa_id,
                                           'A',
                                           p_erro_cod,
                                           p_erro_msg);
       --
       IF p_erro_cod <> '00000'
       THEN
        RAISE v_exception;
       END IF;
      ELSE
       -- cliente ainda nao integrado
       IF p_ponto_integracao = 'PESSOA_ATUALIZAR' AND v_dados_ok = 0
       THEN
        p_erro_cod := '90000';
        p_erro_msg := 'Os dados da pessoa estão incompletos ou inconsistentes ' ||
                      'para integração com o Protheus (' || v_objeto || ').';
        RAISE v_exception;
       END IF;
       --
       IF v_dados_ok = 1
       THEN
        -- cliente com dados completos. Tenta mandar como inclusao.
        it_protheus_pkg.pessoa_cli_integrar(r_sis.sistema_externo_id,
                                            p_empresa_id,
                                            v_pessoa_id,
                                            'I',
                                            p_erro_cod,
                                            p_erro_msg);
        --
        IF p_erro_cod <> '00000'
        THEN
         RAISE v_exception;
         -- deu erro. Tenta mandar como alteracao.
         -- salva a mensagem retornada.
         v_erro_msg := p_erro_msg;
         --
         it_protheus_pkg.pessoa_cli_integrar(r_sis.sistema_externo_id,
                                             p_empresa_id,
                                             v_pessoa_id,
                                             'A',
                                             p_erro_cod,
                                             p_erro_msg);
         --
         IF p_erro_cod <> '00000'
         THEN
          p_erro_msg := v_erro_msg || ' ; ' || p_erro_msg;
          RAISE v_exception;
         END IF;
        END IF;
       END IF; -- fim do IF v_dados_ok = 1
      END IF; -- fim do IF v_qt > 0
     END IF; -- fim do IF v_tipo_cli = 1
     --
     -----------------------------
     -- integracao de fornecedor
     -----------------------------
     IF v_tipo_for = 1
     THEN
      SELECT COUNT(*)
        INTO v_qt
        FROM pessoa_sist_ext ps,
             tipo_pessoa     ti
       WHERE ps.sistema_externo_id = r_sis.sistema_externo_id
         AND ps.pessoa_id = v_pessoa_id
         AND ps.tipo_pessoa_id = ti.tipo_pessoa_id
         AND ti.codigo = 'FORNECEDOR';
      --
      IF v_qt > 0
      THEN
       -- fornecedor ja integrado. Manda como alteracao
       it_protheus_pkg.pessoa_for_integrar(r_sis.sistema_externo_id,
                                           p_empresa_id,
                                           v_pessoa_id,
                                           'A',
                                           p_erro_cod,
                                           p_erro_msg);
       --
       IF p_erro_cod <> '00000'
       THEN
        RAISE v_exception;
       END IF;
      ELSE
       -- fornecedor ainda nao integrado
       IF p_ponto_integracao = 'PESSOA_ATUALIZAR' AND v_dados_ok = 0
       THEN
        p_erro_cod := '90000';
        p_erro_msg := 'Os dados da pessoa estão incompletos ou inconsistentes ' ||
                      'para integração com o Protheus (' || v_objeto || ').';
        RAISE v_exception;
       END IF;
       --
       IF v_dados_ok = 1
       THEN
        -- fornecedor com dados completos. Tenta mandar como inclusao.
        it_protheus_pkg.pessoa_for_integrar(r_sis.sistema_externo_id,
                                            p_empresa_id,
                                            v_pessoa_id,
                                            'I',
                                            p_erro_cod,
                                            p_erro_msg);
        --
        IF p_erro_cod <> '00000'
        THEN
         RAISE v_exception;
         -- deu erro. Tenta mandar como alteracao.
         -- salva a mensagem retornada.
         v_erro_msg := p_erro_msg;
         --
         it_protheus_pkg.pessoa_for_integrar(r_sis.sistema_externo_id,
                                             p_empresa_id,
                                             v_pessoa_id,
                                             'A',
                                             p_erro_cod,
                                             p_erro_msg);
         --
         IF p_erro_cod <> '00000'
         THEN
          p_erro_msg := v_erro_msg || ' ; ' || p_erro_msg;
          RAISE v_exception;
         END IF;
        END IF;
       END IF; -- fim do IF v_dados_ok = 1
      END IF; -- fim do IF v_qt > 0
     END IF; -- fim do IF v_tipo_for = 1
     --
     /*
     -- replica os dados da pessoa para todas as empresas do grupo
     it_protheus_pkg.pessoa_replicar(r_sis.sistema_externo_id, p_empresa_id, v_pessoa_id,
                                     p_erro_cod, p_erro_msg);
     --
     IF p_erro_cod <> '00000' THEN
        RAISE v_exception;
     END IF;
     */
     --
    END IF; -- fim do IF p_ponto_integracao IN ('PESSOA_ATUALIZAR_OPCIONAL'
    --
    --
    ---------------------------------------------------------
    -- pontos de integracao de ORCAMENTO
    ---------------------------------------------------------
    IF p_ponto_integracao IN ('ORCAMENTO_ADICIONAR', 'ORCAMENTO_ATUALIZAR', 'ORCAMENTO_EXCLUIR')
    THEN
     --
     SELECT decode(p_ponto_integracao,
                   'ORCAMENTO_ADICIONAR',
                   'I',
                   'ORCAMENTO_ATUALIZAR',
                   'A',
                   'ORCAMENTO_EXCLUIR',
                   'E')
       INTO v_cod_acao
       FROM dual;
     --
     SELECT cod_ext_orcam,
            status,
            flag_despesa
       INTO v_cod_ext_orcam,
            v_status_orcam,
            v_flag_despesa
       FROM orcamento
      WHERE orcamento_id = v_orcamento_id;
     --
     SELECT nvl(SUM(valor_aprovado), 0)
       INTO v_valor_aprovado
       FROM item
      WHERE orcamento_id = v_orcamento_id
        AND flag_pago_cliente = 'N';
     --
     IF v_cod_ext_orcam IS NULL AND v_cod_acao IN ('E')
     THEN
      -- exclusao de orcamento nao integrado. Pula o processamento.
      NULL;
     ELSIF v_valor_aprovado = 0
     THEN
      -- orcamento sem valor pago pela agencia. Pula o processamento.
      NULL;
     ELSIF v_flag_despesa = 'S'
     THEN
      -- orcamento de despesa. Pula o processamento.
      NULL;
     ELSE
      IF v_cod_ext_orcam IS NULL AND v_cod_acao = 'A'
      THEN
       -- alteracao de orcamento nao integrado. Envia como inclusao.
       v_cod_acao := 'I';
      END IF;
      --
      IF v_status_orcam = 'APROV' OR v_cod_ext_orcam IS NOT NULL
      THEN
       it_protheus_pkg.pv_orcam_integrar(r_sis.sistema_externo_id,
                                         p_empresa_id,
                                         v_orcamento_id,
                                         v_cod_acao,
                                         p_erro_cod,
                                         p_erro_msg);
       --
       IF p_erro_cod <> '00000'
       THEN
        RAISE v_exception;
       END IF;
      END IF;
     END IF;
    END IF; -- fim de ORCAMENTO
    --
    --
    ---------------------------------------------------------
    -- pontos de integracao de CONTRATO_SERVICO
    ---------------------------------------------------------
    IF p_ponto_integracao IN
       ('CONTRATO_SERVICO_ATUALIZAR', 'CONTRATO_SERVICO_FORCAR', 'CONTRATO_SERVICO_EXCLUIR')
    THEN
     --
     SELECT decode(p_ponto_integracao,
                   'CONTRATO_SERVICO_ATUALIZAR',
                   'A',
                   'CONTRATO_SERVICO_FORCAR',
                   'A',
                   'CONTRATO_SERVICO_EXCLUIR',
                   'E')
       INTO v_cod_acao
       FROM dual;
     --
     SELECT cs.cod_ext_ctrser,
            ct.status_parcel
       INTO v_cod_ext_ctrser,
            v_status_parcel
       FROM contrato_servico cs,
            contrato         ct
      WHERE cs.contrato_servico_id = v_contrato_servico_id
        AND cs.contrato_id = ct.contrato_id;
     --
     IF v_cod_ext_ctrser IS NULL AND v_cod_acao IN ('E')
     THEN
      -- exclusao de objeto nao integrado. Pula o processamento.
      NULL;
     ELSE
      IF v_cod_ext_ctrser IS NULL AND v_cod_acao = 'A'
      THEN
       -- alteracao de objeto nao integrado. Envia como inclusao.
       v_cod_acao := 'I';
      END IF;
      --
      IF v_status_parcel = 'PRON' OR v_cod_ext_ctrser IS NOT NULL OR
         p_ponto_integracao = 'CONTRATO_SERVICO_FORCAR'
      THEN
       it_protheus_pkg.pv_contrato_integrar(r_sis.sistema_externo_id,
                                            p_empresa_id,
                                            v_contrato_servico_id,
                                            v_cod_acao,
                                            p_erro_cod,
                                            p_erro_msg);
       --
       IF p_erro_cod <> '00000'
       THEN
        RAISE v_exception;
       END IF;
      END IF;
     END IF;
    END IF; -- fim de CONTRATO_SERVICO
    --
    --
    ---------------------------------------------------------
    -- pontos de integracao de NOTA_FISCAL de ENTRADA
    ---------------------------------------------------------
    IF p_ponto_integracao IN ('NOTA_FISCAL_ENT_ADICIONAR', 'NOTA_FISCAL_ENT_EXCLUIR')
    THEN
     --
     SELECT decode(p_ponto_integracao,
                   'NOTA_FISCAL_ENT_ADICIONAR',
                   'I',
                   'NOTA_FISCAL_ENT_EXCLUIR',
                   'E')
       INTO v_cod_acao
       FROM dual;
     --
     SELECT num_doc || ' ' || serie,
            rtrim(cod_ext_nf),
            flag_pago_cliente
       INTO v_objeto,
            v_cod_ext_nf,
            v_flag_pago_cliente
       FROM nota_fiscal
      WHERE nota_fiscal_id = v_nota_fiscal_id;
     --
     IF v_cod_ext_nf IS NULL AND v_cod_acao = 'E'
     THEN
      -- exclusao de NF nao integrada. Pula o processamento.
      NULL;
     ELSIF v_flag_pago_cliente = 'S'
     THEN
      -- NF paga pelo cliente. Pula o processamento
      NULL;
     ELSE
      it_protheus_pkg.nf_entrada_integrar(r_sis.sistema_externo_id,
                                          p_empresa_id,
                                          v_nota_fiscal_id,
                                          v_cod_acao,
                                          p_erro_cod,
                                          p_erro_msg);
     END IF;
     --
     IF p_erro_cod <> '00000'
     THEN
      RAISE v_exception;
     END IF;
    END IF; -- fim de NOTA_FISCAL_ENT
    --
    --
    ---------------------------------------------------------
    -- pontos de integracao de FATURAMENTO
    ---------------------------------------------------------
    IF p_ponto_integracao IN ('FATURAMENTO_ADICIONAR', 'FATURAMENTO_EXCLUIR')
    THEN
     --
     SELECT decode(p_ponto_integracao, 'FATURAMENTO_ADICIONAR', 'I', 'FATURAMENTO_EXCLUIR', 'E')
       INTO v_cod_acao
       FROM dual;
     --
     IF v_recup_param = 0
     THEN
      -- so recupera os parametros na primeira vez
      v_tipo_fat    := prox_valor_retornar(v_parametros, v_delimitador);
      v_recup_param := 1;
     END IF;
     --
     IF v_tipo_fat = 'JOB'
     THEN
      -- eh faturamento de job
      SELECT MAX(cod_ext_fatur)
        INTO v_cod_ext_fatur
        FROM faturamento
       WHERE faturamento_id = v_faturamento_id;
     ELSE
      -- eh faturamento de contrato
      SELECT MAX(cod_ext_fatur)
        INTO v_cod_ext_fatur
        FROM faturamento_ctr
       WHERE faturamento_ctr_id = v_faturamento_id;
     END IF;
     --
     IF v_cod_ext_fatur IS NULL AND v_cod_acao = 'E'
     THEN
      -- exclusao de faturamento nao integrado. Pula o processamento.
      NULL;
     ELSE
      it_protheus_pkg.faturamento_integrar(r_sis.sistema_externo_id,
                                           p_empresa_id,
                                           v_faturamento_id,
                                           v_cod_acao,
                                           v_tipo_fat,
                                           p_erro_cod,
                                           p_erro_msg);
      --
      IF p_erro_cod <> '00000'
      THEN
       RAISE v_exception;
      END IF;
     END IF;
    END IF; -- fim de FATURAMENTO
    --
    --
    ---------------------------------------------------------
    -- pontos de integracao de TIPO_PRODUTO
    ---------------------------------------------------------
    IF p_ponto_integracao IN ('TIPO_PRODUTO_ATUALIZAR')
    THEN
     IF v_recup_param = 0
     THEN
      -- so recupera os parametros na primeira vez
      v_cod_ext_objeto_ant := prox_valor_retornar(v_parametros, v_delimitador);
      v_objeto_ant         := prox_valor_retornar(v_parametros, v_delimitador);
      v_recup_param        := 1;
     END IF;
     --
     SELECT nome,
            rtrim(cod_ext_produto)
       INTO v_objeto,
            v_cod_ext_produto
       FROM tipo_produto
      WHERE tipo_produto_id = v_tipo_produto_id;
     --
     IF v_cod_ext_objeto_ant IS NOT NULL
     THEN
      IF v_cod_ext_objeto_ant <> nvl(v_cod_ext_produto, 'ZZZ999ZZZ')
      THEN
       p_erro_cod := '90000';
       p_erro_msg := 'O código externo desse tipo de produto não pode ser alterado ' ||
                     'pois está integrado com o sistema ' || r_sis.tipo_integr || '.';
       RAISE v_exception;
      END IF;
      --
      IF v_objeto <> v_objeto_ant
      THEN
       p_erro_cod := '90000';
       p_erro_msg := 'O nome desse tipo de produto não pode ser alterado ' ||
                     'pois está integrado com o sistema ' || r_sis.tipo_integr || '.';
       RAISE v_exception;
      END IF;
     END IF;
    END IF;
    --
    IF p_ponto_integracao IN ('TIPO_PRODUTO_EXCLUIR')
    THEN
     --
     SELECT nome,
            rtrim(cod_ext_produto)
       INTO v_objeto,
            v_cod_ext_produto
       FROM tipo_produto
      WHERE tipo_produto_id = v_tipo_produto_id;
     --
     IF v_cod_ext_produto IS NOT NULL
     THEN
      p_erro_cod := '90000';
      p_erro_msg := 'Esse tipo de produto não pode ser excluído pois está integrado ' ||
                    'com o sistema ' || r_sis.tipo_integr || '.';
      RAISE v_exception;
     END IF;
    END IF;
    --
    --
   END IF; -- fim do PROTHEUS
   --
   --
   --
   ------------------------------------------------------------
   --     ****************** SAP **************************
   ------------------------------------------------------------
   IF r_sis.tipo_integr = 'SAP'
   THEN
    --
    ---------------------------------------------------------
    -- pontos de integracao de PESSOA
    ---------------------------------------------------------
    IF p_ponto_integracao IN ('PESSOA_ATUALIZAR_OPCIONAL', 'PESSOA_ATUALIZAR', 'PESSOA_EXCLUIR')
    THEN
     -- caso integrado, verifica se pode fazer as alteracoes.
     --
     SELECT apelido
       INTO v_objeto
       FROM pessoa
      WHERE pessoa_id = v_pessoa_id;
     --
     IF p_ponto_integracao IN ('PESSOA_ATUALIZAR', 'PESSOA_ATUALIZAR_OPCIONAL')
     THEN
      SELECT MAX(ti.nome)
        INTO v_objeto
        FROM pessoa_sist_ext ps,
             tipo_pessoa     ti
       WHERE ps.sistema_externo_id = r_sis.sistema_externo_id
         AND ps.pessoa_id = v_pessoa_id
         AND ps.tipo_pessoa_id = ti.tipo_pessoa_id
         AND NOT EXISTS (SELECT 1
                FROM tipific_pessoa tp
               WHERE tp.pessoa_id = ps.pessoa_id
                 AND tp.tipo_pessoa_id = ps.tipo_pessoa_id);
      --
      IF v_objeto IS NOT NULL
      THEN
       p_erro_cod := '90000';
       p_erro_msg := 'O tipo ' || v_objeto || ' dessa pessoa não pode ser ' ||
                     'alterado pois existe integração com o sistema ' || r_sis.tipo_integr || '.';
       RAISE v_exception;
      END IF;
     END IF;
     --
     IF p_ponto_integracao = 'PESSOA_EXCLUIR'
     THEN
      SELECT MAX(rtrim(cod_ext_pessoa))
        INTO v_cod_ext_pessoa
        FROM pessoa_sist_ext
       WHERE sistema_externo_id = r_sis.sistema_externo_id
         AND pessoa_id = v_pessoa_id;
      --
      IF v_cod_ext_pessoa IS NOT NULL
      THEN
       p_erro_cod := '90000';
       p_erro_msg := 'Essa pessoa não pode ser excluída pois está integrada ' || 'com o sistema ' ||
                     r_sis.tipo_integr || '.';
       RAISE v_exception;
      END IF;
     END IF;
    END IF;
    --
    ---------------------------------------------------------
    -- pontos de integracao de PRODUTO_CLIENTE
    ---------------------------------------------------------
    --
    IF p_ponto_integracao IN
       ('PRODUTO_CLIENTE_ADICIONAR', 'PRODUTO_CLIENTE_ATUALIZAR', 'PRODUTO_CLIENTE_EXCLUIR')
    THEN
     --
     SELECT nome,
            rtrim(cod_ext_produto)
       INTO v_objeto,
            v_cod_ext_produto
       FROM produto_cliente
      WHERE produto_cliente_id = v_produto_cliente_id;
     --
     IF v_cod_ext_produto IS NOT NULL
     THEN
      p_erro_cod := '90000';
      p_erro_msg := 'Esse produto não pode ser alterado/excluído pois está integrado ' ||
                    'com o sistema ' || r_sis.tipo_integr || '.';
      RAISE v_exception;
     END IF;
    END IF;
    --
    ---------------------------------------------------------
    -- pontos de integracao de ORDEM_SERVICO
    ---------------------------------------------------------
    IF p_ponto_integracao IN ('ORDEM_SERVICO_ADICIONAR',
                              'ORDEM_SERVICO_ATUALIZAR',
                              'ORDEM_SERVICO_ACAO_EXECUTAR',
                              'ORDEM_SERVICO_EXCLUIR')
    THEN
     --
     IF p_ponto_integracao = 'ORDEM_SERVICO_ACAO_EXECUTAR' AND v_recup_param = 0
     THEN
      -- so recupera os parametros na primeira vez
      v_forca_integracao := prox_valor_retornar(v_parametros, v_delimitador);
      v_recup_param      := 1;
     END IF;
     --
     SELECT jo.job_id,
            jo.cod_ext_job,
            os.cod_ext_os,
            os.status,
            ti.status_integracao
       INTO v_job_id,
            v_cod_ext_job,
            v_cod_ext_os,
            v_status_os,
            v_status_integracao
       FROM ordem_servico os,
            job           jo,
            tipo_os       ti
      WHERE os.ordem_servico_id = v_ordem_servico_id
        AND os.job_id = jo.job_id
        AND os.tipo_os_id = ti.tipo_os_id;
     --
     IF p_ponto_integracao = 'ORDEM_SERVICO_EXCLUIR' AND v_cod_ext_os IS NOT NULL
     THEN
      p_erro_cod := '90000';
      p_erro_msg := 'Esse Workflow não pode ser excluído pois está integrado ' || 'com o sistema ' ||
                    r_sis.tipo_integr || '.';
      RAISE v_exception;
     END IF;
     --
     -- verifica se precia integrar o JOB
     IF p_ponto_integracao IN ('ORDEM_SERVICO_ADICIONAR', 'ORDEM_SERVICO_ACAO_EXECUTAR') AND
        (v_status_os = v_status_integracao OR v_forca_integracao = 'S') AND v_cod_ext_job IS NULL
     THEN
      -- integra o JOB
      it_sap_pkg.job_integrar(r_sis.sistema_externo_id,
                              p_empresa_id,
                              v_job_id,
                              'I',
                              p_erro_cod,
                              p_erro_msg);
      --
      IF p_erro_cod <> '00000'
      THEN
       RAISE v_exception;
      END IF;
     END IF;
     --
     -- verifica se precisa integrar a OS
     IF p_ponto_integracao IN ('ORDEM_SERVICO_ADICIONAR', 'ORDEM_SERVICO_ACAO_EXECUTAR') AND
        (v_status_os = v_status_integracao OR v_forca_integracao = 'S')
     THEN
      --
      IF v_cod_ext_os IS NULL
      THEN
       it_sap_pkg.ordem_servico_integrar(r_sis.sistema_externo_id,
                                         p_empresa_id,
                                         v_ordem_servico_id,
                                         'I',
                                         p_erro_cod,
                                         p_erro_msg);
       --
       IF p_erro_cod <> '00000'
       THEN
        RAISE v_exception;
       END IF;
      ELSE
       it_sap_pkg.ordem_servico_integrar(r_sis.sistema_externo_id,
                                         p_empresa_id,
                                         v_ordem_servico_id,
                                         'A',
                                         p_erro_cod,
                                         p_erro_msg);
       --
       IF p_erro_cod <> '00000'
       THEN
        RAISE v_exception;
       END IF;
      END IF;
     END IF;
    END IF; -- fim de ORDEM_SERVICO
    --
    ---------------------------------------------------------
    -- pontos de integracao de JOB
    ---------------------------------------------------------
    IF p_ponto_integracao IN
       ('JOB_ADICIONAR', 'JOB_ATUALIZAR', 'JOB_EXCLUIR', 'JOB_APROV_ORCAM_ENVIAR')
    THEN
     -- envia dados para o sistema externo.
     --
     SELECT cod_ext_job,
            status
       INTO v_cod_ext_job,
            v_status_job
       FROM job
      WHERE job_id = v_job_id;
     --
     IF p_ponto_integracao = 'JOB_EXCLUIR' AND v_cod_ext_job IS NOT NULL
     THEN
      p_erro_cod := '90000';
      p_erro_msg := 'Esse job não pode ser excluído pois está integrado ' || 'com o sistema ' ||
                    r_sis.tipo_integr || '.';
      RAISE v_exception;
     END IF;
     --
     IF (p_ponto_integracao = 'JOB_ADICIONAR' AND v_status_job = 'ANDA') OR
        (p_ponto_integracao = 'JOB_APROV_ORCAM_ENVIAR' AND v_cod_ext_job IS NULL)
     THEN
      -- integra o job quando passa para andamento ou aprova EC
      it_sap_pkg.job_integrar(r_sis.sistema_externo_id,
                              p_empresa_id,
                              v_job_id,
                              'I',
                              p_erro_cod,
                              p_erro_msg);
      --
      IF p_erro_cod <> '00000'
      THEN
       RAISE v_exception;
      END IF;
     END IF;
     --
     IF p_ponto_integracao = 'JOB_ATUALIZAR' AND v_cod_ext_job IS NOT NULL
     THEN
      -- atualiza job ja integrado
      it_sap_pkg.job_integrar(r_sis.sistema_externo_id,
                              p_empresa_id,
                              v_job_id,
                              'A',
                              p_erro_cod,
                              p_erro_msg);
      --
      IF p_erro_cod <> '00000'
      THEN
       RAISE v_exception;
      END IF;
     END IF;
     --
     IF p_ponto_integracao = 'JOB_ATUALIZAR' AND v_status_job = 'ANDA' AND v_cod_ext_job IS NULL
     THEN
      -- tenta integrar o job (pode ter passado do tipo TSH para outro)
      it_sap_pkg.job_integrar(r_sis.sistema_externo_id,
                              p_empresa_id,
                              v_job_id,
                              'I',
                              p_erro_cod,
                              p_erro_msg);
      --
      IF p_erro_cod <> '00000'
      THEN
       RAISE v_exception;
      END IF;
     END IF;
    END IF; -- fim de JOB
    --
    --
    ---------------------------------------------------------
    -- pontos de integracao de TIPO_PRODUTO
    ---------------------------------------------------------
    --
    IF p_ponto_integracao IN ('TIPO_PRODUTO_ATUALIZAR')
    THEN
     IF v_recup_param = 0
     THEN
      -- so recupera os parametros na primeira vez
      v_cod_ext_objeto_ant := prox_valor_retornar(v_parametros, v_delimitador);
      v_objeto_ant         := prox_valor_retornar(v_parametros, v_delimitador);
      v_recup_param        := 1;
     END IF;
     --
     SELECT nome,
            rtrim(cod_ext_produto)
       INTO v_objeto,
            v_cod_ext_produto
       FROM tipo_produto
      WHERE tipo_produto_id = v_tipo_produto_id;
     --
     IF v_cod_ext_objeto_ant IS NOT NULL
     THEN
      IF v_cod_ext_objeto_ant <> nvl(v_cod_ext_produto, 'ZZZ999ZZZ')
      THEN
       p_erro_cod := '90000';
       p_erro_msg := 'O código externo desse tipo de produto não pode ser alterado ' ||
                     'pois está integrado com o sistema ' || r_sis.tipo_integr || '.';
       RAISE v_exception;
      END IF;
      --
      IF v_objeto <> v_objeto_ant
      THEN
       p_erro_cod := '90000';
       p_erro_msg := 'O nome desse tipo de produto não pode ser alterado ' ||
                     'pois está integrado com o sistema ' || r_sis.tipo_integr || '.';
       RAISE v_exception;
      END IF;
     END IF;
    END IF;
    --
    IF p_ponto_integracao IN ('TIPO_PRODUTO_EXCLUIR')
    THEN
     --
     SELECT nome,
            rtrim(cod_ext_produto)
       INTO v_objeto,
            v_cod_ext_produto
       FROM tipo_produto
      WHERE tipo_produto_id = v_tipo_produto_id;
     --
     IF v_cod_ext_produto IS NOT NULL
     THEN
      p_erro_cod := '90000';
      p_erro_msg := 'Esse tipo de produto não pode ser excluído pois está integrado ' ||
                    'com o sistema ' || r_sis.tipo_integr || '.';
      RAISE v_exception;
     END IF;
    END IF;
    --
    --
    ---------------------------------------------------------
    -- pontos de integracao de CARTA_ACORDO
    ---------------------------------------------------------
    IF p_ponto_integracao IN ('PESSOA_ATUALIZAR_OPCIONAL', 'PESSOA_ATUALIZAR', 'PESSOA_EXCLUIR')
    THEN
     -- caso integrado, verifica se pode fazer as alteracoes.
     --
     SELECT apelido
       INTO v_objeto
       FROM pessoa
      WHERE pessoa_id = v_pessoa_id;
     --
     IF p_ponto_integracao IN ('PESSOA_ATUALIZAR', 'PESSOA_ATUALIZAR_OPCIONAL')
     THEN
      SELECT MAX(ti.nome)
        INTO v_objeto
        FROM pessoa_sist_ext ps,
             tipo_pessoa     ti
       WHERE ps.sistema_externo_id = r_sis.sistema_externo_id
         AND ps.pessoa_id = v_pessoa_id
         AND ps.tipo_pessoa_id = ti.tipo_pessoa_id
         AND NOT EXISTS (SELECT 1
                FROM tipific_pessoa tp
               WHERE tp.pessoa_id = ps.pessoa_id
                 AND tp.tipo_pessoa_id = ps.tipo_pessoa_id);
      --
      IF v_objeto IS NOT NULL
      THEN
       p_erro_cod := '90000';
       p_erro_msg := 'O tipo ' || v_objeto || ' dessa pessoa não pode ser ' ||
                     'alterado pois existe integração com o sistema ' || r_sis.tipo_integr || '.';
       RAISE v_exception;
      END IF;
     END IF;
     --
     IF p_ponto_integracao = 'PESSOA_EXCLUIR'
     THEN
      SELECT MAX(rtrim(cod_ext_pessoa))
        INTO v_cod_ext_pessoa
        FROM pessoa_sist_ext
       WHERE sistema_externo_id = r_sis.sistema_externo_id
         AND pessoa_id = v_pessoa_id;
      --
      IF v_cod_ext_pessoa IS NOT NULL
      THEN
       p_erro_cod := '90000';
       p_erro_msg := 'Essa pessoa não pode ser excluída pois está integrada ' || 'com o sistema ' ||
                     r_sis.tipo_integr || '.';
       RAISE v_exception;
      END IF;
     END IF;
    END IF;
    --
    ---------------------------------------------------------
    -- pontos de integracao de PRODUTO_CLIENTE
    ---------------------------------------------------------
    --
    IF p_ponto_integracao IN
       ('PRODUTO_CLIENTE_ADICIONAR', 'PRODUTO_CLIENTE_ATUALIZAR', 'PRODUTO_CLIENTE_EXCLUIR')
    THEN
     --
     SELECT nome,
            rtrim(cod_ext_produto)
       INTO v_objeto,
            v_cod_ext_produto
       FROM produto_cliente
      WHERE produto_cliente_id = v_produto_cliente_id;
     --
     IF v_cod_ext_produto IS NOT NULL
     THEN
      p_erro_cod := '90000';
      p_erro_msg := 'Esse produto não pode ser alterado/excluído pois está integrado ' ||
                    'com o sistema ' || r_sis.tipo_integr || '.';
      RAISE v_exception;
     END IF;
    END IF;
    --
    ---------------------------------------------------------
    -- pontos de integracao de ORDEM_SERVICO
    ---------------------------------------------------------
    IF p_ponto_integracao IN ('ORDEM_SERVICO_ADICIONAR',
                              'ORDEM_SERVICO_ATUALIZAR',
                              'ORDEM_SERVICO_ACAO_EXECUTAR',
                              'ORDEM_SERVICO_EXCLUIR')
    THEN
     --
     IF p_ponto_integracao = 'ORDEM_SERVICO_ACAO_EXECUTAR' AND v_recup_param = 0
     THEN
      -- so recupera os parametros na primeira vez
      v_forca_integracao := prox_valor_retornar(v_parametros, v_delimitador);
      v_recup_param      := 1;
     END IF;
     --
     SELECT jo.job_id,
            jo.cod_ext_job,
            os.cod_ext_os,
            os.status,
            ti.status_integracao
       INTO v_job_id,
            v_cod_ext_job,
            v_cod_ext_os,
            v_status_os,
            v_status_integracao
       FROM ordem_servico os,
            job           jo,
            tipo_os       ti
      WHERE os.ordem_servico_id = v_ordem_servico_id
        AND os.job_id = jo.job_id
        AND os.tipo_os_id = ti.tipo_os_id;
     --
     IF p_ponto_integracao = 'ORDEM_SERVICO_EXCLUIR' AND v_cod_ext_os IS NOT NULL
     THEN
      p_erro_cod := '90000';
      p_erro_msg := 'Esse Workflow não pode ser excluído pois está integrado ' || 'com o sistema ' ||
                    r_sis.tipo_integr || '.';
      RAISE v_exception;
     END IF;
     --
     -- verifica se precia integrar o JOB
     IF p_ponto_integracao IN ('ORDEM_SERVICO_ADICIONAR', 'ORDEM_SERVICO_ACAO_EXECUTAR') AND
        (v_status_os = v_status_integracao OR v_forca_integracao = 'S') AND v_cod_ext_job IS NULL
     THEN
      -- integra o JOB
      it_sap_pkg.job_integrar(r_sis.sistema_externo_id,
                              p_empresa_id,
                              v_job_id,
                              'I',
                              p_erro_cod,
                              p_erro_msg);
      --
      IF p_erro_cod <> '00000'
      THEN
       RAISE v_exception;
      END IF;
     END IF;
     --
     -- verifica se precisa integrar a OS
     IF p_ponto_integracao IN ('ORDEM_SERVICO_ADICIONAR', 'ORDEM_SERVICO_ACAO_EXECUTAR') AND
        (v_status_os = v_status_integracao OR v_forca_integracao = 'S')
     THEN
      --
      IF v_cod_ext_os IS NULL
      THEN
       it_sap_pkg.ordem_servico_integrar(r_sis.sistema_externo_id,
                                         p_empresa_id,
                                         v_ordem_servico_id,
                                         'I',
                                         p_erro_cod,
                                         p_erro_msg);
       --
       IF p_erro_cod <> '00000'
       THEN
        RAISE v_exception;
       END IF;
      ELSE
       it_sap_pkg.ordem_servico_integrar(r_sis.sistema_externo_id,
                                         p_empresa_id,
                                         v_ordem_servico_id,
                                         'A',
                                         p_erro_cod,
                                         p_erro_msg);
       --
       IF p_erro_cod <> '00000'
       THEN
        RAISE v_exception;
       END IF;
      END IF;
     END IF;
    END IF; -- fim de ORDEM_SERVICO
    --
    ---------------------------------------------------------
    -- pontos de integracao de JOB
    ---------------------------------------------------------
    IF p_ponto_integracao IN
       ('JOB_ADICIONAR', 'JOB_ATUALIZAR', 'JOB_EXCLUIR', 'JOB_APROV_ORCAM_ENVIAR')
    THEN
     -- envia dados para o sistema externo.
     --
     SELECT cod_ext_job,
            status
       INTO v_cod_ext_job,
            v_status_job
       FROM job
      WHERE job_id = v_job_id;
     --
     IF p_ponto_integracao = 'JOB_EXCLUIR' AND v_cod_ext_job IS NOT NULL
     THEN
      p_erro_cod := '90000';
      p_erro_msg := 'Esse job não pode ser excluído pois está integrado ' || 'com o sistema ' ||
                    r_sis.tipo_integr || '.';
      RAISE v_exception;
     END IF;
     --
     IF (p_ponto_integracao = 'JOB_ADICIONAR' AND v_status_job = 'ANDA') OR
        (p_ponto_integracao = 'JOB_APROV_ORCAM_ENVIAR' AND v_cod_ext_job IS NULL)
     THEN
      -- integra o job quando passa para andamento ou aprova EC
      it_sap_pkg.job_integrar(r_sis.sistema_externo_id,
                              p_empresa_id,
                              v_job_id,
                              'I',
                              p_erro_cod,
                              p_erro_msg);
      --
      IF p_erro_cod <> '00000'
      THEN
       RAISE v_exception;
      END IF;
     END IF;
     --
     IF p_ponto_integracao = 'JOB_ATUALIZAR' AND v_cod_ext_job IS NOT NULL
     THEN
      -- atualiza job ja integrado
      it_sap_pkg.job_integrar(r_sis.sistema_externo_id,
                              p_empresa_id,
                              v_job_id,
                              'A',
                              p_erro_cod,
                              p_erro_msg);
      --
      IF p_erro_cod <> '00000'
      THEN
       RAISE v_exception;
      END IF;
     END IF;
     --
     IF p_ponto_integracao = 'JOB_ATUALIZAR' AND v_status_job = 'ANDA' AND v_cod_ext_job IS NULL
     THEN
      -- tenta integrar o job (pode ter passado do tipo TSH para outro)
      it_sap_pkg.job_integrar(r_sis.sistema_externo_id,
                              p_empresa_id,
                              v_job_id,
                              'I',
                              p_erro_cod,
                              p_erro_msg);
      --
      IF p_erro_cod <> '00000'
      THEN
       RAISE v_exception;
      END IF;
     END IF;
    END IF; -- fim de JOB
    --
    --
    ---------------------------------------------------------
    -- pontos de integracao de TIPO_PRODUTO
    ---------------------------------------------------------
    --
    IF p_ponto_integracao IN ('TIPO_PRODUTO_ATUALIZAR')
    THEN
     IF v_recup_param = 0
     THEN
      -- so recupera os parametros na primeira vez
      v_cod_ext_objeto_ant := prox_valor_retornar(v_parametros, v_delimitador);
      v_objeto_ant         := prox_valor_retornar(v_parametros, v_delimitador);
      v_recup_param        := 1;
     END IF;
     --
     SELECT nome,
            rtrim(cod_ext_produto)
       INTO v_objeto,
            v_cod_ext_produto
       FROM tipo_produto
      WHERE tipo_produto_id = v_tipo_produto_id;
     --
     IF v_cod_ext_objeto_ant IS NOT NULL
     THEN
      IF v_cod_ext_objeto_ant <> nvl(v_cod_ext_produto, 'ZZZ999ZZZ')
      THEN
       p_erro_cod := '90000';
       p_erro_msg := 'O código externo desse tipo de produto não pode ser alterado ' ||
                     'pois está integrado com o sistema ' || r_sis.tipo_integr || '.';
       RAISE v_exception;
      END IF;
      --
      IF v_objeto <> v_objeto_ant
      THEN
       p_erro_cod := '90000';
       p_erro_msg := 'O nome desse tipo de produto não pode ser alterado ' ||
                     'pois está integrado com o sistema ' || r_sis.tipo_integr || '.';
       RAISE v_exception;
      END IF;
     END IF;
    END IF;
    --
    IF p_ponto_integracao IN ('TIPO_PRODUTO_EXCLUIR')
    THEN
     --
     SELECT nome,
            rtrim(cod_ext_produto)
       INTO v_objeto,
            v_cod_ext_produto
       FROM tipo_produto
      WHERE tipo_produto_id = v_tipo_produto_id;
     --
     IF v_cod_ext_produto IS NOT NULL
     THEN
      p_erro_cod := '90000';
      p_erro_msg := 'Esse tipo de produto não pode ser excluído pois está integrado ' ||
                    'com o sistema ' || r_sis.tipo_integr || '.';
      RAISE v_exception;
     END IF;
    END IF;
    --
    --
    ---------------------------------------------------------
    -- pontos de integracao de CARTA_ACORDO
    ---------------------------------------------------------
    IF p_ponto_integracao IN
       ('CARTA_ACORDO_ADICIONAR', 'CARTA_ACORDO_ATUALIZAR', 'CARTA_ACORDO_EXCLUIR')
    THEN
     --
     SELECT decode(p_ponto_integracao,
                   'CARTA_ACORDO_ADICIONAR',
                   'I',
                   'CARTA_ACORDO_ATUALIZAR',
                   'A',
                   'CARTA_ACORDO_EXCLUIR',
                   'E')
       INTO v_cod_acao
       FROM dual;
     --
     SELECT cod_ext_carta
       INTO v_cod_ext_carta
       FROM carta_acordo
      WHERE carta_acordo_id = v_carta_acordo_id;
     --
     SELECT nvl(to_char(MIN(it.flag_pago_cliente)), 'N')
       INTO v_flag_pago_cliente
       FROM item_carta ic,
            item       it
      WHERE ic.carta_acordo_id = v_carta_acordo_id
        AND ic.item_id = it.item_id;
     --
     IF v_cod_ext_carta IS NULL AND v_cod_acao = 'E'
     THEN
      -- exclusao de carta nao integrada. Pula o processamento.
      NULL;
     ELSIF v_flag_pago_cliente = 'S'
     THEN
      -- carta com itens pagos pelo cliente. Pula o processamento.
      NULL;
      /*
      ELSIF v_cod_ext_carta IS NOT NULL AND v_cod_acao = 'E' THEN
         -- exclusao de carta ja integrado. Nao deixa por enquanto
         p_erro_cod := '90000';
         p_erro_msg := 'Essa carta acordo não pode ser excluída pois está integrada ' ||
                       'com o sistema ' || r_sis.tipo_integr || '.';
         RAISE v_exception;
      */
     ELSE
      IF v_cod_ext_carta IS NULL AND v_cod_acao = 'A'
      THEN
       -- alteracao de carta nao integrada. Envia como inclusao.
       v_cod_acao := 'I';
      END IF;
      --
      it_sap_pkg.carta_acordo_integrar(r_sis.sistema_externo_id,
                                       p_empresa_id,
                                       v_carta_acordo_id,
                                       v_cod_acao,
                                       p_erro_cod,
                                       p_erro_msg);
      --
      IF p_erro_cod <> '00000'
      THEN
       RAISE v_exception;
      END IF;
     END IF;
    END IF; -- fim da CARTA_ACORDO
    --
    ---------------------------------------------------------
    -- pontos de integracao de FATURAMENTO
    ---------------------------------------------------------
    IF p_ponto_integracao IN ('FATURAMENTO_ADICIONAR', 'FATURAMENTO_EXCLUIR')
    THEN
     --
     SELECT decode(p_ponto_integracao, 'FATURAMENTO_ADICIONAR', 'I', 'FATURAMENTO_EXCLUIR', 'E')
       INTO v_cod_acao
       FROM dual;
     --
     SELECT COUNT(*)
       INTO v_qt
       FROM faturamento
      WHERE faturamento_id = v_faturamento_id;
     --
     IF v_qt > 0
     THEN
      -- eh faturamento de job
      SELECT cod_ext_fatur
        INTO v_cod_ext_fatur
        FROM faturamento
       WHERE faturamento_id = v_faturamento_id;
     ELSE
      -- eh faturamento de contrato
      SELECT cod_ext_fatur
        INTO v_cod_ext_fatur
        FROM faturamento_ctr
       WHERE faturamento_ctr_id = v_faturamento_id;
     END IF;
     --
     IF v_cod_ext_fatur IS NULL AND v_cod_acao = 'E'
     THEN
      -- exclusao de faturamento nao integrado. Pula o processamento.
      NULL;
      /*
      ELSIF v_cod_ext_fatur IS NOT NULL AND v_cod_acao = 'E' THEN
         -- exclusao de faturamento ja integrado. Nao deixa por enquanto
         p_erro_cod := '90000';
         p_erro_msg := 'Esse Faturamento não pode ser excluído pois está integrado ' ||
                       'com o sistema ' || r_sis.tipo_integr || '.';
         RAISE v_exception;
      */
     ELSE
      it_sap_pkg.faturamento_integrar(r_sis.sistema_externo_id,
                                      p_empresa_id,
                                      v_faturamento_id,
                                      v_cod_acao,
                                      p_erro_cod,
                                      p_erro_msg);
      --
      IF p_erro_cod <> '00000'
      THEN
       RAISE v_exception;
      END IF;
     END IF;
    END IF; -- fim de FATURAMENTO
    --
   END IF; -- fim do SAP
   --
   --
   --
   ------------------------------------------------------------
   --  ****************** APOLO **************************
   ------------------------------------------------------------
   IF r_sis.tipo_integr = 'APOLO'
   THEN
    --
    ---------------------------------------------------------
    -- pontos de integracao de PESSOA
    ---------------------------------------------------------
    IF p_ponto_integracao IN ('PESSOA_ATUALIZAR_OPCIONAL', 'PESSOA_ATUALIZAR', 'PESSOA_EXCLUIR')
    THEN
     -- caso integrado, verifica se pode fazer as alteracoes.
     --
     SELECT apelido
       INTO v_objeto
       FROM pessoa
      WHERE pessoa_id = v_pessoa_id;
     --
     IF p_ponto_integracao IN ('PESSOA_ATUALIZAR', 'PESSOA_ATUALIZAR_OPCIONAL')
     THEN
      SELECT MAX(ti.nome)
        INTO v_objeto
        FROM pessoa_sist_ext ps,
             tipo_pessoa     ti
       WHERE ps.sistema_externo_id = r_sis.sistema_externo_id
         AND ps.pessoa_id = v_pessoa_id
         AND ps.tipo_pessoa_id = ti.tipo_pessoa_id
         AND NOT EXISTS (SELECT 1
                FROM tipific_pessoa tp
               WHERE tp.pessoa_id = ps.pessoa_id
                 AND tp.tipo_pessoa_id = ps.tipo_pessoa_id);
      --
      IF v_objeto IS NOT NULL
      THEN
       p_erro_cod := '90000';
       p_erro_msg := 'O tipo ' || v_objeto || ' dessa pessoa não pode ser ' ||
                     'alterado pois existe integração com o sistema ' || r_sis.tipo_integr || '.';
       RAISE v_exception;
      END IF;
     END IF;
     --
     IF p_ponto_integracao = 'PESSOA_EXCLUIR'
     THEN
      SELECT MAX(rtrim(cod_ext_pessoa))
        INTO v_cod_ext_pessoa
        FROM pessoa_sist_ext
       WHERE sistema_externo_id = r_sis.sistema_externo_id
         AND pessoa_id = v_pessoa_id;
      --
      IF v_cod_ext_pessoa IS NOT NULL
      THEN
       p_erro_cod := '90000';
       p_erro_msg := 'Essa pessoa não pode ser excluída pois está integrada ' || 'com o sistema ' ||
                     r_sis.tipo_integr || '.';
       RAISE v_exception;
      END IF;
     END IF;
    END IF;
    --
    ---------------------------------------------------------
    -- pontos de integracao de TIPO_PRODUTO
    ---------------------------------------------------------
    IF p_ponto_integracao IN ('TIPO_PRODUTO_ADICIONAR')
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Tipo de Entregável só pode ser criado a partir do sistema ' ||
                   r_sis.tipo_integr || '.';
     RAISE v_exception;
    END IF;
    --
    IF p_ponto_integracao IN ('TIPO_PRODUTO_ATUALIZAR')
    THEN
     IF v_recup_param = 0
     THEN
      -- so recupera os parametros na primeira vez
      v_cod_ext_objeto_ant := prox_valor_retornar(v_parametros, v_delimitador);
      v_objeto_ant         := prox_valor_retornar(v_parametros, v_delimitador);
      v_recup_param        := 1;
     END IF;
     --
     SELECT nome,
            rtrim(cod_ext_produto)
       INTO v_objeto,
            v_cod_ext_produto
       FROM tipo_produto
      WHERE tipo_produto_id = v_tipo_produto_id;
     --
     IF v_cod_ext_objeto_ant IS NOT NULL
     THEN
      IF v_cod_ext_objeto_ant <> nvl(v_cod_ext_produto, 'ZZZ999ZZZ')
      THEN
       p_erro_cod := '90000';
       p_erro_msg := 'O código externo desse tipo de produto não pode ser alterado ' ||
                     'pois está integrado com o sistema ' || r_sis.tipo_integr || '.';
       RAISE v_exception;
      END IF;
      --
      IF v_objeto <> v_objeto_ant
      THEN
       p_erro_cod := '90000';
       p_erro_msg := 'O nome desse tipo de produto não pode ser alterado ' ||
                     'pois está integrado com o sistema ' || r_sis.tipo_integr || '.';
       RAISE v_exception;
      END IF;
     END IF;
    END IF;
    --
    IF p_ponto_integracao IN ('TIPO_PRODUTO_EXCLUIR')
    THEN
     --
     SELECT nome,
            rtrim(cod_ext_produto)
       INTO v_objeto,
            v_cod_ext_produto
       FROM tipo_produto
      WHERE tipo_produto_id = v_tipo_produto_id;
     --
     IF v_cod_ext_produto IS NOT NULL
     THEN
      p_erro_cod := '90000';
      p_erro_msg := 'Esse tipo de produto não pode ser excluído pois está integrado ' ||
                    'com o sistema ' || r_sis.tipo_integr || '.';
      RAISE v_exception;
     END IF;
    END IF;
    --
    ---------------------------------------------------------
    -- pontos de integracao de CARTA_ACORDO
    ---------------------------------------------------------
    IF p_ponto_integracao IN
       ('CARTA_ACORDO_ADICIONAR', 'CARTA_ACORDO_ATUALIZAR', 'CARTA_ACORDO_EXCLUIR')
    THEN
     --
     SELECT decode(p_ponto_integracao,
                   'CARTA_ACORDO_ADICIONAR',
                   'I',
                   'CARTA_ACORDO_ATUALIZAR',
                   'A',
                   'CARTA_ACORDO_EXCLUIR',
                   'E')
       INTO v_cod_acao
       FROM dual;
     --
     SELECT cod_ext_carta
       INTO v_cod_ext_carta
       FROM carta_acordo
      WHERE carta_acordo_id = v_carta_acordo_id;
     --
     IF v_cod_ext_carta IS NULL AND v_cod_acao = 'E'
     THEN
      -- exclusao de carta nao integrada. Pula o processamento.
      NULL;
     ELSE
      IF v_cod_ext_carta IS NULL AND v_cod_acao = 'A'
      THEN
       -- alteracao de carta nao integrada. Envia como inclusao.
       v_cod_acao := 'I';
      END IF;
      --
      it_apolo_pkg.carta_acordo_integrar(r_sis.sistema_externo_id,
                                         p_empresa_id,
                                         v_carta_acordo_id,
                                         v_cod_acao,
                                         p_erro_cod,
                                         p_erro_msg);
      --
      IF p_erro_cod <> '00000'
      THEN
       RAISE v_exception;
      END IF;
     END IF;
    END IF; -- fim de CARTA_ACORDO
    --
    ---------------------------------------------------------
    -- pontos de integracao de FATURAMENTO
    ---------------------------------------------------------
    IF p_ponto_integracao IN ('FATURAMENTO_ADICIONAR', 'FATURAMENTO_EXCLUIR')
    THEN
     --
     SELECT decode(p_ponto_integracao, 'FATURAMENTO_ADICIONAR', 'I', 'FATURAMENTO_EXCLUIR', 'E')
       INTO v_cod_acao
       FROM dual;
     --
     SELECT cod_ext_fatur
       INTO v_cod_ext_fatur
       FROM faturamento
      WHERE faturamento_id = v_faturamento_id;
     --
     IF v_cod_ext_fatur IS NULL AND v_cod_acao = 'E'
     THEN
      -- exclusao de faturamento nao integrada. Pula o processamento.
      NULL;
     ELSE
      it_apolo_pkg.faturamento_integrar(r_sis.sistema_externo_id,
                                        p_empresa_id,
                                        v_faturamento_id,
                                        v_cod_acao,
                                        p_erro_cod,
                                        p_erro_msg);
      --
      IF p_erro_cod <> '00000'
      THEN
       RAISE v_exception;
      END IF;
     END IF;
    END IF; -- fim de FATURAMENTO
    --
    ---------------------------------------------------------
    -- pontos de integracao de NOTA_FISCAL
    ---------------------------------------------------------
    IF p_ponto_integracao IN ('NOTA_FISCAL_SAI_EXCLUIR')
    THEN
     --
     SELECT num_doc || ' ' || serie,
            cod_ext_nf
       INTO v_objeto,
            v_cod_ext_nf
       FROM nota_fiscal
      WHERE nota_fiscal_id = v_nota_fiscal_id;
     --
     IF v_cod_ext_nf IS NOT NULL
     THEN
      p_erro_cod := '90000';
      p_erro_msg := 'Esse documento não pode ser ' ||
                    'excluído pois existe integração com o sistema ' || r_sis.tipo_integr || '.';
      RAISE v_exception;
     END IF;
    END IF; -- fim de NOTA_FISCAL
    --
    --
   END IF; -- fim do APOLO
   --
   --
   --
   ------------------------------------------------------------
   --  ****************** CIGAM **************************
   ------------------------------------------------------------
   IF r_sis.tipo_integr = 'CIGAM'
   THEN
    --
    ---------------------------------------------------------
    -- pontos de integracao de PESSOA
    ---------------------------------------------------------
    IF p_ponto_integracao = 'PESSOA_ATUALIZAR_OPCIONAL'
    THEN
     -- atualiza dados no sistema externo se ja integrado, ou inclui caso ainda
     -- nao esteja integrado, desde que o cadastro no JobOne esteja completo.
     --
     SELECT apelido
       INTO v_objeto
       FROM pessoa
      WHERE pessoa_id = v_pessoa_id;
     --
     SELECT MAX(rtrim(cod_ext_pessoa))
       INTO v_cod_ext_pessoa
       FROM pessoa_sist_ext
      WHERE sistema_externo_id = r_sis.sistema_externo_id
        AND pessoa_id = v_pessoa_id;
     --
     IF v_cod_ext_pessoa IS NOT NULL
     THEN
      -- cliente/fornecedor ja integrado. Pode mandar.
      it_cigam_pkg.pessoa_integrar(r_sis.sistema_externo_id,
                                   p_empresa_id,
                                   v_pessoa_id,
                                   'A',
                                   p_erro_cod,
                                   p_erro_msg);
      --
      IF p_erro_cod <> '00000'
      THEN
       RAISE v_exception;
      END IF;
     ELSIF pessoa_pkg.dados_integr_verificar(v_pessoa_id) = 1
     THEN
      -- cliente/fornecedor com dados completos. Tanta mandar como inclusao.
      it_cigam_pkg.pessoa_integrar(r_sis.sistema_externo_id,
                                   p_empresa_id,
                                   v_pessoa_id,
                                   'I',
                                   p_erro_cod,
                                   p_erro_msg);
      --
      IF p_erro_cod <> '00000'
      THEN
       -- deu erro. Tenta mandar como alteracao.
       -- salva a mensagem retornada.
       v_erro_msg := p_erro_msg;
       --
       it_cigam_pkg.pessoa_integrar(r_sis.sistema_externo_id,
                                    p_empresa_id,
                                    v_pessoa_id,
                                    'A',
                                    p_erro_cod,
                                    p_erro_msg);
       --
       IF p_erro_cod <> '00000'
       THEN
        p_erro_msg := v_erro_msg || ' ; ' || p_erro_msg;
        RAISE v_exception;
       END IF;
      END IF;
     END IF;
    END IF; -- fim de PESSOA_ATUALIZAR_OPCIONAL
    --
    --
    IF p_ponto_integracao = 'PESSOA_ATUALIZAR'
    THEN
     -- atualiza dados no sistema externo se ja integrado, ou inclui caso ainda
     -- nao esteja integrado.
     --
     SELECT apelido
       INTO v_objeto
       FROM pessoa
      WHERE pessoa_id = v_pessoa_id;
     --
     SELECT MAX(rtrim(cod_ext_pessoa))
       INTO v_cod_ext_pessoa
       FROM pessoa_sist_ext
      WHERE sistema_externo_id = r_sis.sistema_externo_id
        AND pessoa_id = v_pessoa_id;
     --
     IF pessoa_pkg.dados_integr_verificar(v_pessoa_id) = 0
     THEN
      p_erro_cod := '90000';
      p_erro_msg := 'Os dados da empresa estão incompletos ou inconsistentes ' ||
                    'para integração com o CIGAM (' || v_objeto || ').';
      RAISE v_exception;
     END IF;
     --
     IF v_cod_ext_pessoa IS NOT NULL
     THEN
      -- cliente/fornecedor ja integrado. Pode mandar
      it_cigam_pkg.pessoa_integrar(r_sis.sistema_externo_id,
                                   p_empresa_id,
                                   v_pessoa_id,
                                   'A',
                                   p_erro_cod,
                                   p_erro_msg);
      --
      IF p_erro_cod <> '00000'
      THEN
       RAISE v_exception;
      END IF;
     ELSE
      -- cliente/fornecedor com dados completos. Tanta mandar como inclusao.
      it_cigam_pkg.pessoa_integrar(r_sis.sistema_externo_id,
                                   p_empresa_id,
                                   v_pessoa_id,
                                   'I',
                                   p_erro_cod,
                                   p_erro_msg);
      --
      IF p_erro_cod <> '00000'
      THEN
       -- deu erro. Tenta mandar como alteracao.
       -- salva a mensagem retornada.
       v_erro_msg := p_erro_msg;
       --
       it_cigam_pkg.pessoa_integrar(r_sis.sistema_externo_id,
                                    p_empresa_id,
                                    v_pessoa_id,
                                    'A',
                                    p_erro_cod,
                                    p_erro_msg);
       --
       IF p_erro_cod <> '00000'
       THEN
        p_erro_msg := v_erro_msg || ' ; ' || p_erro_msg;
        RAISE v_exception;
       END IF;
      END IF;
     END IF;
    END IF; -- fim de PESSOA_ATUALIZAR
    --
    --
    IF p_ponto_integracao = 'PESSOA_EXCLUIR'
    THEN
     -- exclui dados do sistema externo se ja estiver integrado.
     --
     SELECT apelido
       INTO v_objeto
       FROM pessoa
      WHERE pessoa_id = v_pessoa_id;
     --
     SELECT MAX(rtrim(cod_ext_pessoa))
       INTO v_cod_ext_pessoa
       FROM pessoa_sist_ext
      WHERE sistema_externo_id = r_sis.sistema_externo_id
        AND pessoa_id = v_pessoa_id;
     --
     IF v_cod_ext_pessoa IS NOT NULL
     THEN
      -- pessoa ja integrada. Precisa excluir no sistema externo.
      it_cigam_pkg.pessoa_integrar(r_sis.sistema_externo_id,
                                   p_empresa_id,
                                   v_pessoa_id,
                                   'E',
                                   p_erro_cod,
                                   p_erro_msg);
      --
      IF p_erro_cod <> '00000'
      THEN
       RAISE v_exception;
      END IF;
     END IF;
    END IF; -- fim de PESSOA_EXCLUIR
    --
    ---------------------------------------------------------
    -- pontos de integracao de JOB
    ---------------------------------------------------------
    IF p_ponto_integracao IN ('JOB_ADICIONAR', 'JOB_ATUALIZAR', 'JOB_EXCLUIR')
    THEN
     --
     SELECT decode(p_ponto_integracao,
                   'JOB_ADICIONAR',
                   'I',
                   'JOB_ATUALIZAR',
                   'A',
                   'JOB_EXCLUIR',
                   'E')
       INTO v_cod_acao
       FROM dual;
     --
     SELECT cod_ext_job,
            status
       INTO v_cod_ext_job,
            v_status_job
       FROM job
      WHERE job_id = v_job_id;
     --
     IF v_cod_ext_job IS NULL AND v_cod_acao IN ('E')
     THEN
      -- exclusao/cancelamento de job nao integrado. Pula o processamento.
      NULL;
     ELSE
      IF v_cod_ext_job IS NULL AND v_cod_acao = 'A'
      THEN
       -- alteracao de job nao integrado. Envia como inclusao.
       v_cod_acao := 'I';
      END IF;
      --
      it_cigam_pkg.job_integrar(r_sis.sistema_externo_id,
                                p_empresa_id,
                                v_job_id,
                                v_cod_acao,
                                p_erro_cod,
                                p_erro_msg);
      --
      IF p_erro_cod <> '00000'
      THEN
       RAISE v_exception;
      END IF;
     END IF;
    END IF; -- fim de JOB
    --
    ---------------------------------------------------------
    -- pontos de integracao de ORCAMENTO (integra como job/projeto)
    ---------------------------------------------------------
    IF p_ponto_integracao IN ('ORCAMENTO_ADICIONAR', 'ORCAMENTO_ATUALIZAR', 'ORCAMENTO_EXCLUIR')
    THEN
     --
     SELECT decode(p_ponto_integracao,
                   'ORCAMENTO_ADICIONAR',
                   'I',
                   'ORCAMENTO_ATUALIZAR',
                   'A',
                   'ORCAMENTO_EXCLUIR',
                   'E')
       INTO v_cod_acao
       FROM dual;
     --
     SELECT cod_ext_orcam
       INTO v_cod_ext_orcam
       FROM orcamento
      WHERE orcamento_id = v_orcamento_id;
     --
     IF v_cod_ext_orcam IS NULL AND v_cod_acao IN ('E')
     THEN
      -- exclusao de orcamento nao integrado. Pula o processamento.
      NULL;
     ELSE
      IF v_cod_ext_orcam IS NULL AND v_cod_acao = 'A'
      THEN
       -- alteracao de orcamento nao integrado. Envia como inclusao.
       v_cod_acao := 'I';
      END IF;
      --
      it_cigam_pkg.orcamento_integrar(r_sis.sistema_externo_id,
                                      p_empresa_id,
                                      v_orcamento_id,
                                      v_cod_acao,
                                      p_erro_cod,
                                      p_erro_msg);
      --
      IF p_erro_cod <> '00000'
      THEN
       RAISE v_exception;
      END IF;
     END IF;
    END IF; -- fim de ORCAMENTO
    --
    ---------------------------------------------------------
    -- pontos de integracao de FATURAMENTO
    ---------------------------------------------------------
    IF p_ponto_integracao IN ('FATURAMENTO_ADICIONAR', 'FATURAMENTO_EXCLUIR')
    THEN
     --
     SELECT decode(p_ponto_integracao, 'FATURAMENTO_ADICIONAR', 'I', 'FATURAMENTO_EXCLUIR', 'E')
       INTO v_cod_acao
       FROM dual;
     --
     SELECT cod_ext_fatur
       INTO v_cod_ext_fatur
       FROM faturamento
      WHERE faturamento_id = v_faturamento_id;
     --
     IF v_cod_ext_fatur IS NULL AND v_cod_acao = 'E'
     THEN
      -- exclusao de faturamento nao integrada. Pula o processamento.
      NULL;
     ELSE
      it_cigam_pkg.faturamento_integrar(r_sis.sistema_externo_id,
                                        p_empresa_id,
                                        v_faturamento_id,
                                        v_cod_acao,
                                        p_erro_cod,
                                        p_erro_msg);
      --
      IF p_erro_cod <> '00000'
      THEN
       RAISE v_exception;
      END IF;
     END IF;
    END IF; -- fim de FATURAMENTO
    --
    ---------------------------------------------------------
    -- pontos de integracao de NOTA_FISCAL de ENTRADA
    ---------------------------------------------------------
    IF p_ponto_integracao IN ('NOTA_FISCAL_ENT_ADICIONAR', 'NOTA_FISCAL_ENT_EXCLUIR')
    THEN
     --
     SELECT decode(p_ponto_integracao,
                   'NOTA_FISCAL_ENT_ADICIONAR',
                   'I',
                   'NOTA_FISCAL_ENT_EXCLUIR',
                   'E')
       INTO v_cod_acao
       FROM dual;
     --
     SELECT num_doc || ' ' || serie,
            rtrim(cod_ext_nf),
            flag_pago_cliente
       INTO v_objeto,
            v_cod_ext_nf,
            v_flag_pago_cliente
       FROM nota_fiscal
      WHERE nota_fiscal_id = v_nota_fiscal_id;
     --
     IF v_cod_ext_nf IS NULL AND v_cod_acao = 'E'
     THEN
      -- exclusao de NF nao integrada. Pula o processamento.
      NULL;
     ELSIF v_flag_pago_cliente = 'S'
     THEN
      -- NF paga pelo cliente. Pula o processamento
      NULL;
     ELSE
      it_cigam_pkg.nf_entrada_integrar(r_sis.sistema_externo_id,
                                       p_empresa_id,
                                       v_nota_fiscal_id,
                                       v_cod_acao,
                                       p_erro_cod,
                                       p_erro_msg);
     END IF;
     --
     IF p_erro_cod <> '00000'
     THEN
      RAISE v_exception;
     END IF;
    END IF; -- fim de NOTA_FISCAL_ENT
    --
    ---------------------------------------------------------
    -- pontos de integracao de NOTA_FISCAL SAIDA
    ---------------------------------------------------------
    /* comentado para deixar excluir mesmo existindo a integracao
    IF p_ponto_integracao IN ('NOTA_FISCAL_SAI_EXCLUIR') THEN
       --
       SELECT num_doc || ' ' || serie,
              cod_ext_nf
         INTO v_objeto,
              v_cod_ext_nf
         FROM nota_fiscal
        WHERE nota_fiscal_id = v_nota_fiscal_id;
       --
       IF v_cod_ext_nf IS NOT NULL THEN
          p_erro_cod := '90000';
          p_erro_msg := 'Esse documento não pode ser ' ||
                        'excluído pois existe integração com o sistema ' || r_sis.tipo_integr || '.';
          RAISE v_exception;
       END IF;
       --
    END IF; -- fim de NOTA_FISCAL SAIDA
    */
    --
    --
   END IF; -- fim do CIGAM
   --
   --
   --
   ------------------------------------------------------------
   --     ****************** PORTO **************************
   ------------------------------------------------------------
   IF r_sis.tipo_integr = 'PORTO'
   THEN
    --
    ---------------------------------------------------------
    -- pontos de integracao de JOB
    ---------------------------------------------------------
    IF p_ponto_integracao IN ('JOB_MCV_NOTIFICAR')
    THEN
     --
     SELECT ti.codigo
       INTO v_cod_tipo_job
       FROM job      jo,
            tipo_job ti
      WHERE jo.job_id = v_job_id
        AND jo.tipo_job_id = ti.tipo_job_id;
     --
     -- verifica se precisa notificar o JOB
     IF v_cod_tipo_job IN ('MCV', 'CCVV', 'MIM')
     THEN
      it_porto_pkg.job_integrar(r_sis.sistema_externo_id,
                                p_empresa_id,
                                v_job_id,
                                'I',
                                p_erro_cod,
                                p_erro_msg);
      --
      IF p_erro_cod <> '00000'
      THEN
       RAISE v_exception;
      END IF;
     END IF;
    END IF; -- fim de JOB
    --
    ---------------------------------------------------------
    -- pontos de integracao de ORDEM_SERVICO
    ---------------------------------------------------------
    IF p_ponto_integracao IN ('ORDEM_SERVICO_MCV_NOTIFICAR')
    THEN
     --
     SELECT jo.job_id,
            ti.codigo
       INTO v_job_id,
            v_cod_tipo_job
       FROM ordem_servico os,
            job           jo,
            tipo_job      ti
      WHERE os.ordem_servico_id = v_ordem_servico_id
        AND os.job_id = jo.job_id
        AND jo.tipo_job_id = ti.tipo_job_id;
     --
     -- verifica se precisa notificar a OS
     IF v_cod_tipo_job IN ('MCV', 'CCVV', 'MIM')
     THEN
      it_porto_pkg.ordem_servico_integrar(r_sis.sistema_externo_id,
                                          p_empresa_id,
                                          v_ordem_servico_id,
                                          'I',
                                          p_erro_cod,
                                          p_erro_msg);
      --
      IF p_erro_cod <> '00000'
      THEN
       RAISE v_exception;
      END IF;
     END IF;
    END IF; -- fim de ORDEM_SERVICO
    --
    ---------------------------------------------------------
    -- pontos de integracao de COMENTARIO
    ---------------------------------------------------------
    IF p_ponto_integracao IN ('COMENTARIO_MCV_NOTIFICAR')
    THEN
     SELECT ti.codigo,
            co.objeto_id
       INTO v_cod_tipo_obj,
            v_coment_obj_id
       FROM comentario  co,
            tipo_objeto ti
      WHERE co.comentario_id = v_comentario_id
        AND co.tipo_objeto_id = ti.tipo_objeto_id;
     --
     IF v_cod_tipo_obj = 'JOB'
     THEN
      v_job_id := v_coment_obj_id;
      --
      SELECT ti.codigo
        INTO v_cod_tipo_job
        FROM job      jo,
             tipo_job ti
       WHERE jo.job_id = v_job_id
         AND jo.tipo_job_id = ti.tipo_job_id;
     ELSIF v_cod_tipo_obj = 'ORDEM_SERVICO'
     THEN
      v_ordem_servico_id := v_coment_obj_id;
      --
      SELECT ti.codigo
        INTO v_cod_tipo_job
        FROM ordem_servico os,
             job           jo,
             tipo_job      ti
       WHERE os.ordem_servico_id = v_ordem_servico_id
         AND os.job_id = jo.job_id
         AND jo.tipo_job_id = ti.tipo_job_id;
     END IF;
     --
     -- verifica se precisa notificar o COMENTARIO
     IF v_cod_tipo_job IN ('MCV', 'CCVV', 'MIM')
     THEN
      it_porto_pkg.comentario_integrar(r_sis.sistema_externo_id,
                                       p_empresa_id,
                                       v_comentario_id,
                                       'I',
                                       p_erro_cod,
                                       p_erro_msg);
      --
      IF p_erro_cod <> '00000'
      THEN
       RAISE v_exception;
      END IF;
     END IF;
    END IF; -- fim de JOB
    --
    --
   END IF; -- fim do PORTO
  END LOOP;
  --
  --
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   NULL;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := 'IT_CONTROLE_PKG: ' ||
                 substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 2000);
 END integrar;
END; -- IT_CONTROLE_PKG

/
