--------------------------------------------------------
--  DDL for Package Body USUARIO_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "USUARIO_PKG" IS
 --
 g_key_str2 VARCHAR2(20) := '8UzpL2!R)12kX+jA';
 --
 FUNCTION priv_verificar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 06/10/2004
  -- DESCRICAO: verifica se foi concedido determinado privilegio a um usuario (via papel).
  --  O tipo de privilegio e' definido pelo parametro "p_codigo". O parametro "p_objeto_id"
  --  indica o objeto sobre o qual o privilegio deve ser verificado, e so' e' utilizado em
  --  alguns tipos de privilegio (PESSOA e grupo JOBEND, DOCEND, OSEND, ORCEND).
  --
  --  O parametro p_outros e' opcional e serve para casos especiais como DOCUMENTO, em que
  --  o tipo de documento tb deve ser passado. Para OS, o tipo de OS deve ser passado. Para
  --  carta acordo/nota fiscal multijob, o carta_acordo_id/nota_fiscal_id deve ser passado.
  --  Para criar job, o tipo_job_id deve ser passado.
  --
  --  Retorna '1' caso o usuario possua o privilegio ou '0', caso nao.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            08/11/2006  Alteracao de alocacao de supervisor (passou para a tabela
  --                               alocacao), resultando em alteracao de select que verifica
  --                               enderecamento implicito de supervisor.
  -- Silvia            01/08/2007  Alteracao de consistencias para alteracao de pessoa.
  -- Silvia            09/04/2008  Privilegios por tipo de documento (novo grupo DOCEND)
  -- Silvia            04/07/2008  Tratamento especifico para privilegios de POST.
  -- Silvia            13/04/2010  O privilegio da OS passou a usar o enderecamento do JOB.
  -- Silvia            14/04/2010  Novo parametro p/ receber empresa_id.
  -- Silvia            20/07/2012  Privilegios por tipo de OS flexiveis, via p_outros.
  -- Silvia            04/04/2013  Atributo de tipo_pessoa renomeado (flag_especial para
  --                               flag_trata_base). Novo atributo flag_trata_contato.
  -- Silvia            24/11/2014  Tratamento especial para carta acordo multijob.
  -- Silvia            13/04/2015  Tratamento especial para NF multijob.
  -- Silvia            06/05/2015  Privilegios de ender. por area (novo grupo ENDERECAR)
  -- Silvia            11/06/2015  Privilegios dos grupos END passaram a obrigar o papel
  --                               com esse privilegio no enderecamento do job.
  -- Silvia            01/07/2015  Novo parametro de empresa USAR_PRIV_PAPEL_ENDER
  -- Silvia            01/09/2015  Tratamento para tipo_os_id nulo.
  -- Silvia            21/12/2015  Tratamento para privilegio JOB_I.
  -- Silvia            01/06/2016  Tratamento para privilegio JOB_TIPO_FIN_C.
  -- Silvia            21/10/2016  Nova coluna abrangencia no lugar de flag_todos_obj. Novo
  --                               grupo ORCEND. Remocao do parametro USAR_PRIV_PAPEL_ENDER.
  -- Silvia            26/12/2016  Teste priv JOBONE_CLI_V (acessar interface de clientes)
  --                               antes de testar enderecamento implicito (JOBEND).
  -- Silvia            16/08/2017  Tratamnento de JOB_CONC (restricao).
  -- Silvia            14/11/2017  Remocao de privilegio JOBONE_CLI_V.
  -- Silvia            13/07/2018  Alteracao no teste de JOBEND com acesso a interface do
  --                               cliente (so testa contato se nao tem acesso a interface
  --                               principal).
  -- Silvia            09/10/2018  Remocao do modulo de casting.
  -- Silvia            06/03/2019  Novo grupo OPORTUNEND
  -- Silvia            18/05/2020  Quebra galho para deixar enderecar usuario em area de
  --                               outra empresa.
  -- Ana Luiza         27/10/2023  Ajustado novos grupos de enderecamento de contrato e
  --                               oportunidade
  -- Joel Dias         30/07/2023  Negar privilégio para alterar usuario ou pessoa
  --                               do usuário com flag_admin_sistema = S
  ------------------------------------------------------------------------------------------
  p_usuario_sessao_id IN usuario.usuario_id%TYPE,
  p_codigo            IN privilegio.codigo%TYPE,
  p_objeto_id         IN NUMBER,
  p_outros            IN VARCHAR2,
  p_empresa_id        IN NUMBER
 ) RETURN INTEGER AS
  v_ret                 INTEGER;
  v_qt                  INTEGER;
  v_flag_admin          usuario.flag_admin%TYPE;
  v_flag_ativo          usuario.flag_ativo%TYPE;
  v_abrangencia         papel_priv.abrangencia%TYPE;
  v_grupo               privilegio.grupo%TYPE;
  v_codigo_priv         privilegio.codigo%TYPE;
  v_pessoa_sessao_id    pessoa.pessoa_id%TYPE;
  v_cliente_id          job.cliente_id%TYPE;
  v_job_id              job.job_id%TYPE;
  v_tipo_job_id         job.tipo_job_id%TYPE;
  v_tipo_financeiro_id  job.tipo_financeiro_id%TYPE;
  v_tipo_os_id          ordem_servico.tipo_os_id%TYPE;
  v_tipo_documento_id   documento.tipo_documento_id%TYPE;
  v_carta_acordo_id     carta_acordo.carta_acordo_id%TYPE;
  v_nota_fiscal_id      nota_fiscal.nota_fiscal_id%TYPE;
  v_area_id             area.area_id%TYPE;
  v_orcamento_id        orcamento.orcamento_id%TYPE;
  v_tem_restricao       INTEGER;
  v_flag_restringe_conc VARCHAR2(100);
  v_empresa_area_id     area.empresa_id%TYPE;
  v_objeto_id           NUMBER;
  --
  -- estimativas da carta acordo
  CURSOR c_ca IS
   SELECT DISTINCT it.orcamento_id
     FROM item_carta ic,
          item       it
    WHERE ic.carta_acordo_id = v_carta_acordo_id
      AND ic.item_id = it.item_id;
  --
  -- estimativas da nota fiscal
  CURSOR c_nf IS
   SELECT DISTINCT it.orcamento_id
     FROM item_nota io,
          item      it
    WHERE io.nota_fiscal_id = v_nota_fiscal_id
      AND io.item_id = it.item_id;
  --
 BEGIN
  v_ret := 0;
  --
  ------------------------------------------------------------
  -- testes iniciais
  ------------------------------------------------------------
  IF p_codigo = 'JOB_CONC' THEN
   -- conclusao de job.
   -- verifica se precisa restringir esse priv ao responsavel interno
   v_flag_restringe_conc := empresa_pkg.parametro_retornar(p_empresa_id, 'FLAG_RESTRINGE_CONC_JOB');
  ELSE
   v_flag_restringe_conc := 'N';
  END IF;
  --
  -- verifica o tipo de usuario
  SELECT flag_admin,
         flag_ativo
    INTO v_flag_admin,
         v_flag_ativo
    FROM usuario
   WHERE usuario_id = p_usuario_sessao_id;
  --
  -- usuario administrador pode tudo.
  IF v_flag_admin = 'S' THEN
   v_ret := 1;
   RETURN v_ret;
  END IF;
  --
  -- usuario inativo nao tem privilegio.
  IF v_flag_ativo = 'N' THEN
   v_ret := 0;
   RETURN v_ret;
  END IF;
  --
  -- tratamento especial p/ o codigo de privilegio virtual PESSOA_A
  IF p_codigo = 'PESSOA_A' THEN
   v_codigo_priv := 'PESSOA_C';
  ELSE
   v_codigo_priv := p_codigo;
  END IF;
  --
  SELECT grupo
    INTO v_grupo
    FROM privilegio
   WHERE codigo = v_codigo_priv;
  --
  IF v_codigo_priv IN ('PESSOA_C') THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM pessoa p
    INNER JOIN usuario u
       ON u.usuario_id = p.pessoa_id
    WHERE u.flag_admin_sistema = 'S'
      AND p.pessoa_id = p_objeto_id;
   --
   IF v_qt > 0 THEN
    v_ret := 0;
    RETURN v_ret;
   END IF;
  END IF;
  --
  IF v_codigo_priv = 'USUARIO_C' THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM usuario u
    WHERE u.flag_admin_sistema = 'S'
      AND u.usuario_id = p_objeto_id;
   --
   IF v_qt > 0 THEN
    v_ret := 0;
    RETURN v_ret;
   END IF;
  END IF;
  --
  -- tratamento especial para carta acordo
  v_carta_acordo_id := 0;
  IF v_codigo_priv LIKE 'CARTA_ACORDO%' AND nvl(p_objeto_id, 0) = 0 AND TRIM(p_outros) IS NOT NULL THEN
   -- carta acordo enviada (o orcamento_id enviado via objeto_id nao vem e o
   -- carta_acordo_id vem em outros)
   v_carta_acordo_id := nvl(to_number(p_outros), 0);
  END IF;
  --
  -- tratamento especial para nota fiscal
  v_nota_fiscal_id := 0;
  IF v_codigo_priv LIKE 'NOTA_FISCAL%' AND nvl(p_objeto_id, 0) = 0 AND TRIM(p_outros) IS NOT NULL THEN
   -- nota fiscal enviada (o orcamento_id enviado via objeto_id nao vem e o
   -- nota_fiscal_id vem em outros)
   v_nota_fiscal_id := nvl(to_number(p_outros), 0);
  END IF;
  --
  -----------------------------------------------------------
  -- verifica se os papeis do usuario garantem privilegio
  -- para realizar a operacao.
  -----------------------------------------------------------
  SELECT COUNT(*),
         to_char(MAX(pp.abrangencia))
    INTO v_qt,
         v_abrangencia
    FROM usuario_papel up,
         papel_priv    pp,
         privilegio    pr,
         papel         pa
   WHERE up.usuario_id = p_usuario_sessao_id
     AND up.papel_id = pa.papel_id
     AND pa.empresa_id = p_empresa_id
     AND up.papel_id = pp.papel_id
     AND pp.privilegio_id = pr.privilegio_id
     AND pr.codigo = v_codigo_priv;
  --
  IF v_qt = 0 THEN
   -- usuario nao tem privilegio
   v_ret := 0;
   RETURN v_ret;
  END IF;
  --
  -----------------------------------------------------------
  -- usuario tem privilegio sobre qualquer objeto, sem
  -- necessidade de se verificar enderecamento ou tipo de pessoa
  -----------------------------------------------------------
  IF v_abrangencia = 'T' THEN
   v_ret := 1;
   RETURN v_ret;
  END IF;
  --
  IF v_abrangencia <> 'T' AND
     v_grupo NOT IN ('JOBEND',
                     'OSEND',
                     'DOCEND',
                     'CONTRATOEND',
                     'ENDERECAR',
                     'ORCEND',
                     'OPORTUNEND',
                     'CONTRATOENDERAREA',
                     'OPORTUNENDERAREA') AND v_codigo_priv NOT LIKE 'PESSOA_%' AND
     v_codigo_priv NOT IN ('JOB_I', 'JOB_IA', 'JOB_TIPO_FIN_C') THEN
   -- o 'P' foi gravado por padrao na tabela papel_priv.
   -- Nao precisa testar enderecamento ou demais restricoes.
   v_ret := 1;
   RETURN v_ret;
  END IF;
  --
  -----------------------------------------------------------
  -- usuario tem privilegio apenas sobre alguns objetos
  -----------------------------------------------------------
  IF nvl(p_objeto_id, 0) = 0 AND
     v_grupo NOT IN ('OSEND', 'DOCEND', 'ENDERECAR', 'CONTRATOENDERAREA', 'OPORTUNENDERAREA') AND
     v_carta_acordo_id = 0 AND v_nota_fiscal_id = 0 AND
     v_codigo_priv NOT IN ('JOB_I', 'JOB_IA', 'JOB_TIPO_FIN_C') THEN
   -- caso o objeto nao tenha sido especificado, retorna OK. Excecoes:
   -- 1- no caso de OS,DOCUMENTO,ou ENDERECAR ainda precisa testar o respectivo tipo
   -- 2- no caso de carta acordo enviada, precisa testar enderecamentos
   -- 3- no caso de nota fiscal enviada, precisa testar enderecamentos
   -- 4- no caso de inclusao de job, precisa testar o tipo de job
   -- 5- no caso e indicacao de tipo financeiro, precisa testar o tipo financeiro
   v_ret := 1;
   RETURN v_ret;
  END IF;
  --
  -----------------------------------------------------------
  -- tratamento especifico p/ CRIAR JOB
  -----------------------------------------------------------
  IF v_codigo_priv IN ('JOB_I', 'JOB_IA') THEN
   v_tipo_job_id := nvl(to_number(p_outros), 0);
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM usuario_papel   up,
          papel_priv_tjob pp,
          privilegio      pr,
          papel           pa
    WHERE up.usuario_id = p_usuario_sessao_id
      AND up.papel_id = pa.papel_id
      AND pa.empresa_id = p_empresa_id
      AND up.papel_id = pp.papel_id
      AND pp.privilegio_id = pr.privilegio_id
      AND pr.codigo = v_codigo_priv
      AND pp.tipo_job_id = v_tipo_job_id;
   --
   IF v_qt = 0 THEN
    -- usuario nao tem privilegio para esse tipo de job
    v_ret := 0;
    RETURN v_ret;
   ELSE
    v_ret := 1;
    RETURN v_ret;
   END IF;
  END IF; -- fim do IF v_codigo_priv IN ('JOB_I','JOB_IA')
  --
  -----------------------------------------------------------
  -- tratamento especifico p/ indicar tipo financeiro
  -----------------------------------------------------------
  IF v_codigo_priv = 'JOB_TIPO_FIN_C' THEN
   v_tipo_financeiro_id := nvl(to_number(p_outros), 0);
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM usuario_papel   up,
          papel_priv_tfin pp,
          privilegio      pr,
          papel           pa
    WHERE up.usuario_id = p_usuario_sessao_id
      AND up.papel_id = pa.papel_id
      AND pa.empresa_id = p_empresa_id
      AND up.papel_id = pp.papel_id
      AND pp.privilegio_id = pr.privilegio_id
      AND pr.codigo = v_codigo_priv
      AND pp.tipo_financeiro_id = v_tipo_financeiro_id;
   --
   IF v_qt = 0 THEN
    -- usuario nao tem privilegio para esse tipo financeiro
    v_ret := 0;
    RETURN v_ret;
   ELSE
    v_ret := 1;
    RETURN v_ret;
   END IF;
  END IF; -- fim do IF v_codigo_priv = 'JOB_TIPO_FIN_C'
  --
  -----------------------------------------------------------
  -- tratamento especifico p/ PESSOA, qdo o usuario nao tem o
  -- privilegio de ver/configurar TODOS os tipos existentes.
  -----------------------------------------------------------
  v_tem_restricao := 0;
  --
  IF v_codigo_priv IN ('PESSOA_V', 'PESSOA_C') OR p_codigo = 'PESSOA_A' THEN
   --
   -- verifica se a pessoa esta associada a algum tipo com restricoes de acesso
   SELECT COUNT(*)
     INTO v_qt
     FROM tipific_pessoa tp,
          tipo_pessoa    t
    WHERE tp.pessoa_id = p_objeto_id
      AND tp.tipo_pessoa_id = t.tipo_pessoa_id
      AND t.flag_trata_contato = 'S';
   --
   IF v_qt > 0 THEN
    v_tem_restricao := 1;
   END IF;
   --
   IF v_codigo_priv = 'PESSOA_C' THEN
    -- precisa de um teste mais rigido, pois permite criar e excluir a pessoa.
    -- verifica se a pessoa esta' tipificada.
    SELECT COUNT(*)
      INTO v_qt
      FROM tipific_pessoa tp
     WHERE tp.pessoa_id = p_objeto_id;
    --
    IF v_qt = 0 THEN
     -- pessoa nao tem tipo. Acesso negado.
     v_ret := 0;
     RETURN v_ret;
    END IF;
    --
    -- verifica se o usuario tem privilegio de configurar TODOS os
    -- tipos dessa pessoa.
    SELECT COUNT(*)
      INTO v_qt
      FROM tipific_pessoa tp,
           tipo_pessoa    t
     WHERE tp.pessoa_id = p_objeto_id
       AND tp.tipo_pessoa_id = t.tipo_pessoa_id
       AND NOT EXISTS (SELECT 1
              FROM usuario_papel      up,
                   papel_priv_tpessoa pp,
                   privilegio         pr,
                   papel              pa
             WHERE up.usuario_id = p_usuario_sessao_id
               AND up.papel_id = pa.papel_id
               AND pa.empresa_id = p_empresa_id
               AND up.papel_id = pp.papel_id
               AND pp.privilegio_id = pr.privilegio_id
               AND pr.codigo = v_codigo_priv
               AND pp.tipo_pessoa_id = tp.tipo_pessoa_id);
    --
    IF v_qt > 0 THEN
     -- nao tem privilegio sobre algum dos tipos. Acesso negado.
     v_ret := 0;
     RETURN v_ret;
    END IF;
    --
    IF v_tem_restricao = 0 THEN
     -- nao tem restricoes. Acesso liberado.
     v_ret := 1;
     RETURN v_ret;
    END IF;
   END IF; -- fim do IF v_codigo_priv = 'PESSOA_C'
   --
   -- verifica se o usuario tem privilegio de ver/alterar pelo menos um dos
   -- tipos dessa pessoa, sem restricoes (de base, de contato).
   SELECT COUNT(*)
     INTO v_qt
     FROM tipific_pessoa tp
    WHERE tp.pessoa_id = p_objeto_id
      AND EXISTS (SELECT 1
             FROM usuario_papel      up,
                  papel_priv_tpessoa pp,
                  privilegio         pr,
                  papel              pa
            WHERE up.usuario_id = p_usuario_sessao_id
              AND up.papel_id = pa.papel_id
              AND pa.empresa_id = p_empresa_id
              AND up.papel_id = pp.papel_id
              AND pp.privilegio_id = pr.privilegio_id
              AND pr.codigo = v_codigo_priv
              AND pp.tipo_pessoa_id = tp.tipo_pessoa_id
              AND pp.abrangencia = 'T');
   --
   IF v_qt > 0 THEN
    v_ret := 1;
    RETURN v_ret;
   END IF;
   --
   -- verifica se o usuario tem privilegio de ver/alterar pelo menos um dos
   -- tipos dessa pessoa, com restricoes de contato
   SELECT COUNT(*)
     INTO v_qt
     FROM tipific_pessoa tp,
          tipo_pessoa    t
    WHERE tp.pessoa_id = p_objeto_id
      AND tp.tipo_pessoa_id = t.tipo_pessoa_id
      AND t.flag_trata_contato = 'S'
      AND EXISTS (SELECT 1
             FROM usuario_papel      up,
                  papel_priv_tpessoa pp,
                  privilegio         pr,
                  papel              pa
            WHERE up.usuario_id = p_usuario_sessao_id
              AND up.papel_id = pa.papel_id
              AND pa.empresa_id = p_empresa_id
              AND up.papel_id = pp.papel_id
              AND pp.privilegio_id = pr.privilegio_id
              AND pr.codigo = v_codigo_priv
              AND pp.tipo_pessoa_id = tp.tipo_pessoa_id
              AND pp.abrangencia = 'P');
   --
   IF v_qt > 0 THEN
    -- usuario pode ver/alterar apenas se a pessoa for contato
    SELECT COUNT(*)
      INTO v_qt
      FROM relacao
     WHERE pessoa_filho_id = p_objeto_id;
    --
    IF v_qt > 0 THEN
     -- a pessoa eh contato. Acesso liberado.
     v_ret := 1;
     RETURN v_ret;
    ELSE
     -- a pessoa nao eh contato. Acesso negado.
     v_ret := 0;
     RETURN v_ret;
    END IF;
   END IF;
  END IF; -- fim do v_codigo_priv IN ('PESSOA_V','PESSOA_C') OR p_codigo = 'PESSOA_A'
  --
  -----------------------------------------------------------
  -- tratamento especifico p/ ORDEM_SERVICO
  -----------------------------------------------------------
  IF v_grupo = 'OSEND' THEN
   v_job_id     := nvl(p_objeto_id, 0);
   v_tipo_os_id := nvl(to_number(p_outros), 0);
   --
   IF v_job_id = 0 AND v_tipo_os_id = 0 THEN
    v_ret := 1;
    RETURN v_ret;
   END IF;
   --
   IF v_tipo_os_id > 0 THEN
    -- o tipo de OS foi especificado.
    SELECT COUNT(*),
           to_char(MAX(pp.abrangencia))
      INTO v_qt,
           v_abrangencia
      FROM usuario_papel  up,
           papel_priv_tos pp,
           privilegio     pr,
           papel          pa
     WHERE up.usuario_id = p_usuario_sessao_id
       AND up.papel_id = pa.papel_id
       AND pa.empresa_id = p_empresa_id
       AND up.papel_id = pp.papel_id
       AND pp.privilegio_id = pr.privilegio_id
       AND pr.codigo = v_codigo_priv
       AND pp.tipo_os_id = v_tipo_os_id;
    --
    IF v_qt = 0 THEN
     -- usuario nao tem privilegio para esse tipo de OS
     v_ret := 0;
     RETURN v_ret;
    END IF;
    --
    IF v_abrangencia = 'T' THEN
     -- usuario tem privilegio, independente do enderecamento do job
     v_ret := 1;
     RETURN v_ret;
    END IF;
   ELSE
    -- o tipo de OS nao foi especificado.
    -- continua os testes de enderecamento
    NULL;
   END IF;
   --
   --
   IF v_job_id = 0 THEN
    -- nao eh para testar o enderecamento (usado em links do menu)
    v_ret := 1;
    RETURN v_ret;
   END IF;
   --
   -- verifica se o job da OS esta' enderecado para o usuario.
   SELECT COUNT(*)
     INTO v_qt
     FROM job_usuario
    WHERE usuario_id = p_usuario_sessao_id
      AND job_id = v_job_id;
   --
   IF v_qt > 0 THEN
    v_ret := 1;
    RETURN v_ret;
   END IF;
   --
  END IF; -- fim do IF v_grupo = 'OSEND'
  --
  -----------------------------------------------------------
  -- tratamento especifico p/ JOBEND
  -----------------------------------------------------------
  IF v_grupo = 'JOBEND' THEN
   IF v_flag_restringe_conc = 'S' THEN
    -- conclusao restrita de job (Apenas para responsavel interno).
    -- verifica se o job passado pelo parametro esta' enderecado para o usuario
    -- como responsavel interno.
    SELECT COUNT(*)
      INTO v_qt
      FROM job_usuario
     WHERE usuario_id = p_usuario_sessao_id
       AND job_id = p_objeto_id
       AND flag_responsavel = 'S';
    --
    IF v_qt = 0 THEN
     v_ret := 0;
     RETURN v_ret;
    ELSE
     v_ret := 1;
     RETURN v_ret;
    END IF;
   END IF;
   --
   -- verifica se o job passado pelo parametro esta' enderecado para o usuario.
   SELECT COUNT(*)
     INTO v_qt
     FROM job_usuario
    WHERE usuario_id = p_usuario_sessao_id
      AND job_id = p_objeto_id;
   --
   IF v_qt > 0 THEN
    v_ret := 1;
    RETURN v_ret;
   END IF;
   --
   -- verifica se eh um usuario que acessa APENAS a interface de cliente
   SELECT COUNT(*)
     INTO v_qt
     FROM usuario us
    WHERE us.flag_acesso_cli = 'S'
      AND us.usuario_id = p_usuario_sessao_id
      AND us.flag_acesso_pri = 'N';
   --
   IF v_qt > 0 THEN
    -- verifica se o usuario pertence a empresa do job (o cliente do
    -- job e' um enderecamento implicito).
    SELECT pessoa_id
      INTO v_pessoa_sessao_id
      FROM pessoa
     WHERE usuario_id = p_usuario_sessao_id;
    --
    SELECT cliente_id
      INTO v_cliente_id
      FROM job
     WHERE job_id = p_objeto_id;
    --
    SELECT COUNT(*)
      INTO v_qt
      FROM relacao
     WHERE pessoa_filho_id = v_pessoa_sessao_id
       AND pessoa_pai_id = v_cliente_id;
    --
    IF v_qt > 0 OR v_pessoa_sessao_id = v_cliente_id THEN
     v_ret := 1;
     RETURN v_ret;
    END IF;
   END IF;
  END IF; -- fim do IF v_grupo = 'JOBEND'
  --
  -----------------------------------------------------------
  -- tratamento especifico p/ ORCEND
  -----------------------------------------------------------
  IF v_grupo = 'ORCEND' AND v_carta_acordo_id = 0 AND v_nota_fiscal_id = 0 THEN
   v_orcamento_id := nvl(p_objeto_id, 0);
   --
   SELECT MAX(job_id)
     INTO v_job_id
     FROM orcamento
    WHERE orcamento_id = v_orcamento_id;
   --
   -- verifica se o JOB esta' enderecado para o usuario
   SELECT COUNT(*)
     INTO v_qt
     FROM job_usuario
    WHERE usuario_id = p_usuario_sessao_id
      AND job_id = v_job_id;
   --
   IF v_qt > 0 AND v_abrangencia = 'P' THEN
    -- o enderecamento no job eh suficiente
    v_ret := 1;
    RETURN v_ret;
   END IF;
   --
   -- verifica se a ESTIMATIVA esta' enderecada para o usuario
   SELECT COUNT(*)
     INTO v_qt
     FROM orcam_usuario ou
    WHERE ou.usuario_id = p_usuario_sessao_id
      AND ou.orcamento_id = v_orcamento_id
      AND ou.atuacao = 'ENDER';
   --
   IF v_qt > 0 THEN
    v_ret := 1;
    RETURN v_ret;
   END IF;
   --
  END IF; -- fim do IF v_grupo = 'ORCEND'
  --
  -----------------------------------------------------------
  -- tratamento especifico p/ ORCEND (com carta_acordo_id multijob)
  -----------------------------------------------------------
  IF v_grupo = 'ORCEND' AND v_carta_acordo_id > 0 THEN
   v_ret := -1;
   --
   FOR r_ca IN c_ca
   LOOP
    -- loop por estimativa da carta acordo
    IF v_ret = -1 THEN
     -- primeira vez no loop. Inicializa variavel.
     v_ret := 1;
    END IF;
    --
    v_ret := usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                        v_codigo_priv,
                                        r_ca.orcamento_id,
                                        NULL,
                                        p_empresa_id);
    --
    IF v_ret = 0 THEN
     -- retorna 0 (sem privilegio em alguma estimativa)
     RETURN v_ret;
    END IF;
   END LOOP;
   --
   IF v_ret = -1 THEN
    -- nao entrou no loop
    v_ret := 0;
    RETURN v_ret;
   ELSE
    RETURN v_ret;
   END IF;
  END IF;
  --
  -----------------------------------------------------------
  -- tratamento especifico p/ ORCEND (com nota_fiscal_id multijob)
  -----------------------------------------------------------
  IF v_grupo = 'ORCEND' AND v_nota_fiscal_id > 0 THEN
   v_ret := -1;
   --
   FOR r_nf IN c_nf
   LOOP
    -- loop por estimativa da nota fiscal
    IF v_ret = -1 THEN
     -- primeira vez no loop. Inicializa variavel.
     v_ret := 1;
    END IF;
    --
    v_ret := usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                        v_codigo_priv,
                                        r_nf.orcamento_id,
                                        NULL,
                                        p_empresa_id);
    --
    IF v_ret = 0 THEN
     -- retorna 0 (sem privilegio em alguma estimativa)
     RETURN v_ret;
    END IF;
   END LOOP;
   --
   IF v_ret = -1 THEN
    -- nao entrou no loop
    v_ret := 0;
    RETURN v_ret;
   ELSE
    RETURN v_ret;
   END IF;
  END IF;
  --
  -----------------------------------------------------------
  -- tratamento especifico p/ CONTRATOEND
  -----------------------------------------------------------
  IF v_grupo = 'CONTRATOEND' THEN
   -- verifica se o contrato passado pelo parametro esta' enderecado
   -- para o usuario.
   SELECT COUNT(*)
     INTO v_qt
     FROM contrato_usuario ct
    WHERE ct.usuario_id = p_usuario_sessao_id
      AND ct.contrato_id = p_objeto_id;
   --
   IF v_qt > 0 THEN
    v_ret := 1;
    RETURN v_ret;
   END IF;
   --
  END IF; -- fim do IF v_grupo = 'CONTRATOEND'
  --
  -----------------------------------------------------------
  -- tratamento especifico p/ DOCUMENTO
  -----------------------------------------------------------
  IF v_grupo = 'DOCEND' THEN
   v_job_id            := nvl(p_objeto_id, 0);
   v_tipo_documento_id := nvl(to_number(p_outros), 0);
   --
   IF v_job_id = 0 AND v_tipo_documento_id = 0 THEN
    v_ret := 1;
    RETURN v_ret;
   END IF;
   --
   IF v_tipo_documento_id > 0 THEN
    -- o tipo de documento foi especificado.
    SELECT COUNT(*),
           to_char(MAX(pp.abrangencia))
      INTO v_qt,
           v_abrangencia
      FROM usuario_papel   up,
           papel_priv_tdoc pp,
           privilegio      pr,
           papel           pa
     WHERE up.usuario_id = p_usuario_sessao_id
       AND up.papel_id = pa.papel_id
       AND pa.empresa_id = p_empresa_id
       AND up.papel_id = pp.papel_id
       AND pp.privilegio_id = pr.privilegio_id
       AND pr.codigo = v_codigo_priv
       AND pp.tipo_documento_id = v_tipo_documento_id;
    --
    IF v_qt = 0 THEN
     -- usuario nao tem privilegio para esse tipo de documento
     v_ret := 0;
     RETURN v_ret;
    END IF;
    --
    IF v_abrangencia = 'T' THEN
     -- usuario tem privilegio, independente do enderecamento do job
     v_ret := 1;
     RETURN v_ret;
    END IF;
   ELSE
    -- o tipo de documento nao foi especificado.
    -- continua os testes de enderecamento
    NULL;
   END IF;
   --
   --
   IF v_job_id = 0 THEN
    -- nao eh para testar o enderecamento (usado em links do menu)
    v_ret := 1;
    RETURN v_ret;
   END IF;
   --
   -- verifica se o job do documento esta' enderecado para o usuario.
   SELECT COUNT(*)
     INTO v_qt
     FROM job_usuario
    WHERE usuario_id = p_usuario_sessao_id
      AND job_id = v_job_id;
   --
   IF v_qt > 0 THEN
    v_ret := 1;
    RETURN v_ret;
   END IF;
   --
  END IF; -- fim do IF v_grupo = 'DOCEND'
  --ALCBO_271023
  -----------------------------------------------------------
  -- tratamento especifico p/ ENDERECAR no job, contrato, opoertunidade
  -----------------------------------------------------------
  IF v_grupo = 'ENDERECAR' OR v_grupo = 'CONTRATOENDERAREA' OR v_grupo = 'OPORTUNENDERAREA' THEN
   v_objeto_id := nvl(p_objeto_id, 0);
   v_area_id   := nvl(to_number(p_outros), 0);
   --
   IF v_objeto_id = 0 AND v_area_id = 0 THEN
    v_ret := 1;
    RETURN v_ret;
   END IF;
   --
   IF v_area_id > 0 THEN
    SELECT MAX(empresa_id)
      INTO v_empresa_area_id
      FROM area
     WHERE area_id = v_area_id;
    --
    IF v_empresa_area_id <> p_empresa_id THEN
     -- enderecamento em area de outra empresa.
     -- libera por enquanto.
     v_ret := 1;
     RETURN v_ret;
    END IF;
    --
    -- a area foi especificada.
    SELECT COUNT(*),
           to_char(MAX(pp.abrangencia))
      INTO v_qt,
           v_abrangencia
      FROM usuario_papel   up,
           papel_priv_area pp,
           privilegio      pr,
           papel           pa
     WHERE up.usuario_id = p_usuario_sessao_id
       AND up.papel_id = pa.papel_id
       AND pa.empresa_id = p_empresa_id
       AND up.papel_id = pp.papel_id
       AND pp.privilegio_id = pr.privilegio_id
       AND pr.codigo = v_codigo_priv
       AND pp.area_id = v_area_id;
    --
    IF v_qt = 0 THEN
     -- usuario nao tem privilegio para essa area
     v_ret := 0;
     RETURN v_ret;
    END IF;
    --
    IF v_abrangencia = 'T' THEN
     -- usuario tem privilegio, independente do enderecamento do job
     v_ret := 1;
     RETURN v_ret;
    END IF;
   ELSE
    -- a area nao foi especificada.
    -- continua os testes de enderecamento
    NULL;
   END IF;
   --
   --
   IF v_objeto_id = 0 THEN
    -- nao eh para testar o enderecamento (usado em links do menu)
    v_ret := 1;
    RETURN v_ret;
   END IF;
   -- verifica se o job esta' enderecado para o usuario.
   IF v_grupo = 'ENDERECAR' THEN
    SELECT COUNT(*)
      INTO v_qt
      FROM job_usuario
     WHERE usuario_id = p_usuario_sessao_id
       AND job_id = v_objeto_id;
   END IF;
   --ALCBO_271023
   -- verifica se o contrato esta' enderecado para o usuario.
   IF v_grupo = 'CONTRATOENDERAREA' THEN
    SELECT COUNT(*)
      INTO v_qt
      FROM contrato_usuario
     WHERE usuario_id = p_usuario_sessao_id
       AND contrato_id = v_objeto_id;
   END IF;
   --ALCBO_271023
   -- verifica se o oportunidade esta' enderecado para o usuario.
   IF v_grupo = 'OPORTUNENDERAREA' THEN
    SELECT COUNT(*)
      INTO v_qt
      FROM oport_usuario
     WHERE usuario_id = p_usuario_sessao_id
       AND oportunidade_id = v_objeto_id;
   END IF;
   --
   IF v_qt > 0 THEN
    v_ret := 1;
    RETURN v_ret;
   END IF;
   --
  END IF; -- fim do IF v_grupo = 'ENDERECAR, CONTRATOENDERAREA, OPORTUNENDERAREA'
  --
  -----------------------------------------------------------
  -- tratamento especifico p/ OPORTUNEND
  -----------------------------------------------------------
  IF v_grupo = 'OPORTUNEND' THEN
   -- verifica se a oportunidade passada pelo parametro esta' enderecada para o usuario.
   SELECT COUNT(*)
     INTO v_qt
     FROM oport_usuario ou
    WHERE ou.usuario_id = p_usuario_sessao_id
      AND ou.oportunidade_id = p_objeto_id;
   --
   IF v_qt > 0 THEN
    v_ret := 1;
    RETURN v_ret;
   END IF;
  END IF; -- fim do IF v_grupo = 'OPORTUNEND'
  --
  RETURN v_ret;
 EXCEPTION
  WHEN OTHERS THEN
   v_ret := 0;
   RETURN v_ret;
 END priv_verificar;
 --
 --
 FUNCTION priv_tipo_pessoa_verificar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 19/04/2005
  -- DESCRICAO: verifica se o usuario tem determinado privilegio de pessoa (PESSOA_C,
  --   PESSOA_V) para um determinado tipo de pessoa. Retorna 1 caso seja e 0 caso não.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            14/04/2010  Novo parametro p/ receber empresa_id.
  -- Silvia            21/10/2016  Nova coluna abrangencia no lugar de flag_todos_obj.
  ------------------------------------------------------------------------------------------
  p_usuario_sessao_id IN NUMBER,
  p_cod_priv          IN VARCHAR2,
  p_tipo_pessoa       IN VARCHAR2,
  p_empresa_id        IN NUMBER
 ) RETURN INTEGER AS
  v_retorno     INTEGER;
  v_qt          INTEGER;
  v_abrangencia papel_priv.abrangencia%TYPE;
  v_flag_admin  usuario.flag_admin%TYPE;
  v_flag_ativo  usuario.flag_ativo%TYPE;
  v_exception   EXCEPTION;
  --
 BEGIN
  v_retorno := 0;
  --
  -- verifica o tipo de usuario
  SELECT flag_admin,
         flag_ativo
    INTO v_flag_admin,
         v_flag_ativo
    FROM usuario
   WHERE usuario_id = p_usuario_sessao_id;
  --
  -- usuario administrador pode tudo.
  IF v_flag_admin = 'S' THEN
   v_retorno := 1;
   RETURN v_retorno;
  END IF;
  --
  -- usuario inativo nao tem privilegio.
  IF v_flag_ativo = 'N' THEN
   v_retorno := 0;
   RETURN v_retorno;
  END IF;
  --
  SELECT COUNT(*),
         to_char(MAX(pp.abrangencia))
    INTO v_qt,
         v_abrangencia
    FROM usuario_papel up,
         papel_priv    pp,
         privilegio    pr,
         papel         pa
   WHERE up.usuario_id = p_usuario_sessao_id
     AND up.papel_id = pa.papel_id
     AND pa.empresa_id = p_empresa_id
     AND up.papel_id = pp.papel_id
     AND pp.privilegio_id = pr.privilegio_id
     AND pr.codigo = p_cod_priv;
  --
  IF v_qt = 0 THEN
   -- usuario nao tem privilegio
   v_retorno := 0;
   RETURN v_retorno;
  END IF;
  --
  IF v_abrangencia = 'T' THEN
   -- usuario tem privilegio sobre qualquer tipo de pessoa
   v_retorno := 1;
   RETURN v_retorno;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM usuario_papel      up,
         papel_priv_tpessoa pp,
         privilegio         pr,
         tipo_pessoa        ti,
         papel              pa
   WHERE up.usuario_id = p_usuario_sessao_id
     AND up.papel_id = pa.papel_id
     AND pa.empresa_id = p_empresa_id
     AND up.papel_id = pp.papel_id
     AND pp.privilegio_id = pr.privilegio_id
     AND pr.codigo = p_cod_priv
     AND pp.tipo_pessoa_id = ti.tipo_pessoa_id
     AND ti.codigo = p_tipo_pessoa;
  --
  IF v_qt > 0 THEN
   v_retorno := 1;
  END IF;
  --
  RETURN v_retorno;
 EXCEPTION
  WHEN OTHERS THEN
   v_retorno := 0;
   RETURN v_retorno;
 END priv_tipo_pessoa_verificar;
 --
 --
 FUNCTION acesso_grupo_verificar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 23/02/2005
  -- DESCRICAO: verifica se determinado usuario tem acesso as funcionalidades do grupo.
  --
  --  Retorna '1' caso o usuario tenha acesso ou '0', caso nao.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_usuario_sessao_id IN usuario.usuario_id%TYPE,
  p_grupo             IN VARCHAR2,
  p_empresa_id        IN NUMBER
 ) RETURN INTEGER AS
  v_ret        INTEGER;
  v_qt         INTEGER;
  v_flag_admin usuario.flag_admin%TYPE;
  v_flag_ativo usuario.flag_ativo%TYPE;
  --
 BEGIN
  v_ret := 0;
  --
  -- verifica o tipo de usuario
  SELECT flag_admin,
         flag_ativo
    INTO v_flag_admin,
         v_flag_ativo
    FROM usuario
   WHERE usuario_id = p_usuario_sessao_id;
  --
  -- usuario administrador pode tudo.
  IF v_flag_admin = 'S' THEN
   v_ret := 1;
   RETURN v_ret;
  END IF;
  --
  -- usuario inativo nao tem privilegio.
  IF v_flag_ativo = 'N' THEN
   v_ret := 0;
   RETURN v_ret;
  END IF;
  --
  -- verifica se os papeis do usuario garantem acesso ao grupo ADMIN
  IF p_grupo = 'ADMIN' THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM usuario_papel up,
          papel_priv    pp,
          privilegio    pr,
          papel         pa
    WHERE up.usuario_id = p_usuario_sessao_id
      AND up.papel_id = pa.papel_id
      AND pa.empresa_id = p_empresa_id
      AND up.papel_id = pp.papel_id
      AND pp.privilegio_id = pr.privilegio_id
      AND pr.grupo = p_grupo
      AND pr.codigo <> 'PESSOA_V';
   --
   IF v_qt > 0 THEN
    v_ret := 1;
    RETURN v_ret;
   ELSE
    RETURN v_ret;
   END IF;
  END IF;
  --
  -- verifica se os papeis do usuario garantem acesso aos demais grupos
  -- que nao necessitam de tratamento especial
  SELECT COUNT(*)
    INTO v_qt
    FROM usuario_papel up,
         papel_priv    pp,
         privilegio    pr,
         papel         pa
   WHERE up.usuario_id = p_usuario_sessao_id
     AND up.papel_id = pa.papel_id
     AND pa.empresa_id = p_empresa_id
     AND up.papel_id = pp.papel_id
     AND pp.privilegio_id = pr.privilegio_id
     AND pr.grupo = p_grupo;
  --
  IF v_qt > 0 THEN
   v_ret := 1;
  END IF;
  --
  RETURN v_ret;
 EXCEPTION
  WHEN OTHERS THEN
   v_ret := 0;
   RETURN v_ret;
 END acesso_grupo_verificar;
 --
 --
 PROCEDURE adicionar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 06/10/2004
  -- DESCRICAO: adiciona novo USUARIO, apos consistencia dos dados de
  --  entrada, alem de atribuir ao usuário os papeis que constam  da
  --  lista fornecida pelo parametro p_vetor_papeis.
  --  O parametro p_vetor_papeis consiste de uma relacao de papel_id
  --  separados por ',' como em: '2,3,7,10'
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            07/02/2007  Inclusao de parametro custo_hora.
  -- Silvia            02/10/2008  Retirada do parametro custo_hora (implem. de salario).
  -- Silvia            12/04/2010  Implementacao de multiagencia.
  -- Silvia            26/04/2013  Novos flags de controle de bloqueio.
  -- Silvia            21/05/2013  Datas de inicio e fim dos apontamentos. Nivel.
  -- Silvia            11/12/2013  Manutencao do cod_ext_usuario.
  -- Silvia            23/05/2014  Novo parametro tab_feriado_id
  -- Silvia            11/03/2015  Novo parametro cod_funcionario.
  -- Silvia            19/03/2015  Novo parametro flag_permite_home.
  -- Silvia            28/08/2015  Carrega flag_notifica_email com 'S'.
  -- Silvia            19/05/2016  Novo parametro departamento_id.
  -- Silvia            23/09/2016  Novo parametro cargo_id.
  -- Silvia            18/10/2016  Novos parametros categoria e tipo_relacao
  -- Silvia            28/12/2016  Retirada do parametro cargo_id.
  -- Silvia            15/09/2017  Novos parametros flag_acesso_pri e flag_acesso_cli
  -- Silvia            14/11/2017  Novo parametro flag_simula_cli
  -- Silvia            04/01/2018  Novo parametro min_horas_apont_dia
  -- Silvia            08/01/2018  Novo parametro de output: usuario_id
  -- Silvia            05/07/2018  Novo parametro flag_acesso_wall
  -- Silvia            23/07/2018  Novos parametros cod_hash_wallboard/painel_wallboard_id
  -- Silvia            28/09/2018  Implementacao de alteracoes de seguranca da senha.
  -- Silvia            04/02/2019  Numero minimo de horas apontadas aceita decimal.
  -- Silvia            09/09/2019  Novo atributo funcao e area_id
  -- Silvia            19/05/2020  Eliminacao de nivel
  -- Silvia            21/07/2022  Novo paametro flag_admin
  -- Silvia            08/11/2022  Consistencia de data_apontam_ini (periodo encerrado)
  ------------------------------------------------------------------------------------------
  p_usuario_sessao_id    IN usuario.usuario_id%TYPE,
  p_empresa_id           IN empresa.empresa_id%TYPE,
  p_pessoa_id            IN pessoa.pessoa_id%TYPE,
  p_flag_admin           IN VARCHAR2,
  p_login                IN usuario.login%TYPE,
  p_senha                IN usuario.senha%TYPE,
  p_resenha              IN usuario.senha%TYPE,
  p_flag_sem_bloq_apont  IN VARCHAR2,
  p_flag_sem_bloq_aprov  IN VARCHAR2,
  p_flag_sem_aprov_horas IN VARCHAR2,
  p_flag_permite_home    IN VARCHAR2,
  p_flag_acesso_pri      IN VARCHAR2,
  p_flag_acesso_cli      IN VARCHAR2,
  p_flag_acesso_wall     IN VARCHAR2,
  p_cod_hash_wallboard   IN VARCHAR2,
  p_painel_wallboard_id  IN NUMBER,
  p_flag_simula_cli      IN VARCHAR2,
  p_data_apontam_ini     IN VARCHAR2,
  p_data_apontam_fim     IN VARCHAR2,
  p_min_horas_apont_dia  IN VARCHAR2,
  p_categoria            IN VARCHAR2,
  p_tipo_relacao         IN VARCHAR2,
  p_cod_ext_usuario      IN usuario.cod_ext_usuario%TYPE,
  p_cod_funcionario      IN usuario.cod_funcionario%TYPE,
  p_vetor_papeis         IN VARCHAR2,
  p_vetor_empresas       IN VARCHAR2,
  p_empresa_padrao_id    IN empresa.empresa_id%TYPE,
  p_departamento_id      IN usuario.departamento_id%TYPE,
  p_tab_feriado_id       IN usuario.tab_feriado_id%TYPE,
  p_funcao               IN usuario.funcao%TYPE,
  p_area_id              IN usuario.area_id%TYPE,
  p_usuario_id           OUT usuario.usuario_id%TYPE,
  p_erro_cod             OUT VARCHAR2,
  p_erro_msg             OUT VARCHAR2
 ) AS
  v_qt                  INTEGER;
  v_usuario_id          usuario.usuario_id%TYPE;
  v_delimitador         CHAR(1);
  v_vetor_papeis        VARCHAR2(1000);
  v_papel_id            papel.papel_id%TYPE;
  v_vetor_empresas      VARCHAR2(1000);
  v_empresa_id          usuario_empresa.empresa_id%TYPE;
  v_flag_padrao         usuario_empresa.flag_padrao%TYPE;
  v_senha               usuario.senha%TYPE;
  v_senha_encriptada    usuario.senha%TYPE;
  v_data_apontam_ini    usuario.data_apontam_ini%TYPE;
  v_data_apontam_fim    usuario.data_apontam_fim%TYPE;
  v_min_horas_apont_dia NUMBER;
  v_nome                pessoa.nome%TYPE;
  v_apelido             pessoa.apelido%TYPE;
  v_identif_objeto      historico.identif_objeto%TYPE;
  v_compl_histor        historico.complemento%TYPE;
  v_historico_id        historico.historico_id%TYPE;
  v_exception           EXCEPTION;
  v_flag_login_integr   VARCHAR2(5);
  v_num_dias_exp_senha  NUMBER(10);
  v_data_exp_senha      DATE;
  v_flag_redef_senha    VARCHAR2(10);
  v_data_mes_ano        DATE;
  v_xml_atual           CLOB;
  --
 BEGIN
  p_erro_cod           := ' ';
  p_erro_msg           := ' ';
  p_usuario_id         := 0;
  v_flag_login_integr  := empresa_pkg.parametro_retornar(p_empresa_id, 'FLAG_LOGIN_INTEGRADO');
  v_num_dias_exp_senha := to_number(empresa_pkg.parametro_retornar(p_empresa_id,
                                                                   'NUM_DIAS_REDEFINIR_SENHA'));
  v_flag_redef_senha   := empresa_pkg.parametro_retornar(p_empresa_id, 'REDEFINIR_SENHA_ALTERADA');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'USUARIO_C', NULL, NULL, p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF p_pessoa_id = 0 OR p_pessoa_id IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da pessoa é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(nome),
         MAX(apelido)
    INTO v_nome,
         v_apelido
    FROM pessoa
   WHERE pessoa_id = p_pessoa_id;
  --
  IF v_nome IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa pessoa não existe.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_empresa_padrao_id, 0) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A empresa padrão deve ser definida.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF flag_validar(p_flag_admin) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag admin inválido (' || p_flag_admin || ').';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_area_id, 0) = 0 AND p_flag_admin = 'N' THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da área é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_area_id, 0) > 0 THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM area
    WHERE area_id = p_area_id
      AND empresa_id = p_empresa_padrao_id;
   --
   IF v_qt = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'A área não pertence à empresa definida como padrão.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF rtrim(p_funcao) IS NULL AND p_flag_admin = 'N' THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da função é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_login) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do login é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF length(p_login) > 50 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O login não pode ter mais que 50 caracteres.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM usuario
   WHERE rtrim(upper(login)) = rtrim(upper(p_login));
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Já existe usuário cadastrado com esse login.';
   RAISE v_exception;
  END IF;
  --
  -- verifica se a pessoa escolhida já está associada a outro usuário.
  SELECT COUNT(*)
    INTO v_qt
    FROM pessoa
   WHERE pessoa_id = p_pessoa_id
     AND usuario_id IS NOT NULL;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa pessoa já está associada a um usuário.';
   RAISE v_exception;
  END IF;
  --
  v_senha := p_senha;
  --
  IF v_flag_login_integr = 'N' THEN
   IF TRIM(v_senha) IS NULL OR TRIM(p_resenha) IS NULL THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O preenchimento da senha e da confirmação da senha é obrigatório.';
    RAISE v_exception;
   END IF;
   --
   IF v_senha <> p_resenha THEN
    p_erro_cod := '90000';
    p_erro_msg := 'A confirmação da senha não confere.';
    RAISE v_exception;
   END IF;
   --
   usuario_pkg.senha_validar(p_empresa_id,
                             v_nome,
                             v_apelido,
                             p_login,
                             v_senha,
                             p_erro_cod,
                             p_erro_msg);
   --
   IF p_erro_cod <> '00000' THEN
    RAISE v_exception;
   END IF;
  ELSE
   -- login integrado. A senha eh gerada automaticamente pois nao sera usada.
   IF TRIM(v_senha) IS NOT NULL OR TRIM(p_resenha) IS NOT NULL THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Em ambientes com login integrado, a senha não deve ser fornecida.';
    RAISE v_exception;
   END IF;
   --
   v_senha := substr(sys_guid(), 1, 10);
  END IF;
  --
  --util_pkg.encriptar( NULL, v_senha, v_senha_encriptada, p_erro_cod, p_erro_msg);
  v_senha_encriptada := util_pkg.texto_encriptar(v_senha, NULL);
  IF v_senha_encriptada IS NULL OR length(v_senha_encriptada) > 256 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Senha com tamanho inválido ou com erro na encriptação.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_departamento_id, 0) > 0 THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM departamento
    WHERE departamento_id = p_departamento_id
      AND empresa_id = p_empresa_padrao_id;
   --
   IF v_qt = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O departamento não pertence à empresa definida como padrão.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF nvl(p_tab_feriado_id, 0) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A tabela de feriados deve ser definida.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM tab_feriado
   WHERE tab_feriado_id = p_tab_feriado_id
     AND empresa_id = p_empresa_padrao_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A tabela de feriados não pertence à empresa definida como padrão.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_sem_bloq_apont) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag sem bloqueio de apontamento inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_sem_bloq_aprov) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag sem bloqueio de aprovação inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_sem_aprov_horas) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag sem aprovação de horas inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_permite_home) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag permite home office inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_acesso_pri) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag acesso à interface Principal inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_acesso_cli) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag acesso à interface Do Cliente inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_acesso_wall) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag acesso somente wallboard inválido.';
   RAISE v_exception;
  END IF;
  --
  IF p_flag_acesso_wall = 'S' THEN
   IF p_flag_acesso_pri = 'S' OR p_flag_acesso_cli = 'S' THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Combinação inválida de acesso às interfaces.';
    RAISE v_exception;
   END IF;
   --
   IF TRIM(p_cod_hash_wallboard) IS NULL THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O preenchimento do código hash para o wallboard é obrigatório.';
    RAISE v_exception;
   END IF;
   --
   IF TRIM(length(p_cod_hash_wallboard)) > 60 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O tamanho do código hash para o wallboard não pode ' ||
                  'ter mais que 60 caracteres.';
    RAISE v_exception;
   END IF;
   --
   IF nvl(p_painel_wallboard_id, 0) = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O preenchimento do painel do wallboard é obrigatório.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF flag_validar(p_flag_simula_cli) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag simula acesso cliente inválido.';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_data_apontam_ini) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de início dos apontamentos inválida.';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_data_apontam_fim) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de término dos apontamentos inválida.';
   RAISE v_exception;
  END IF;
  --
  v_data_apontam_ini := data_converter(p_data_apontam_ini);
  v_data_apontam_fim := data_converter(p_data_apontam_fim);
  --
  IF v_data_apontam_ini > v_data_apontam_fim THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A data de início dos apontamentos não pode ser maior que a data de térnimo.';
   RAISE v_exception;
  END IF;
  --
  IF numero_validar(p_min_horas_apont_dia) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Número mínimo de horas apontadas por dia inválido.';
   RAISE v_exception;
  END IF;
  --
  -- verifica se a data de inicio de apontam cai num mes encerrado
  v_data_mes_ano := data_converter('01/' || to_char(v_data_apontam_ini, 'MM/YYYY'));
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM apontam_ence
   WHERE empresa_id = p_empresa_padrao_id
     AND mes_ano = v_data_mes_ano
     AND flag_encerrado = 'S';
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Não é possível iniciar o apontamento na data fornecida pois o timesheet do mês ' ||
                 mes_ano_mostrar(v_data_mes_ano) || ' está encerrado.';
   RAISE v_exception;
  END IF;
  --
  v_min_horas_apont_dia := round(numero_converter(p_min_horas_apont_dia), 2);
  --
  IF v_min_horas_apont_dia > 24 OR v_min_horas_apont_dia < 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Número mínimo de horas apontadas por dia inválido.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_categoria) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da categoria do usuário é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF util_pkg.desc_retornar('categoria_usu', p_categoria) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Categoria do usuário inválida (' || p_categoria || ').';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_tipo_relacao) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do tipo de relação do usuário é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF util_pkg.desc_retornar('tipo_relacao_usu', p_tipo_relacao) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de relação inválida (' || p_tipo_relacao || ').';
   RAISE v_exception;
  END IF;
  --
  IF v_num_dias_exp_senha = 0 THEN
   -- a senha nunca expira
   v_data_exp_senha := NULL;
  ELSE
   v_data_exp_senha := trunc(SYSDATE) + v_num_dias_exp_senha;
  END IF;
  --
  IF v_flag_redef_senha = 'S' THEN
   -- forca o usuario a redefinir a senha no proximo login
   v_data_exp_senha := trunc(SYSDATE);
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT seq_usuario.nextval
    INTO v_usuario_id
    FROM dual;
  --
  INSERT INTO usuario
   (usuario_id,
    login,
    senha,
    data_exp_senha,
    qtd_login_invalido,
    flag_bloqueado,
    flag_email_bloq,
    flag_admin,
    flag_ativo,
    flag_sem_bloq_apont,
    flag_sem_bloq_aprov,
    flag_sem_aprov_horas,
    flag_permite_home,
    flag_acesso_pri,
    flag_acesso_cli,
    flag_acesso_wall,
    cod_hash_wallboard,
    flag_simula_cli,
    data_apontam_ini,
    data_apontam_fim,
    min_horas_apont_dia,
    categoria,
    tipo_relacao,
    cod_ext_usuario,
    cod_funcionario,
    tab_feriado_id,
    departamento_id,
    flag_notifica_email,
    funcao,
    area_id)
  VALUES
   (v_usuario_id,
    rtrim(p_login),
    v_senha_encriptada,
    v_data_exp_senha,
    0,
    'N',
    'N',
    p_flag_admin,
    'S',
    p_flag_sem_bloq_apont,
    p_flag_sem_bloq_aprov,
    p_flag_sem_aprov_horas,
    p_flag_permite_home,
    p_flag_acesso_pri,
    p_flag_acesso_cli,
    p_flag_acesso_wall,
    TRIM(p_cod_hash_wallboard),
    p_flag_simula_cli,
    v_data_apontam_ini,
    v_data_apontam_fim,
    v_min_horas_apont_dia,
    TRIM(p_categoria),
    TRIM(p_tipo_relacao),
    TRIM(p_cod_ext_usuario),
    TRIM(p_cod_funcionario),
    p_tab_feriado_id,
    zvl(p_departamento_id, NULL),
    'S',
    TRIM(p_funcao),
    zvl(p_area_id, NULL));
  --
  UPDATE pessoa
     SET usuario_id = v_usuario_id
   WHERE pessoa_id = p_pessoa_id;
  --
  v_delimitador  := ',';
  v_vetor_papeis := p_vetor_papeis;
  --
  -- loop por papel no vetor
  WHILE nvl(length(rtrim(v_vetor_papeis)), 0) > 0
  LOOP
   v_papel_id := to_number(prox_valor_retornar(v_vetor_papeis, v_delimitador));
   --
   INSERT INTO usuario_papel
    (usuario_id,
     papel_id)
   VALUES
    (v_usuario_id,
     v_papel_id);
  END LOOP;
  --
  v_vetor_empresas := p_vetor_empresas;
  --
  -- loop por empresa no vetor
  WHILE nvl(length(rtrim(v_vetor_empresas)), 0) > 0
  LOOP
   v_empresa_id  := to_number(prox_valor_retornar(v_vetor_empresas, v_delimitador));
   v_flag_padrao := 'N';
   --
   IF v_empresa_id = p_empresa_padrao_id THEN
    v_flag_padrao := 'S';
   END IF;
   --
   INSERT INTO usuario_empresa
    (usuario_id,
     empresa_id,
     flag_padrao)
   VALUES
    (v_usuario_id,
     v_empresa_id,
     v_flag_padrao);
  END LOOP;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM usuario_empresa
   WHERE usuario_id = v_usuario_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O usuário deve ser associado a pelo menos uma empresa.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM usuario_empresa
   WHERE usuario_id = v_usuario_id
     AND flag_padrao = 'S';
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A empresa padrão deve obrigatoriamente ser associada ao usuário.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  usuario_pkg.xml_gerar(v_usuario_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := rtrim(p_login);
  v_compl_histor   := 'Pessoa: ' || v_nome;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'USUARIO',
                   'INCLUIR',
                   v_identif_objeto,
                   v_usuario_id,
                   v_compl_histor,
                   NULL,
                   'N',
                   NULL,
                   v_xml_atual,
                   v_historico_id,
                   p_erro_cod,
                   p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  COMMIT;
  p_usuario_id := v_usuario_id;
  p_erro_cod   := '00000';
  p_erro_msg   := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END adicionar;
 --
 --
 PROCEDURE atualizar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 06/10/2004
  -- DESCRICAO: atualiza USUARIO, apos consistencia dos dados de
  --  entrada, alem de atribuir ao usuário os papeis que constam  da
  --  lista fornecida pelo parametro p_vetor_papeis. Os papeis atuais
  --  do usuario que nao aparecerem na lista, serao retirados.
  --  O parametro p_vetor_papeis consiste de uma relacao de papel_id
  --  separados por ',' como em: '2,3,7,10'.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            07/02/2007  Inclusao de parametro custo_hora.
  -- Silvia            02/10/2008  Retirada do parametro custo_hora (implem. de salario).
  -- Silvia            12/04/2010  Implementacao de multiagencia.
  -- Silvia            26/04/2013  Novos flags de controle de bloqueio.
  -- Silvia            21/05/2013  Datas de inicio e fim dos apontamentos. Nivel.
  -- Silvia            11/12/2013  Manutencao do cod_ext_usuario.
  -- Silvia            23/05/2014  Novo parametro tab_feriado_id
  -- Silvia            11/03/2015  Novo parametro cod_funcionario.
  -- Silvia            19/03/2015  Novo parametro flag_permite_home.
  -- Silvia            19/05/2016  Novo parametro departamento_id.
  -- Silvia            23/09/2016  Novo parametro cargo_id.
  -- Silvia            18/10/2016  Novos parametros categoria e tipo_relacao
  -- Silvia            28/12/2016  Retirada do parametro cargo_id.
  -- Silvia            09/05/2017  Novo parametro flag_notifica_email
  -- Silvia            09/08/2017  Limpa apontamentos pendentes ao inativar usuario.
  -- Silvia            15/09/2017  Novos parametros flag_acesso_pri e flag_acesso_cli
  -- Silvia            14/11/2017  Novo parametro flag_simula_cli
  -- Silvia            04/01/2018  Novo parametro min_horas_apont_dia
  -- Silvia            05/07/2018  Novo parametro flag_acesso_wall
  -- Silvia            23/07/2018  Novos parametros cod_hash_wallboard/painel_wallboard_id
  -- Silvia            28/09/2018  Implementacao de alteracoes de seguranca da senha
  --                               (retirada de parametros de senha).
  -- Silvia            04/02/2019  Numero minimo de horas apontadas aceita decimal.
  -- Silvia            09/09/2019  Novo atributo funcao e area_id
  -- Silvia            19/05/2020  Eliminacao de nivel
  -- Silvia            29/03/2021  Chamada de subrotina para enderecar em todos jobs
  -- Silvia            10/05/2021  Retirada do parametro min_horas_apont_dia
  -- Silvia            21/07/2022  Novo patrametro flag_admin
  -- Silvia            08/11/2022  Consistencia de data_apontam_ini (periodo encerrado)
  ------------------------------------------------------------------------------------------
  p_usuario_sessao_id    IN usuario.usuario_id%TYPE,
  p_empresa_id           IN empresa.empresa_id%TYPE,
  p_usuario_id           IN usuario.usuario_id%TYPE,
  p_login                IN usuario.login%TYPE,
  p_flag_admin           IN VARCHAR2,
  p_flag_ativo           IN usuario.flag_ativo%TYPE,
  p_flag_notifica_email  IN usuario.flag_notifica_email%TYPE,
  p_flag_sem_bloq_apont  IN VARCHAR2,
  p_flag_sem_bloq_aprov  IN VARCHAR2,
  p_flag_sem_aprov_horas IN VARCHAR2,
  p_flag_permite_home    IN VARCHAR2,
  p_flag_acesso_pri      IN VARCHAR2,
  p_flag_acesso_cli      IN VARCHAR2,
  p_flag_acesso_wall     IN VARCHAR2,
  p_cod_hash_wallboard   IN VARCHAR2,
  p_painel_wallboard_id  IN NUMBER,
  p_flag_simula_cli      IN VARCHAR2,
  p_data_apontam_ini     IN VARCHAR2,
  p_data_apontam_fim     IN VARCHAR2,
  p_categoria            IN VARCHAR2,
  p_tipo_relacao         IN VARCHAR2,
  p_cod_ext_usuario      IN usuario.cod_ext_usuario%TYPE,
  p_cod_funcionario      IN usuario.cod_funcionario%TYPE,
  p_vetor_papeis         IN VARCHAR2,
  p_vetor_empresas       IN VARCHAR2,
  p_empresa_padrao_id    IN empresa.empresa_id%TYPE,
  p_departamento_id      IN usuario.departamento_id%TYPE,
  p_tab_feriado_id       IN usuario.tab_feriado_id%TYPE,
  p_funcao               IN usuario.funcao%TYPE,
  p_area_id              IN usuario.area_id%TYPE,
  p_erro_cod             OUT VARCHAR2,
  p_erro_msg             OUT VARCHAR2
 ) AS
  v_qt                   INTEGER;
  v_delimitador          CHAR(1);
  v_vetor_papeis         VARCHAR2(500);
  v_papel_id             papel.papel_id%TYPE;
  v_vetor_empresas       VARCHAR2(1000);
  v_empresa_id           usuario_empresa.empresa_id%TYPE;
  v_flag_padrao          usuario_empresa.flag_padrao%TYPE;
  v_data_apontam_ini     usuario.data_apontam_ini%TYPE;
  v_data_apontam_fim     usuario.data_apontam_fim%TYPE;
  v_data_apontam_ini_old usuario.data_apontam_ini%TYPE;
  v_flag_ativo_old       usuario.flag_ativo%TYPE;
  v_admin                INTEGER;
  v_nome                 pessoa.nome%TYPE;
  v_identif_objeto       historico.identif_objeto%TYPE;
  v_compl_histor         historico.complemento%TYPE;
  v_historico_id         historico.historico_id%TYPE;
  v_exception            EXCEPTION;
  v_papel_id_erro        papel.papel_id%TYPE;
  v_compl_erro           VARCHAR2(300);
  v_cod_acao             tipo_acao.codigo%TYPE;
  v_data_mes_ano         DATE;
  v_xml_antes            CLOB;
  v_xml_atual            CLOB;
  --
 BEGIN
  p_erro_cod := ' ';
  p_erro_msg := ' ';
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'USUARIO_C', p_usuario_id, NULL, p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(nome)
    INTO v_nome
    FROM pessoa
   WHERE usuario_id = p_usuario_id;
  --
  IF v_nome IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Erro na seleção da pessoa associada.';
   RAISE v_exception;
  END IF;
  --
  SELECT flag_ativo,
         data_apontam_ini
    INTO v_flag_ativo_old,
         v_data_apontam_ini_old
    FROM usuario
   WHERE usuario_id = p_usuario_id;
  --
  IF nvl(p_empresa_padrao_id, 0) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A empresa padrão deve ser definida.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF flag_validar(p_flag_admin) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag admin inválido (' || p_flag_admin || ').';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_area_id, 0) = 0 AND p_flag_admin = 'N' THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da área é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_area_id, 0) > 0 THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM area
    WHERE area_id = p_area_id
      AND empresa_id = p_empresa_padrao_id;
   --
   IF v_qt = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'A área não pertence à empresa definida como padrão.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF rtrim(p_funcao) IS NULL AND p_flag_admin = 'N' THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da função é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_login) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do login é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF length(p_login) > 50 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O login não pode ter mais que 50 caracteres.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM usuario
   WHERE rtrim(upper(login)) = rtrim(upper(p_login))
     AND usuario_id <> p_usuario_id;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Já existe usuário cadastrado com esse login.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_departamento_id, 0) > 0 THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM departamento
    WHERE departamento_id = p_departamento_id
      AND empresa_id = p_empresa_padrao_id;
   --
   IF v_qt = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O departamento não pertence à empresa definida como padrão.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF nvl(p_tab_feriado_id, 0) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A tabela de feriados deve ser definida.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM tab_feriado
   WHERE tab_feriado_id = p_tab_feriado_id
     AND empresa_id = p_empresa_padrao_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A tabela de feriados não pertence à empresa definida como padrão.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_ativo) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag ativo inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_notifica_email) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag notifica email inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_sem_bloq_apont) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag sem bloqueio de apontamento inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_sem_bloq_aprov) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag sem bloqueio de aprovação inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_sem_aprov_horas) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag sem aprovação de horas inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_permite_home) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag permite home office inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_acesso_pri) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag acesso à interface Principal inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_acesso_cli) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag acesso à interface Do Cliente inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_acesso_wall) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag acesso somente wallboard inválido.';
   RAISE v_exception;
  END IF;
  --
  IF p_flag_acesso_wall = 'S' THEN
   IF p_flag_acesso_pri = 'S' OR p_flag_acesso_cli = 'S' THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Combinação inválida de acesso às interfaces.';
    RAISE v_exception;
   END IF;
   --
   IF TRIM(p_cod_hash_wallboard) IS NULL THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O preenchimento do código hash para o wallboard é obrigatório.';
    RAISE v_exception;
   END IF;
   --
   IF TRIM(length(p_cod_hash_wallboard)) > 60 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O tamanho do código hash para o wallboard não pode ' ||
                  'ter mais que 60 caracteres.';
    RAISE v_exception;
   END IF;
   --
   IF nvl(p_painel_wallboard_id, 0) = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O preenchimento do painel do wallboard é obrigatório.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF flag_validar(p_flag_simula_cli) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag simula acesso cliente inválido.';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_data_apontam_ini) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de início dos apontamentos inválida.';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_data_apontam_fim) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de término dos apontamentos inválida.';
   RAISE v_exception;
  END IF;
  --
  v_data_apontam_ini := data_converter(p_data_apontam_ini);
  v_data_apontam_fim := data_converter(p_data_apontam_fim);
  --
  IF v_data_apontam_ini > v_data_apontam_fim THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A data de início dos apontamentos não pode ser maior que a data de térnimo.';
   RAISE v_exception;
  END IF;
  --
  IF v_data_apontam_ini_old <> v_data_apontam_ini OR
     (v_data_apontam_ini_old IS NULL AND v_data_apontam_ini IS NOT NULL) THEN
   -- verifica se a data de inicio de apontam cai num mes encerrado
   v_data_mes_ano := data_converter('01/' || to_char(v_data_apontam_ini, 'MM/YYYY'));
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM apontam_ence
    WHERE empresa_id = p_empresa_padrao_id
      AND mes_ano = v_data_mes_ano
      AND flag_encerrado = 'S';
   --
   IF v_qt > 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Não é possível iniciar o apontamento na data fornecida pois o timesheet do mês ' ||
                  mes_ano_mostrar(v_data_mes_ano) || ' está encerrado.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF TRIM(p_categoria) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da categoria do usuário é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF util_pkg.desc_retornar('categoria_usu', p_categoria) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Categoria do usuário inválida (' || p_categoria || ').';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_tipo_relacao) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do tipo de relação do usuário é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF util_pkg.desc_retornar('tipo_relacao_usu', p_tipo_relacao) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de relação inválida (' || p_tipo_relacao || ').';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  usuario_pkg.xml_gerar(p_usuario_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE usuario
     SET login                = rtrim(p_login),
         flag_ativo           = p_flag_ativo,
         flag_admin           = p_flag_admin,
         flag_notifica_email  = p_flag_notifica_email,
         flag_sem_bloq_apont  = p_flag_sem_bloq_apont,
         flag_sem_bloq_aprov  = p_flag_sem_bloq_aprov,
         flag_sem_aprov_horas = p_flag_sem_aprov_horas,
         flag_permite_home    = p_flag_permite_home,
         flag_acesso_pri      = p_flag_acesso_pri,
         flag_acesso_cli      = p_flag_acesso_cli,
         flag_acesso_wall     = p_flag_acesso_wall,
         cod_hash_wallboard   = TRIM(p_cod_hash_wallboard),
         flag_simula_cli      = p_flag_simula_cli,
         data_apontam_ini     = v_data_apontam_ini,
         data_apontam_fim     = v_data_apontam_fim,
         categoria            = TRIM(p_categoria),
         tipo_relacao         = TRIM(p_tipo_relacao),
         cod_ext_usuario      = TRIM(p_cod_ext_usuario),
         cod_funcionario      = TRIM(p_cod_funcionario),
         tab_feriado_id       = p_tab_feriado_id,
         departamento_id      = zvl(p_departamento_id, NULL),
         funcao               = TRIM(p_funcao),
         area_id              = zvl(p_area_id, NULL)
   WHERE usuario_id = p_usuario_id;
  --
  IF p_flag_sem_aprov_horas = 'S' THEN
   DELETE FROM ts_equipe
    WHERE usuario_id = p_usuario_id;
  END IF;
  --
  v_delimitador := ',';
  --
  DELETE FROM usuario_papel up
   WHERE usuario_id = p_usuario_id
     AND EXISTS (SELECT 1
            FROM papel pa
           WHERE up.papel_id = pa.papel_id
             AND pa.empresa_id = p_empresa_id);
  --
  v_vetor_papeis := p_vetor_papeis;
  --
  -- loop por papel no vetor
  WHILE nvl(length(rtrim(v_vetor_papeis)), 0) > 0
  LOOP
   v_papel_id := to_number(prox_valor_retornar(v_vetor_papeis, v_delimitador));
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM papel
    WHERE papel_id = v_papel_id
      AND empresa_id = p_empresa_id;
   --
   IF v_qt = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Papel inválido ou que não pertence à empresa (' || p_vetor_papeis || ').';
    RAISE v_exception;
   END IF;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM usuario_papel
    WHERE usuario_id = p_usuario_id
      AND papel_id = v_papel_id;
   --
   IF v_qt = 0 THEN
    INSERT INTO usuario_papel
     (usuario_id,
      papel_id)
    VALUES
     (p_usuario_id,
      v_papel_id);
   END IF;
   --
  END LOOP;
  --
  -- verifica se foi dado algum papel a usuario administrador
  SELECT COUNT(*)
    INTO v_qt
    FROM usuario_papel up,
         usuario       us
   WHERE us.usuario_id = p_usuario_id
     AND us.flag_admin_sistema = 'S'
     AND us.usuario_id = up.usuario_id;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Usuário administrador do sistema não pode ter papéis associados .';
   RAISE v_exception;
  END IF;
  --
  DELETE FROM usuario_empresa
   WHERE usuario_id = p_usuario_id;
  --
  v_vetor_empresas := p_vetor_empresas;
  --
  -- loop por empresa no vetor
  WHILE nvl(length(rtrim(v_vetor_empresas)), 0) > 0
  LOOP
   v_empresa_id  := to_number(prox_valor_retornar(v_vetor_empresas, v_delimitador));
   v_flag_padrao := 'N';
   --
   IF v_empresa_id = p_empresa_padrao_id THEN
    v_flag_padrao := 'S';
   END IF;
   --
   INSERT INTO usuario_empresa
    (usuario_id,
     empresa_id,
     flag_padrao)
   VALUES
    (p_usuario_id,
     v_empresa_id,
     v_flag_padrao);
  END LOOP;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM usuario_empresa
   WHERE usuario_id = p_usuario_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O usuário deve ser associado a pelo menos uma empresa.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM usuario_empresa
   WHERE usuario_id = p_usuario_id
     AND flag_padrao = 'S';
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A empresa padrão deve obrigatoriamente ser associada ao usuário.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(pa.papel_id)
    INTO v_papel_id_erro
    FROM usuario_papel up,
         papel         pa
   WHERE up.usuario_id = p_usuario_id
     AND up.papel_id = pa.papel_id
     AND NOT EXISTS (SELECT 1
            FROM usuario_empresa ue
           WHERE ue.usuario_id = up.usuario_id
             AND ue.empresa_id = pa.empresa_id);
  --
  IF v_papel_id_erro IS NOT NULL THEN
   SELECT 'Empresa: ' || em.nome || ' Papel: ' || pa.nome
     INTO v_compl_erro
     FROM papel   pa,
          empresa em
    WHERE pa.papel_id = v_papel_id_erro
      AND pa.empresa_id = em.empresa_id;
   --
   p_erro_cod := '90000';
   p_erro_msg := 'Usuário ainda possui papéis de empresa a que ele não está ' ||
                 'sendo associado (' || v_compl_erro || ').';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- enderecamento do usuario em todos os jobs marcados (se for o caso)
  ------------------------------------------------------------
  usuario_pkg.enderecar_em_todos_jobs(p_usuario_sessao_id,
                                      p_empresa_id,
                                      p_usuario_id,
                                      p_erro_cod,
                                      p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  usuario_pkg.xml_gerar(p_usuario_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := rtrim(p_login);
  v_compl_histor   := 'Pessoa: ' || v_nome;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'USUARIO',
                   'ALTERAR',
                   v_identif_objeto,
                   p_usuario_id,
                   v_compl_histor,
                   NULL,
                   'N',
                   v_xml_antes,
                   v_xml_atual,
                   v_historico_id,
                   p_erro_cod,
                   p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  IF v_flag_ativo_old <> p_flag_ativo THEN
   -- registra a mudanca de ativo/inativo
   IF p_flag_ativo = 'S' THEN
    v_cod_acao := 'REATIVAR';
    --
    UPDATE usuario
       SET data_inativacao = NULL
     WHERE usuario_id = p_usuario_id;
   ELSE
    v_cod_acao := 'INATIVAR';
    --
    UPDATE usuario
       SET data_inativacao = SYSDATE
     WHERE usuario_id = p_usuario_id;
    --
    -- limpa apontamentos pendentes
    DELETE FROM apontam_hora ah
     WHERE EXISTS (SELECT 1
              FROM apontam_data ad
             WHERE ah.apontam_data_id = ad.apontam_data_id
               AND ad.usuario_id = p_usuario_id
               AND ad.status = 'PEND');
    --
    DELETE FROM apontam_data_ev ae
     WHERE EXISTS (SELECT 1
              FROM apontam_data ad
             WHERE ae.apontam_data_id = ad.apontam_data_id
               AND ad.usuario_id = p_usuario_id
               AND ad.status = 'PEND');
    --
    DELETE FROM apontam_job aj
     WHERE EXISTS (SELECT 1
              FROM apontam_data ad
             WHERE aj.apontam_data_id = ad.apontam_data_id
               AND ad.usuario_id = p_usuario_id
               AND ad.status = 'PEND');
    --
    DELETE FROM apontam_data ad
     WHERE ad.usuario_id = p_usuario_id
       AND ad.status = 'PEND';
   END IF;
   --
   ------------------------------------------------------------
   -- gera xml do log
   ------------------------------------------------------------
   usuario_pkg.xml_gerar(p_usuario_id, v_xml_atual, p_erro_cod, p_erro_msg);
   --
   IF p_erro_cod <> '00000' THEN
    RAISE v_exception;
   END IF;
   --
   evento_pkg.gerar(p_usuario_sessao_id,
                    p_empresa_id,
                    'USUARIO',
                    v_cod_acao,
                    v_identif_objeto,
                    p_usuario_id,
                    v_compl_histor,
                    NULL,
                    'N',
                    NULL,
                    v_xml_atual,
                    v_historico_id,
                    p_erro_cod,
                    p_erro_msg);
   --
   IF p_erro_cod <> '00000' THEN
    RAISE v_exception;
   END IF;
  END IF;
  --
  COMMIT;
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END atualizar;
 --
 --
 PROCEDURE min_horas_apont_atualizar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 05/05/2021
  -- DESCRICAO: atualiza nro minimo de horas apontadas pelo USUARIO a partir de uma
  -- data de referencia.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_usuario_sessao_id   IN usuario.usuario_id%TYPE,
  p_empresa_id          IN empresa.empresa_id%TYPE,
  p_usuario_id          IN usuario.usuario_id%TYPE,
  p_min_horas_apont_dia IN VARCHAR2,
  p_data_refer          IN VARCHAR2,
  p_erro_cod            OUT VARCHAR2,
  p_erro_msg            OUT VARCHAR2
 ) AS
  v_qt                      INTEGER;
  v_min_horas_apont_dia     NUMBER;
  v_min_horas_apont_dia_old NUMBER;
  v_num_horas_pdr           NUMBER;
  v_num_horas_ts            NUMBER;
  v_nome                    pessoa.nome%TYPE;
  v_login                   usuario.login%TYPE;
  v_data_refer              DATE;
  v_data_ini                DATE;
  v_data_fim                DATE;
  v_identif_objeto          historico.identif_objeto%TYPE;
  v_compl_histor            historico.complemento%TYPE;
  v_historico_id            historico.historico_id%TYPE;
  v_exception               EXCEPTION;
  --
 BEGIN
  p_erro_cod      := ' ';
  p_erro_msg      := ' ';
  v_num_horas_pdr := nvl(numero_converter(empresa_pkg.parametro_retornar(p_empresa_id,
                                                                         'NUM_MIN_HORAS_APONTADAS_DIA')),
                         0);
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'USUARIO_C', p_usuario_id, NULL, p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(nome)
    INTO v_nome
    FROM pessoa
   WHERE usuario_id = p_usuario_id;
  --
  SELECT min_horas_apont_dia,
         login
    INTO v_min_horas_apont_dia_old,
         v_login
    FROM usuario
   WHERE usuario_id = p_usuario_id;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF numero_validar(p_min_horas_apont_dia) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Número mínimo de horas apontadas por dia inválido.';
   RAISE v_exception;
  END IF;
  --
  v_min_horas_apont_dia := round(numero_converter(p_min_horas_apont_dia), 2);
  --
  IF v_min_horas_apont_dia > 24 OR v_min_horas_apont_dia < 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Número mínimo de horas apontadas por dia inválido.';
   RAISE v_exception;
  END IF;
  --
  -- caso o campo de horas seja NULL, usa as horas minimas
  -- padrao da empresa para atualizar timesheet.
  v_num_horas_ts := nvl(v_min_horas_apont_dia, v_num_horas_pdr);
  --
  IF TRIM(p_data_refer) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da data é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_data_refer) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data inválida (' || p_data_refer || ').';
   RAISE v_exception;
  END IF;
  --
  v_data_refer := data_converter(p_data_refer);
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE usuario
     SET min_horas_apont_dia = v_min_horas_apont_dia
   WHERE usuario_id = p_usuario_id;
  --
  UPDATE apontam_data ad
     SET num_horas_dia = v_num_horas_ts
   WHERE usuario_id = p_usuario_id
     AND data >= v_data_refer;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := rtrim(v_login);
  v_compl_histor   := 'Pessoa: ' || v_nome || ' - Nro de horas apontadas alterado de ' ||
                      nvl(to_char(v_min_horas_apont_dia_old), 'ND') || ' para ' ||
                      nvl(to_char(v_min_horas_apont_dia), 'ND') || ' a partir do dia ' ||
                      data_mostrar(v_data_refer);
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'USUARIO',
                   'ALTERAR',
                   v_identif_objeto,
                   p_usuario_id,
                   v_compl_histor,
                   NULL,
                   'N',
                   NULL,
                   NULL,
                   v_historico_id,
                   p_erro_cod,
                   p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  COMMIT;
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END min_horas_apont_atualizar;
 --
 --
 PROCEDURE num_horas_prod_atualizar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 20/08/2021
  -- DESCRICAO: atualiza nro de horas produtivas do USUARIO a partir de uma
  -- data de referencia.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_usuario_sessao_id  IN usuario.usuario_id%TYPE,
  p_empresa_id         IN empresa.empresa_id%TYPE,
  p_usuario_id         IN usuario.usuario_id%TYPE,
  p_num_horas_prod_dia IN VARCHAR2,
  p_data_refer         IN VARCHAR2,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 ) AS
  v_qt                     INTEGER;
  v_num_horas_prod_dia     NUMBER;
  v_num_horas_prod_dia_old NUMBER;
  v_num_horas_pdr          NUMBER;
  v_num_horas_ts           NUMBER;
  v_nome                   pessoa.nome%TYPE;
  v_login                  usuario.login%TYPE;
  v_data_refer             DATE;
  v_data_ini               DATE;
  v_data_fim               DATE;
  v_empresa_pdr_id         empresa.empresa_id%TYPE;
  v_identif_objeto         historico.identif_objeto%TYPE;
  v_compl_histor           historico.complemento%TYPE;
  v_historico_id           historico.historico_id%TYPE;
  v_exception              EXCEPTION;
  --
 BEGIN
  p_erro_cod      := ' ';
  p_erro_msg      := ' ';
  v_num_horas_pdr := nvl(numero_converter(empresa_pkg.parametro_retornar(p_empresa_id,
                                                                         'NUM_HORAS_PRODUTIVAS')),
                         0);
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'USUARIO_C', p_usuario_id, NULL, p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(nome)
    INTO v_nome
    FROM pessoa
   WHERE usuario_id = p_usuario_id;
  --
  SELECT num_horas_prod_dia,
         login
    INTO v_num_horas_prod_dia_old,
         v_login
    FROM usuario
   WHERE usuario_id = p_usuario_id;
  --
  v_empresa_pdr_id := usuario_pkg.empresa_padrao_retornar(p_usuario_id);
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF numero_validar(p_num_horas_prod_dia) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Número de horas produtivas por dia inválido.';
   RAISE v_exception;
  END IF;
  --
  v_num_horas_prod_dia := round(numero_converter(p_num_horas_prod_dia), 2);
  --
  IF v_num_horas_prod_dia > 24 OR v_num_horas_prod_dia < 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Número de horas produtivas por dia inválido.';
   RAISE v_exception;
  END IF;
  --
  -- caso o campo de horas seja NULL, usa as horas produtivas
  -- padrao da empresa para atualizar timesheet e dia_alocacao.
  v_num_horas_ts := nvl(v_num_horas_prod_dia, v_num_horas_pdr);
  --
  IF TRIM(p_data_refer) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da data é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_data_refer) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data inválida (' || p_data_refer || ').';
   RAISE v_exception;
  END IF;
  --
  v_data_refer := data_converter(p_data_refer);
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE usuario
     SET num_horas_prod_dia = v_num_horas_prod_dia
   WHERE usuario_id = p_usuario_id;
  --
  UPDATE apontam_data ad
     SET num_horas_prod_dia = v_num_horas_ts
   WHERE usuario_id = p_usuario_id
     AND data >= v_data_refer;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM dia_alocacao
   WHERE usuario_id = p_usuario_id
     AND horas_diarias <> horas_livre
     AND data >= v_data_refer;
  --
  IF v_qt = 0 THEN
   -- todas as datas instanciadas a partir da data de
   -- referencia estao iguais. Faz um update geral
   UPDATE dia_alocacao
      SET horas_diarias = v_num_horas_ts,
          horas_livre   = v_num_horas_ts
    WHERE usuario_id = p_usuario_id
      AND data >= v_data_refer;
  ELSE
   -- precisa recalcular as horas livres e demais horas
   -- no periodo afetado
   v_data_ini := v_data_refer;
   --
   SELECT MAX(data)
     INTO v_data_fim
     FROM dia_alocacao
    WHERE usuario_id = p_usuario_id;
   --
   cronograma_pkg.alocacao_usu_processar(p_usuario_sessao_id,
                                         v_empresa_pdr_id,
                                         p_usuario_id,
                                         v_data_ini,
                                         v_data_fim,
                                         p_erro_cod,
                                         p_erro_msg);
   IF p_erro_cod <> '00000' THEN
    RAISE v_exception;
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := rtrim(v_login);
  v_compl_histor   := 'Pessoa: ' || v_nome || ' - Nro de horas produtivas alterado de ' ||
                      nvl(to_char(v_num_horas_prod_dia_old), 'ND') || ' para ' ||
                      nvl(to_char(v_num_horas_prod_dia), 'ND') || ' a partir do dia ' ||
                      data_mostrar(v_data_refer);
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'USUARIO',
                   'ALTERAR',
                   v_identif_objeto,
                   p_usuario_id,
                   v_compl_histor,
                   NULL,
                   'N',
                   NULL,
                   NULL,
                   v_historico_id,
                   p_erro_cod,
                   p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  COMMIT;
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END num_horas_prod_atualizar;
 --
 --
 PROCEDURE excluir
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 06/10/2004
  -- DESCRICAO: exclui um USUARIO.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            08/11/2006  Consistencia de usuario que concluiu coletas/frequencia
  -- Silvia            07/02/2007  Consistencia de apontamentos
  -- Silvia            01/04/2008  Consistencia de sobra/abatimento
  -- Silvia            26/06/2008  Consistencia de programacao de apontamentos
  -- Silvia            04/07/2008  Consistencia de posts
  -- Silvia            02/10/2008  Consistencia de salario
  -- Silvia            10/12/2008  Consistencia de ajuste_job
  -- Silvia            12/05/2009  Consistencia de tarefa
  -- Silvia            19/08/2009  Exclusao automatica de preferencias.
  -- Silvia            04/01/2010  Exclusao automatica de milestone_usuario.
  -- Silvia            12/04/2010  Implementacao de multiagencia.
  -- Silvia            07/02/2011  Exclusao automatica de painel.
  -- Silvia            28/05/2015  Novas tabelas de regras de coenderecamento
  -- Silvia            07/07/2015  Consistencia de aval_fornec
  -- Silvia            18/10/2016  Consistencia de  "orcam_usuario"
  -- Silvia            19/12/2016  Consistencia de  "apontam_ence"
  -- Silvia            28/09/2018  Exclusao automatica de hist_senha.
  -- Silvia            11/03/2019  Consistencia de oportunidade
  -- Silvia            07/11/2019  Consistencia de faturamento
  -- Silvia            29/11/2019  Exclusao automatica de usuario_cargo
  -- Silvia            03/12/2019  Exclusao automatica de equipe_usuario
  -- Silvia            18/08/2020  Consistencia de usuario_situacao_id
  -- Silvia            14/04/2022  Consistencia de responsavel por servico
  -- Silvia            01/06/2022  Consistencia de orcam_aprov
  -- Silvia            21/06/2022  Consistencia de contrato_elab e contrato_fisico
  -- Silvia            21/06/2022  Consistencia de contrato_horas_usu
  -- Silvia            15/08/2022  Exclusao automatica de dia_alocacao
  -- Silvia            08/09/2022  Deixa excluir com registros no historico
  ------------------------------------------------------------------------------------------
  p_usuario_sessao_id IN usuario.usuario_id%TYPE,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_usuario_id        IN usuario.usuario_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) AS
  v_qt             INTEGER;
  v_admin          INTEGER;
  v_nome           pessoa.nome%TYPE;
  v_login          usuario.login%TYPE;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_exception      EXCEPTION;
  v_lbl_job        VARCHAR2(100);
  v_lbl_jobs       VARCHAR2(100);
  v_xml_atual      CLOB;
  --
 BEGIN
  p_erro_cod := ' ';
  p_erro_msg := ' ';
  v_lbl_job  := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  v_lbl_jobs := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_PLURAL');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'USUARIO_C', NULL, NULL, p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(u.login),
         MAX(p.nome)
    INTO v_login,
         v_nome
    FROM pessoa  p,
         usuario u
   WHERE u.usuario_id = p_usuario_id
     AND u.usuario_id = p.usuario_id;
  --
  IF v_login IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse usuário não existe.';
   RAISE v_exception;
  END IF;
  --
  -- verifica se o usuario que esta' sendo excluido e' o administrador
  SELECT COUNT(*)
    INTO v_admin
    FROM usuario
   WHERE usuario_id = p_usuario_id
     AND flag_admin_sistema = 'S';
  --
  IF v_admin = 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O usuário administrador do sistema não pode ser excluído.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM job_usuario
   WHERE usuario_id = p_usuario_id
     AND rownum = 1;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem ' || v_lbl_jobs || ' endereçados para esse usuário.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM job
   WHERE usuario_solic_id = p_usuario_id
     AND rownum = 1;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem ' || v_lbl_jobs || ' criados por esse usuário.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM arquivo
   WHERE usuario_alt_id = p_usuario_id
     AND rownum = 1;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem arquivos que foram alterados por esse usuário.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM apontam_data ad,
         apontam_hora ho
   WHERE ad.usuario_id = p_usuario_id
     AND ad.apontam_data_id = ho.apontam_data_id
     AND rownum = 1;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Usuário já fez apontamento de horas.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM apontam_data ad
   WHERE ad.usuario_aprov_id = p_usuario_id
     AND rownum = 1;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Usuário já fez aprovação de apontamento de horas.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM apontam_progr
   WHERE usuario_id = p_usuario_id
     AND rownum = 1;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem programações de apontamentos para esse usuário.';
   RAISE v_exception;
  END IF;
  --
  /*
    SELECT COUNT(*)
      INTO v_qt
      FROM historico
     WHERE usuario_id = p_usuario_id
       AND ROWNUM = 1;
  --
    IF v_qt > 0 THEN
       p_erro_cod := '90000';
       p_erro_msg := 'Existem registros de histórico associados a esse usuário.';
       RAISE v_exception;
    END IF;
  */
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM milestone
   WHERE usuario_autor_id = p_usuario_id
     AND rownum = 1;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem milestones associados a esse usuário.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM task
   WHERE usuario_autor_id = p_usuario_id
     AND rownum = 1;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem tasks associadas a esse usuário.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM task_coment
   WHERE usuario_id = p_usuario_id
     AND rownum = 1;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem comentários de tasks associados a esse usuário.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM task_hist
   WHERE usuario_id = p_usuario_id
     AND rownum = 1;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem históricos de tasks associados a esse usuário.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM task_hist_ciencia
   WHERE usuario_id = p_usuario_id
     AND rownum = 1;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem registros de ciência de tasks associados a esse usuário.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM os_usuario
   WHERE usuario_id = p_usuario_id
     AND rownum = 1;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem Workflows endereçados para esse usuário.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM os_link
   WHERE usuario_id = p_usuario_id
     AND rownum = 1;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem Links de Workflows associados a esse usuário.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM os_evento
   WHERE usuario_id = p_usuario_id
     AND rownum = 1;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem eventos de Workflow associados a esse usuário.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM os_afazer
   WHERE usuario_resp_id = p_usuario_id
     AND rownum = 1;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existe TO-DO list de Workflow associado a esse usuário.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM carta_acordo
   WHERE elaborador_id = p_usuario_id
     AND rownum = 1;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem cartas acordo associadas a esse usuário como elaborador.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM carta_acordo
   WHERE produtor_id = p_usuario_id
     AND rownum = 1;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem cartas acordo associadas a esse usuário como produtor.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM carta_acordo
   WHERE usuario_acei_id = p_usuario_id
     AND rownum = 1;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem aceites de cartas acordo feitos por esse usuário.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM sobra
   WHERE usuario_resp_id = p_usuario_id
     AND rownum = 1;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem sobras associadas a esse usuário.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM abatimento
   WHERE usuario_resp_id = p_usuario_id
     AND rownum = 1;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem abatimentos associados a esse usuário.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM email_carta
   WHERE usuario_resp_id = p_usuario_id
     AND rownum = 1;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem emails de carta acordo associados a esse usuário.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM salario
   WHERE usuario_id = p_usuario_id
     AND rownum = 1;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem salários associados a esse usuário.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM ajuste_job
   WHERE usuario_id = p_usuario_id
     AND rownum = 1;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem ajustes de receitas/despesas de ' || v_lbl_job ||
                 ' associados a esse usuário.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM tarefa
   WHERE usuario_de_id = p_usuario_id
     AND rownum = 1;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem Tasks associadas a esse usuário (solicitante).';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM tarefa_usuario
   WHERE usuario_para_id = p_usuario_id
     AND rownum = 1;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem Tasks associadas a esse usuário (destinatário).';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM tarefa_link
   WHERE usuario_id = p_usuario_id
     AND rownum = 1;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem Links de Tasks associados a esse usuário.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM tarefa_afazer
   WHERE usuario_resp_id = p_usuario_id
     AND rownum = 1;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existe TO-DO list de Task associado a esse usuário.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM ts_grupo
   WHERE usuario_resp_id = p_usuario_id
     AND rownum = 1;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem grupos de aprovação de timesheet associados a esse usuário (responsável).';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM ts_aprovador
   WHERE usuario_id = p_usuario_id
     AND rownum = 1;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse usuário está configurado como aprovador de timesheet.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM documento
   WHERE usuario_id = p_usuario_id
     AND rownum = 1;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem documentos associados a esse usuário.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM briefing
   WHERE usuario_id = p_usuario_id
     AND rownum = 1;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem briefings associados a esse usuário.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM brief_hist
   WHERE usuario_id = p_usuario_id
     AND rownum = 1;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem briefings associados a esse usuário.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM contrato
   WHERE usuario_solic_id = p_usuario_id
     AND rownum = 1;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem contratos associados a esse usuário.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM contrato
   WHERE usuario_desc_id = p_usuario_id
     AND rownum = 1;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem contratos associados a esse usuário.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM contrato_usuario
   WHERE usuario_id = p_usuario_id
     AND rownum = 1;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem contratos endereçados para esse usuário.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM contrato_elab
   WHERE usuario_id = p_usuario_id
     AND rownum = 1;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem históricos de elaboração de contrato associados a esse usuário.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM contrato_fisico
   WHERE usuario_elab_id = p_usuario_id
     AND rownum = 1;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem contratos físicos associados a esse usuário como elaborador.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM contrato_fisico
   WHERE usuario_motivo_id = p_usuario_id
     AND rownum = 1;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem contratos físicos associados a esse usuário.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM contrato_horas_usu
   WHERE usuario_id = p_usuario_id
     AND rownum = 1;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem horas alocadas em contratos para esse usuário.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM adiant_desp
   WHERE solicitante_id = p_usuario_id
     AND rownum = 1;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem adiantamentos solicitados por esse usuário.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM adiant_desp
   WHERE criador_id = p_usuario_id
     AND rownum = 1;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem adiantamentos criados por esse usuário.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM adiant_desp
   WHERE aprovador_id = p_usuario_id
     AND rownum = 1;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem adiantamentos aprovados por esse usuário.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM adiant_realiz
   WHERE usuario_id = p_usuario_id
     AND rownum = 1;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem adiantamentos realizados por esse usuário.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM desp_realiz
   WHERE usuario_id = p_usuario_id
     AND rownum = 1;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem despesas de adiantamentos realizadas por esse usuário.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM devol_realiz
   WHERE usuario_id = p_usuario_id
     AND rownum = 1;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem devoluções de adiantamentos realizadas por esse usuário.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM usuario_ender
   WHERE usuario_id = p_usuario_id
     AND rownum = 1;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem regras de coendereçamento associadas a esse usuário.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM usuario_coender
   WHERE usuario_id = p_usuario_id
     AND rownum = 1;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem regras de coendereçamento associadas a esse usuário.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM aval_fornec
   WHERE usuario_aval_id = p_usuario_id
     AND rownum = 1;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem avaliações de fornecedores feitas por esse usuário.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM os_horas
   WHERE usuario_id = p_usuario_id
     AND rownum = 1;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem estimativas de horas de Workflow feitas para esse usuário.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM orcam_usuario
   WHERE usuario_id = p_usuario_id
     AND rownum = 1;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem Estimativas de Custo endereçadas para esse usuário.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM orcam_fluxo_aprov
   WHERE usuario_id = p_usuario_id
     AND rownum = 1;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem aprovações de Estimativas de Custo associadas a esse usuário.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM apontam_ence
   WHERE usuario_ence_id = p_usuario_id
     AND rownum = 1;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem encerramentos de apontamentos feitos por esse usuário.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM oportunidade
   WHERE usuario_solic_id = p_usuario_id
     AND rownum = 1;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem Oportunidades criadas por esse usuário.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM oport_usuario
   WHERE usuario_id = p_usuario_id
     AND rownum = 1;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem Oportunidades endereçadas para esse usuário.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM interacao
   WHERE usuario_resp_id = p_usuario_id
     AND rownum = 1;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem Interações de Oportunidades associadas a esse usuário.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM faturamento
   WHERE usuario_fatur_id = p_usuario_id
     AND rownum = 1;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem Faturamentos associados a esse usuário.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM faturamento_ctr
   WHERE usuario_fatur_id = p_usuario_id
     AND rownum = 1;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem Faturamentos de Contratos associados a esse usuário.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM item_crono_usu
   WHERE usuario_id = p_usuario_id
     AND rownum = 1;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem estimativas de horas em Cronogramas de ' || v_lbl_job ||
                 ' para esse usuário.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM item_crono
   WHERE usuario_situacao_id = p_usuario_id
     AND rownum = 1;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem atividades de Cronogramas de ' || v_lbl_job ||
                 ' associadas a esse usuário.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM oportunidade
   WHERE usuario_resp_id = p_usuario_id
     AND rownum = 1;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem Oportunidades associadas a esse usuário.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM cenario_servico
   WHERE usuario_resp_id = p_usuario_id
     AND rownum = 1;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem Cenários/produtos associados a esse usuário.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM oport_servico
   WHERE usuario_resp_id = p_usuario_id
     AND rownum = 1;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem Oportunidades/produtos associados a esse usuário.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM contrato_serv_valor
   WHERE usuario_resp_id = p_usuario_id
     AND rownum = 1;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem Contratos/produtos associados a esse usuário.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  usuario_pkg.xml_gerar(p_usuario_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE pessoa
     SET usuario_id = NULL
   WHERE usuario_id = p_usuario_id;
  --
  DELETE FROM coment_usuario
   WHERE usuario_id = p_usuario_id;
  DELETE FROM apontam_data_ev ae
   WHERE EXISTS (SELECT 1
            FROM apontam_data ad
           WHERE ad.usuario_id = p_usuario_id
             AND ad.apontam_data_id = ae.apontam_data_id);
  DELETE FROM apontam_data
   WHERE usuario_id = p_usuario_id;
  DELETE FROM milestone_usuario
   WHERE usuario_id = p_usuario_id;
  DELETE FROM usuario_papel
   WHERE usuario_id = p_usuario_id;
  DELETE FROM usuario_pref
   WHERE usuario_id = p_usuario_id;
  DELETE FROM ts_equipe
   WHERE usuario_id = p_usuario_id;
  DELETE FROM notifica_usuario
   WHERE usuario_id = p_usuario_id;
  DELETE FROM notifica_desliga
   WHERE usuario_id = p_usuario_id;
  DELETE FROM tipo_job_usuario
   WHERE usuario_id = p_usuario_id;
  DELETE FROM usuario_empresa
   WHERE usuario_id = p_usuario_id;
  DELETE FROM pesquisa
   WHERE usuario_id = p_usuario_id;
  DELETE FROM hist_senha
   WHERE usuario_id = p_usuario_id;
  DELETE FROM usuario_cargo
   WHERE usuario_id = p_usuario_id;
  DELETE FROM equipe_usuario
   WHERE usuario_id = p_usuario_id;
  DELETE FROM dia_alocacao
   WHERE usuario_id = p_usuario_id;
  DELETE FROM historico
   WHERE usuario_id = p_usuario_id;
  DELETE FROM usuario
   WHERE usuario_id = p_usuario_id;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_login;
  v_compl_histor   := 'Pessoa: ' || v_nome;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'USUARIO',
                   'EXCLUIR',
                   v_identif_objeto,
                   p_usuario_id,
                   v_compl_histor,
                   NULL,
                   'N',
                   NULL,
                   v_xml_atual,
                   v_historico_id,
                   p_erro_cod,
                   p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  COMMIT;
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END excluir;
 --
 --
 PROCEDURE cargo_adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                    ProcessMind     DATA: 28/12/2016
  -- DESCRICAO: Inclusão de CARGO do usuario
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            28/12/2017  Nao deixa cadastrar cargo em empresas diferentes.
  -- Silvia            28/12/2017  Atualizacao de apontamentos do usuario.
  -- Silvia            20/02/2018  Troca do priv CARGO_CUSTO_PRECO_C por USUARIO_C
  -- Rafael            16/05/2025  Adicionado o filtro de empresa_id para não inativar o cargo da outra empresa
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_usuario_id        IN usuario.usuario_id%TYPE,
  p_cargo_id          IN cargo.cargo_id%TYPE,
  p_data_ini          IN VARCHAR2,
  p_nivel             IN VARCHAR2,
  p_usuario_cargo_id  OUT usuario_cargo.usuario_cargo_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt               INTEGER;
  v_identif_objeto   historico.identif_objeto%TYPE;
  v_compl_histor     historico.complemento%TYPE;
  v_historico_id     historico.historico_id%TYPE;
  v_exception        EXCEPTION;
  v_usuario_cargo_id usuario_cargo.usuario_cargo_id%TYPE;
  v_data_ini         usuario_cargo.data_ini%TYPE;
  v_data_ini_ant     usuario_cargo.data_ini%TYPE;
  v_nome_cargo       cargo.nome%TYPE;
  v_nome_usuario     pessoa.nome%TYPE;
  v_login            usuario.login%TYPE;
  v_empresa_id       empresa.empresa_id%TYPE;
  v_xml_antes        CLOB;
  v_xml_atual        CLOB;
  --
 BEGIN
  v_qt               := 0;
  p_usuario_cargo_id := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'USUARIO_C', p_usuario_id, NULL, p_empresa_id) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(u.login),
         MAX(p.nome)
    INTO v_login,
         v_nome_usuario
    FROM pessoa  p,
         usuario u
   WHERE u.usuario_id = p_usuario_id
     AND u.usuario_id = p.usuario_id;
  --
  IF v_login IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse usuário não existe.';
   RAISE v_exception;
  END IF;
  --
  v_empresa_id := usuario_pkg.empresa_padrao_retornar(p_usuario_id);
  --
  /*
    IF v_empresa_id <> p_empresa_id THEN
       p_erro_cod := '90000';
       p_erro_msg := 'A empresa padrão do usuário não é a mesma da empresa do cargo.';
       RAISE v_exception;
    END IF;
  */
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF rtrim(p_data_ini) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da data é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_cargo_id, 0) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do cargo é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM cargo
   WHERE cargo_id = p_cargo_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse cargo não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  IF data_validar('01' || p_data_ini) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Mês inválido (' || p_data_ini || ').';
   RAISE v_exception;
  END IF;
  --
  v_data_ini := data_converter('01' || p_data_ini);
  --
  SELECT MAX(data_ini)
    INTO v_data_ini_ant
    FROM usuario_cargo
   WHERE usuario_id = p_usuario_id;
  --
  IF v_data_ini <= v_data_ini_ant THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O mês não pode ser anterior ou igual a meses já cadastrados.';
   RAISE v_exception;
  END IF;
  --
  SELECT nome
    INTO v_nome_cargo
    FROM cargo
   WHERE cargo_id = p_cargo_id;
  --
  IF TRIM(p_nivel) IS NOT NULL AND util_pkg.desc_retornar('nivel_usuario', p_nivel) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Nível do usuário inválido (' || p_nivel || ').';
   RAISE v_exception;
  END IF;
  --
  /*
    -- verifia se usuario tem cargo em outra empresa
    SELECT COUNT(*)
      INTO v_qt
      FROM usuario_cargo uc,
           cargo ca
     WHERE uc.usuario_id = p_usuario_id
       AND uc.cargo_id = ca.cargo_id
       AND ca.empresa_id <> p_empresa_id;
  --
    IF v_qt > 0 THEN
       p_erro_cod := '90000';
       p_erro_msg := 'Usuário já possui cargo em outra empresa.';
       RAISE v_exception;
    END IF;
  */
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  usuario_pkg.xml_gerar(p_usuario_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  -- atualiza data_fim de eventual registro anterior em aberto
  -- RP_16052025 adicionado o filtro de empresa_id para não inativar o cargo da outra empresa
  UPDATE usuario_cargo
     SET data_fim = v_data_ini - 1
   WHERE usuario_id = p_usuario_id
     AND data_fim IS NULL
     AND cargo_id IN (
       SELECT c.cargo_id
         FROM cargo c
        WHERE c.empresa_id = p_empresa_id
   );
  -- RP_16052025F
  --
  SELECT seq_usuario_cargo.nextval
    INTO v_usuario_cargo_id
    FROM dual;
  --
  INSERT INTO usuario_cargo
   (usuario_cargo_id,
    usuario_id,
    cargo_id,
    data_ini,
    data_fim,
    nivel)
  VALUES
   (v_usuario_cargo_id,
    p_usuario_id,
    p_cargo_id,
    v_data_ini,
    NULL,
    TRIM(p_nivel));
  --
  -- atualiza o cargo/area de eventuais apontamentos realizados a partir dessa data
  apontam_pkg.apontamento_cargo_atualizar(p_usuario_id,
                                          p_empresa_id,
                                          v_data_ini,
                                          p_erro_cod,
                                          p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  usuario_pkg.xml_gerar(p_usuario_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_login;
  v_compl_histor   := 'Pessoa: ' || v_nome_usuario || ' (Novo cargo: ' || v_nome_cargo || ' - ' ||
                      p_nivel || ' - ' || mes_ano_mostrar(v_data_ini) || ')';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'USUARIO',
                   'ALTERAR',
                   v_identif_objeto,
                   p_usuario_id,
                   v_compl_histor,
                   NULL,
                   'N',
                   v_xml_antes,
                   v_xml_atual,
                   v_historico_id,
                   p_erro_cod,
                   p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  COMMIT;
  p_usuario_cargo_id := v_usuario_cargo_id;
  p_erro_cod         := '00000';
  p_erro_msg         := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END cargo_adicionar;
 --
 --
 PROCEDURE cargo_atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                    ProcessMind     DATA: 28/12/2016
  -- DESCRICAO: Alteracao de CARGO do usuario (apenas o mais recente, com data_fim
  --   em aberto).
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            28/12/2017  Nao deixa cadastrar cargo em empresas diferentes.
  -- Silvia            28/12/2017  Atualizacao de apontamentos do usuario.
  -- Silvia            20/02/2018  Troca do priv CARGO_CUSTO_PRECO_C por USUARIO_C
  -- Rafael            16/05/2025  Adicionado o filtro de empresa_id para não inativar o cargo da outra empresa
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_usuario_cargo_id  IN usuario_cargo.usuario_cargo_id%TYPE,
  p_cargo_id          IN usuario_cargo.cargo_id%TYPE,
  p_data_ini          IN VARCHAR2,
  p_nivel             IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_exception      EXCEPTION;
  v_usuario_id     usuario_cargo.usuario_id%TYPE;
  v_data_ini       usuario_cargo.data_ini%TYPE;
  v_data_ini_ant   usuario_cargo.data_ini%TYPE;
  v_data_fim       usuario_cargo.data_fim%TYPE;
  v_nome_cargo     cargo.nome%TYPE;
  v_nome_usuario   pessoa.nome%TYPE;
  v_login          usuario.login%TYPE;
  v_empresa_id     empresa.empresa_id%TYPE;
  v_xml_antes      CLOB;
  v_xml_atual      CLOB;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'USUARIO_C', NULL, NULL, p_empresa_id) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(usuario_id),
         MAX(data_fim)
    INTO v_usuario_id,
         v_data_fim
    FROM usuario_cargo
   WHERE usuario_cargo_id = p_usuario_cargo_id;
  --
  IF v_usuario_id IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Usuário X Cargo X Data não encontrado.';
   RAISE v_exception;
  END IF;
  --
  IF v_data_fim IS NOT NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Usuário X Cargo X Data não se encontra em aberto para edição.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(u.login),
         MAX(p.nome)
    INTO v_login,
         v_nome_usuario
    FROM pessoa  p,
         usuario u
   WHERE u.usuario_id = v_usuario_id
     AND u.usuario_id = p.usuario_id;
  --
  IF v_login IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse usuário não existe.';
   RAISE v_exception;
  END IF;
  --
  v_empresa_id := usuario_pkg.empresa_padrao_retornar(v_usuario_id);
  --
  /*
    IF v_empresa_id <> p_empresa_id THEN
       p_erro_cod := '90000';
       p_erro_msg := 'A empresa padrão do usuário não é a mesma da empresa do cargo.';
       RAISE v_exception;
    END IF;
  */
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF rtrim(p_data_ini) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da data é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_cargo_id, 0) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do cargo é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM cargo
   WHERE cargo_id = p_cargo_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse cargo não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  IF data_validar('01' || p_data_ini) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Mês inválido (' || p_data_ini || ').';
   RAISE v_exception;
  END IF;
  --
  v_data_ini := data_converter('01' || p_data_ini);
  --
  SELECT MAX(data_ini)
    INTO v_data_ini_ant
    FROM usuario_cargo
   WHERE usuario_id = v_usuario_id
     AND usuario_cargo_id <> p_usuario_cargo_id;
  --
  IF v_data_ini <= v_data_ini_ant THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O mês não pode ser anterior ou igual a meses já cadastrados.';
   RAISE v_exception;
  END IF;
  --
  SELECT nome
    INTO v_nome_cargo
    FROM cargo
   WHERE cargo_id = p_cargo_id;
  --
  IF TRIM(p_nivel) IS NOT NULL AND util_pkg.desc_retornar('nivel_usuario', p_nivel) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Nível do usuário inválido (' || p_nivel || ').';
   RAISE v_exception;
  END IF;
  --
  /*
    -- verifia se usuario tem cargo em outra empresa
    SELECT COUNT(*)
      INTO v_qt
      FROM usuario_cargo uc,
           cargo ca
     WHERE uc.usuario_id = v_usuario_id
       AND uc.cargo_id = ca.cargo_id
       AND uc.usuario_cargo_id <> p_usuario_cargo_id
       AND ca.empresa_id <> p_empresa_id;
  --
    IF v_qt > 0 THEN
       p_erro_cod := '90000';
       p_erro_msg := 'Usuário já possui cargo em outra empresa.';
       RAISE v_exception;
    END IF;
  */
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  usuario_pkg.xml_gerar(v_usuario_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE usuario_cargo
     SET cargo_id = p_cargo_id,
         data_ini = v_data_ini,
         data_fim = NULL,
         nivel    = TRIM(p_nivel)
   WHERE usuario_cargo_id = p_usuario_cargo_id;
  --
  IF v_data_ini_ant IS NOT NULL THEN
   -- ajusta data_fim do periodo anterior
   -- RP_16052025 adicionado o filtro de empresa_id para não inativar o cargo da outra empresa
   UPDATE usuario_cargo
      SET data_fim = v_data_ini - 1
    WHERE usuario_id = v_usuario_id
      AND data_ini = v_data_ini_ant
      AND cargo_id IN (
       SELECT c.cargo_id
         FROM cargo c
        WHERE c.empresa_id = p_empresa_id
   );
  END IF;
  --  RP_16052025F
  --
  IF v_data_ini_ant IS NULL THEN
   v_data_ini_ant := v_data_ini;
  END IF;
  --
  -- atualiza o cargo/area de eventuais apontamentos realizados a partir da data anterior
  apontam_pkg.apontamento_cargo_atualizar(v_usuario_id,
                                          p_empresa_id,
                                          v_data_ini_ant,
                                          p_erro_cod,
                                          p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  usuario_pkg.xml_gerar(v_usuario_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_login;
  v_compl_histor   := 'Pessoa: ' || v_nome_usuario || ' (Alteração de cargo: ' || v_nome_cargo ||
                      ' - ' || p_nivel || ' - ' || mes_ano_mostrar(v_data_ini) || ')';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'USUARIO',
                   'ALTERAR',
                   v_identif_objeto,
                   v_usuario_id,
                   v_compl_histor,
                   NULL,
                   'N',
                   v_xml_antes,
                   v_xml_atual,
                   v_historico_id,
                   p_erro_cod,
                   p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  COMMIT;
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END cargo_atualizar;
 --
 --
 PROCEDURE cargo_excluir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                    ProcessMind     DATA: 28/12/2016
  -- DESCRICAO: Exclusao de CARGO do usuario (apenas o mais recente, com data_fim
  --   em aberto).
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            28/12/2017  Atualizacao de apontamentos do usuario.
  -- Silvia            28/12/2017  Atualizacao de apontamentos do usuario.
  -- Silvia            20/02/2018  Troca do priv CARGO_CUSTO_PRECO_C por USUARIO_C
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_usuario_cargo_id  IN usuario_cargo.usuario_cargo_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt               INTEGER;
  v_identif_objeto   historico.identif_objeto%TYPE;
  v_compl_histor     historico.complemento%TYPE;
  v_historico_id     historico.historico_id%TYPE;
  v_exception        EXCEPTION;
  v_usuario_cargo_id usuario_cargo.usuario_cargo_id%TYPE;
  v_usuario_id       usuario_cargo.usuario_id%TYPE;
  v_data_ini         usuario_cargo.data_ini%TYPE;
  v_data_ini_ant     usuario_cargo.data_ini%TYPE;
  v_data_fim         usuario_cargo.data_fim%TYPE;
  v_cargo_id         usuario_cargo.cargo_id%TYPE;
  v_nivel            usuario_cargo.nivel%TYPE;
  v_nome_cargo       cargo.nome%TYPE;
  v_nome_usuario     pessoa.nome%TYPE;
  v_login            usuario.login%TYPE;
  v_empresa_id       empresa.empresa_id%TYPE;
  v_xml_antes        CLOB;
  v_xml_atual        CLOB;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'USUARIO_C', NULL, NULL, p_empresa_id) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM usuario_cargo
   WHERE usuario_cargo_id = p_usuario_cargo_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Usuário X Cargo X Data não encontrado.';
   RAISE v_exception;
  END IF;
  --
  SELECT uc.usuario_id,
         uc.data_ini,
         uc.data_fim,
         uc.cargo_id,
         uc.nivel,
         ca.empresa_id
    INTO v_usuario_id,
         v_data_ini,
         v_data_fim,
         v_cargo_id,
         v_nivel,
         v_empresa_id
    FROM usuario_cargo uc,
         cargo         ca
   WHERE uc.usuario_cargo_id = p_usuario_cargo_id
     AND uc.cargo_id = ca.cargo_id;
  --
  IF v_data_fim IS NOT NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Usuário X Cargo X Data não se encontra em aberto para edição.';
   RAISE v_exception;
  END IF;
  --
  IF v_empresa_id <> p_empresa_id THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse cargo não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(u.login),
         MAX(p.nome)
    INTO v_login,
         v_nome_usuario
    FROM pessoa  p,
         usuario u
   WHERE u.usuario_id = v_usuario_id
     AND u.usuario_id = p.usuario_id;
  --
  IF v_login IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse usuário não existe.';
   RAISE v_exception;
  END IF;
  --
  /*
    v_empresa_id := usuario_pkg.empresa_padrao_retornar(v_usuario_id);
    --
    IF v_empresa_id <> p_empresa_id THEN
       p_erro_cod := '90000';
       p_erro_msg := 'A empresa padrão do usuário não é a mesma da empresa do cargo.';
       RAISE v_exception;
    END IF;
  */
  --
  SELECT nome
    INTO v_nome_cargo
    FROM cargo
   WHERE cargo_id = v_cargo_id;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  usuario_pkg.xml_gerar(v_usuario_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  DELETE FROM usuario_cargo
   WHERE usuario_cargo_id = p_usuario_cargo_id;
  --
  -- procura pelo cargo anterior do usuario, nessa mesma empresa
  SELECT MAX(data_ini)
    INTO v_data_ini_ant
    FROM usuario_cargo uc,
         cargo         ca
   WHERE uc.usuario_id = v_usuario_id
     AND uc.cargo_id = ca.cargo_id
     AND ca.empresa_id = p_empresa_id;
  --
  IF v_data_ini_ant IS NOT NULL THEN
   SELECT MAX(usuario_cargo_id)
     INTO v_usuario_cargo_id
     FROM usuario_cargo uc,
          cargo         ca
    WHERE uc.usuario_id = v_usuario_id
      AND uc.cargo_id = ca.cargo_id
      AND ca.empresa_id = p_empresa_id
      AND data_ini = v_data_ini_ant;
   --
   -- reabre o cargo (torna vigente)
   UPDATE usuario_cargo
      SET data_fim = NULL
    WHERE usuario_cargo_id = v_usuario_cargo_id;
  END IF;
  --
  IF v_data_ini_ant IS NOT NULL THEN
   -- atualiza o cargo/area de eventuais apontamentos realizados a partir da data anterior
   apontam_pkg.apontamento_cargo_atualizar(v_usuario_id,
                                           p_empresa_id,
                                           v_data_ini_ant,
                                           p_erro_cod,
                                           p_erro_msg);
   --
   IF p_erro_cod <> '00000' THEN
    RAISE v_exception;
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  usuario_pkg.xml_gerar(v_usuario_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_login;
  v_compl_histor   := 'Pessoa: ' || v_nome_usuario || ' (Exclusão de cargo: ' || v_nome_cargo ||
                      ' - ' || v_nivel || ' - ' || mes_ano_mostrar(v_data_ini) || ')';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'USUARIO',
                   'ALTERAR',
                   v_identif_objeto,
                   v_usuario_id,
                   v_compl_histor,
                   NULL,
                   'N',
                   v_xml_antes,
                   v_xml_atual,
                   v_historico_id,
                   p_erro_cod,
                   p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  COMMIT;
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END cargo_excluir;
 --
 --
 PROCEDURE autenticar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 06/10/2004
  -- DESCRICAO: autentica o login do usuario e a senha.
  --  Retorna o usuario_id caso seja uma identificacao valida,
  --  ou memsagem de erro, caso nao seja.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            12/04/2010  Implementacao de multiagencia.
  -- Silvia            31/10/2011  Implementacao de registro de login.
  -- Silvia            26/12/2017  Testa definicao de cargo.
  -- Silvia            23/07/2018  Novo parametro cod_hash_wallboard
  -- Silvia            20/05/2022  Troca de pacote de encriptacao
  -- Ana Luiza         13/12/2024  Adicionando empresa padrão na chamada do_usuario_retornar         
  ------------------------------------------------------------------------------------------
  p_tipo_acesso        IN VARCHAR2,
  p_login              IN usuario.login%TYPE,
  p_senha              IN usuario.senha%TYPE,
  p_cod_hash_wallboard IN VARCHAR2,
  p_usuario_id         OUT usuario.usuario_id%TYPE,
  p_apelido            OUT pessoa.apelido%TYPE,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 ) AS
  v_qt                    INTEGER;
  v_usuario_id            usuario.usuario_id%TYPE;
  v_exception             EXCEPTION;
  v_senha_encriptada      usuario.senha%TYPE;
  v_senha_desencriptada   VARCHAR2(1000);
  v_qt_login_invalido_usu usuario.qtd_login_invalido%TYPE;
  v_qt_login_invalido_max usuario.qtd_login_invalido%TYPE;
  v_flag_bloqueado        usuario.flag_bloqueado%TYPE;
  v_flag_acesso_pri       usuario.flag_acesso_pri%TYPE;
  v_flag_acesso_cli       usuario.flag_acesso_cli%TYPE;
  v_flag_acesso_wall      usuario.flag_acesso_wall%TYPE;
  v_flag_admin            usuario.flag_admin%TYPE;
  v_apelido               pessoa.apelido%TYPE;
  v_identif_objeto        historico.identif_objeto%TYPE;
  v_compl_histor          historico.complemento%TYPE;
  v_historico_id          historico.historico_id%TYPE;
  v_empresa_id            empresa.empresa_id%TYPE;
  v_flag_cargo_obr        VARCHAR2(10);
  --
 BEGIN
  p_erro_cod   := ' ';
  p_erro_msg   := ' ';
  p_usuario_id := 0;
  p_apelido    := ' ';
  --
  IF TRIM(p_tipo_acesso) IS NULL OR p_tipo_acesso NOT IN ('PRINCIPAL', 'CLIENTE', 'WALLBOARD') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de acesso inválido (' || p_tipo_acesso || ').';
   RAISE v_exception;
  END IF;
  --
  IF p_tipo_acesso <> 'WALLBOARD' THEN
   -- consistencias para login normal
   IF rtrim(p_login) IS NULL THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O preenchimendo do usuário é obrigatório.';
    RAISE v_exception;
   END IF;
   --
   IF TRIM(p_senha) IS NULL THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O preenchimendo da senha é obrigatório.';
    RAISE v_exception;
   END IF;
   --
   -- verifica se existe usuario ativo com essa
   -- identificacao
   -- (o MAX foi utilizado para evitar NO DATA FOUND)
   SELECT MAX(usuario_id),
          MAX(senha),
          nvl(MAX(qtd_login_invalido), 0)
     INTO v_usuario_id,
          v_senha_encriptada,
          v_qt_login_invalido_usu
     FROM usuario
    WHERE upper(rtrim(login)) = upper(rtrim(p_login))
      AND flag_bloqueado = 'N'
      AND flag_ativo = 'S';
  ELSE
   -- consistencias para login do wallboard
   -- verifica se existe usuario ativo com esse cod hash
   -- (o MAX foi utilizado para evitar NO DATA FOUND)
   SELECT MAX(usuario_id),
          MAX(senha),
          nvl(MAX(qtd_login_invalido), 0)
     INTO v_usuario_id,
          v_senha_encriptada,
          v_qt_login_invalido_usu
     FROM usuario
    WHERE cod_hash_wallboard = TRIM(p_cod_hash_wallboard)
      AND flag_bloqueado = 'N'
      AND flag_ativo = 'S';
  END IF;
  --
  IF v_usuario_id IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Identificação do usuário inválida.';
   RAISE v_exception;
  END IF;
  --
  SELECT flag_acesso_pri,
         flag_acesso_cli,
         flag_acesso_wall,
         flag_admin
    INTO v_flag_acesso_pri,
         v_flag_acesso_cli,
         v_flag_acesso_wall,
         v_flag_admin
    FROM usuario
   WHERE usuario_id = v_usuario_id;
  --
  IF v_flag_admin = 'N' AND p_tipo_acesso = 'PRINCIPAL' AND v_flag_acesso_pri = 'N' THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Usuário sem acesso à interface Principal.';
   RAISE v_exception;
  END IF;
  --
  IF v_flag_admin = 'N' AND p_tipo_acesso = 'CLIENTE' AND v_flag_acesso_cli = 'N' THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Usuário sem acesso à interface Do Cliente.';
   RAISE v_exception;
  END IF;
  --
  IF p_tipo_acesso = 'WALLBOARD' AND v_flag_acesso_wall = 'N' THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Usuário sem acesso à interface Do Wallboard.';
   RAISE v_exception;
  END IF;
  --
  v_empresa_id            := usuario_pkg.empresa_padrao_retornar(v_usuario_id);
  v_qt_login_invalido_max := to_number(empresa_pkg.parametro_retornar(v_empresa_id,
                                                                      'QT_LOGIN_INVALIDO'));
  v_flag_cargo_obr        := empresa_pkg.parametro_retornar(v_empresa_id, 'FLAG_CARGO_OBRIGATORIO');
  --
  IF p_tipo_acesso <> 'WALLBOARD' THEN
   --util_pkg.encriptar( NULL, p_senha, v_senha_encriptada, p_erro_cod, p_erro_msg);
   --v_senha_encriptada := util_pkg.texto_encriptar(p_senha,NULL);
   v_senha_desencriptada := util_pkg.texto_desencriptar(v_senha_encriptada, g_key_str2);
   IF v_senha_desencriptada IS NULL OR v_senha_desencriptada = 'ERRO' THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Erro na desencriptação da senha.';
    RAISE v_exception;
   END IF;
   --ALCBO_131224
  
   --
   IF v_flag_admin = 'N' AND v_flag_cargo_obr = 'S' AND
      cargo_pkg.do_usuario_retornar(v_usuario_id, trunc(SYSDATE), NULL) IS NULL THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Usuário sem cargo definido.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  v_flag_bloqueado := 'N';
  --
  IF p_tipo_acesso <> 'WALLBOARD' AND p_senha <> v_senha_desencriptada THEN
   v_qt_login_invalido_usu := v_qt_login_invalido_usu + 1;
   v_flag_bloqueado        := 'N';
   --
   IF v_qt_login_invalido_usu >= v_qt_login_invalido_max THEN
    v_flag_bloqueado := 'S';
   END IF;
  ELSE
   -- acesso via WALLBOARD ou senha valida
   -- zera qtd delogin invalido
   v_qt_login_invalido_usu := 0;
  END IF;
  --
  SELECT MAX(apelido)
    INTO v_apelido
    FROM pessoa
   WHERE usuario_id = v_usuario_id;
  --
  p_apelido := v_apelido;
  --
  UPDATE usuario
     SET qtd_login_invalido = v_qt_login_invalido_usu,
         flag_bloqueado     = v_flag_bloqueado
   WHERE usuario_id = v_usuario_id;
  --
  ------------------------------------------------------------
  -- geracao de evento de bloqueio
  ------------------------------------------------------------
  IF v_flag_bloqueado = 'S' THEN
   v_identif_objeto := initcap(rtrim(p_login));
   v_compl_histor   := 'Apelido: ' || v_apelido;
   --
   evento_pkg.gerar(v_usuario_id,
                    v_empresa_id,
                    'USUARIO',
                    'BLOQUEAR',
                    v_identif_objeto,
                    v_usuario_id,
                    v_compl_histor,
                    NULL,
                    'N',
                    NULL,
                    NULL,
                    v_historico_id,
                    p_erro_cod,
                    p_erro_msg);
   --
   IF p_erro_cod <> '00000' THEN
    RAISE v_exception;
   END IF;
  END IF;
  --
  COMMIT;
  --
  -- deixa para dar a mesagem no final, apos atualizacao do banco
  IF p_tipo_acesso <> 'WALLBOARD' AND p_senha <> v_senha_desencriptada THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Identificação do usuário inválida.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento de login
  ------------------------------------------------------------
  v_identif_objeto := initcap(rtrim(p_login) || ' - ' || p_tipo_acesso);
  v_compl_histor   := 'Apelido: ' || v_apelido;
  --
  evento_pkg.gerar(v_usuario_id,
                   v_empresa_id,
                   'USUARIO',
                   'LOGAR',
                   v_identif_objeto,
                   v_usuario_id,
                   v_compl_histor,
                   NULL,
                   'N',
                   NULL,
                   NULL,
                   v_historico_id,
                   p_erro_cod,
                   p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  UPDATE usuario
     SET data_ult_login = SYSDATE
   WHERE usuario_id = v_usuario_id;
  --
  COMMIT;
  p_usuario_id := v_usuario_id;
  p_erro_cod   := '00000';
  p_erro_msg   := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END autenticar;
 --
 --
 PROCEDURE login_registrar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 13/12/2013
  -- DESCRICAO: registra evento de login do usuario quando realizado por fora do
  -- JobOne.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            15/09/2017  Novo parametro tipo_acesso
  -- Silvia            26/12/2017  Testa definicao de cargo.
  ------------------------------------------------------------------------------------------
  p_tipo_acesso IN VARCHAR2,
  p_usuario_id  IN usuario.usuario_id%TYPE,
  p_erro_cod    OUT VARCHAR2,
  p_erro_msg    OUT VARCHAR2
 ) AS
  v_qt              INTEGER;
  v_exception       EXCEPTION;
  v_apelido         pessoa.apelido%TYPE;
  v_login           usuario.login%TYPE;
  v_identif_objeto  historico.identif_objeto%TYPE;
  v_compl_histor    historico.complemento%TYPE;
  v_historico_id    historico.historico_id%TYPE;
  v_empresa_id      empresa.empresa_id%TYPE;
  v_flag_acesso_pri usuario.flag_acesso_pri%TYPE;
  v_flag_acesso_cli usuario.flag_acesso_cli%TYPE;
  v_flag_admin      usuario.flag_admin%TYPE;
  --
 BEGIN
  --
  IF TRIM(p_tipo_acesso) IS NULL OR p_tipo_acesso NOT IN ('PRINCIPAL', 'CLIENTE') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de acesso inválido (' || p_tipo_acesso || ').';
   RAISE v_exception;
  END IF;
  --
  v_empresa_id := usuario_pkg.empresa_padrao_retornar(p_usuario_id);
  --
  SELECT MAX(apelido)
    INTO v_apelido
    FROM pessoa
   WHERE usuario_id = p_usuario_id;
  --
  IF v_apelido IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse usuário não existe (' || to_char(p_usuario_id) || ').';
   RAISE v_exception;
  END IF;
  --
  SELECT login,
         flag_acesso_pri,
         flag_acesso_cli,
         flag_admin
    INTO v_login,
         v_flag_acesso_pri,
         v_flag_acesso_cli,
         v_flag_admin
    FROM usuario
   WHERE usuario_id = p_usuario_id;
  --
  IF v_flag_admin = 'N' AND p_tipo_acesso = 'PRINCIPAL' AND v_flag_acesso_pri = 'N' THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Usuário sem acesso à interface Principal.';
   RAISE v_exception;
  END IF;
  --
  IF v_flag_admin = 'N' AND p_tipo_acesso = 'CLIENTE' AND v_flag_acesso_cli = 'N' THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Usuário sem acesso à interface Do Cliente.';
   RAISE v_exception;
  END IF;
  --
  IF v_flag_admin = 'N' AND
     cargo_pkg.do_usuario_retornar(p_usuario_id, trunc(SYSDATE), NULL) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Usuário sem cargo definido.';
   RAISE v_exception;
  END IF;
  --
  UPDATE usuario
     SET qtd_login_invalido = 0,
         flag_bloqueado     = 'N'
   WHERE usuario_id = p_usuario_id;
  --
  ------------------------------------------------------------
  -- geracao de evento de login
  ------------------------------------------------------------
  v_identif_objeto := initcap(rtrim(v_login));
  v_compl_histor   := 'Apelido: ' || v_apelido;
  --
  evento_pkg.gerar(p_usuario_id,
                   v_empresa_id,
                   'USUARIO',
                   'LOGAR',
                   v_identif_objeto,
                   p_usuario_id,
                   v_compl_histor,
                   NULL,
                   'N',
                   NULL,
                   NULL,
                   v_historico_id,
                   p_erro_cod,
                   p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  UPDATE usuario
     SET data_ult_login = SYSDATE
   WHERE usuario_id = p_usuario_id;
  --
  COMMIT;
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END login_registrar;
 --
 --
 PROCEDURE senha_atualizar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 06/10/2004
  -- DESCRICAO: atualiza a senha de determinado usuario.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            13/08/2014  Permitir atualizar a senha via codigo hash (sem a senha
  --                               antiga).
  -- Silvia            28/09/2018  Implementacao de alteracoes de seguranca da senha.
  -- Silvia            16/05/2023  Ajuste no teste da senha atual
  ------------------------------------------------------------------------------------------
  p_usuario_sessao_id IN usuario.usuario_id%TYPE,
  p_senha_old         IN VARCHAR2,
  p_senha_new         IN usuario.senha%TYPE,
  p_senha_new_conf    IN usuario.senha%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) AS
  v_qt                  INTEGER;
  v_exception           EXCEPTION;
  v_login               usuario.login%TYPE;
  v_nome                pessoa.nome%TYPE;
  v_apelido             pessoa.apelido%TYPE;
  v_identif_objeto      historico.identif_objeto%TYPE;
  v_compl_histor        historico.complemento%TYPE;
  v_historico_id        historico.historico_id%TYPE;
  v_senha_encriptada    usuario.senha%TYPE;
  v_senha_desencriptada VARCHAR2(1000);
  v_cod_hash            usuario.cod_hash%TYPE;
  v_data_hash           usuario.data_hash%TYPE;
  v_empresa_id          empresa.empresa_id%TYPE;
  v_num_dias_exp_senha  NUMBER(10);
  v_data_exp_senha      DATE;
  v_qt_reuso_senha      NUMBER(10);
  --
  CURSOR c_hi IS
   SELECT hist_senha_id
     FROM hist_senha
    WHERE usuario_id = p_usuario_sessao_id
    ORDER BY data_entrada  DESC,
             hist_senha_id DESC;
  --
 BEGIN
  p_erro_cod := ' ';
  p_erro_msg := ' ';
  --
  SELECT MAX(u.login),
         MAX(p.nome),
         MAX(p.apelido)
    INTO v_login,
         v_nome,
         v_apelido
    FROM usuario u,
         pessoa  p
   WHERE u.usuario_id = p_usuario_sessao_id
     AND u.usuario_id = p.usuario_id;
  --
  IF v_login IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse usuário não existe.';
   RAISE v_exception;
  END IF;
  --
  v_empresa_id := usuario_pkg.empresa_padrao_retornar(p_usuario_sessao_id);
  --
  SELECT cod_hash,
         data_hash,
         senha
    INTO v_cod_hash,
         v_data_hash,
         v_senha_encriptada
    FROM usuario
   WHERE usuario_id = p_usuario_sessao_id;
  --
  v_num_dias_exp_senha := to_number(empresa_pkg.parametro_retornar(v_empresa_id,
                                                                   'NUM_DIAS_REDEFINIR_SENHA'));
  v_qt_reuso_senha     := to_number(empresa_pkg.parametro_retornar(v_empresa_id,
                                                                   'NAO_PERMITIR_REUSO_SENHA'));
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF TRIM(p_senha_old) IS NULL OR TRIM(p_senha_new) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da senha atual e da nova senha é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF p_senha_new <> p_senha_new_conf OR TRIM(p_senha_new_conf) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A confirmação da nova senha não confere.';
   RAISE v_exception;
  END IF;
  --
  usuario_pkg.senha_validar(v_empresa_id,
                            v_nome,
                            v_apelido,
                            v_login,
                            p_senha_new,
                            p_erro_cod,
                            p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  IF p_senha_old = nvl(v_cod_hash, 'ZW89345WERRW988') THEN
   -- login via codigo hash (recebido no parametro p_senha_old)
   SELECT COUNT(*)
     INTO v_qt
     FROM usuario
    WHERE usuario_id = p_usuario_sessao_id
      AND cod_hash = v_cod_hash;
   --
   IF v_qt = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Solicitação de redefinição de senha expirada ou inválida.';
    RAISE v_exception;
   END IF;
   --
   -- testa validade de 8 horas do codigo hash
   IF v_data_hash + 8 / 24 < SYSDATE THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Solicitação de redefinição de senha expirada ou inválida.';
    RAISE v_exception;
   END IF;
  ELSE
   -- verifica a senha antiga
   v_senha_desencriptada := util_pkg.texto_desencriptar(v_senha_encriptada, g_key_str2);
   IF v_senha_desencriptada IS NULL OR v_senha_desencriptada = 'ERRO' THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Erro na desencriptação da senha.';
    RAISE v_exception;
   END IF;
   --
   IF p_senha_old <> v_senha_desencriptada THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Senha atual inválida.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  --util_pkg.encriptar( NULL, p_senha_new, v_senha_encriptada, p_erro_cod, p_erro_msg);
  v_senha_encriptada := util_pkg.texto_encriptar(p_senha_new, NULL);
  IF v_senha_encriptada IS NULL OR length(v_senha_encriptada) > 256 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Nova senha com tamanho inválido ou com erro na encriptação.';
   RAISE v_exception;
  END IF;
  --
  IF v_qt_reuso_senha > 0 THEN
   -- nao pode repetir determinado numero de senhas anteriores.
   -- primeiro limpa eventuais senhas mais antigas.
   v_qt := 0;
   FOR r_hi IN c_hi
   LOOP
    v_qt := v_qt + 1;
    --
    IF v_qt > v_qt_reuso_senha THEN
     DELETE FROM hist_senha
      WHERE hist_senha_id = r_hi.hist_senha_id;
    END IF;
   END LOOP;
   --
   -- verifica senha ja utilizada
   SELECT COUNT(*)
     INTO v_qt
     FROM hist_senha
    WHERE usuario_id = p_usuario_sessao_id
      AND senha = v_senha_encriptada;
   --
   IF v_qt > 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Essa senha já foi utilizada anteriormente.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF v_num_dias_exp_senha = 0 THEN
   -- a senha nunca expira
   v_data_exp_senha := NULL;
  ELSE
   v_data_exp_senha := trunc(SYSDATE) + v_num_dias_exp_senha;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE usuario
     SET senha              = v_senha_encriptada,
         data_exp_senha     = v_data_exp_senha,
         cod_hash           = NULL,
         data_hash          = NULL,
         flag_bloqueado     = 'N',
         qtd_login_invalido = 0
   WHERE usuario_id = p_usuario_sessao_id;
  --
  INSERT INTO hist_senha
   (hist_senha_id,
    usuario_id,
    senha,
    data_entrada)
  VALUES
   (seq_hist_senha.nextval,
    p_usuario_sessao_id,
    v_senha_encriptada,
    SYSDATE);
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_login;
  v_compl_histor   := 'Alteração de Senha. Pessoa: ' || v_nome;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   v_empresa_id,
                   'USUARIO',
                   'ALTERAR',
                   v_identif_objeto,
                   p_usuario_sessao_id,
                   v_compl_histor,
                   NULL,
                   'N',
                   NULL,
                   NULL,
                   v_historico_id,
                   p_erro_cod,
                   p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  COMMIT;
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END senha_atualizar;
 --
 --
 PROCEDURE senha_configurar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 28/09/2018
  -- DESCRICAO: alteracao da senha de determinado usuario pelo administrador do sistema.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_usuario_sessao_id IN usuario.usuario_id%TYPE,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_usuario_id        IN usuario.usuario_id%TYPE,
  p_senha_new         IN usuario.senha%TYPE,
  p_senha_new_conf    IN usuario.senha%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) AS
  v_qt                 INTEGER;
  v_exception          EXCEPTION;
  v_login              usuario.login%TYPE;
  v_nome               pessoa.nome%TYPE;
  v_identif_objeto     historico.identif_objeto%TYPE;
  v_compl_histor       historico.complemento%TYPE;
  v_historico_id       historico.historico_id%TYPE;
  v_senha_encriptada   usuario.senha%TYPE;
  v_data_exp_senha     DATE;
  v_num_dias_exp_senha NUMBER(10);
  v_flag_redef_senha   VARCHAR2(10);
  --
 BEGIN
  --
  v_num_dias_exp_senha := to_number(empresa_pkg.parametro_retornar(p_empresa_id,
                                                                   'NUM_DIAS_REDEFINIR_SENHA'));
  v_flag_redef_senha   := empresa_pkg.parametro_retornar(p_empresa_id, 'REDEFINIR_SENHA_ALTERADA');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'USUARIO_C', NULL, NULL, p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(u.login),
         MAX(p.nome)
    INTO v_login,
         v_nome
    FROM usuario u,
         pessoa  p
   WHERE u.usuario_id = p_usuario_id
     AND u.usuario_id = p.usuario_id;
  --
  IF v_login IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse usuário não existe.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF p_senha_new <> p_senha_new_conf OR TRIM(p_senha_new_conf) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A confirmação da nova senha não confere.';
   RAISE v_exception;
  END IF;
  --
  IF length(p_senha_new) < 4 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A nova senha deve ter no mínimo 4 caracteres.';
   RAISE v_exception;
  END IF;
  --
  --util_pkg.encriptar( NULL, p_senha_new, v_senha_encriptada, p_erro_cod, p_erro_msg);
  v_senha_encriptada := util_pkg.texto_encriptar(p_senha_new, NULL);
  IF v_senha_encriptada IS NULL OR length(v_senha_encriptada) > 256 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Nova senha com tamanho inválido ou com erro na encriptação.';
   RAISE v_exception;
  END IF;
  --
  IF v_num_dias_exp_senha = 0 THEN
   -- a senha nunca expira
   v_data_exp_senha := NULL;
  ELSE
   v_data_exp_senha := trunc(SYSDATE) + v_num_dias_exp_senha;
  END IF;
  --
  IF v_flag_redef_senha = 'S' THEN
   -- forca o usuario a redefinir a senha no proximo login
   v_data_exp_senha := trunc(SYSDATE);
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE usuario
     SET senha              = v_senha_encriptada,
         data_exp_senha     = v_data_exp_senha,
         cod_hash           = NULL,
         data_hash          = NULL,
         flag_bloqueado     = 'N',
         qtd_login_invalido = 0
   WHERE usuario_id = p_usuario_id;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_login;
  v_compl_histor   := 'Configuração de Senha. Pessoa: ' || v_nome;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'USUARIO',
                   'ALTERAR',
                   v_identif_objeto,
                   p_usuario_id,
                   v_compl_histor,
                   NULL,
                   'N',
                   NULL,
                   NULL,
                   v_historico_id,
                   p_erro_cod,
                   p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  COMMIT;
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END senha_configurar;
 --
 --
 --
 PROCEDURE senha_redefinir
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 13/08/2014
  -- DESCRICAO: gera cod hash para que o usuario que esqueceu a senha possa redefini-la.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            10/04/2017  Antiga proc cod_hash_gerar. Adaptada para aceitar email
  --                               ou login.
  ------------------------------------------------------------------------------------------
  p_email_login IN VARCHAR2,
  p_cod_hash    OUT usuario.cod_hash%TYPE,
  p_erro_cod    OUT VARCHAR2,
  p_erro_msg    OUT VARCHAR2
 ) AS
  v_qt         INTEGER;
  v_exception  EXCEPTION;
  v_cod_hash   usuario.cod_hash%TYPE;
  v_usuario_id usuario.usuario_id%TYPE;
  v_flag_ativo usuario.flag_ativo%TYPE;
  --
 BEGIN
  p_cod_hash := ' ';
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  SELECT COUNT(*),
         MAX(us.usuario_id)
    INTO v_qt,
         v_usuario_id
    FROM usuario us,
         pessoa  pe
   WHERE upper(TRIM(pe.email)) = upper(TRIM(p_email_login))
     AND pe.usuario_id = us.usuario_id;
  --
  IF v_qt > 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existe mais de um usuário com esse E-mail.';
   RAISE v_exception;
  END IF;
  --
  IF v_usuario_id IS NULL THEN
   -- nao achou pelo email. Tenta via login
   SELECT MAX(us.usuario_id)
     INTO v_usuario_id
     FROM usuario us,
          pessoa  pe
    WHERE upper(TRIM(us.login)) = upper(TRIM(p_email_login))
      AND pe.usuario_id = us.usuario_id;
   --
   IF v_usuario_id IS NULL THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O usuário ou E-mail informado não corresponde a nenhum usuário cadastrado no JobOne.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  SELECT flag_ativo
    INTO v_flag_ativo
    FROM usuario
   WHERE usuario_id = v_usuario_id;
  --
  IF v_flag_ativo = 'N' THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Usuário inativo não pode redefinir a senha.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  v_cod_hash := rawtohex(sys_guid());
  --
  UPDATE usuario
     SET cod_hash  = v_cod_hash,
         data_hash = SYSDATE
   WHERE usuario_id = v_usuario_id;
  --
  p_cod_hash := v_cod_hash;
  --
  COMMIT;
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END senha_redefinir;
 --
 --
 PROCEDURE senha_validar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 13/04/2010
  -- DESCRICAO: subrotina qhe valida o string da senha.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_empresa_id       IN empresa.empresa_id%TYPE,
  p_nome_completo    IN pessoa.nome%TYPE,
  p_apelido_completo IN pessoa.apelido%TYPE,
  p_login            IN usuario.login%TYPE,
  p_senha            IN VARCHAR2,
  p_erro_cod         OUT VARCHAR2,
  p_erro_msg         OUT VARCHAR2
 ) AS
  v_retorno          NUMBER(5);
  v_qt               INTEGER;
  v_exception        EXCEPTION;
  v_tam_min_senha    NUMBER(5);
  v_qt_min_char_esp  NUMBER(5);
  v_qt_reuso_senha   NUMBER(5);
  v_flag_char_num    VARCHAR2(5);
  v_flag_pode_nome   VARCHAR2(5);
  v_senha_aux        VARCHAR2(100);
  v_login            usuario.login%TYPE;
  v_nome_completo    pessoa.nome%TYPE;
  v_apelido_completo pessoa.apelido%TYPE;
  v_nome_parte       pessoa.nome%TYPE;
  v_nome_aux         pessoa.nome%TYPE;
  v_delimitador      VARCHAR2(1);
  --
 BEGIN
  v_retorno := NULL;
  --
  v_tam_min_senha   := to_number(empresa_pkg.parametro_retornar(p_empresa_id, 'TAMANHO_MIN_SENHA'));
  v_flag_char_num   := empresa_pkg.parametro_retornar(p_empresa_id, 'OBRIGAR_CHAR_NUM_SENHA');
  v_qt_min_char_esp := to_number(empresa_pkg.parametro_retornar(p_empresa_id,
                                                                'QT_MIN_CHAR_ESPECIAL_SENHA'));
  v_flag_pode_nome  := empresa_pkg.parametro_retornar(p_empresa_id, 'PERMITIR_NOME_NA_SENHA');
  v_qt_reuso_senha  := to_number(empresa_pkg.parametro_retornar(p_empresa_id,
                                                                'NAO_PERMITIR_REUSO_SENHA'));
  --
  IF TRIM(p_senha) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Senha inválida.';
   RAISE v_exception;
  END IF;
  --
  IF length(p_senha) > 20 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A senha não pode ter mais que 20 caracteres.';
   RAISE v_exception;
  END IF;
  --
  -- testa tamanho minimo da senha
  IF length(p_senha) < v_tam_min_senha THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A senha deve ter no mínimo ' || to_char(v_tam_min_senha) || ' caracteres.';
   RAISE v_exception;
  END IF;
  --
  -- testa obrigatoriedade de letras e numeros na senha
  IF v_flag_char_num = 'S' THEN
   v_qt := regexp_instr(p_senha, '[0-9]');
   --
   IF v_qt = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'A senha deve ter no mínimo um número.';
    RAISE v_exception;
   END IF;
   --
   v_qt := regexp_instr(p_senha, '[a-zA-Z]');
   --
   IF v_qt = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'A senha deve ter no mínimo uma letra.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  -- testa obrigatoriedade de caracteres especiais na senha
  IF v_qt_min_char_esp > 0 THEN
   -- retira letras e numeros da senha
   v_senha_aux := regexp_replace(regexp_replace(p_senha, '[0-9]'), '[a-zA-Z]');
   --
   IF nvl(length(v_senha_aux), 0) < v_qt_min_char_esp THEN
    p_erro_cod := '90000';
    p_erro_msg := 'A senha deve ter no mínimo ' || to_char(v_qt_min_char_esp) ||
                  ' caracteres especiais.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  -- testa se o nome do usuario ou o login foram utilizados na senha
  IF v_flag_pode_nome = 'N' THEN
   v_delimitador := '|';
   --
   -- teste do nome
   v_nome_aux  := REPLACE(TRIM(p_nome_completo), ' ', v_delimitador);
   v_nome_aux  := acento_retirar(v_nome_aux);
   v_senha_aux := acento_retirar(p_senha);
   --
   WHILE nvl(length(rtrim(v_nome_aux)), 0) > 0
   LOOP
    v_nome_parte := TRIM(prox_valor_retornar(v_nome_aux, v_delimitador));
    v_nome_parte := acento_retirar(v_nome_parte);
    --
    IF length(v_nome_parte) > 2 AND instr(v_senha_aux, v_nome_parte) > 0 THEN
     p_erro_cod := '90000';
     p_erro_msg := 'O nome ' || v_nome_parte || ' não pode fazer parte da senha.';
     RAISE v_exception;
    END IF;
   END LOOP;
   --
   -- teste do apelido
   v_nome_aux  := REPLACE(TRIM(p_apelido_completo), ' ', v_delimitador);
   v_nome_aux  := acento_retirar(v_nome_aux);
   v_senha_aux := acento_retirar(p_senha);
   --
   WHILE nvl(length(rtrim(v_nome_aux)), 0) > 0
   LOOP
    v_nome_parte := TRIM(prox_valor_retornar(v_nome_aux, v_delimitador));
    v_nome_parte := acento_retirar(v_nome_parte);
    --
    IF length(v_nome_parte) > 2 AND instr(v_senha_aux, v_nome_parte) > 0 THEN
     p_erro_cod := '90000';
     p_erro_msg := 'O nome ' || v_nome_parte || ' não pode fazer parte da senha.';
     RAISE v_exception;
    END IF;
   END LOOP;
   --
   -- teste do login
   v_login := p_login;
   v_login := REPLACE(TRIM(v_login), ' ', v_delimitador);
   v_login := REPLACE(TRIM(v_login), '.', v_delimitador);
   v_login := REPLACE(TRIM(v_login), '-', v_delimitador);
   v_login := REPLACE(TRIM(v_login), '_', v_delimitador);
   v_login := REPLACE(TRIM(v_login), '@', v_delimitador);
   v_login := REPLACE(TRIM(v_login), '*', v_delimitador);
   v_login := REPLACE(TRIM(v_login), '$', v_delimitador);
   v_login := REPLACE(TRIM(v_login), '&', v_delimitador);
   v_login := REPLACE(TRIM(v_login), ';', v_delimitador);
   v_login := REPLACE(TRIM(v_login), ',', v_delimitador);
   v_login := REPLACE(TRIM(v_login), ':', v_delimitador);
   v_login := REPLACE(TRIM(v_login), '?', v_delimitador);
   v_login := REPLACE(TRIM(v_login), '/', v_delimitador);
   v_login := REPLACE(TRIM(v_login), '\', v_delimitador);
   --
   WHILE nvl(length(rtrim(v_login)), 0) > 0
   LOOP
    v_nome_parte := TRIM(prox_valor_retornar(v_login, v_delimitador));
    v_nome_parte := acento_retirar(v_nome_parte);
    --
    IF length(v_nome_parte) > 2 AND instr(v_senha_aux, v_nome_parte) > 0 THEN
     p_erro_cod := '90000';
     p_erro_msg := 'O nome ' || v_nome_parte || ' não pode fazer parte da senha.';
     RAISE v_exception;
    END IF;
   END LOOP;
  END IF;
  --
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   NULL;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
 END senha_validar;
 --
 --
 --
 PROCEDURE desbloquear
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 06/10/2004
  -- DESCRICAO: desbloqueia usuario e zera contador de logins invalidos.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_usuario_sessao_id IN usuario.usuario_id%TYPE,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_usuario_id        IN usuario.usuario_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) AS
  v_qt             INTEGER;
  v_login          usuario.login%TYPE;
  v_nome           pessoa.nome%TYPE;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_exception      EXCEPTION;
  --
 BEGIN
  p_erro_cod := ' ';
  p_erro_msg := ' ';
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'USUARIO_C', NULL, NULL, p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(u.login),
         MAX(p.nome)
    INTO v_login,
         v_nome
    FROM pessoa  p,
         usuario u
   WHERE u.usuario_id = p_usuario_id
     AND u.usuario_id = p.usuario_id;
  --
  IF v_login IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse usuário não existe.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE usuario
     SET flag_bloqueado     = 'N',
         qtd_login_invalido = 0
   WHERE usuario_id = p_usuario_id;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_login;
  v_compl_histor   := 'Desbloqueio de Usuário. Pessoa: ' || v_nome;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'USUARIO',
                   'ALTERAR',
                   v_identif_objeto,
                   p_usuario_id,
                   v_compl_histor,
                   NULL,
                   'N',
                   NULL,
                   NULL,
                   v_historico_id,
                   p_erro_cod,
                   p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  COMMIT;
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END desbloquear;
 --
 --
 PROCEDURE email_bloquear
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 23/07/2009
  -- DESCRICAO: marca o email do usuario como bloqueado no Exchange.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            17/11/2011  Qdo usuario_sessao_id vem zero, usa o ADMIN como executor
  ------------------------------------------------------------------------------------------
  p_usuario_sessao_id IN usuario.usuario_id%TYPE,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_usuario_id        IN usuario.usuario_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) AS
  v_qt              INTEGER;
  v_login           usuario.login%TYPE;
  v_nome            pessoa.nome%TYPE;
  v_identif_objeto  historico.identif_objeto%TYPE;
  v_compl_histor    historico.complemento%TYPE;
  v_historico_id    historico.historico_id%TYPE;
  v_exception       EXCEPTION;
  v_usuario_exec_id usuario.usuario_id%TYPE;
  v_empresa_id      empresa.empresa_id%TYPE;
  --
 BEGIN
  p_erro_cod := ' ';
  p_erro_msg := ' ';
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF nvl(p_usuario_sessao_id, 0) > 0 THEN
   -- verifica se o usuario tem privilegio
   IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'USUARIO_C', NULL, NULL, p_empresa_id) <> 1 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
    RAISE v_exception;
   END IF;
   --
   v_usuario_exec_id := p_usuario_sessao_id;
   v_empresa_id      := p_empresa_id;
  ELSE
   SELECT MAX(usuario_id)
     INTO v_usuario_exec_id
     FROM usuario
    WHERE flag_admin_sistema = 'S';
   --
   IF v_usuario_exec_id IS NULL THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Impossível realizar o bloqueio sem um usuário administrador definido.';
    RAISE v_exception;
   END IF;
   --
   v_empresa_id := usuario_pkg.empresa_padrao_retornar(v_usuario_exec_id);
  END IF;
  --
  SELECT MAX(u.login),
         MAX(p.nome)
    INTO v_login,
         v_nome
    FROM pessoa  p,
         usuario u
   WHERE u.usuario_id = p_usuario_id
     AND u.usuario_id = p.usuario_id;
  --
  IF v_login IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse usuário não existe.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE usuario
     SET flag_email_bloq = 'S'
   WHERE usuario_id = p_usuario_id;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_login;
  v_compl_histor   := 'Bloqueio de E-mail de Usuário. Pessoa: ' || v_nome;
  --
  evento_pkg.gerar(v_usuario_exec_id,
                   v_empresa_id,
                   'USUARIO',
                   'ALTERAR',
                   v_identif_objeto,
                   p_usuario_id,
                   v_compl_histor,
                   NULL,
                   'N',
                   NULL,
                   NULL,
                   v_historico_id,
                   p_erro_cod,
                   p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  COMMIT;
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END email_bloquear;
 --
 --
 PROCEDURE email_desbloquear
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 23/07/2009
  -- DESCRICAO: marca o email do usuario como desbloqueado no Exchange.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            17/11/2011  Qdo usuario_sessao_id vem zero, usa o ADMIN como executor
  ------------------------------------------------------------------------------------------
  p_usuario_sessao_id IN usuario.usuario_id%TYPE,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_usuario_id        IN usuario.usuario_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) AS
  v_qt              INTEGER;
  v_login           usuario.login%TYPE;
  v_nome            pessoa.nome%TYPE;
  v_identif_objeto  historico.identif_objeto%TYPE;
  v_compl_histor    historico.complemento%TYPE;
  v_historico_id    historico.historico_id%TYPE;
  v_exception       EXCEPTION;
  v_usuario_exec_id usuario.usuario_id%TYPE;
  v_empresa_id      empresa.empresa_id%TYPE;
  --
 BEGIN
  p_erro_cod := ' ';
  p_erro_msg := ' ';
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF nvl(p_usuario_sessao_id, 0) > 0 THEN
   -- verifica se o usuario tem privilegio
   IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'USUARIO_C', NULL, NULL, p_empresa_id) <> 1 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
    RAISE v_exception;
   END IF;
   --
   v_usuario_exec_id := p_usuario_sessao_id;
   v_empresa_id      := p_empresa_id;
  ELSE
   SELECT MAX(usuario_id)
     INTO v_usuario_exec_id
     FROM usuario
    WHERE flag_admin_sistema = 'S';
   --
   IF v_usuario_exec_id IS NULL THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Impossível realizar o desbloqueio sem um usuário administrador definido.';
    RAISE v_exception;
   END IF;
   --
   v_empresa_id := usuario_pkg.empresa_padrao_retornar(v_usuario_exec_id);
  END IF;
  --
  SELECT MAX(u.login),
         MAX(p.nome)
    INTO v_login,
         v_nome
    FROM pessoa  p,
         usuario u
   WHERE u.usuario_id = p_usuario_id
     AND u.usuario_id = p.usuario_id;
  --
  IF v_login IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse usuário não existe.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE usuario
     SET flag_email_bloq = 'N'
   WHERE usuario_id = p_usuario_id;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_login;
  v_compl_histor   := 'Desbloqueio de E-mail de Usuário. Pessoa: ' || v_nome;
  --
  evento_pkg.gerar(v_usuario_exec_id,
                   v_empresa_id,
                   'USUARIO',
                   'ALTERAR',
                   v_identif_objeto,
                   v_usuario_exec_id,
                   v_compl_histor,
                   NULL,
                   'N',
                   NULL,
                   NULL,
                   v_historico_id,
                   p_erro_cod,
                   p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  COMMIT;
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END email_desbloquear;
 --
 --
 PROCEDURE inativar_automatico
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 02/10/2018
  -- DESCRICAO: inativa usuarios que nao fizeram login ate a data limite (chamada via job
  --   SISTEMA_PKG.JOBS_DIARIOS_EXECUTAR).
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  IS
  v_qt               INTEGER;
  v_exception        EXCEPTION;
  v_erro_cod         VARCHAR2(20);
  v_erro_msg         VARCHAR2(200);
  v_usuario_admin_id usuario.usuario_id%TYPE;
  v_empresa_id       empresa.empresa_id%TYPE;
  v_identif_objeto   historico.identif_objeto%TYPE;
  v_compl_histor     historico.complemento%TYPE;
  v_historico_id     historico.historico_id%TYPE;
  v_num_dias_inativ  NUMBER(10);
  --
  CURSOR c_usu IS
   SELECT us.usuario_id,
          us.login,
          pe.apelido,
          us.data_ult_login
     FROM usuario us,
          pessoa  pe
    WHERE us.flag_ativo = 'S'
      AND us.usuario_id = pe.usuario_id;
  --
 BEGIN
  --
  SELECT MAX(usuario_id)
    INTO v_usuario_admin_id
    FROM usuario
   WHERE flag_admin_sistema = 'S';
  --
  FOR r_usu IN c_usu
  LOOP
   v_empresa_id      := usuario_pkg.empresa_padrao_retornar(r_usu.usuario_id);
   v_num_dias_inativ := empresa_pkg.parametro_retornar(v_empresa_id, 'NUM_DIAS_INATIVAR_USUARIO');
   --
   IF v_num_dias_inativ > 0 AND r_usu.data_ult_login + v_num_dias_inativ < SYSDATE THEN
    UPDATE usuario
       SET flag_ativo      = 'N',
           data_inativacao = SYSDATE
     WHERE usuario_id = r_usu.usuario_id;
    --
    v_identif_objeto := initcap(rtrim(r_usu.login));
    v_compl_histor   := 'Apelido: ' || r_usu.apelido;
    --
    evento_pkg.gerar(v_usuario_admin_id,
                     v_empresa_id,
                     'USUARIO',
                     'INATIVAR_AUTO',
                     v_identif_objeto,
                     r_usu.usuario_id,
                     v_compl_histor,
                     NULL,
                     'N',
                     NULL,
                     NULL,
                     v_historico_id,
                     v_erro_cod,
                     v_erro_msg);
    --
    IF v_erro_cod <> '00000' THEN
     RAISE v_exception;
    END IF;
   END IF;
  END LOOP;
  --
  COMMIT;
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
   INSERT INTO erro_log
    (erro_log_id,
     data,
     nome_programa,
     cod_erro,
     msg_erro)
   VALUES
    (seq_erro_log.nextval,
     SYSDATE,
     'usuario_pkg.inativar_autom',
     v_erro_cod,
     v_erro_msg);
   COMMIT;
  WHEN OTHERS THEN
   ROLLBACK;
   v_erro_cod := SQLCODE;
   v_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
   INSERT INTO erro_log
    (erro_log_id,
     data,
     nome_programa,
     cod_erro,
     msg_erro)
   VALUES
    (seq_erro_log.nextval,
     SYSDATE,
     'usuario_pkg.inativar_autom',
     v_erro_cod,
     v_erro_msg);
   COMMIT;
 END inativar_automatico;
 --
 --
 --
 PROCEDURE preferencia_atualizar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 20/08/2009
  -- DESCRICAO: atualiza a opcao do usuario para uma determinada preferencia.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Ana Luiza         15/03/2024  Adicionado parametro empresa_id
  ------------------------------------------------------------------------------------------
  p_usuario_id    IN usuario.usuario_id%TYPE,
  p_nome_pref     IN preferencia.nome%TYPE,
  p_valor_usuario IN usuario_pref.valor_usuario%TYPE,
  p_empresa_id    IN NUMBER, --ALCBO_150324
  p_erro_cod      OUT VARCHAR2,
  p_erro_msg      OUT VARCHAR2
 ) AS
  v_qt             INTEGER;
  v_exception      EXCEPTION;
  v_preferencia_id preferencia.preferencia_id%TYPE;
  --
 BEGIN
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT MAX(preferencia_id)
    INTO v_preferencia_id
    FROM preferencia
   WHERE nome = p_nome_pref;
  --
  IF v_preferencia_id IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa preferência não existe (' || p_nome_pref || ').';
   RAISE v_exception;
  END IF;
  --
  IF p_valor_usuario IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O valor da preferência não pode ser nulo.';
   RAISE v_exception;
  END IF;
  --
  DELETE FROM usuario_pref
   WHERE usuario_id = p_usuario_id
     AND preferencia_id = v_preferencia_id
     AND empresa_id = p_empresa_id; --ALCBO_150324
  --ALCBO_150324
  INSERT INTO usuario_pref
   (usuario_id,
    preferencia_id,
    valor_usuario,
    empresa_id)
  VALUES
   (p_usuario_id,
    v_preferencia_id,
    p_valor_usuario,
    p_empresa_id);
  --
  COMMIT;
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END preferencia_atualizar;
 --
 --
 PROCEDURE notifica_regra_adicionar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 08/08/2013
  -- DESCRICAO: inclui regra para desligar notificacoes para o usuario.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_usuario_sessao_id IN usuario.usuario_id%TYPE,
  p_empresa_id        IN notifica_desliga.empresa_id%TYPE,
  p_cliente_id        IN notifica_desliga.cliente_id%TYPE,
  p_job_id            IN notifica_desliga.job_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) AS
  v_qt        INTEGER;
  v_exception EXCEPTION;
  v_insere    INTEGER;
  --
 BEGIN
  --
  v_insere := 0;
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  IF nvl(p_job_id, 0) = 0 AND nvl(p_cliente_id, 0) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Um job ou cliente devem ser indicados.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_job_id, 0) <> 0 AND nvl(p_cliente_id, 0) <> 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Job e cliente não devem ser indicados ao mesmo tempo.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_job_id, 0) <> 0 THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM notifica_desliga
    WHERE usuario_id = p_usuario_sessao_id
      AND job_id = p_job_id;
   --
   IF v_qt = 0 THEN
    v_insere := 1;
   END IF;
  END IF;
  --
  IF nvl(p_cliente_id, 0) <> 0 THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM notifica_desliga
    WHERE usuario_id = p_usuario_sessao_id
      AND cliente_id = p_cliente_id;
   --
   IF v_qt = 0 THEN
    v_insere := 1;
   END IF;
  END IF;
  --
  IF v_insere = 1 THEN
   INSERT INTO notifica_desliga
    (notifica_desliga_id,
     empresa_id,
     usuario_id,
     cliente_id,
     job_id,
     data_desliga)
   VALUES
    (seq_notifica_desliga.nextval,
     p_empresa_id,
     p_usuario_sessao_id,
     zvl(p_cliente_id, NULL),
     zvl(p_job_id, NULL),
     SYSDATE);
  END IF;
  --
  COMMIT;
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END notifica_regra_adicionar;
 --
 --
 PROCEDURE notifica_regra_excluir
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 08/08/2013
  -- DESCRICAO: exclui regra para desligar notificacoes para o usuario.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_usuario_sessao_id   IN usuario.usuario_id%TYPE,
  p_empresa_id          IN notifica_desliga.empresa_id%TYPE,
  p_notifica_desliga_id IN notifica_desliga.notifica_desliga_id%TYPE,
  p_erro_cod            OUT VARCHAR2,
  p_erro_msg            OUT VARCHAR2
 ) AS
  v_qt        INTEGER;
  v_exception EXCEPTION;
  --
 BEGIN
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM notifica_desliga
   WHERE notifica_desliga_id = p_notifica_desliga_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa regra não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  DELETE FROM notifica_desliga
   WHERE notifica_desliga_id = p_notifica_desliga_id;
  --
  COMMIT;
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END notifica_regra_excluir;
 --
 --
 PROCEDURE enderecar_em_todos_jobs
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 29/03/2021
  -- DESCRICAO: subrotina p/ Enderecamento de usuario em todos os jobs.
  --     NAO FAZ COMMIT.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN job.empresa_id%TYPE,
  p_usuario_id        IN usuario.usuario_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt        INTEGER;
  v_exception EXCEPTION;
  --
  -- todos os jobs da empresa no status Em Andamento e cujo tipo de job
  -- esteja marcado para enderecar todos os usuarios
  CURSOR c_jo IS
   SELECT jo.job_id
     FROM job      jo,
          tipo_job tj
    WHERE jo.tipo_job_id = tj.tipo_job_id
      AND jo.empresa_id = p_empresa_id
      AND jo.status = 'ANDA'
      AND tj.flag_ender_todos = 'S'
    ORDER BY 1;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  IF nvl(p_usuario_id, 0) > 0 THEN
   -- veio o usuario. Endereca em todos os jobs.
   FOR r_jo IN c_jo
   LOOP
    SELECT COUNT(*)
      INTO v_qt
      FROM job_usuario
     WHERE job_id = r_jo.job_id
       AND usuario_id = p_usuario_id;
    --
    IF v_qt = 0 THEN
     INSERT INTO job_usuario
      (job_id,
       usuario_id)
     VALUES
      (r_jo.job_id,
       p_usuario_id);
     --
     historico_pkg.hist_ender_registrar(p_usuario_id,
                                        'JOB',
                                        r_jo.job_id,
                                        NULL,
                                        p_erro_cod,
                                        p_erro_msg);
     IF p_erro_cod <> '00000' THEN
      RAISE v_exception;
     END IF;
     --
     -- verifica se esse usuario/papel pode ser resp interno e marca
     job_pkg.resp_int_tratar(r_jo.job_id, p_usuario_id, p_erro_cod, p_erro_msg);
     IF p_erro_cod <> '00000' THEN
      RAISE v_exception;
     END IF;
    END IF;
   END LOOP;
  END IF; -- fim do IF NVL(p_usuario_id,0)
  --
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   NULL;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
 END enderecar_em_todos_jobs;
 --
 --
 --
 PROCEDURE enderecar_nos_jobs_marcados
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 17/10/2014
  -- DESCRICAO: endereca o usuario nos jobs passados no vetor com o papel indicado.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            18/01/2017  Geracao de evento de enderecar
  -- Silvia            03/10/2019  Eliminacao de job_usuario_papel
  ------------------------------------------------------------------------------------------
  p_usuario_sessao_id IN usuario.usuario_id%TYPE,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_usuario_id        IN usuario.usuario_id%TYPE,
  p_vetor_job         IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) AS
  TYPE row_cursor IS REF CURSOR;
  v_qt             INTEGER;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_exception      EXCEPTION;
  v_vetor_job      VARCHAR2(32000);
  v_job_id         job.job_id%TYPE;
  v_delimitador    CHAR(1);
  v_lbl_job        VARCHAR2(100);
  v_lbl_jobs       VARCHAR2(100);
  v_apelido        pessoa.apelido%TYPE;
  --
 BEGIN
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  v_lbl_job  := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  v_lbl_jobs := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_PLURAL');
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'MULTI_ENDER_C', NULL, NULL, p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF nvl(p_usuario_id, 0) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do usuário é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM usuario_empresa
   WHERE usuario_id = p_usuario_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O usuário a ser endereçado não existe ou não está ' ||
                 'associado a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_vetor_job) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Nenhum ' || v_lbl_job || ' foi selecionado.';
   RAISE v_exception;
  END IF;
  --
  SELECT apelido
    INTO v_apelido
    FROM pessoa
   WHERE usuario_id = p_usuario_id;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  v_delimitador := '|';
  v_vetor_job   := p_vetor_job;
  --
  WHILE nvl(length(rtrim(v_vetor_job)), 0) > 0
  LOOP
   v_job_id := to_number(TRIM(prox_valor_retornar(v_vetor_job, v_delimitador)));
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM job
    WHERE job_id = v_job_id
      AND empresa_id = p_empresa_id;
   --
   IF v_qt = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse ' || v_lbl_job || ' não existe ou não pertence a essa empresa (' ||
                  to_char(v_job_id) || ').';
    RAISE v_exception;
   END IF;
   --
   -- sem co-ender, sem pula notif
   job_pkg.enderecar_usuario(p_usuario_sessao_id,
                             'N',
                             'N',
                             'N',
                             p_empresa_id,
                             v_job_id,
                             p_usuario_id,
                             v_apelido || ' endereçado em ' || v_lbl_jobs,
                             'Endereçamento em ' || v_lbl_jobs,
                             p_erro_cod,
                             p_erro_msg);
   --
   IF p_erro_cod <> '00000' THEN
    RAISE v_exception;
   END IF;
  END LOOP;
  --
  COMMIT;
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END enderecar_nos_jobs_marcados;
 --
 --
 --
 PROCEDURE desenderecar_nos_jobs_marcados
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 17/10/2014
  -- DESCRICAO: desendereca o usuario dos jobs passados no vetor com o papel indicado.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            18/01/2017  Geracao de evento de desenderecar
  -- Silvia            03/10/2019  Eliminacao de job_usuario_papel
  ------------------------------------------------------------------------------------------
  p_usuario_sessao_id IN usuario.usuario_id%TYPE,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_usuario_id        IN usuario.usuario_id%TYPE,
  p_vetor_job         IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) AS
  TYPE row_cursor IS REF CURSOR;
  v_qt             INTEGER;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_exception      EXCEPTION;
  v_vetor_job      VARCHAR2(32000);
  v_job_id         job.job_id%TYPE;
  v_delimitador    CHAR(1);
  v_lbl_job        VARCHAR2(100);
  v_lbl_jobs       VARCHAR2(100);
  v_apelido        pessoa.apelido%TYPE;
  --
 BEGIN
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  v_lbl_job  := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  v_lbl_jobs := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_PLURAL');
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'MULTI_ENDER_C', NULL, NULL, p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF nvl(p_usuario_id, 0) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do usuário é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM usuario_empresa
   WHERE usuario_id = p_usuario_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O usuário a ser desendereçado não existe ou não está ' ||
                 'associado a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_vetor_job) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Nenhum ' || v_lbl_job || ' foi selecionado.';
   RAISE v_exception;
  END IF;
  --
  SELECT apelido
    INTO v_apelido
    FROM pessoa
   WHERE usuario_id = p_usuario_id;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  v_delimitador := '|';
  v_vetor_job   := p_vetor_job;
  --
  WHILE nvl(length(rtrim(v_vetor_job)), 0) > 0
  LOOP
   v_job_id := to_number(TRIM(prox_valor_retornar(v_vetor_job, v_delimitador)));
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM job
    WHERE job_id = v_job_id
      AND empresa_id = p_empresa_id;
   --
   IF v_qt = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse ' || v_lbl_job || ' não existe ou não pertence a essa empresa (' ||
                  to_char(v_job_id) || ').';
    RAISE v_exception;
   END IF;
   --
   -- desendereca o usuario a ser substituido, sem pula notif
   job_pkg.desenderecar_usuario(p_usuario_sessao_id,
                                'N',
                                'N',
                                p_empresa_id,
                                v_job_id,
                                p_usuario_id,
                                v_apelido || ' desendereçado em ' || v_lbl_jobs,
                                'Desendereçamento em ' || v_lbl_jobs,
                                p_erro_cod,
                                p_erro_msg);
   --
   IF p_erro_cod <> '00000' THEN
    RAISE v_exception;
   END IF;
  END LOOP;
  --
  COMMIT;
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END desenderecar_nos_jobs_marcados;
 --
 --
 --
 PROCEDURE substituir_nos_jobs_marcados
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 17/10/2014
  -- DESCRICAO: substitui o usuario nos jobs passados no vetor.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            17/01/2017  Geracao de evento de enderecar/desenderecar
  -- Silvia            30/09/2019  Eliminacao da tabela job_usuario_papel
  -- Silvia            04/09/2020  Recalculo da alocacao dos usuarios envolvidos
  -- Silvia            06/11/2020  Tratamento de tarefa_usuario_data
  ------------------------------------------------------------------------------------------
  p_usuario_sessao_id IN usuario.usuario_id%TYPE,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_usuario_ori_id    IN usuario.usuario_id%TYPE,
  p_usuario_sub_id    IN usuario.usuario_id%TYPE,
  p_vetor_job         IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) AS
  TYPE row_cursor IS REF CURSOR;
  v_qt             INTEGER;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_justif_histor  historico.justificativa%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_exception      EXCEPTION;
  v_vetor_job      VARCHAR2(4000);
  v_job_id         job.job_id%TYPE;
  v_numero_job     job.numero%TYPE;
  v_delimitador    CHAR(1);
  v_lbl_job        VARCHAR2(100);
  v_lbl_jobs       VARCHAR2(100);
  v_flag_ativo     usuario.flag_ativo%TYPE;
  v_apelido_ori    pessoa.apelido%TYPE;
  v_apelido_sub    pessoa.apelido%TYPE;
  --
  CURSOR c_ta IS
   SELECT tarefa_id,
          'DE' AS tipo,
          data_inicio,
          data_termino
     FROM tarefa
    WHERE job_id = v_job_id
      AND usuario_de_id = p_usuario_ori_id
      AND status NOT IN ('CANC', 'CONC')
   UNION
   SELECT ta.tarefa_id,
          'PARA' AS tipo,
          ta.data_inicio,
          ta.data_termino
     FROM tarefa         ta,
          tarefa_usuario tu
    WHERE ta.job_id = v_job_id
      AND ta.tarefa_id = tu.tarefa_id
      AND tu.usuario_para_id = p_usuario_ori_id
      AND ta.status NOT IN ('CANC', 'CONC')
    ORDER BY 1,
             2;
  --
 BEGIN
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  v_lbl_job  := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  v_lbl_jobs := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_PLURAL');
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'MULTI_ENDER_C', NULL, NULL, p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF nvl(p_usuario_ori_id, 0) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do usuário a ser substituído é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM usuario_empresa
   WHERE usuario_id = p_usuario_ori_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O usuário a ser substituído não existe ou não está ' ||
                 'associado a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  SELECT apelido
    INTO v_apelido_ori
    FROM pessoa
   WHERE usuario_id = p_usuario_ori_id;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM job_usuario
   WHERE usuario_id = p_usuario_ori_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O usuário a ser substituído não está associado a ' || v_lbl_jobs || '.';
   RAISE v_exception;
  END IF;
  --
  --
  IF nvl(p_usuario_sub_id, 0) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do usuário substituto é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM usuario_empresa
   WHERE usuario_id = p_usuario_sub_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O usuário substituto não existe ou não está ' || 'associado a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  IF p_usuario_ori_id = p_usuario_sub_id THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O usuário não pode ser substiuído por ele mesmo.';
   RAISE v_exception;
  END IF;
  --
  SELECT us.flag_ativo,
         pe.apelido
    INTO v_flag_ativo,
         v_apelido_sub
    FROM usuario us,
         pessoa  pe
   WHERE us.usuario_id = p_usuario_sub_id
     AND us.usuario_id = pe.usuario_id;
  --
  IF v_flag_ativo = 'N' THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O usuário substituto não pode estar inativo.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_vetor_job) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Nenhum ' || v_lbl_job || ' foi selecionado.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  v_delimitador := '|';
  v_vetor_job   := p_vetor_job;
  --
  WHILE nvl(length(rtrim(v_vetor_job)), 0) > 0
  LOOP
   v_job_id := to_number(TRIM(prox_valor_retornar(v_vetor_job, v_delimitador)));
   --
   SELECT MAX(numero)
     INTO v_numero_job
     FROM job
    WHERE job_id = v_job_id
      AND empresa_id = p_empresa_id;
   --
   IF v_numero_job IS NULL THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse ' || v_lbl_job || ' não existe ou não pertence a essa empresa (' ||
                  v_numero_job || ').';
    RAISE v_exception;
   END IF;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM job_usuario
    WHERE job_id = v_job_id
      AND usuario_id = p_usuario_ori_id;
   --
   IF v_qt > 0 THEN
    -- desendereca o usuario a ser substituido, sem pula notif
    job_pkg.desenderecar_usuario(p_usuario_sessao_id,
                                 'N',
                                 'N',
                                 p_empresa_id,
                                 v_job_id,
                                 p_usuario_ori_id,
                                 v_apelido_ori || ' substituído por ' || v_apelido_sub,
                                 'Substituição de Usuário nos ' || v_lbl_jobs,
                                 p_erro_cod,
                                 p_erro_msg);
    --
    IF p_erro_cod <> '00000' THEN
     RAISE v_exception;
    END IF;
    --
    -- endereca o usuario substituto, sem co-ender, sem pula notif
    job_pkg.enderecar_usuario(p_usuario_sessao_id,
                              'N',
                              'N',
                              'N',
                              p_empresa_id,
                              v_job_id,
                              p_usuario_sub_id,
                              v_apelido_sub || ' substituiu ' || v_apelido_ori,
                              'Substituição de Usuário nos ' || v_lbl_jobs,
                              p_erro_cod,
                              p_erro_msg);
    --
    IF p_erro_cod <> '00000' THEN
     RAISE v_exception;
    END IF;
   END IF;
   --
   ------------------------------------------------------------
   -- tratamento de tarefas vinculados ao job, para o
   -- usuario a ser substituido
   ------------------------------------------------------------
   FOR r_ta IN c_ta
   LOOP
    IF r_ta.tipo = 'DE' THEN
     -- troca o autor da tarefa
     UPDATE tarefa
        SET usuario_de_id = p_usuario_sub_id
      WHERE tarefa_id = r_ta.tarefa_id;
     --
     historico_pkg.hist_ender_registrar(p_usuario_sub_id,
                                        'TAR',
                                        r_ta.tarefa_id,
                                        'SOL',
                                        p_erro_cod,
                                        p_erro_msg);
     IF p_erro_cod <> '00000' THEN
      RAISE v_exception;
     END IF;
    ELSIF r_ta.tipo = 'PARA' THEN
     -- troca o executor da tarefa.
     -- verifica se o substituto ja eh executor.
     SELECT COUNT(*)
       INTO v_qt
       FROM tarefa_usuario
      WHERE tarefa_id = r_ta.tarefa_id
        AND usuario_para_id = p_usuario_sub_id;
     --
     IF v_qt = 0 THEN
      -- cria novo registro ao inves de fazer update por causa
      -- da chave primaria composta.
      INSERT INTO tarefa_usuario
       (tarefa_id,
        usuario_para_id,
        status,
        data_status)
      VALUES
       (r_ta.tarefa_id,
        p_usuario_sub_id,
        'EMEX',
        SYSDATE);
      --
      -- transfere datas para o novo executor
      UPDATE tarefa_usuario_data
         SET usuario_para_id = p_usuario_sub_id
       WHERE tarefa_id = r_ta.tarefa_id
         AND usuario_para_id = p_usuario_ori_id;
      --
      UPDATE tarefa_usuario tu
         SET horas_totais =
             (SELECT nvl(SUM(horas), 0)
                FROM tarefa_usuario_data td
               WHERE td.tarefa_id = tu.tarefa_id
                 AND td.usuario_para_id = tu.usuario_para_id)
       WHERE tarefa_id = r_ta.tarefa_id
         AND usuario_para_id = p_usuario_sub_id;
      --
      historico_pkg.hist_ender_registrar(p_usuario_sub_id,
                                         'TAR',
                                         r_ta.tarefa_id,
                                         'EXE',
                                         p_erro_cod,
                                         p_erro_msg);
      IF p_erro_cod <> '00000' THEN
       RAISE v_exception;
      END IF;
      --
      cronograma_pkg.alocacao_usu_processar(p_usuario_sessao_id,
                                            p_empresa_id,
                                            p_usuario_sub_id,
                                            r_ta.data_inicio,
                                            r_ta.data_termino,
                                            p_erro_cod,
                                            p_erro_msg);
      --
      IF p_erro_cod <> '00000' THEN
       RAISE v_exception;
      END IF;
     END IF;
     --
     DELETE FROM tarefa_usuario_data
      WHERE tarefa_id = r_ta.tarefa_id
        AND usuario_para_id = p_usuario_ori_id;
     DELETE FROM tarefa_usuario
      WHERE tarefa_id = r_ta.tarefa_id
        AND usuario_para_id = p_usuario_ori_id;
     --
     cronograma_pkg.alocacao_usu_processar(p_usuario_sessao_id,
                                           p_empresa_id,
                                           p_usuario_ori_id,
                                           r_ta.data_inicio,
                                           r_ta.data_termino,
                                           p_erro_cod,
                                           p_erro_msg);
     --
     IF p_erro_cod <> '00000' THEN
      RAISE v_exception;
     END IF;
    END IF;
   END LOOP;
   --
  END LOOP;
  --
  COMMIT;
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END substituir_nos_jobs_marcados;
 --
 --
 --
 PROCEDURE substituir_nos_jobs
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 15/05/2014
  -- DESCRICAO: substitui o usuario nos jobs em andamento/preparacao e nas
  --  tarefas nao finalizadas desses jobs.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            17/01/2017  Geracao de evento de enderecar/desenderecar
  -- Silvia            16/03/2018  Novo parametro p_pos_resp_int (na posicao de resp int)
  -- Silvia            04/09/2020  Recalculo da alocacao dos usuarios envolvidos
  -- Silvia            06/11/2020  Tratamento de tarefa_usuario_data
  ------------------------------------------------------------------------------------------
  p_usuario_sessao_id IN usuario.usuario_id%TYPE,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_usuario_ori_id    IN usuario.usuario_id%TYPE,
  p_cliente_job_id    IN job.cliente_id%TYPE,
  p_usuario_sub_id    IN usuario.usuario_id%TYPE,
  p_pos_resp_int      IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) AS
  TYPE row_cursor IS REF CURSOR;
  v_qt             INTEGER;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_exception      EXCEPTION;
  v_sql            VARCHAR2(10000);
  c_up             row_cursor;
  v_job_id         job.job_id%TYPE;
  v_flag_ativo     usuario.flag_ativo%TYPE;
  v_apelido_ori    pessoa.apelido%TYPE;
  v_apelido_sub    pessoa.apelido%TYPE;
  v_lbl_jobs       VARCHAR2(100);
  --
  CURSOR c_ta IS
   SELECT tarefa_id,
          'DE' AS tipo,
          data_inicio,
          data_termino
     FROM tarefa
    WHERE job_id = v_job_id
      AND usuario_de_id = p_usuario_ori_id
      AND status NOT IN ('CANC', 'CONC')
   UNION
   SELECT ta.tarefa_id,
          'PARA' AS tipo,
          ta.data_inicio,
          ta.data_termino
     FROM tarefa         ta,
          tarefa_usuario tu
    WHERE ta.job_id = v_job_id
      AND ta.tarefa_id = tu.tarefa_id
      AND tu.usuario_para_id = p_usuario_ori_id
      AND ta.status NOT IN ('CANC', 'CONC')
    ORDER BY 1,
             2;
  --
 BEGIN
  v_lbl_jobs := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_PLURAL');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'USUARIO_C', NULL, NULL, p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_pos_resp_int) IS NULL OR p_pos_resp_int NOT IN ('S', 'N', 'A') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Posição de responsável inválida (' || p_pos_resp_int || ').';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM usuario_empresa
   WHERE usuario_id = p_usuario_ori_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O usuário a ser substituído não existe ou não está ' ||
                 'associado a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  SELECT apelido
    INTO v_apelido_ori
    FROM pessoa
   WHERE usuario_id = p_usuario_ori_id;
  --
  IF nvl(p_usuario_sub_id, 0) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do usuário substituto é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM usuario_empresa
   WHERE usuario_id = p_usuario_sub_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O usuário substituto não existe ou não está ' || 'associado a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  IF p_usuario_ori_id = p_usuario_sub_id THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O usuário não pode ser substiuído por ele mesmo.';
   RAISE v_exception;
  END IF;
  --
  SELECT us.flag_ativo,
         pe.apelido
    INTO v_flag_ativo,
         v_apelido_sub
    FROM usuario us,
         pessoa  pe
   WHERE us.usuario_id = p_usuario_sub_id
     AND us.usuario_id = pe.usuario_id;
  --
  IF v_flag_ativo = 'N' THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O usuário substituto não pode estar inativo.';
   RAISE v_exception;
  END IF;
  --
  v_sql := 'SELECT DISTINCT jo.job_id' || ' FROM job_usuario ju,' || ' job jo' ||
           ' WHERE jo.status IN (''ANDA'',''PREP'')' || ' AND jo.empresa_id = ' ||
           to_char(p_empresa_id) || ' AND jo.job_id = ju.job_id ' || ' AND ju.usuario_id = ' ||
           to_char(p_usuario_ori_id);
  --
  IF nvl(p_cliente_job_id, 0) > 0 THEN
   v_sql := v_sql || ' AND jo.cliente_id = ' || to_char(p_cliente_job_id);
  END IF;
  --
  IF p_pos_resp_int IN ('S', 'N') THEN
   v_sql := v_sql || ' AND ju.flag_responsavel = ''' || p_pos_resp_int || '''';
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  OPEN c_up FOR v_sql;
  LOOP
   FETCH c_up
   INTO v_job_id;
   EXIT WHEN c_up%NOTFOUND;
   --
   -- desendereca o usuario a ser substituido, sem pula notif
   job_pkg.desenderecar_usuario(p_usuario_sessao_id,
                                'N',
                                'N',
                                p_empresa_id,
                                v_job_id,
                                p_usuario_ori_id,
                                v_apelido_ori || ' substituído por ' || v_apelido_sub,
                                'Substituição de Usuário nos ' || v_lbl_jobs,
                                p_erro_cod,
                                p_erro_msg);
   --
   IF p_erro_cod <> '00000' THEN
    RAISE v_exception;
   END IF;
   --
   -- endereca o usuario substituto, sem co-ender, sem pula notif
   job_pkg.enderecar_usuario(p_usuario_sessao_id,
                             'N',
                             'N',
                             'N',
                             p_empresa_id,
                             v_job_id,
                             p_usuario_sub_id,
                             v_apelido_sub || ' substituiu ' || v_apelido_ori,
                             'Substituição de Usuário nos ' || v_lbl_jobs,
                             p_erro_cod,
                             p_erro_msg);
   --
   IF p_erro_cod <> '00000' THEN
    RAISE v_exception;
   END IF;
   --
   ------------------------------------------------------------
   -- tratamento de tarefas vinculados ao job, para o
   -- usuario a ser substituido
   ------------------------------------------------------------
   FOR r_ta IN c_ta
   LOOP
    IF r_ta.tipo = 'DE' THEN
     -- troca o autor da tarefa
     UPDATE tarefa
        SET usuario_de_id = p_usuario_sub_id
      WHERE tarefa_id = r_ta.tarefa_id;
     --
     historico_pkg.hist_ender_registrar(p_usuario_sub_id,
                                        'TAR',
                                        r_ta.tarefa_id,
                                        'SOL',
                                        p_erro_cod,
                                        p_erro_msg);
     IF p_erro_cod <> '00000' THEN
      RAISE v_exception;
     END IF;
    ELSIF r_ta.tipo = 'PARA' THEN
     -- troca o executor da tarefa.
     -- verifica se o substituto ja eh executor (se ja for, nao faz nada)
     SELECT COUNT(*)
       INTO v_qt
       FROM tarefa_usuario
      WHERE tarefa_id = r_ta.tarefa_id
        AND usuario_para_id = p_usuario_sub_id;
     --
     IF v_qt = 0 THEN
      -- cria novo registro ao inves de fazer update por causa
      -- da chave primaria composta.
      INSERT INTO tarefa_usuario
       (tarefa_id,
        usuario_para_id,
        status,
        data_status)
      VALUES
       (r_ta.tarefa_id,
        p_usuario_sub_id,
        'EMEX',
        SYSDATE);
      --
      -- transfere datas/horas para o novo executor
      UPDATE tarefa_usuario_data
         SET usuario_para_id = p_usuario_sub_id
       WHERE tarefa_id = r_ta.tarefa_id
         AND usuario_para_id = p_usuario_ori_id;
      --
      UPDATE tarefa_usuario tu
         SET horas_totais =
             (SELECT nvl(SUM(horas), 0)
                FROM tarefa_usuario_data td
               WHERE td.tarefa_id = tu.tarefa_id
                 AND td.usuario_para_id = tu.usuario_para_id)
       WHERE tarefa_id = r_ta.tarefa_id
         AND usuario_para_id = p_usuario_sub_id;
      --
      historico_pkg.hist_ender_registrar(p_usuario_sub_id,
                                         'TAR',
                                         r_ta.tarefa_id,
                                         'EXE',
                                         p_erro_cod,
                                         p_erro_msg);
      IF p_erro_cod <> '00000' THEN
       RAISE v_exception;
      END IF;
      --
      cronograma_pkg.alocacao_usu_processar(p_usuario_sessao_id,
                                            p_empresa_id,
                                            p_usuario_sub_id,
                                            r_ta.data_inicio,
                                            r_ta.data_termino,
                                            p_erro_cod,
                                            p_erro_msg);
      --
      IF p_erro_cod <> '00000' THEN
       RAISE v_exception;
      END IF;
     END IF;
     --
     DELETE FROM tarefa_usuario_data
      WHERE tarefa_id = r_ta.tarefa_id
        AND usuario_para_id = p_usuario_ori_id;
     DELETE FROM tarefa_usuario
      WHERE tarefa_id = r_ta.tarefa_id
        AND usuario_para_id = p_usuario_ori_id;
     --
     cronograma_pkg.alocacao_usu_processar(p_usuario_sessao_id,
                                           p_empresa_id,
                                           p_usuario_ori_id,
                                           r_ta.data_inicio,
                                           r_ta.data_termino,
                                           p_erro_cod,
                                           p_erro_msg);
     --
     IF p_erro_cod <> '00000' THEN
      RAISE v_exception;
     END IF;
    END IF;
   END LOOP;
   --
  END LOOP;
  CLOSE c_up;
  --
  COMMIT;
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   IF c_up%ISOPEN THEN
    CLOSE c_up;
   END IF;
   ROLLBACK;
  WHEN OTHERS THEN
   IF c_up%ISOPEN THEN
    CLOSE c_up;
   END IF;
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END substituir_nos_jobs;
 --
 --
 --
 PROCEDURE substituir_nas_ca
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 15/05/2014
  -- DESCRICAO: substitui o usuario nas cartas acordo nao emitidas.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            18/01/2017  Geracao de evento de enderecar
  ------------------------------------------------------------------------------------------
  p_usuario_sessao_id IN usuario.usuario_id%TYPE,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_usuario_ori_id    IN usuario.usuario_id%TYPE,
  p_usuario_sub_id    IN usuario.usuario_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) AS
  v_qt               INTEGER;
  v_identif_objeto   historico.identif_objeto%TYPE;
  v_compl_histor     historico.complemento%TYPE;
  v_historico_id     historico.historico_id%TYPE;
  v_exception        EXCEPTION;
  v_flag_ativo       usuario.flag_ativo%TYPE;
  v_papel_id         papel.papel_id%TYPE;
  v_apelido_ori      pessoa.apelido%TYPE;
  v_apelido_sub      pessoa.apelido%TYPE;
  v_num_carta_acordo VARCHAR2(100);
  --
  CURSOR c_ca IS
   SELECT DISTINCT ca.carta_acordo_id,
                   it.job_id
     FROM carta_acordo ca,
          item_carta   ic,
          item         it
    WHERE ca.produtor_id = p_usuario_ori_id
      AND ca.status <> 'EMITIDA'
      AND ca.carta_acordo_id = ic.carta_acordo_id
      AND ic.item_id = it.item_id;
  --
 BEGIN
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'USUARIO_C', NULL, NULL, p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF nvl(p_usuario_ori_id, 0) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do usuário a ser substituído é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM usuario_empresa
   WHERE usuario_id = p_usuario_ori_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O usuário a ser substituído não existe ou não está ' ||
                 'associado a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  SELECT apelido
    INTO v_apelido_ori
    FROM pessoa
   WHERE usuario_id = p_usuario_ori_id;
  --
  IF nvl(p_usuario_sub_id, 0) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do usuário substituto é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM usuario_empresa
   WHERE usuario_id = p_usuario_sub_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O usuário substituto não existe ou não está ' || 'associado a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  IF p_usuario_ori_id = p_usuario_sub_id THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O usuário não pode ser substiuído por ele mesmo.';
   RAISE v_exception;
  END IF;
  --
  SELECT us.flag_ativo,
         pe.apelido
    INTO v_flag_ativo,
         v_apelido_sub
    FROM usuario us,
         pessoa  pe
   WHERE us.usuario_id = p_usuario_sub_id
     AND us.usuario_id = pe.usuario_id;
  --
  IF v_flag_ativo = 'N' THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O usuário substituto não pode estar inativo.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  FOR r_ca IN c_ca
  LOOP
   v_num_carta_acordo := carta_acordo_pkg.numero_completo_formatar(r_ca.carta_acordo_id, 'N');
   --
   -- endereca o usuario substituto
   -- tenta achar um papel com privilegio
   SELECT MAX(up.papel_id)
     INTO v_papel_id
     FROM usuario_papel up,
          papel_priv    pp,
          privilegio    pr,
          papel         pa
    WHERE up.usuario_id = p_usuario_sub_id
      AND up.papel_id = pp.papel_id
      AND pp.papel_id = pa.papel_id
      AND pa.empresa_id = p_empresa_id
      AND pp.privilegio_id = pr.privilegio_id
      AND pr.codigo IN ('CARTA_ACORDO_EM', 'CARTA_ACORDO_C');
   --
   -- sem co-ender, sem pula notif
   job_pkg.enderecar_usuario(p_usuario_sessao_id,
                             'N',
                             'N',
                             'N',
                             p_empresa_id,
                             r_ca.job_id,
                             p_usuario_sub_id,
                             v_apelido_sub || ' substituiu ' || v_apelido_ori ||
                             ' como Produtor na Carta Acordo ' || v_num_carta_acordo,
                             'Substituição de Usuário em Cartas Acordo',
                             p_erro_cod,
                             p_erro_msg);
   --
   IF p_erro_cod <> '00000' THEN
    RAISE v_exception;
   END IF;
   --
   UPDATE carta_acordo
      SET produtor_id = p_usuario_sub_id
    WHERE carta_acordo_id = r_ca.carta_acordo_id;
  END LOOP;
  --
  COMMIT;
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END substituir_nas_ca;
 --
 --
 --
 PROCEDURE substituir_nas_os
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 15/05/2014
  -- DESCRICAO: substitui o usuario nas OS nao finalizadas do cliente informado e do tipo
  --   de OS informado.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            18/09/2015  Novo parametro opcional p_cliente_id.
  -- Silvia            18/01/2017  Geracao de evento de enderecar
  -- Silvia            22/03/2017  Volta do status da OS qdo o executor mudar.
  -- Silvia            04/09/2020  Recalculo da alocacao dos usuarios envolvidos
  -- Silvia            06/11/2020  Tratamento de os_usuario_data
  ------------------------------------------------------------------------------------------
  p_usuario_sessao_id IN usuario.usuario_id%TYPE,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_usuario_ori_id    IN usuario.usuario_id%TYPE,
  p_tipo_ender        IN os_usuario.tipo_ender%TYPE,
  p_tipo_os_id        IN ordem_servico.tipo_os_id%TYPE,
  p_usuario_sub_id    IN usuario.usuario_id%TYPE,
  p_cliente_id        IN job.cliente_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) AS
  v_qt              INTEGER;
  v_identif_objeto  historico.identif_objeto%TYPE;
  v_compl_histor    historico.complemento%TYPE;
  v_historico_id    historico.historico_id%TYPE;
  v_exception       EXCEPTION;
  v_flag_ativo      usuario.flag_ativo%TYPE;
  v_papel_id        papel.papel_id%TYPE;
  v_apelido_ori     pessoa.apelido%TYPE;
  v_apelido_sub     pessoa.apelido%TYPE;
  v_tipo_ender_desc VARCHAR2(20);
  v_numero_os_char  VARCHAR2(50);
  --
  CURSOR c_os IS
   SELECT jo.job_id,
          jo.cliente_id,
          os.ordem_servico_id,
          os.tipo_os_id,
          ti.nome             AS tipo_os_desc,
          os.status           AS status_os,
          ou.tipo_ender,
          ou.status,
          ou.data_status,
          ou.sequencia,
          ou.horas_planej,
          os.data_inicio,
          os.data_termino
     FROM ordem_servico os,
          job           jo,
          os_usuario    ou,
          tipo_os       ti
    WHERE os.job_id = jo.job_id
      AND os.tipo_os_id = p_tipo_os_id
      AND os.status NOT IN ('CONC', 'CANC', 'DESC')
      AND jo.empresa_id = p_empresa_id
      AND ou.ordem_servico_id = os.ordem_servico_id
      AND ou.usuario_id = p_usuario_ori_id
      AND ou.tipo_ender = p_tipo_ender
      AND os.tipo_os_id = ti.tipo_os_id;
  --
 BEGIN
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'USUARIO_C', NULL, NULL, p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF TRIM(p_tipo_ender) IS NULL OR p_tipo_ender NOT IN ('EXE', 'SOL', 'DIS') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de endereçamento inválido (' || p_tipo_ender || ').';
   RAISE v_exception;
  END IF;
  --
  SELECT decode(p_tipo_ender, 'EXE', 'Executor', 'SOL', 'Solicitante', 'DIS', 'Distribuidor')
    INTO v_tipo_ender_desc
    FROM dual;
  --
  IF nvl(p_usuario_ori_id, 0) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do usuário a ser substituído é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM usuario_empresa
   WHERE usuario_id = p_usuario_ori_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O usuário a ser substituído não existe ou não está ' ||
                 'associado a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  SELECT apelido
    INTO v_apelido_ori
    FROM pessoa
   WHERE usuario_id = p_usuario_ori_id;
  --
  IF nvl(p_tipo_os_id, 0) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do Tipo da Workflows é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_usuario_sub_id, 0) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do usuário substituto é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM usuario_empresa
   WHERE usuario_id = p_usuario_sub_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O usuário substituto não existe ou não está ' || 'associado a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  IF p_usuario_ori_id = p_usuario_sub_id THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O usuário não pode ser substiuído por ele mesmo.';
   RAISE v_exception;
  END IF;
  --
  SELECT us.flag_ativo,
         pe.apelido
    INTO v_flag_ativo,
         v_apelido_sub
    FROM usuario us,
         pessoa  pe
   WHERE us.usuario_id = p_usuario_sub_id
     AND us.usuario_id = pe.usuario_id;
  --
  IF v_flag_ativo = 'N' THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O usuário substituto não pode estar inativo.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  FOR r_os IN c_os
  LOOP
   IF nvl(p_cliente_id, 0) = 0 OR nvl(p_cliente_id, 0) = r_os.cliente_id THEN
    -- verifica se o usuario substituto estah enderecado na OS
    -- com o mesmo tipo de enderecamento do usuario original.
    SELECT COUNT(*)
      INTO v_qt
      FROM os_usuario
     WHERE ordem_servico_id = r_os.ordem_servico_id
       AND usuario_id = p_usuario_sub_id
       AND tipo_ender = r_os.tipo_ender;
    --
    IF v_qt = 0 THEN
     v_numero_os_char := ordem_servico_pkg.numero_formatar(r_os.ordem_servico_id);
     -- nao estah. Pode enderecar.
     --
     INSERT INTO os_usuario
      (ordem_servico_id,
       usuario_id,
       tipo_ender,
       status,
       data_status,
       flag_lido,
       horas_planej,
       sequencia)
     VALUES
      (r_os.ordem_servico_id,
       p_usuario_sub_id,
       r_os.tipo_ender,
       r_os.status,
       r_os.data_status,
       'N',
       r_os.horas_planej,
       r_os.sequencia);
     --
     UPDATE os_usuario_data
        SET usuario_id = p_usuario_sub_id
      WHERE ordem_servico_id = r_os.ordem_servico_id
        AND usuario_id = p_usuario_ori_id
        AND tipo_ender = r_os.tipo_ender;
     --
     historico_pkg.hist_ender_registrar(p_usuario_sub_id,
                                        'OS',
                                        r_os.ordem_servico_id,
                                        r_os.tipo_ender,
                                        p_erro_cod,
                                        p_erro_msg);
     IF p_erro_cod <> '00000' THEN
      RAISE v_exception;
     END IF;
     --
     IF r_os.tipo_ender = 'EXE' THEN
      cronograma_pkg.alocacao_usu_processar(p_usuario_sessao_id,
                                            p_empresa_id,
                                            p_usuario_sub_id,
                                            r_os.data_inicio,
                                            r_os.data_termino,
                                            p_erro_cod,
                                            p_erro_msg);
      --
      IF p_erro_cod <> '00000' THEN
       RAISE v_exception;
      END IF;
     END IF;
     --
     -- tenta achar um papel com privilegio
     SELECT MAX(up.papel_id)
       INTO v_papel_id
       FROM usuario_papel  up,
            papel_priv_tos pt,
            privilegio     pr
      WHERE up.usuario_id = p_usuario_sub_id
        AND up.papel_id = pt.papel_id
        AND pt.tipo_os_id = p_tipo_os_id
        AND pt.privilegio_id = pr.privilegio_id
        AND pr.codigo = decode(r_os.tipo_ender, 'SOL', 'OS_C', 'DIS', 'OS_DI', 'EXE', 'OS_EX');
     --
     -- endereca o usuario substituto no job, sem co-ender, sem pula notif
     job_pkg.enderecar_usuario(p_usuario_sessao_id,
                               'N',
                               'N',
                               'N',
                               p_empresa_id,
                               r_os.job_id,
                               p_usuario_sub_id,
                               v_apelido_sub || ' substituiu ' || v_apelido_ori || ' como ' ||
                               v_tipo_ender_desc || ' no Workflow ' || v_numero_os_char || ' de ' ||
                               r_os.tipo_os_desc,
                               'Substituição de Usuário nos Workflows',
                               p_erro_cod,
                               p_erro_msg);
     --
     IF p_erro_cod <> '00000' THEN
      RAISE v_exception;
     END IF;
    END IF;
    --
    -- desendereca o usuario substituido
    DELETE FROM os_usuario_data
     WHERE ordem_servico_id = r_os.ordem_servico_id
       AND usuario_id = p_usuario_ori_id
       AND tipo_ender = r_os.tipo_ender;
    DELETE FROM os_usuario
     WHERE ordem_servico_id = r_os.ordem_servico_id
       AND usuario_id = p_usuario_ori_id
       AND tipo_ender = r_os.tipo_ender;
    --
    IF r_os.tipo_ender = 'EXE' THEN
     cronograma_pkg.alocacao_usu_processar(p_usuario_sessao_id,
                                           p_empresa_id,
                                           p_usuario_ori_id,
                                           r_os.data_inicio,
                                           r_os.data_termino,
                                           p_erro_cod,
                                           p_erro_msg);
     --
     IF p_erro_cod <> '00000' THEN
      RAISE v_exception;
     END IF;
    END IF;
    --
    -- trata volta status de EMEX p/ ACEI caso o executor seja alterado
    IF r_os.tipo_ender = 'EXE' AND r_os.status_os = 'EMEX' THEN
     -- verifica se a transicacao p/ voltar status existe
     SELECT COUNT(*)
       INTO v_qt
       FROM tipo_os_transicao ti,
            os_transicao      ot
      WHERE ti.tipo_os_id = r_os.tipo_os_id
        AND ti.os_transicao_id = ot.os_transicao_id
        AND ot.status_de = 'EMEX'
        AND ot.status_para = 'ACEI';
     --
     IF v_qt > 0 THEN
      ordem_servico_pkg.acao_executar(p_usuario_sessao_id,
                                      p_empresa_id,
                                      'N',
                                      r_os.ordem_servico_id,
                                      'RETORNAR',
                                      0,
                                      'Substituição de executor',
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      p_erro_cod,
                                      p_erro_msg);
      IF p_erro_cod <> '00000' THEN
       RAISE v_exception;
      END IF;
     END IF;
    END IF; -- fim do IF r_os.tipo_ender = 'EXE'
   END IF; -- fim do IF NVL(p_cliente_id,0) = 0
  END LOOP;
  --
  COMMIT;
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END substituir_nas_os;
 --
 --
 --
 PROCEDURE substituir_nas_tarefas
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 15/05/2014
  -- DESCRICAO: substitui o usuario nas tarefas nao finalizadas.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            04/09/2020  Recalculo da alocacao dos usuarios envolvidos
  -- Silvia            06/11/2020  Tratamento de tarefa_usuario_data
  -- Silvia            15/07/2021  Novo parametro de tipo de usuario. Substituicao em
  --                               tarefas com ou sem job.
  ------------------------------------------------------------------------------------------
  p_usuario_sessao_id IN usuario.usuario_id%TYPE,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_usuario_ori_id    IN usuario.usuario_id%TYPE,
  p_usuario_sub_id    IN usuario.usuario_id%TYPE,
  p_tipo_usuario      IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) AS
  v_qt             INTEGER;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_exception      EXCEPTION;
  v_flag_ativo     usuario.flag_ativo%TYPE;
  --
  CURSOR c_ts IS
   SELECT tarefa_id,
          data_inicio,
          data_termino
     FROM tarefa
    WHERE usuario_de_id = p_usuario_ori_id
      AND status NOT IN ('CANC', 'CONC')
    ORDER BY 1,
             2;
  --
  CURSOR c_te IS
   SELECT ta.tarefa_id,
          ta.data_inicio,
          ta.data_termino
     FROM tarefa         ta,
          tarefa_usuario tu
    WHERE ta.tarefa_id = tu.tarefa_id
      AND tu.usuario_para_id = p_usuario_ori_id
      AND ta.status NOT IN ('CANC', 'CONC')
    ORDER BY 1,
             2;
  --
 BEGIN
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'USUARIO_C', NULL, NULL, p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_tipo_usuario) IS NULL OR p_tipo_usuario NOT IN ('SOL', 'EXE') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de usuário inválido (' || p_tipo_usuario || ').';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM usuario_empresa
   WHERE usuario_id = p_usuario_ori_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O usuário a ser substituído não existe ou não está ' ||
                 'associado a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_usuario_sub_id, 0) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do usuário substituto é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM usuario_empresa
   WHERE usuario_id = p_usuario_sub_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O usuário substituto não existe ou não está ' || 'associado a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  IF p_usuario_ori_id = p_usuario_sub_id THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O usuário não pode ser substiuído por ele mesmo.';
   RAISE v_exception;
  END IF;
  --
  SELECT flag_ativo
    INTO v_flag_ativo
    FROM usuario
   WHERE usuario_id = p_usuario_sub_id;
  --
  IF v_flag_ativo = 'N' THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O usuário substituto não pode estar inativo.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco - substituicao de solicitante
  ------------------------------------------------------------
  IF p_tipo_usuario = 'SOL' THEN
   FOR r_ts IN c_ts
   LOOP
    -- troca o autor da tarefa
    UPDATE tarefa
       SET usuario_de_id = p_usuario_sub_id
     WHERE tarefa_id = r_ts.tarefa_id;
    --
    historico_pkg.hist_ender_registrar(p_usuario_sub_id,
                                       'TAR',
                                       r_ts.tarefa_id,
                                       'SOL',
                                       p_erro_cod,
                                       p_erro_msg);
    IF p_erro_cod <> '00000' THEN
     RAISE v_exception;
    END IF;
   END LOOP;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco - substituicao de executor
  ------------------------------------------------------------
  IF p_tipo_usuario = 'EXE' THEN
   FOR r_te IN c_te
   LOOP
    -- troca o executor da tarefa.
    -- verifica se o substituto ja eh executor.
    SELECT COUNT(*)
      INTO v_qt
      FROM tarefa_usuario
     WHERE tarefa_id = r_te.tarefa_id
       AND usuario_para_id = p_usuario_sub_id;
    --
    IF v_qt = 0 THEN
     -- cria novo registro ao inves de fazer update por causa
     -- da chave primaria composta.
     INSERT INTO tarefa_usuario
      (tarefa_id,
       usuario_para_id,
       status,
       data_status)
     VALUES
      (r_te.tarefa_id,
       p_usuario_sub_id,
       'EMEX',
       SYSDATE);
     --
     -- transfere datas para o novo executor
     UPDATE tarefa_usuario_data
        SET usuario_para_id = p_usuario_sub_id
      WHERE tarefa_id = r_te.tarefa_id
        AND usuario_para_id = p_usuario_ori_id;
     --
     UPDATE tarefa_usuario tu
        SET horas_totais =
            (SELECT nvl(SUM(horas), 0)
               FROM tarefa_usuario_data td
              WHERE td.tarefa_id = tu.tarefa_id
                AND td.usuario_para_id = tu.usuario_para_id)
      WHERE tarefa_id = r_te.tarefa_id
        AND usuario_para_id = p_usuario_sub_id;
     --
     historico_pkg.hist_ender_registrar(p_usuario_sub_id,
                                        'TAR',
                                        r_te.tarefa_id,
                                        'EXE',
                                        p_erro_cod,
                                        p_erro_msg);
     IF p_erro_cod <> '00000' THEN
      RAISE v_exception;
     END IF;
     --
     cronograma_pkg.alocacao_usu_processar(p_usuario_sessao_id,
                                           p_empresa_id,
                                           p_usuario_sub_id,
                                           r_te.data_inicio,
                                           r_te.data_termino,
                                           p_erro_cod,
                                           p_erro_msg);
     --
     IF p_erro_cod <> '00000' THEN
      RAISE v_exception;
     END IF;
    END IF;
    --
    -- apaga registros do usuario que foi substituido
    DELETE FROM tarefa_usuario_data
     WHERE tarefa_id = r_te.tarefa_id
       AND usuario_para_id = p_usuario_ori_id;
    DELETE FROM tarefa_usuario
     WHERE tarefa_id = r_te.tarefa_id
       AND usuario_para_id = p_usuario_ori_id;
    --
    cronograma_pkg.alocacao_usu_processar(p_usuario_sessao_id,
                                          p_empresa_id,
                                          p_usuario_ori_id,
                                          r_te.data_inicio,
                                          r_te.data_termino,
                                          p_erro_cod,
                                          p_erro_msg);
    --
    IF p_erro_cod <> '00000' THEN
     RAISE v_exception;
    END IF;
   END LOOP;
  END IF;
  --
  COMMIT;
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END substituir_nas_tarefas;
 --
 --
 --
 PROCEDURE ts_grupo_adicionar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 09/05/2013
  -- DESCRICAO: Adiciona grupo de aprovacao de timesheet.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            31/07/2015  Novo privilegio TS_APROV_C
  -- Silvia            06/09/2017  Implementacao de historico c/ XML.
  ------------------------------------------------------------------------------------------
  p_usuario_sessao_id IN usuario.usuario_id%TYPE,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_usuario_aprov_id  IN usuario.usuario_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) AS
  v_qt             INTEGER;
  v_exception      EXCEPTION;
  v_ts_grupo_id    ts_grupo.ts_grupo_id%TYPE;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_xml_atual      CLOB;
  --
 BEGIN
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'TS_APROV_C', NULL, NULL, p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_usuario_aprov_id, 0) = 0 THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM ts_grupo gr
    WHERE NOT EXISTS (SELECT 1
             FROM ts_aprovador ap
            WHERE ap.ts_grupo_id = gr.ts_grupo_id);
   --
   IF v_qt > 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Já existe um grupo criado sem indicação de aprovador .';
    RAISE v_exception;
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT seq_ts_grupo.nextval
    INTO v_ts_grupo_id
    FROM dual;
  --
  INSERT INTO ts_grupo
   (ts_grupo_id,
    usuario_resp_id,
    data_entrada)
  VALUES
   (v_ts_grupo_id,
    p_usuario_sessao_id,
    SYSDATE);
  --
  IF nvl(p_usuario_aprov_id, 0) > 0 THEN
   INSERT INTO ts_aprovador
    (ts_grupo_id,
     usuario_id)
   VALUES
    (v_ts_grupo_id,
     p_usuario_aprov_id);
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  usuario_pkg.xml_ts_gerar(v_ts_grupo_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(v_ts_grupo_id);
  v_compl_histor   := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'TS_GRUPO',
                   'INCLUIR',
                   v_identif_objeto,
                   v_ts_grupo_id,
                   v_compl_histor,
                   NULL,
                   'N',
                   NULL,
                   v_xml_atual,
                   v_historico_id,
                   p_erro_cod,
                   p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  COMMIT;
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END ts_grupo_adicionar;
 --
 --
 PROCEDURE ts_grupo_excluir
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 09/05/2013
  -- DESCRICAO: Exclui grupo de aprovacao de timesheet.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            06/09/2017  Implementacao de historico c/ XML.
  ------------------------------------------------------------------------------------------
  p_usuario_sessao_id IN usuario.usuario_id%TYPE,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_ts_grupo_id       IN ts_grupo.ts_grupo_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) AS
  v_qt             INTEGER;
  v_exception      EXCEPTION;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_xml_atual      CLOB;
  --
 BEGIN
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'TS_APROV_C', NULL, NULL, p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM ts_grupo
   WHERE ts_grupo_id = p_ts_grupo_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse grupo de aprovação não existe.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  usuario_pkg.xml_ts_gerar(p_ts_grupo_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  DELETE FROM ts_equipe
   WHERE ts_grupo_id = p_ts_grupo_id;
  --
  DELETE FROM ts_aprovador
   WHERE ts_grupo_id = p_ts_grupo_id;
  --
  DELETE FROM ts_grupo
   WHERE ts_grupo_id = p_ts_grupo_id;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(p_ts_grupo_id);
  v_compl_histor   := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'TS_GRUPO',
                   'EXCLUIR',
                   v_identif_objeto,
                   p_ts_grupo_id,
                   v_compl_histor,
                   NULL,
                   'N',
                   NULL,
                   v_xml_atual,
                   v_historico_id,
                   p_erro_cod,
                   p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  COMMIT;
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END ts_grupo_excluir;
 --
 --
 PROCEDURE ts_aprovador_atualizar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 09/05/2013
  -- DESCRICAO: Atualiza os aprovadores de um determinado grupo de aprovacao de timesheet.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            31/07/2015  Novo privilegio TS_APROV_C
  -- Silvia            06/09/2017  Implementacao de historico c/ XML.
  ------------------------------------------------------------------------------------------
  p_usuario_sessao_id IN usuario.usuario_id%TYPE,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_ts_grupo_id       IN ts_grupo.ts_grupo_id%TYPE,
  p_vetor_usuario_id  IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) AS
  v_qt               INTEGER;
  v_exception        EXCEPTION;
  v_delimitador      CHAR(1);
  v_vetor_usuario_id VARCHAR2(4000);
  v_usuario_id       usuario.usuario_id%TYPE;
  v_identif_objeto   historico.identif_objeto%TYPE;
  v_compl_histor     historico.complemento%TYPE;
  v_historico_id     historico.historico_id%TYPE;
  v_xml_antes        CLOB;
  v_xml_atual        CLOB;
  --
 BEGIN
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'TS_APROV_C', NULL, NULL, p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM ts_grupo
   WHERE ts_grupo_id = p_ts_grupo_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse grupo de aprovação não existe.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  usuario_pkg.xml_ts_gerar(p_ts_grupo_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  DELETE FROM ts_aprovador
   WHERE ts_grupo_id = p_ts_grupo_id;
  --
  v_delimitador      := '|';
  v_vetor_usuario_id := p_vetor_usuario_id;
  --
  WHILE nvl(length(rtrim(v_vetor_usuario_id)), 0) > 0
  LOOP
   v_usuario_id := to_number(prox_valor_retornar(v_vetor_usuario_id, v_delimitador));
   --
   INSERT INTO ts_aprovador
    (ts_grupo_id,
     usuario_id)
   VALUES
    (p_ts_grupo_id,
     v_usuario_id);
  END LOOP;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM ts_aprovador
   WHERE ts_grupo_id = p_ts_grupo_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O grupo não pode ficar sem usuários aprovadores.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  usuario_pkg.xml_ts_gerar(p_ts_grupo_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(p_ts_grupo_id);
  v_compl_histor   := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'TS_GRUPO',
                   'ALTERAR',
                   v_identif_objeto,
                   p_ts_grupo_id,
                   v_compl_histor,
                   NULL,
                   'N',
                   v_xml_antes,
                   v_xml_atual,
                   v_historico_id,
                   p_erro_cod,
                   p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  COMMIT;
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END ts_aprovador_atualizar;
 --
 --
 PROCEDURE ts_equipe_atualizar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 09/05/2013
  -- DESCRICAO: Atualiza a equipe de um determinado grupo de aprovacao de timesheet.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            31/07/2015  Novo privilegio TS_APROV_C
  -- Silvia            06/09/2017  Implementacao de historico c/ XML.
  ------------------------------------------------------------------------------------------
  p_usuario_sessao_id IN usuario.usuario_id%TYPE,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_ts_grupo_id       IN ts_grupo.ts_grupo_id%TYPE,
  p_vetor_usuario_id  IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) AS
  v_qt               INTEGER;
  v_exception        EXCEPTION;
  v_delimitador      CHAR(1);
  v_vetor_usuario_id VARCHAR2(4000);
  v_usuario_id       usuario.usuario_id%TYPE;
  v_identif_objeto   historico.identif_objeto%TYPE;
  v_compl_histor     historico.complemento%TYPE;
  v_historico_id     historico.historico_id%TYPE;
  v_xml_antes        CLOB;
  v_xml_atual        CLOB;
  --
 BEGIN
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'TS_APROV_C', NULL, NULL, p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM ts_grupo
   WHERE ts_grupo_id = p_ts_grupo_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse grupo de aprovação não existe.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  usuario_pkg.xml_ts_gerar(p_ts_grupo_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  DELETE FROM ts_equipe
   WHERE ts_grupo_id = p_ts_grupo_id;
  --
  v_delimitador      := '|';
  v_vetor_usuario_id := p_vetor_usuario_id;
  --
  WHILE nvl(length(rtrim(v_vetor_usuario_id)), 0) > 0
  LOOP
   v_usuario_id := to_number(prox_valor_retornar(v_vetor_usuario_id, v_delimitador));
   --
   INSERT INTO ts_equipe
    (ts_grupo_id,
     usuario_id)
   VALUES
    (p_ts_grupo_id,
     v_usuario_id);
   --
   UPDATE usuario
      SET flag_sem_aprov_horas = 'N'
    WHERE usuario_id = v_usuario_id;
  END LOOP;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  usuario_pkg.xml_ts_gerar(p_ts_grupo_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(p_ts_grupo_id);
  v_compl_histor   := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'TS_GRUPO',
                   'ALTERAR',
                   v_identif_objeto,
                   p_ts_grupo_id,
                   v_compl_histor,
                   NULL,
                   'N',
                   v_xml_antes,
                   v_xml_atual,
                   v_historico_id,
                   p_erro_cod,
                   p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  COMMIT;
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END ts_equipe_atualizar;
 --
 --
 PROCEDURE ts_sem_aprov_atualizar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 09/05/2013
  -- DESCRICAO: Atualiza usuarios que nao precisam de aprovacao de timesheet.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            31/07/2015  Novo privilegio TS_APROV_C
  -- Silvia            06/09/2017  Implementacao de historico c/ XML.
  ------------------------------------------------------------------------------------------
  p_usuario_sessao_id IN usuario.usuario_id%TYPE,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_vetor_usuario_id  IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) AS
  v_qt               INTEGER;
  v_exception        EXCEPTION;
  v_delimitador      CHAR(1);
  v_vetor_usuario_id VARCHAR2(4000);
  v_usuario_id       usuario.usuario_id%TYPE;
  v_login            usuario.login%TYPE;
  v_nome             pessoa.nome%TYPE;
  v_identif_objeto   historico.identif_objeto%TYPE;
  v_compl_histor     historico.complemento%TYPE;
  v_historico_id     historico.historico_id%TYPE;
  v_xml_atual        CLOB;
  --
 BEGIN
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'TS_APROV_C', NULL, NULL, p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE usuario us
     SET flag_sem_aprov_horas = 'N'
   WHERE EXISTS (SELECT 1
            FROM usuario_empresa ue
           WHERE ue.usuario_id = us.usuario_id
             AND ue.empresa_id = p_empresa_id);
  --
  v_delimitador      := '|';
  v_vetor_usuario_id := p_vetor_usuario_id;
  --
  WHILE nvl(length(rtrim(v_vetor_usuario_id)), 0) > 0
  LOOP
   v_usuario_id := to_number(prox_valor_retornar(v_vetor_usuario_id, v_delimitador));
   --
   SELECT MAX(u.login),
          MAX(p.nome)
     INTO v_login,
          v_nome
     FROM pessoa  p,
          usuario u
    WHERE u.usuario_id = v_usuario_id
      AND u.usuario_id = p.usuario_id;
   --
   IF v_login IS NULL THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse usuário não existe.';
    RAISE v_exception;
   END IF;
   --
   DELETE FROM ts_equipe
    WHERE usuario_id = v_usuario_id;
   --
   UPDATE usuario
      SET flag_sem_aprov_horas = 'S'
    WHERE usuario_id = v_usuario_id;
   --
   ------------------------------------------------------------
   -- gera xml do log
   ------------------------------------------------------------
   usuario_pkg.xml_gerar(v_usuario_id, v_xml_atual, p_erro_cod, p_erro_msg);
   --
   IF p_erro_cod <> '00000' THEN
    RAISE v_exception;
   END IF;
   --
   ------------------------------------------------------------
   -- geracao de evento
   ------------------------------------------------------------
   v_identif_objeto := rtrim(v_login);
   v_compl_histor   := 'Sem aprovação de horas. Pessoa: ' || v_nome;
   --
   evento_pkg.gerar(p_usuario_sessao_id,
                    p_empresa_id,
                    'USUARIO',
                    'ALTERAR',
                    v_identif_objeto,
                    v_usuario_id,
                    v_compl_histor,
                    NULL,
                    'N',
                    NULL,
                    v_xml_atual,
                    v_historico_id,
                    p_erro_cod,
                    p_erro_msg);
   --
   IF p_erro_cod <> '00000' THEN
    RAISE v_exception;
   END IF;
  END LOOP;
  --
  COMMIT;
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END ts_sem_aprov_atualizar;
 --
 --
 PROCEDURE xml_gerar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 31/01/2017
  -- DESCRICAO: Subrotina que gera o xml do USUARIO para o historico.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_id IN usuario.usuario_id%TYPE,
  p_xml        OUT CLOB,
  p_erro_cod   OUT VARCHAR2,
  p_erro_msg   OUT VARCHAR2
 ) IS
  v_qt        INTEGER;
  v_exception EXCEPTION;
  v_xml       xmltype;
  v_xml_aux1  xmltype;
  v_xml_aux99 xmltype;
  v_xml_doc   VARCHAR2(100);
  --
  CURSOR c_em IS
   SELECT em.nome AS empresa,
          up.flag_padrao
     FROM usuario_empresa up,
          empresa         em
    WHERE up.usuario_id = p_usuario_id
      AND up.empresa_id = em.empresa_id
    ORDER BY em.nome;
  --
  CURSOR c_pa IS
   SELECT pa.nome AS papel
     FROM usuario_papel up,
          papel         pa
    WHERE up.usuario_id = p_usuario_id
      AND up.papel_id = pa.papel_id
    ORDER BY pa.nome;
  --
  CURSOR c_ca IS
   SELECT ca.nome AS cargo,
          uc.data_ini,
          uc.nivel,
          to_char(uc.data_ini, 'MM/YYYY') AS data_ini_char
     FROM usuario_cargo uc,
          cargo         ca
    WHERE uc.usuario_id = p_usuario_id
      AND uc.cargo_id = ca.cargo_id
    ORDER BY uc.data_ini;
  --
 BEGIN
  v_qt      := 0;
  v_xml_doc := '<?xml version="1.0" encoding="ISO-8859-1" ?>';
  --
  ------------------------------------------------------------
  -- monta as informacoes gerais
  ------------------------------------------------------------
  SELECT xmlconcat(xmlelement("usuario_id", us.usuario_id),
                   xmlelement("data_evento", data_hora_mostrar(SYSDATE)),
                   xmlelement("apelido", pe.apelido),
                   xmlelement("nome", pe.nome),
                   xmlelement("login", us.login),
                   xmlelement("ativo", us.flag_ativo),
                   xmlelement("admin", us.flag_admin),
                   xmlelement("admin_sistema", us.flag_admin_sistema),
                   xmlelement("login_bloqueado", us.flag_bloqueado),
                   xmlelement("email_bloqueado", us.flag_email_bloq),
                   xmlelement("recebe_notif_email", us.flag_notifica_email),
                   xmlelement("data_ult_login", data_hora_mostrar(us.data_ult_login)),
                   xmlelement("data_inativacao", data_hora_mostrar(us.data_inativacao)),
                   xmlelement("data_apontam_inicial", data_mostrar(us.data_apontam_ini)),
                   xmlelement("data_apontam_final", data_mostrar(us.data_apontam_fim)),
                   xmlelement("data_exp_senha", data_mostrar(us.data_exp_senha)),
                   xmlelement("sem_bloq_apont_horas", us.flag_sem_bloq_apont),
                   xmlelement("sem_bloq_aprov_horas", us.flag_sem_bloq_aprov),
                   xmlelement("sem_aprov_horas", us.flag_sem_aprov_horas),
                   xmlelement("permite_home_office", us.flag_permite_home),
                   xmlelement("departamento", de.nome),
                   xmlelement("area", ar.nome),
                   xmlelement("funcao", us.funcao),
                   xmlelement("categoria", us.categoria),
                   xmlelement("tipo_relacao", us.tipo_relacao),
                   xmlelement("cod_funcionario", us.cod_funcionario),
                   xmlelement("cod_ext_usuario", us.cod_ext_usuario),
                   xmlelement("tabela_feriado", tf.nome),
                   xmlelement("min_horas_apont_dia", numero_mostrar(us.min_horas_apont_dia, 2, 'N')),
                   xmlelement("acesso_principal", us.flag_acesso_pri),
                   xmlelement("acesso_cliente", us.flag_acesso_cli),
                   xmlelement("acesso_wallboard", us.flag_acesso_wall),
                   xmlelement("simula_cliente", us.flag_simula_cli))
    INTO v_xml
    FROM pessoa       pe,
         usuario      us,
         departamento de,
         tab_feriado  tf,
         area         ar
   WHERE us.usuario_id = p_usuario_id
     AND us.usuario_id = pe.usuario_id
     AND us.departamento_id = de.departamento_id(+)
     AND us.tab_feriado_id = tf.tab_feriado_id(+)
     AND us.area_id = ar.area_id(+);
  --
  ------------------------------------------------------------
  -- monta EMPRESAS
  ------------------------------------------------------------
  v_xml_aux1 := NULL;
  FOR r_em IN c_em
  LOOP
   SELECT xmlagg(xmlelement("empresa",
                            xmlelement("nome", r_em.empresa),
                            xmlelement("padrao", r_em.flag_padrao)))
     INTO v_xml_aux99
     FROM dual;
   --
   SELECT xmlconcat(v_xml_aux1, v_xml_aux99)
     INTO v_xml_aux1
     FROM dual;
  END LOOP;
  --
  SELECT xmlagg(xmlelement("empresas", v_xml_aux1))
    INTO v_xml_aux1
    FROM dual;
  --
  SELECT xmlconcat(v_xml, v_xml_aux1)
    INTO v_xml
    FROM dual;
  --
  ------------------------------------------------------------
  -- monta PAPEIS
  ------------------------------------------------------------
  v_xml_aux1 := NULL;
  FOR r_pa IN c_pa
  LOOP
   SELECT xmlconcat(xmlelement("papel", r_pa.papel))
     INTO v_xml_aux99
     FROM dual;
   --
   SELECT xmlconcat(v_xml_aux1, v_xml_aux99)
     INTO v_xml_aux1
     FROM dual;
  END LOOP;
  --
  SELECT xmlagg(xmlelement("papeis", v_xml_aux1))
    INTO v_xml_aux1
    FROM dual;
  --
  SELECT xmlconcat(v_xml, v_xml_aux1)
    INTO v_xml
    FROM dual;
  --
  ------------------------------------------------------------
  -- monta CARGOS
  ------------------------------------------------------------
  v_xml_aux1 := NULL;
  FOR r_ca IN c_ca
  LOOP
   SELECT xmlagg(xmlelement("cargo",
                            xmlelement("desde", r_ca.data_ini_char),
                            xmlelement("cargo", r_ca.cargo),
                            xmlelement("nivel", r_ca.nivel)))
     INTO v_xml_aux99
     FROM dual;
   --
   SELECT xmlconcat(v_xml_aux1, v_xml_aux99)
     INTO v_xml_aux1
     FROM dual;
  END LOOP;
  --
  SELECT xmlagg(xmlelement("cargos", v_xml_aux1))
    INTO v_xml_aux1
    FROM dual;
  --
  SELECT xmlconcat(v_xml, v_xml_aux1)
    INTO v_xml
    FROM dual;
  --
  ------------------------------------------------------------
  -- junta tudo debaixo de "usuario"
  ------------------------------------------------------------
  SELECT xmlagg(xmlelement("usuario", v_xml))
    INTO v_xml
    FROM dual;
  --
  ------------------------------------------------------------
  -- acrescenta o tipo de documento e converte para CLOB
  ------------------------------------------------------------
  SELECT v_xml_doc || v_xml.getclobval()
    INTO p_xml
    FROM dual;
  --
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   NULL;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
 END xml_gerar;
 --
 --
 PROCEDURE xml_ts_gerar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 06/09/2017
  -- DESCRICAO: Subrotina que gera o xml do TS_GRUPO para o historico.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_ts_grupo_id IN ts_grupo.ts_grupo_id%TYPE,
  p_xml         OUT CLOB,
  p_erro_cod    OUT VARCHAR2,
  p_erro_msg    OUT VARCHAR2
 ) IS
  v_qt        INTEGER;
  v_exception EXCEPTION;
  v_xml       xmltype;
  v_xml_aux1  xmltype;
  v_xml_aux99 xmltype;
  v_xml_doc   VARCHAR2(100);
  --
  CURSOR c_ap IS
   SELECT pe.nome
     FROM ts_aprovador ap,
          pessoa       pe
    WHERE ap.ts_grupo_id = p_ts_grupo_id
      AND ap.usuario_id = pe.usuario_id
    ORDER BY pe.nome;
  --
  CURSOR c_eq IS
   SELECT pe.nome
     FROM ts_equipe eq,
          pessoa    pe
    WHERE eq.ts_grupo_id = p_ts_grupo_id
      AND eq.usuario_id = pe.usuario_id
    ORDER BY pe.nome;
  --
 BEGIN
  v_qt      := 0;
  v_xml_doc := '<?xml version="1.0" encoding="ISO-8859-1" ?>';
  --
  ------------------------------------------------------------
  -- monta as informacoes gerais
  ------------------------------------------------------------
  SELECT xmlconcat(xmlelement("ts_grupo_id", gr.ts_grupo_id),
                   xmlelement("data_evento", data_hora_mostrar(SYSDATE)),
                   xmlelement("responsavel", pe.apelido),
                   xmlelement("data_criacao", data_hora_mostrar(gr.data_entrada)))
    INTO v_xml
    FROM ts_grupo gr,
         pessoa   pe
   WHERE gr.ts_grupo_id = p_ts_grupo_id
     AND gr.usuario_resp_id = pe.usuario_id;
  --
  ------------------------------------------------------------
  -- monta APROVADORES
  ------------------------------------------------------------
  v_xml_aux1 := NULL;
  FOR r_ap IN c_ap
  LOOP
   SELECT xmlconcat(xmlelement("nome", r_ap.nome))
     INTO v_xml_aux99
     FROM dual;
   --
   SELECT xmlconcat(v_xml_aux1, v_xml_aux99)
     INTO v_xml_aux1
     FROM dual;
  END LOOP;
  --
  SELECT xmlagg(xmlelement("aprovadores", v_xml_aux1))
    INTO v_xml_aux1
    FROM dual;
  --
  SELECT xmlconcat(v_xml, v_xml_aux1)
    INTO v_xml
    FROM dual;
  --
  ------------------------------------------------------------
  -- monta EQUIPE
  ------------------------------------------------------------
  v_xml_aux1 := NULL;
  FOR r_eq IN c_eq
  LOOP
   SELECT xmlconcat(xmlelement("nome", r_eq.nome))
     INTO v_xml_aux99
     FROM dual;
   --
   SELECT xmlconcat(v_xml_aux1, v_xml_aux99)
     INTO v_xml_aux1
     FROM dual;
  END LOOP;
  --
  SELECT xmlagg(xmlelement("equipe", v_xml_aux1))
    INTO v_xml_aux1
    FROM dual;
  --
  SELECT xmlconcat(v_xml, v_xml_aux1)
    INTO v_xml
    FROM dual;
  --
  ------------------------------------------------------------
  -- junta tudo debaixo de "ts_grupo"
  ------------------------------------------------------------
  SELECT xmlagg(xmlelement("ts_grupo", v_xml))
    INTO v_xml
    FROM dual;
  --
  ------------------------------------------------------------
  -- acrescenta o tipo de documento e converte para CLOB
  ------------------------------------------------------------
  SELECT v_xml_doc || v_xml.getclobval()
    INTO p_xml
    FROM dual;
  --
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   NULL;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
 END xml_ts_gerar;
 --
 --
 --
 FUNCTION numero_enderecamentos_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Joel        ProcessMind     DATA: 31/05/2007
  -- DESCRICAO: retorna o número de jobs EM PREPARACAO ou EM ANDAMENTO nos quais o
  --            usuário está endereçado
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_usuario_id IN usuario.usuario_id%TYPE,
  p_empresa_id IN empresa.empresa_id%TYPE
 ) RETURN INTEGER AS
  v_retorno   INTEGER;
  v_qt        INTEGER;
  v_exception EXCEPTION;
  --
 BEGIN
  v_retorno := 0;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM job_usuario e,
         job         j
   WHERE e.job_id = j.job_id
     AND j.empresa_id = p_empresa_id
     AND j.status IN ('ANDA', 'PREP')
     AND e.usuario_id = p_usuario_id;
  --
  v_retorno := v_qt;
  --
  RETURN v_retorno;
 EXCEPTION
  WHEN OTHERS THEN
   v_retorno := 0;
   RETURN v_retorno;
 END numero_enderecamentos_retornar;
 --
 --
 FUNCTION numero_os_executor_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 20/08/2008
  -- DESCRICAO: retorna o número OS que o usuario participa como executor.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_usuario_id IN usuario.usuario_id%TYPE,
  p_empresa_id IN empresa.empresa_id%TYPE
 ) RETURN INTEGER AS
  v_retorno   INTEGER;
  v_qt        INTEGER;
  v_exception EXCEPTION;
  --
 BEGIN
  v_retorno := 0;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM ordem_servico os,
         os_usuario    us,
         job           jo
   WHERE us.usuario_id = p_usuario_id
     AND us.ordem_servico_id = os.ordem_servico_id
     AND os.status NOT IN ('FINA', 'CANC')
     AND os.job_id = jo.job_id
     AND jo.empresa_id = p_empresa_id;
  --
  v_retorno := v_qt;
  --
  RETURN v_retorno;
 EXCEPTION
  WHEN OTHERS THEN
   v_retorno := 0;
   RETURN v_retorno;
 END numero_os_executor_retornar;
 --
 --
 FUNCTION preferencia_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 20/08/2009
  -- DESCRICAO: retorna a opcao de um determinado usuario com relacao a uma determinada
  --    preferencia.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Ana Luiza         15/03/2024  Adicionado parametro de empresa
  ------------------------------------------------------------------------------------------
  p_usuario_id IN usuario.usuario_id%TYPE,
  p_nome_pref  IN preferencia.nome%TYPE,
  p_empresa_id IN NUMBER
 ) RETURN CLOB AS
  v_retorno        CLOB;
  v_valor_padrao   preferencia.valor_padrao%TYPE;
  v_preferencia_id preferencia.preferencia_id%TYPE;
  v_qt             INTEGER;
  v_exception      EXCEPTION;
  --
  --
 BEGIN
  v_retorno := NULL;
  --
  SELECT valor_padrao,
         preferencia_id
    INTO v_valor_padrao,
         v_preferencia_id
    FROM preferencia
   WHERE nome = p_nome_pref;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM usuario_pref
   WHERE usuario_id = p_usuario_id
     AND preferencia_id = v_preferencia_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt > 0 THEN
   SELECT valor_usuario
     INTO v_retorno
     FROM usuario_pref
    WHERE usuario_id = p_usuario_id
      AND preferencia_id = v_preferencia_id
      AND empresa_id = p_empresa_id;
  END IF;
  --
  IF v_retorno IS NULL THEN
   v_retorno := v_valor_padrao;
  END IF;
  --
  RETURN v_retorno;
 EXCEPTION
  WHEN OTHERS THEN
   v_retorno := 'ERRO';
   RETURN v_retorno;
 END preferencia_retornar;
 --
 --
 FUNCTION empresa_padrao_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 13/04/2010
  -- DESCRICAO: retorna o id da empresa padrao de um determinado usuario.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_usuario_id IN usuario.usuario_id%TYPE
 ) RETURN NUMBER AS
  v_retorno   empresa.empresa_id%TYPE;
  v_qt        INTEGER;
  v_exception EXCEPTION;
  --
 BEGIN
  v_retorno := NULL;
  --
  SELECT MAX(empresa_id)
    INTO v_retorno
    FROM usuario_empresa
   WHERE usuario_id = p_usuario_id
     AND flag_padrao = 'S';
  --
  RETURN v_retorno;
 EXCEPTION
  WHEN OTHERS THEN
   v_retorno := NULL;
   RETURN v_retorno;
 END empresa_padrao_retornar;
 --
 --
 FUNCTION unid_negocio_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia       ProcessMind     DATA: 05/12/2018
  -- DESCRICAO: Retorna a unidade de negocio do usuario. Se o cliente_id/job_id forem
  --   passados, a preferencia eh pela unidade de negocio que bata com um deles.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            09/07/2020  Novo parametro job_id
  ------------------------------------------------------------------------------------------
  p_usuario_id IN usuario.usuario_id%TYPE,
  p_empresa_id IN empresa.empresa_id%TYPE,
  p_cliente_id IN pessoa.pessoa_id%TYPE,
  p_job_id     IN job.job_id%TYPE
 )
 --
  RETURN NUMBER AS
  v_unidade_negocio_id unidade_negocio.unidade_negocio_id%TYPE;
  v_exception          EXCEPTION;
  v_perc_rateio_max    unidade_negocio_usu.perc_rateio%TYPE;
  --
 BEGIN
  v_unidade_negocio_id := NULL;
  --
  IF nvl(p_job_id, 0) > 0 THEN
   SELECT MAX(us.unidade_negocio_id)
     INTO v_unidade_negocio_id
     FROM unidade_negocio_usu us,
          job                 jo
    WHERE jo.job_id = p_job_id
      AND jo.unidade_negocio_id = us.unidade_negocio_id
      AND us.usuario_id = p_usuario_id;
  END IF;
  --
  IF v_unidade_negocio_id IS NULL AND nvl(p_cliente_id, 0) > 0 THEN
   SELECT MAX(us.unidade_negocio_id)
     INTO v_unidade_negocio_id
     FROM unidade_negocio_usu us,
          unidade_negocio_cli cl
    WHERE us.usuario_id = p_usuario_id
      AND us.unidade_negocio_id = cl.unidade_negocio_id
      AND cl.cliente_id = p_cliente_id;
  END IF;
  --
  IF v_unidade_negocio_id IS NULL THEN
   SELECT nvl(MAX(us.perc_rateio), 0)
     INTO v_perc_rateio_max
     FROM unidade_negocio_usu us,
          unidade_negocio     un
    WHERE us.usuario_id = p_usuario_id
      AND us.unidade_negocio_id = un.unidade_negocio_id
      AND un.empresa_id = p_empresa_id;
   --
   SELECT MAX(us.unidade_negocio_id)
     INTO v_unidade_negocio_id
     FROM unidade_negocio_usu us,
          unidade_negocio     un
    WHERE us.usuario_id = p_usuario_id
      AND us.unidade_negocio_id = un.unidade_negocio_id
      AND un.empresa_id = p_empresa_id
      AND nvl(us.perc_rateio, 0) = v_perc_rateio_max;
  END IF;
  --
  RETURN v_unidade_negocio_id;
 EXCEPTION
  WHEN v_exception THEN
   v_unidade_negocio_id := NULL;
   RETURN v_unidade_negocio_id;
  WHEN OTHERS THEN
   v_unidade_negocio_id := NULL;
   RETURN v_unidade_negocio_id;
 END unid_negocio_retornar;
 --
--
END usuario_pkg;

/
