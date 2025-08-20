--------------------------------------------------------
--  DDL for Package Body IT_ADNNET_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "IT_ADNNET_PKG" IS
 --
 --
 PROCEDURE log_envio_gravar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 25/05/2007
  -- DESCRICAO: Subrotina que grava o log do XML (transacao autonoma, que faz commit mas
  --  nao interfere no processamento da transacao original).
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            20/06/2017  Novo parametro objeto_id
  ------------------------------------------------------------------------------------------
 (
  p_xml_log_id IN NUMBER,
  p_cod_objeto IN VARCHAR2,
  p_cod_acao   IN VARCHAR2,
  p_objeto_id  IN VARCHAR2,
  p_xml_in     IN CLOB
 ) IS
  PRAGMA AUTONOMOUS_TRANSACTION;
  --
 BEGIN
  --
  INSERT INTO xml_log
   (xml_log_id,
    data,
    texto_xml,
    retorno_xml,
    sistema_origem,
    sistema_destino,
    cod_objeto,
    cod_acao,
    objeto_id)
  VALUES
   (p_xml_log_id,
    SYSDATE,
    p_xml_in,
    'PENDENTE',
    'JOBONE',
    'ADNNET',
    p_cod_objeto,
    p_cod_acao,
    to_number(p_objeto_id));
  --
  COMMIT;
  --
 END log_envio_gravar;
 --
 --
 PROCEDURE log_chegada_gravar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 23/11/2016
  -- DESCRICAO: Subrotina que grava no log o XML recebido (transacao autonoma, que faz commit
  -- mas nao interfere no processamento da transacao original).
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_xml_log_id IN NUMBER,
  p_cod_objeto IN VARCHAR2,
  p_cod_acao   IN VARCHAR2,
  p_xml_in     IN CLOB
 ) IS
  PRAGMA AUTONOMOUS_TRANSACTION;
  --
 BEGIN
  --
  INSERT INTO xml_log
   (xml_log_id,
    data,
    texto_xml,
    retorno_xml,
    sistema_origem,
    sistema_destino,
    cod_objeto,
    cod_acao)
  VALUES
   (p_xml_log_id,
    SYSDATE,
    p_xml_in,
    'PENDENTE',
    'ADNNET',
    'JOBONE',
    p_cod_objeto,
    p_cod_acao);
  --
  COMMIT;
  --
 END log_chegada_gravar;
 --
 --
 PROCEDURE log_retorno_gravar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 25/05/2007
  -- DESCRICAO: Subrotina que grava no log o XML de retorno (transacao autonoma, que faz
  --  commit mas nao interfere no processamento da transacao original).
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_xml_log_id IN NUMBER,
  p_objeto_id  IN VARCHAR2,
  p_xml_out    IN CLOB
 ) IS
  PRAGMA AUTONOMOUS_TRANSACTION;
  --
 BEGIN
  --
  UPDATE xml_log
     SET retorno_xml = p_xml_out,
         objeto_id   = to_number(p_objeto_id)
   WHERE xml_log_id = p_xml_log_id;
  --
  COMMIT;
  --
 END log_retorno_gravar;
 --
 --
 PROCEDURE xml_cabecalho_gerar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 25/05/2007
  -- DESCRICAO: Subrotina que gera o xml padrao do cabecalho
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_sistema_externo_id IN sistema_externo.sistema_externo_id%TYPE,
  p_empresa_id         IN empresa.empresa_id%TYPE,
  p_cod_objeto         IN VARCHAR2,
  p_objeto_id          IN NUMBER,
  p_xml_cabecalho      OUT xmltype,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 ) IS
  v_qt              INTEGER;
  v_exception       EXCEPTION;
  v_cod_ext_empresa empresa_sist_ext.cod_ext_empresa%TYPE;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- monta o cabecalho padrao
  ------------------------------------------------------------
  SELECT MAX(cod_ext_empresa)
    INTO v_cod_ext_empresa
    FROM empresa_sist_ext
   WHERE empresa_id = p_empresa_id
     AND sistema_externo_id = p_sistema_externo_id;
  --
  IF v_cod_ext_empresa IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Código externo da empresa não definido.';
   RAISE v_exception;
  END IF;
  --
  SELECT xmlagg(xmlelement("cabecalho",
                           xmlelement("empresa", v_cod_ext_empresa),
                           xmlelement("sistema", 'JOBONE'),
                           xmlelement("processo", p_cod_objeto),
                           xmlelement("data", to_char(SYSDATE, 'yyyy-mm-dd hh24:mi:ss')),
                           xmlelement("identidade", TRIM(to_char(p_objeto_id)))))
    INTO p_xml_cabecalho
    FROM dual;
  --
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   p_erro_msg := 'IT_ADNNET_PKG(cabeçalho): ' || p_erro_msg;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := 'IT_ADNNET_PKG(cabeçalho): ' ||
                 substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 2000);
 END; -- xml_cabecalho_gerar
 --
 --
 --
 PROCEDURE job_integrar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 25/05/2007
  -- DESCRICAO: Subrotina que gera o xml e processa a integracao de jobs.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            25/08/2011  Nova tag p/ enviar tipo_job.
  -- Silvia            15/09/2016  Nao concatenar o nome do produto no nome do job (todas as
  --                               empresas, exceto BFerraz).
  -- Ana Luiza         31/05/2024  Tratamento para nao pegar codigo job do adn
  -- Ana Luiza         31/03/2025  Retirada de tratamento realizado dia 31/05/2024
  ------------------------------------------------------------------------------------------
 (
  p_sistema_externo_id IN sistema_externo.sistema_externo_id%TYPE,
  p_empresa_id         IN empresa.empresa_id%TYPE,
  p_job_id             IN job.job_id%TYPE,
  p_cod_acao           IN VARCHAR2,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 ) IS
  v_qt               INTEGER;
  v_exception        EXCEPTION;
  v_xml_doc          VARCHAR2(100);
  v_xml_cabecalho    xmltype;
  v_xml_conteudo     xmltype;
  v_xml_conteudo_aux xmltype;
  v_xml_mensagem     xmltype;
  v_xml_out          CLOB;
  v_xml_in           CLOB;
  v_num_job          job.numero%TYPE;
  v_nome_job_ori     job.nome%TYPE;
  v_nome_job         VARCHAR2(200);
  v_apelido          pessoa.apelido%TYPE;
  v_cod_obj_adnnet   VARCHAR2(20);
  v_cod_ext_tipo_job tipo_job.cod_ext_tipo_job%TYPE;
  v_cod_sist_ext     sistema_externo.codigo%TYPE;
  v_cod_ext_unid_neg unidade_negocio.cod_ext_unid_neg%TYPE;
  --
 BEGIN
  v_qt      := 0;
  v_xml_doc := '<?xml version="1.0" encoding="ISO-8859-1" ?>';
  --
  ------------------------------------------------------------
  -- consistencias
  ------------------------------------------------------------
  IF TRIM(p_cod_acao) IS NULL OR p_cod_acao NOT IN ('I', 'A', 'E', 'C')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Código da ação inválido.';
   RAISE v_exception;
  END IF;
  --
  SELECT jo.numero,
         pe.apelido,
         jo.nome,
         job_pkg.nome_retornar(jo.job_id),
         tj.cod_ext_tipo_job,
         un.cod_ext_unid_neg
    INTO v_num_job,
         v_apelido,
         v_nome_job_ori,
         v_nome_job,
         v_cod_ext_tipo_job,
         v_cod_ext_unid_neg
    FROM job             jo,
         pessoa          pe,
         tipo_job        tj,
         unidade_negocio un
   WHERE jo.job_id = p_job_id
     AND jo.cliente_id = pe.pessoa_id
     AND jo.tipo_job_id = tj.tipo_job_id
     AND jo.unidade_negocio_id = un.unidade_negocio_id(+);
  --
  SELECT codigo
    INTO v_cod_sist_ext
    FROM sistema_externo
   WHERE sistema_externo_id = p_sistema_externo_id;
  --
  IF v_cod_sist_ext NOT LIKE '%BFERRAZ%'
  THEN
   v_nome_job := v_nome_job_ori;
  END IF;
  --
  ------------------------------------------------------------
  -- monta a secao "cabecalho"
  ------------------------------------------------------------
  xml_cabecalho_gerar(p_sistema_externo_id,
                      p_empresa_id,
                      'JOB',
                      p_job_id,
                      v_xml_cabecalho,
                      p_erro_cod,
                      p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- monta a secao "conteudo"
  ------------------------------------------------------------
  SELECT xmlagg(xmlelement("root",
                           xmlelement("idjob", to_char(job_id)),
                           xmlelement("nojob", to_char(numero)),
                           xmlelement("dcjob", substr(v_nome_job, 1, 100)),
                           xmlelement("tpjob", v_cod_ext_tipo_job),
                           xmlelement("cdun", v_cod_ext_unid_neg),
                           xmlelement("cdcliente", to_char(cliente_id)),
                           xmlelement("nmcliente", v_apelido),
                           xmlelement("dtinicial", to_char(data_entrada, 'yyyy-mm-dd')),
                           xmlelement("dtfinal", NULL)))
    INTO v_xml_conteudo_aux
    FROM job
   WHERE job_id = p_job_id;
  --
  SELECT xmlagg(xmlelement("conteudo", v_xml_conteudo_aux))
    INTO v_xml_conteudo
    FROM dual;
  --
  ------------------------------------------------------------
  -- junta o cabecalho com o conteudo debaixo de "mensagem"
  ------------------------------------------------------------
  SELECT xmlagg(xmlelement("mensagem", v_xml_cabecalho, v_xml_conteudo))
    INTO v_xml_mensagem
    FROM dual;
  --
  -- acrescenta o tipo de documento
  SELECT v_xml_doc || v_xml_mensagem.getclobval()
    INTO v_xml_in
    FROM dual;
  --
  ------------------------------------------------------------
  -- chama a procedure de integracao
  ------------------------------------------------------------
  adnnet_executar(p_sistema_externo_id,
                  p_empresa_id,
                  'JOB',
                  p_cod_acao,
                  p_job_id,
                  v_xml_in,
                  v_xml_out,
                  p_erro_cod,
                  p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  SELECT codigo
    INTO v_cod_sist_ext
    FROM sistema_externo
   WHERE sistema_externo_id = p_sistema_externo_id;
  IF p_cod_acao <> 'E'
  THEN
   /* --ALCBO_310524 Tratamento para nao alterar codigo job
   IF v_cod_sist_ext NOT LIKE '%REDDOOR%' THEN*/
   -- recupera o codigo adn net do job
   SELECT MAX(extractvalue(xml_out, '/mensagem/conteudo/root/cdjob_adn'))
     INTO v_cod_obj_adnnet
     FROM (SELECT xmltype(v_xml_out) AS xml_out
             FROM dual);
   --
   IF v_cod_obj_adnnet IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Erro na recuperação do código ADN Net do job.';
    RAISE v_exception;
   END IF;
   --
   UPDATE job
      SET cod_ext_job = v_cod_obj_adnnet
    WHERE job_id = p_job_id;
   --END IF;
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
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 2000);
 END job_integrar;
 --
 --
 --
 PROCEDURE contrato_integrar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 27/06/2023
  -- DESCRICAO: Subrotina que gera o xml e processa a integracao de contratos,
  --  usando o mesmo mdelo de XML e servico de integracao de JOB.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_sistema_externo_id IN sistema_externo.sistema_externo_id%TYPE,
  p_empresa_id         IN empresa.empresa_id%TYPE,
  p_contrato_id        IN contrato.contrato_id%TYPE,
  p_cod_acao           IN VARCHAR2,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 ) IS
  v_qt               INTEGER;
  v_exception        EXCEPTION;
  v_xml_doc          VARCHAR2(100);
  v_xml_cabecalho    xmltype;
  v_xml_conteudo     xmltype;
  v_xml_conteudo_aux xmltype;
  v_xml_mensagem     xmltype;
  v_xml_out          CLOB;
  v_xml_in           CLOB;
  v_num_ctr          VARCHAR2(50);
  v_nome_ctr         contrato.nome%TYPE;
  v_nome_job         VARCHAR2(200);
  v_apelido          pessoa.apelido%TYPE;
  v_cod_obj_adnnet   VARCHAR2(20);
  v_cod_ext_tipo_ctr tipo_contrato.cod_ext_tipo%TYPE;
  v_cod_sist_ext     sistema_externo.codigo%TYPE;
  v_cod_ext_unid_neg unidade_negocio.cod_ext_unid_neg%TYPE;
  --
 BEGIN
  v_qt      := 0;
  v_xml_doc := '<?xml version="1.0" encoding="ISO-8859-1" ?>';
  --
  ------------------------------------------------------------
  -- consistencias
  ------------------------------------------------------------
  IF TRIM(p_cod_acao) IS NULL OR p_cod_acao NOT IN ('I', 'A', 'E')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Código da ação inválido.';
   RAISE v_exception;
  END IF;
  --
  SELECT numero,
         pe.apelido,
         ct.nome,
         tc.cod_ext_tipo
    INTO v_num_ctr,
         v_apelido,
         v_nome_ctr,
         v_cod_ext_tipo_ctr
    FROM contrato      ct,
         pessoa        pe,
         tipo_contrato tc
   WHERE ct.contrato_id = p_contrato_id
     AND ct.contratante_id = pe.pessoa_id
     AND ct.tipo_contrato_id = tc.tipo_contrato_id;
  --
  SELECT codigo
    INTO v_cod_sist_ext
    FROM sistema_externo
   WHERE sistema_externo_id = p_sistema_externo_id;
  --
  v_cod_ext_unid_neg := '99';
  --
  ------------------------------------------------------------
  -- monta a secao "cabecalho"
  ------------------------------------------------------------
  -- manda o contrato_id negativo para diferenciar de job
  xml_cabecalho_gerar(p_sistema_externo_id,
                      p_empresa_id,
                      'JOB',
                      -p_contrato_id,
                      v_xml_cabecalho,
                      p_erro_cod,
                      p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  -- soma 5000000 no nro do contrato para diferenciar do
  -- nro do job. Para diferenciar o idjob, foi usado o sinal
  -- negativo.
  v_num_ctr := v_num_ctr + 5000000;
  --
  ------------------------------------------------------------
  -- monta a secao "conteudo"
  ------------------------------------------------------------
  SELECT xmlagg(xmlelement("root",
                           xmlelement("idjob", to_char(-contrato_id)),
                           xmlelement("nojob", to_char(v_num_ctr)),
                           xmlelement("dcjob", substr(v_nome_ctr, 1, 100)),
                           xmlelement("tpjob", v_cod_ext_tipo_ctr),
                           xmlelement("cdun", v_cod_ext_unid_neg),
                           xmlelement("cdcliente", to_char(contratante_id)),
                           xmlelement("nmcliente", v_apelido),
                           xmlelement("dtinicial", to_char(data_entrada, 'yyyy-mm-dd')),
                           xmlelement("dtfinal", NULL)))
    INTO v_xml_conteudo_aux
    FROM contrato
   WHERE contrato_id = p_contrato_id;
  --
  SELECT xmlagg(xmlelement("conteudo", v_xml_conteudo_aux))
    INTO v_xml_conteudo
    FROM dual;
  --
  ------------------------------------------------------------
  -- junta o cabecalho com o conteudo debaixo de "mensagem"
  ------------------------------------------------------------
  SELECT xmlagg(xmlelement("mensagem", v_xml_cabecalho, v_xml_conteudo))
    INTO v_xml_mensagem
    FROM dual;
  --
  -- acrescenta o tipo de documento
  SELECT v_xml_doc || v_xml_mensagem.getclobval()
    INTO v_xml_in
    FROM dual;
  --
  ------------------------------------------------------------
  -- chama a procedure de integracao
  ------------------------------------------------------------
  adnnet_executar(p_sistema_externo_id,
                  p_empresa_id,
                  'CONTRATO',
                  p_cod_acao,
                  p_contrato_id,
                  v_xml_in,
                  v_xml_out,
                  p_erro_cod,
                  p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  IF p_cod_acao <> 'E'
  THEN
   -- recupera o codigo adn net do job
   SELECT MAX(extractvalue(xml_out, '/mensagem/conteudo/root/cdjob_adn'))
     INTO v_cod_obj_adnnet
     FROM (SELECT xmltype(v_xml_out) AS xml_out
             FROM dual);
   --
   IF v_cod_obj_adnnet IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Erro na recuperação do código ADN Net do job.';
    RAISE v_exception;
   END IF;
   --
   UPDATE contrato
      SET cod_ext_contrato = v_cod_obj_adnnet
    WHERE contrato_id = p_contrato_id;
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
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 2000);
 END contrato_integrar;
 --
 --
 --
 PROCEDURE orcamento_integrar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 20/02/2020
  -- DESCRICAO: Subrotina que gera o xml de envio e executa a integracao de ORCAMENTO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_sistema_externo_id IN sistema_externo.sistema_externo_id%TYPE,
  p_empresa_id         IN empresa.empresa_id%TYPE,
  p_orcamento_id       IN orcamento.orcamento_id%TYPE,
  p_cod_acao           IN VARCHAR2,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 ) IS
  v_qt               INTEGER;
  v_exception        EXCEPTION;
  v_saida            EXCEPTION;
  v_xml_doc          VARCHAR2(100);
  v_xml_cabecalho    xmltype;
  v_xml_conteudo     xmltype;
  v_xml_conteudo_aux xmltype;
  v_xml_mensagem     xmltype;
  v_xml_out          CLOB;
  v_xml_in           CLOB;
  v_job_id           job.job_id%TYPE;
  v_num_job          job.numero%TYPE;
  v_cod_ext_job      job.cod_ext_job%TYPE;
  v_cod_ext_orcam    orcamento.cod_ext_orcam%TYPE;
  v_cod_ext_unid_neg unidade_negocio.cod_ext_unid_neg%TYPE;
  v_cod_obj_adnnet   VARCHAR2(20);
  --
 BEGIN
  v_qt      := 0;
  v_xml_doc := '<?xml version="1.0" encoding="ISO-8859-1" ?>';
  ------------------------------------------------------------
  -- consistencias
  ------------------------------------------------------------
  IF TRIM(p_cod_acao) IS NULL OR p_cod_acao NOT IN ('I', 'A', 'E')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Código da ação inválido.';
   RAISE v_exception;
  END IF;
  --
  SELECT jo.job_id,
         jo.numero,
         jo.cod_ext_job,
         un.cod_ext_unid_neg
    INTO v_job_id,
         v_num_job,
         v_cod_ext_job,
         v_cod_ext_unid_neg
    FROM job             jo,
         orcamento       oc,
         unidade_negocio un
   WHERE oc.orcamento_id = p_orcamento_id
     AND oc.job_id = jo.job_id
     AND jo.unidade_negocio_id = un.unidade_negocio_id(+);
  --
  IF v_cod_ext_job IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse job ainda não está integrado (' || to_char(v_num_job) || ').';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- monta a secao "cabecalho"
  ------------------------------------------------------------
  xml_cabecalho_gerar(p_sistema_externo_id,
                      p_empresa_id,
                      'ESTIMATIVA',
                      p_orcamento_id,
                      v_xml_cabecalho,
                      p_erro_cod,
                      p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- monta a secao "conteudo"
  ------------------------------------------------------------
  SELECT xmlagg(xmlelement("root",
                           xmlelement("nojob", to_char(v_num_job)),
                           xmlelement("noestimativa", to_char(num_orcamento)),
                           xmlelement("dcestimativa", substr(descricao, 1, 100)),
                           xmlelement("cdun", v_cod_ext_unid_neg)))
    INTO v_xml_conteudo_aux
    FROM orcamento
   WHERE orcamento_id = p_orcamento_id;
  --
  SELECT xmlagg(xmlelement("conteudo", v_xml_conteudo_aux))
    INTO v_xml_conteudo
    FROM dual;
  --
  ------------------------------------------------------------
  -- junta o cabecalho com o conteudo debaixo de "mensagem"
  ------------------------------------------------------------
  SELECT xmlagg(xmlelement("mensagem", v_xml_cabecalho, v_xml_conteudo))
    INTO v_xml_mensagem
    FROM dual;
  --
  -- acrescenta o tipo de documento
  SELECT v_xml_doc || v_xml_mensagem.getclobval()
    INTO v_xml_in
    FROM dual;
  --
  ------------------------------------------------------------
  -- chama a procedure de integracao
  ------------------------------------------------------------
  adnnet_executar(p_sistema_externo_id,
                  p_empresa_id,
                  'ORCAMENTO',
                  p_cod_acao,
                  p_orcamento_id,
                  v_xml_in,
                  v_xml_out,
                  p_erro_cod,
                  p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  IF p_cod_acao <> 'E'
  THEN
   -- recupera o codigo adn net do job
   SELECT MAX(extractvalue(xml_out, '/mensagem/conteudo/root/cdestimativa_adn'))
     INTO v_cod_obj_adnnet
     FROM (SELECT xmltype(v_xml_out) AS xml_out
             FROM dual);
   --
   IF v_cod_obj_adnnet IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Erro na recuperação do código ADN Net da Estimativa.';
    RAISE v_exception;
   END IF;
   --
   UPDATE orcamento
      SET cod_ext_orcam = v_cod_obj_adnnet
    WHERE orcamento_id = p_orcamento_id;
  END IF;
  --
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_saida THEN
   p_erro_cod := '00000';
   p_erro_msg := 'Operação realizada com sucesso.';
  WHEN v_exception THEN
   NULL;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 500);
 END orcamento_integrar;
 --
 --
 --
 PROCEDURE pessoa_integrar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 25/05/2007
  -- DESCRICAO: Subrotina que gera o xml e processa a integracao de pessoas do
  --  tipo cliente/fornecedor.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            20/06/2017  Tabela de pais
  -- Rafael            24/07/2025  inclusão da chave pix no xml
  ------------------------------------------------------------------------------------------
 (
  p_sistema_externo_id IN sistema_externo.sistema_externo_id%TYPE,
  p_empresa_id         IN empresa.empresa_id%TYPE,
  p_pessoa_id          IN pessoa.pessoa_id%TYPE,
  p_cod_acao           IN VARCHAR2,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 ) IS
  v_qt               INTEGER;
  v_exception        EXCEPTION;
  v_xml_doc          VARCHAR2(100);
  v_xml_cabecalho    xmltype;
  v_xml_conteudo     xmltype;
  v_xml_conteudo_aux xmltype;
  v_xml_mensagem     xmltype;
  v_xml_out          CLOB;
  v_xml_in           CLOB;
  v_tipo_pessoa_adn  CHAR(1);
  v_flag_pessoa_jur  pessoa.flag_pessoa_jur%TYPE;
  v_cidade           pessoa.cidade%TYPE;
  v_cod_banco        fi_banco.codigo%TYPE;
  v_cod_tipo_pessoa  tipo_pessoa.codigo%TYPE;
  v_contato_fatur_id pessoa.pessoa_id%TYPE;
  v_endereco_cob     pessoa.endereco%TYPE;
  v_num_ender_cob    pessoa.num_ender%TYPE;
  v_compl_ender_cob  pessoa.compl_ender%TYPE;
  v_cep_cob          pessoa.cep%TYPE;
  v_bairro_cob       pessoa.bairro%TYPE;
  v_cidade_cob       pessoa.cidade%TYPE;
  v_uf_cob           pessoa.uf%TYPE;
  v_pais_cob         pessoa.pais%TYPE;
  v_pais             pessoa.pais%TYPE;
  v_pais_cob_sigla   VARCHAR2(10);
  v_pais_sigla       VARCHAR2(10);
  v_ddd_telefone_cob pessoa.ddd_telefone%TYPE;
  v_num_telefone_cob pessoa.num_telefone%TYPE;
  --v_num_fax_cob         pessoa.num_fax%TYPE;
  v_pessoa_nome         pessoa.nome%TYPE;
  v_pessoa_apelido      pessoa.apelido%TYPE;
  v_tipo_conta          pessoa.tipo_conta%TYPE;
  v_flag_fornec_interno pessoa.flag_fornec_interno%TYPE;
  v_cod_obj_adnnet      VARCHAR2(20);
  v_flag_cliente        CHAR(1);
  v_flag_fornec         CHAR(1);
  v_tipo_pessoa_cli_id  tipo_pessoa.tipo_pessoa_id%TYPE;
  v_tipo_pessoa_for_id  tipo_pessoa.tipo_pessoa_id%TYPE;
  v_cod_sist_ext        sistema_externo.codigo%TYPE;
  --
 BEGIN
  v_qt      := 0;
  v_xml_doc := '<?xml version="1.0" encoding="ISO-8859-1" ?>';
  --
  SELECT codigo
    INTO v_cod_sist_ext
    FROM sistema_externo
   WHERE sistema_externo_id = p_sistema_externo_id;
  --
  ------------------------------------------------------------
  -- consistencias
  ------------------------------------------------------------
  IF TRIM(p_cod_acao) IS NULL OR p_cod_acao NOT IN ('I', 'A', 'E', 'C')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Código da ação inválido.';
   RAISE v_exception;
  END IF;
  --
  SELECT pe.flag_pessoa_jur,
         pe.cidade,
         ba.codigo,
         pe.tipo_conta,
         pe.flag_fornec_interno,
         pe.nome,
         pe.apelido,
         pe.pais
    INTO v_flag_pessoa_jur,
         v_cidade,
         v_cod_banco,
         v_tipo_conta,
         v_flag_fornec_interno,
         v_pessoa_nome,
         v_pessoa_apelido,
         v_pais
    FROM pessoa   pe,
         fi_banco ba
   WHERE pe.pessoa_id = p_pessoa_id
     AND pe.fi_banco_id = ba.fi_banco_id(+);
  --
  SELECT tipo_pessoa_id
    INTO v_tipo_pessoa_cli_id
    FROM tipo_pessoa
   WHERE codigo = 'CLIENTE';
  --
  SELECT tipo_pessoa_id
    INTO v_tipo_pessoa_for_id
    FROM tipo_pessoa
   WHERE codigo = 'FORNECEDOR';
  --
  v_cidade := util_pkg.acento_municipio_retirar(v_cidade);
  v_cidade := char_especial_retirar(v_cidade);
  --
  v_pessoa_nome    := char_especial_retirar(v_pessoa_nome);
  v_pessoa_apelido := char_especial_retirar(v_pessoa_apelido);
  --
  IF v_cod_banco IS NULL
  THEN
   v_tipo_conta := NULL;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM tipific_pessoa tf,
         tipo_pessoa    tp
   WHERE tf.pessoa_id = p_pessoa_id
     AND tf.tipo_pessoa_id = tp.tipo_pessoa_id
     AND tp.codigo = 'ESTRANGEIRO';
  --
  IF v_qt > 0
  THEN
   -- alterado em 17/05/2017 a pedido da ADN (SRCOM)
   v_tipo_pessoa_adn := 'E';
   /*
   IF v_flag_pessoa_jur = 'S' THEN
      -- pessoa juridica no estrangeiro
      v_tipo_pessoa_adn := 'E';
   ELSE
      -- pessoa fisica no estrangeiro
      v_tipo_pessoa_adn := 'T';
   END IF;*/
  ELSE
   SELECT MAX(tp.codigo)
     INTO v_cod_tipo_pessoa
     FROM tipific_pessoa tf,
          tipo_pessoa    tp
    WHERE tf.pessoa_id = p_pessoa_id
      AND tf.tipo_pessoa_id = tp.tipo_pessoa_id
      AND tp.codigo LIKE 'ORG_PUB%';
   --
   IF v_cod_tipo_pessoa IS NOT NULL
   THEN
    IF v_cod_tipo_pessoa = 'ORG_PUB_MUN'
    THEN
     v_tipo_pessoa_adn := 'M';
    ELSIF v_cod_tipo_pessoa = 'ORG_PUB_EST'
    THEN
     v_tipo_pessoa_adn := 'S';
    ELSIF v_cod_tipo_pessoa = 'ORG_PUB_FED'
    THEN
     v_tipo_pessoa_adn := 'P';
    END IF;
   ELSE
    IF v_flag_fornec_interno = 'S'
    THEN
     v_tipo_pessoa_adn := 'N';
    ELSE
     IF v_flag_pessoa_jur = 'S'
     THEN
      v_tipo_pessoa_adn := 'J';
     ELSE
      v_tipo_pessoa_adn := 'F';
     END IF;
    END IF;
   END IF;
  END IF;
  --
  v_flag_cliente := 'N';
  v_flag_fornec  := 'N';
  --
  IF pessoa_pkg.tipo_verificar(p_pessoa_id, 'CLIENTE') = 1
  THEN
   v_flag_cliente := 'S';
  END IF;
  --
  IF pessoa_pkg.tipo_verificar(p_pessoa_id, 'FORNECEDOR') = 1
  THEN
   v_flag_fornec := 'S';
  END IF;
  --
  -- verifica se a empresa tem contato de faturamento p/
  -- enviar o endereco de cobranca.
  SELECT MAX(pessoa_filho_id)
    INTO v_contato_fatur_id
    FROM relacao        re,
         tipific_pessoa ti,
         tipo_pessoa    tp
   WHERE re.pessoa_pai_id = p_pessoa_id
     AND re.pessoa_filho_id = ti.pessoa_id
     AND ti.tipo_pessoa_id = tp.tipo_pessoa_id
     AND tp.codigo = 'CONTATO_FATUR';
  --
  IF v_contato_fatur_id IS NOT NULL
  THEN
   SELECT endereco,
          num_ender,
          compl_ender,
          cep,
          bairro,
          cidade,
          uf,
          pais,
          ddd_telefone,
          num_telefone
   --num_fax
     INTO v_endereco_cob,
          v_num_ender_cob,
          v_compl_ender_cob,
          v_cep_cob,
          v_bairro_cob,
          v_cidade_cob,
          v_uf_cob,
          v_pais_cob,
          v_ddd_telefone_cob,
          v_num_telefone_cob
   --v_num_fax_cob
     FROM pessoa
    WHERE pessoa_id = v_contato_fatur_id;
   --
   v_cidade_cob := util_pkg.acento_municipio_retirar(v_cidade_cob);
  END IF;
  --
  IF v_pais IS NULL
  THEN
   v_pais_sigla := 'BRA';
  ELSE
   SELECT MAX(codigo)
     INTO v_pais_sigla
     FROM pais
    WHERE upper(acento_retirar(v_pais)) = upper(acento_retirar(nome));
  END IF;
  --
  IF v_pais_cob IS NULL
  THEN
   v_pais_cob_sigla := 'BRA';
  ELSE
   SELECT MAX(codigo)
     INTO v_pais_cob_sigla
     FROM pais
    WHERE upper(acento_retirar(v_pais_cob)) = upper(acento_retirar(nome));
  END IF;
  --
  ------------------------------------------------------------
  -- monta a secao "cabecalho"
  ------------------------------------------------------------
  xml_cabecalho_gerar(p_sistema_externo_id,
                      p_empresa_id,
                      'PESSOA',
                      p_pessoa_id,
                      v_xml_cabecalho,
                      p_erro_cod,
                      p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- monta a secao "conteudo"
  ------------------------------------------------------------
  SELECT xmlagg(xmlelement("root",
                           xmlelement("cdpessoa", TRIM(to_char(p_pessoa_id))),
                           xmlelement("tppessoa", v_tipo_pessoa_adn),
                           xmlelement("flcliente", v_flag_cliente),
                           xmlelement("flfornec", v_flag_fornec),
                           xmlelement("nmfantasia", v_pessoa_apelido),
                           xmlelement("dcrazao_social", v_pessoa_nome),
                           xmlelement("nocnpj_cpf", decode(flag_pessoa_jur, 'S', cnpj, 'N', cpf)),
                           xmlelement("noinsc_estadual", char_especial_retirar(inscr_estadual)),
                           xmlelement("noinsc_municipal", char_especial_retirar(inscr_municipal)),
                           xmlelement("noinsc_inss", char_especial_retirar(inscr_inss)),
                           xmlelement("dcendereco", char_especial_retirar(endereco)),
                           xmlelement("noendereco", char_especial_retirar(num_ender)),
                           xmlelement("dcend_compl", char_especial_retirar(compl_ender)),
                           xmlelement("nocep", char_especial_retirar(cep)),
                           xmlelement("nmbairro", char_especial_retirar(bairro)),
                           xmlelement("nmmunicipio", v_cidade),
                           xmlelement("sguf", uf),
                           xmlelement("sgpais", v_pais_sigla),
                           xmlelement("nodddddi", char_especial_retirar(ddd_telefone)),
                           xmlelement("notelefone1", char_especial_retirar(num_telefone)),
                           --xmlelement("nofax", char_especial_retirar(num_fax)),
                           xmlelement("dcendereco_cob", char_especial_retirar(v_endereco_cob)),
                           xmlelement("noendereco_cob", char_especial_retirar(v_num_ender_cob)),
                           xmlelement("dcend_compl_cob", char_especial_retirar(v_compl_ender_cob)),
                           xmlelement("nocep_cob", char_especial_retirar(v_cep_cob)),
                           xmlelement("nmbairro_cob", char_especial_retirar(v_bairro_cob)),
                           xmlelement("nmmunicipio_cob", char_especial_retirar(v_cidade_cob)),
                           xmlelement("sguf_cob", v_uf_cob),
                           xmlelement("sgpais_cob", v_pais_cob_sigla),
                           xmlelement("nodddddi_cob", char_especial_retirar(v_ddd_telefone_cob)),
                           xmlelement("notelefone1_cob", char_especial_retirar(v_num_telefone_cob)),
                           --xmlelement("nofax_cob", char_especial_retirar(v_num_fax_cob)),
                           xmlelement("nmcontato", NULL),
                           xmlelement("dcemail", NULL),
                           xmlelement("cdmeio_pagto", NULL),
                           xmlelement("cdbanco", v_cod_banco),
                           xmlelement("noagencia", char_especial_retirar(num_agencia)),
                           xmlelement("nocta_corrente", char_especial_retirar(num_conta)),
                           xmlelement("tpcta_corrente", v_tipo_conta),
                           CASE
                            WHEN v_cod_sist_ext LIKE '%INHA%' THEN
                             xmlelement("chpix", chave_pix) --RP_24/07/2025
                            ELSE
                             NULL
                           END,
                           xmlelement("nmfavorecido", char_especial_retirar(nome_titular)),
                           xmlelement("nocnpj_cpf_favorecido",
                                      char_especial_retirar(cnpj_cpf_titular)),
                           xmlelement("cg_ativo", flag_ativo),
                           xmlelement("cg_ativo_motivo", NULL)))
    INTO v_xml_conteudo_aux
    FROM pessoa
   WHERE pessoa_id = p_pessoa_id;
  --
  SELECT xmlagg(xmlelement("conteudo", v_xml_conteudo_aux))
    INTO v_xml_conteudo
    FROM dual;
  --
  ------------------------------------------------------------
  -- junta o cabecalho com o conteudo debaixo de "mensagem"
  ------------------------------------------------------------
  SELECT xmlagg(xmlelement("mensagem", v_xml_cabecalho, v_xml_conteudo))
    INTO v_xml_mensagem
    FROM dual;
  --
  -- acrescenta o tipo de documento
  SELECT v_xml_doc || v_xml_mensagem.getclobval()
    INTO v_xml_in
    FROM dual;
  --
  ------------------------------------------------------------
  -- chama a procedure de integracao
  ------------------------------------------------------------
  adnnet_executar(p_sistema_externo_id,
                  p_empresa_id,
                  'PESSOA',
                  p_cod_acao,
                  p_pessoa_id,
                  v_xml_in,
                  v_xml_out,
                  p_erro_cod,
                  p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  DELETE FROM pessoa_sist_ext
   WHERE pessoa_id = p_pessoa_id
     AND sistema_externo_id = p_sistema_externo_id;
  --
  IF p_cod_acao <> 'E'
  THEN
   -- recupera o codigo adn net da pessoa
   SELECT MAX(extractvalue(xml_out, '/mensagem/conteudo/root/cdpessoa_adn'))
     INTO v_cod_obj_adnnet
     FROM (SELECT xmltype(v_xml_out) AS xml_out
             FROM dual);
   --
   IF v_cod_obj_adnnet IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Erro na recuperação do código ADN Net da pessoa.';
    RAISE v_exception;
   END IF;
   --
   IF v_flag_cliente = 'S'
   THEN
    INSERT INTO pessoa_sist_ext
     (sistema_externo_id,
      pessoa_id,
      tipo_pessoa_id,
      cod_ext_pessoa)
    VALUES
     (p_sistema_externo_id,
      p_pessoa_id,
      v_tipo_pessoa_cli_id,
      v_cod_obj_adnnet);
   END IF;
   --
   IF v_flag_fornec = 'S'
   THEN
    INSERT INTO pessoa_sist_ext
     (sistema_externo_id,
      pessoa_id,
      tipo_pessoa_id,
      cod_ext_pessoa)
    VALUES
     (p_sistema_externo_id,
      p_pessoa_id,
      v_tipo_pessoa_for_id,
      v_cod_obj_adnnet);
   END IF;
  END IF; -- fim do IF p_cod_acao <> 'E'
  --
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   NULL;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 2000);
 END pessoa_integrar;
 --
 --
 --
 PROCEDURE nf_entrada_integrar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 25/05/2007
  -- DESCRICAO: Subrotina que gera o xml e processa a integracao de notas fiscais de
  --  entrada.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            27/02/2008  Geracao de duplicata com BV a abater (nao envia valor 0)
  -- Silvia            23/05/2008  Novo tipo de doc "NFL" (nota fiscal de locacao).
  -- Silvia            14/08/2008  Envia o cliente para itens de B e C patrocinados.
  -- Silvia            23/01/2009  Consistencia de BV/TIP a ser pago (o valor liq da
  --                               duplicata tem que ser suficiente).
  -- Silvia            26/04/2010  O local da prestacao de servico passou a vir da NF.
  -- Silvia            18/01/2011  Novo atributo tipo_fatur_bv na NF.
  -- Silvia            27/04/2011  Tratamento para envio da conta gerencial.
  -- Silvia            17/11/2011  Novos tipos de doc que nao tomam credito (NFF e RD)
  -- Silvia            05/08/2016  Parametro que habilita ou nao calculo do imposto.
  -- Silvia            15/09/2016  Nao concatenar o nome do produto no nome do job (todas
  --                               as empresas, exceto BF). Mudancas nas contas gerenciais.
  -- Silvia            23/03/2018  Ajuste para aceitar job_id NULL na NF.
  -- Silvia            11/03/2020  Novas tags para Bullet (noestimativa, vlbv).
  -- Silvia            24/04/2020  Na Bullet, manda o cliente para itens de B.
  -- Silvia            22/05/2020  Na Bullet e demais, manda o rateio.
  -- Silvia            29/12/2022  Nao manda rateio para a PROS.
  -- Joel Dias         19/09/2023  Inclusão de código de integração antigo na tag <cditem>
  --                               extraído do campo OBS do item quando preenchido
  -- Joel Dias         19/09/2023  incluída a tag flfat_pelo_pedido com o valor fixo S
  -- Ana Luiza         06/02/2024  Ajuste do faturamento
  -- Ana Luiza         16/05/2024  Adicionado condicao especial para Reddoor.
  -- Ana Luiza         17/05/2024  Enviando modo de pgto nulo para ADN fazer de/para REDDOOR
  -- Ana Luiza         11/07/2024  Enviando modo de pgto nulo para ADN fazer de/para VITRIO
  -- Ana Luiza         20/08/2024  Atrelar documento a contas contabeis PROS
  -- Ana Luiza         23/05/2024  Classificacao de produto REDDOOR
  -- Ana Luiza         21/06/2024  Altercao para enviar num job ao inves de num orcamento
  -- Ana Luiza         01/08/2024  So envia idnf_repasse se tiver no campo obs do item,
  --                               se nao, vai vazio
  -- Ana Luiza         01/10/2024  Adicao de tag nova para arquivo externo
  -- Ana Luiza         06/11/2024  Nova natureza de operacao para PROS
  -- Ana Luiza         30/12/2024  Tratamento para não enviar item ou valor de rateio zerados
  -- Ana Luiza         02/01/2025  Adicionado nova condicao para INHAUS sem BV
  -- Ana Luiza         13/01/2025  Adicionando condicoes para novas naturezas de operacao Inhaus
  -- Ana Luiza         12/02/2025  Armazenar conta especifica de acordo com parametro Inhaus
  -- Ana Luiza         19/02/2025  Enviando modo_pgto nulo para Inhaus
  -- Ana Luiza         20/02/2025  Resstruturacao de naturezas de operacao para ficarem em uma
  --                               condição apenas para melhorar a manutenção
  -- Ana Luiza         28/02/2025  Alteracao para mudar modo_pagto apenas na camada de integracao
  -- Ana Luiza         09/04/2025  Alterado para pegar classe_produto_id da categoria do produto
  -- Rafael            02/06/2025  Alterado para que na INHAUS a tag tpitem o ADN consiga distinguir o que é nota de Produto ou Servico
  -- Rafael            24/07/2025  inclusão da chave pix no xml
  -- Ana Luiza         04/08/2025  Ajuste para pegar modo_pagto Inhaus
  -- Ana Luiza         18/08/2025  Guarda o modo_pagto em codigo antes da conversao em numero 
  --                               (de/para ADNNET) para testar na montagem da tag chpix 
  ------------------------------------------------------------------------------------------
 (
  p_sistema_externo_id IN sistema_externo.sistema_externo_id%TYPE,
  p_empresa_id         IN empresa.empresa_id%TYPE,
  p_nota_fiscal_id     IN nota_fiscal.nota_fiscal_id%TYPE,
  p_cod_acao           IN VARCHAR2,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 ) IS
  v_qt                      INTEGER;
  v_exception               EXCEPTION;
  v_saida                   EXCEPTION;
  v_xml_doc                 VARCHAR2(100);
  v_xml_cabecalho           xmltype;
  v_xml_conteudo            xmltype;
  v_xml_conteudo_header     xmltype;
  v_xml_conteudo_itens      xmltype;
  v_xml_conteudo_itens_aux  xmltype;
  v_xml_conteudo_impos      xmltype;
  v_xml_conteudo_dupli      xmltype;
  v_xml_conteudo_dupli_aux1 xmltype;
  v_xml_conteudo_dupli_aux2 xmltype;
  v_xml_mensagem            xmltype;
  v_xml_conteudo_rat        xmltype;
  v_xml_conteudo_rat_aux1   xmltype;
  v_xml_out                 CLOB;
  v_xml_in                  CLOB;
  v_emp_emissora_id         pessoa.pessoa_id%TYPE;
  v_cidade                  pessoa.cidade%TYPE;
  v_uf                      pessoa.uf%TYPE;
  v_tipo_conta              pessoa.tipo_conta%TYPE;
  v_flag_pessoa_jur         pessoa.flag_pessoa_jur%TYPE;
  v_cod_banco_fornec        fi_banco.codigo%TYPE;
  v_cod_banco_cobrador      fi_banco.codigo%TYPE;
  v_tipo_item               item.tipo_item%TYPE;
  v_item_id                 item.item_id%TYPE;
  v_valor_tot_itens         NUMBER;
  v_num_job                 job.numero%TYPE;
  v_nome_job_ori            job.nome%TYPE;
  v_job_id                  job.job_id%TYPE;
  v_nome_job                VARCHAR2(200);
  v_valor_mao_obra          nota_fiscal.valor_mao_obra%TYPE;
  v_valor_bruto             nota_fiscal.valor_bruto%TYPE;
  v_desc_servico            nota_fiscal.desc_servico%TYPE;
  v_cliente_id              nota_fiscal.cliente_id%TYPE;
  v_flag_item_patrocinado   nota_fiscal.flag_item_patrocinado%TYPE;
  v_flag_pago_cliente       nota_fiscal.flag_pago_cliente%TYPE;
  v_emp_faturar_por_id      nota_fiscal.emp_faturar_por_id%TYPE;
  v_flag_toma_credito       tipo_doc_nf.flag_toma_credito%TYPE;
  v_cod_ext_fatur           empr_fatur_sist_ext.cod_ext_fatur%TYPE;
  v_cdconta_classificacao   VARCHAR2(20);
  v_cdconta_naocredito      VARCHAR2(20);
  v_perc_mao_obra           NUMBER(5, 2);
  v_cod_obj_adnnet          VARCHAR2(20);
  v_num_seq                 INTEGER;
  v_tipo_fatur_bv           VARCHAR2(10);
  v_num_dias_bv             INTEGER;
  v_valor_bv_total          NUMBER;
  v_valor_duplicata_tot     NUMBER;
  v_num_parcela             INTEGER;
  v_valor_parcela_dup       NUMBER;
  v_valor_parcela_bv        NUMBER;
  v_nome_item               VARCHAR2(1000);
  v_tipo_item_nota          VARCHAR2(20);
  v_compl_mensagem          VARCHAR2(50);
  v_cod_ext_tipo_job        tipo_job.cod_ext_tipo_job%TYPE;
  v_calcula_imposto         VARCHAR2(10);
  v_cod_sist_ext            sistema_externo.codigo%TYPE;
  v_cod_ext_doc             tipo_doc_nf.cod_ext_doc%TYPE;
  v_cd_nat_oper             VARCHAR2(20);
  v_cd_item                 VARCHAR(50);
  v_idnf_repasse            VARCHAR(50);
  v_flfat_pelo_pedido       VARCHAR(1);
  v_vlcredito               sobra.valor_sobra%TYPE;
  v_modo_pagto              nota_fiscal.modo_pagto%TYPE;
  v_cod_ext                 VARCHAR2(100);
  v_nocusto                 VARCHAR2(100);
  v_cod_ext_item_checkin    parametro.valor%TYPE;
  v_chave_pix               pessoa.chave_pix%TYPE;
  v_modo_pagto_old          dicionario.codigo%TYPE;
  --
  CURSOR c_itn IS
   SELECT jo.numero AS num_job,
          ie.item_id,
          nvl(SUM(it.valor_aprovado), 0) AS valor_aprovado,
          oc.num_orcamento,
          ie.tipo_item,
          ie.num_seq,
          TRIM(tp.nome || ' ' || ie.complemento) AS nome_item,
          ie.obs,
          jo.job_id
     FROM item_nota    it,
          item         ie,
          orcamento    oc,
          tipo_produto tp,
          job          jo
    WHERE it.nota_fiscal_id = p_nota_fiscal_id
      AND it.item_id = ie.item_id
      AND ie.orcamento_id = oc.orcamento_id
      AND ie.tipo_produto_id = tp.tipo_produto_id
      AND oc.job_id = jo.job_id
    GROUP BY jo.numero,
             ie.tipo_item,
             ie.num_seq,
             ie.item_id,
             oc.num_orcamento,
             tp.nome,
             ie.complemento,
             ie.obs,
             jo.job_id
    ORDER BY jo.numero,
             oc.num_orcamento,
             ie.tipo_item,
             ie.num_seq;
  --
  CURSOR c_dup IS
   SELECT duplicata_id,
          num_parcela,
          data_vencim,
          valor_duplicata
     FROM duplicata
    WHERE nota_fiscal_id = p_nota_fiscal_id
    ORDER BY num_parcela;
  --
  CURSOR c_ra IS
   SELECT it.item_id,
          jo.numero AS num_job,
          jo.numero || '/' || to_char(oc.num_orcamento) AS num_est,
          nvl(SUM(io.valor_aprovado), 0) AS valor_rateio,
          it.cod_externo
     FROM item_nota io,
          item      it,
          orcamento oc,
          job       jo
    WHERE io.nota_fiscal_id = p_nota_fiscal_id
      AND io.item_id = it.item_id
      AND it.orcamento_id = oc.orcamento_id
      AND oc.job_id = jo.job_id
    GROUP BY it.item_id,
             jo.numero,
             oc.num_orcamento,
             it.cod_externo
    ORDER BY jo.numero,
             oc.num_orcamento,
             it.cod_externo;
  --
 BEGIN
  v_qt              := 0;
  v_xml_doc         := '<?xml version="1.0" encoding="ISO-8859-1" ?>';
  v_calcula_imposto := empresa_pkg.parametro_retornar(p_empresa_id, 'HABILITA_CALCULO_IMPOSTO');
  --ALCBO_120225
  v_cod_ext_item_checkin := empresa_pkg.parametro_retornar(p_empresa_id, 'COD_EXT_ITEM_CHECKIN');
  --
  ------------------------------------------------------------
  -- consistencias
  ------------------------------------------------------------
  IF TRIM(p_cod_acao) IS NULL OR p_cod_acao NOT IN ('I', 'A', 'E', 'C')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Código da ação inválido.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(it.job_id)
    INTO v_job_id
    FROM item_nota io,
         item      it
   WHERE io.nota_fiscal_id = p_nota_fiscal_id
     AND io.item_id = it.item_id;
  --
  SELECT jo.numero,
         jo.nome,
         job_pkg.nome_retornar(jo.job_id),
         tj.cod_ext_tipo_job
    INTO v_num_job,
         v_nome_job_ori,
         v_nome_job,
         v_cod_ext_tipo_job
    FROM job      jo,
         tipo_job tj
   WHERE jo.job_id = v_job_id
     AND jo.tipo_job_id = tj.tipo_job_id;
  --
  SELECT bf.codigo,
         bc.codigo,
         nf.emp_emissora_id,
         nf.valor_mao_obra,
         nf.valor_bruto,
         nf.desc_servico,
         nf.tipo_conta,
         nf.cliente_id,
         nota_fiscal_pkg.tipo_item_retornar(nf.nota_fiscal_id),
         nf.flag_item_patrocinado,
         nf.municipio_servico,
         nf.uf_servico,
         nf.tipo_fatur_bv,
         pe.flag_pessoa_jur,
         nf.tipo_pag_pessoa,
         nf.emp_faturar_por_id,
         td.flag_toma_credito,
         td.cod_ext_doc,
         nf.flag_pago_cliente,
         pe.chave_pix
    INTO v_cod_banco_fornec,
         v_cod_banco_cobrador,
         v_emp_emissora_id,
         v_valor_mao_obra,
         v_valor_bruto,
         v_desc_servico,
         v_tipo_conta,
         v_cliente_id,
         v_tipo_item_nota,
         v_flag_item_patrocinado,
         v_cidade,
         v_uf,
         v_tipo_fatur_bv,
         v_flag_pessoa_jur,
         v_cdconta_classificacao,
         v_emp_faturar_por_id,
         v_flag_toma_credito,
         v_cod_ext_doc,
         v_flag_pago_cliente,
         v_chave_pix
    FROM nota_fiscal nf,
         fi_banco    bf,
         fi_banco    bc,
         pessoa      pe,
         tipo_doc_nf td
   WHERE nf.nota_fiscal_id = p_nota_fiscal_id
     AND nf.emp_emissora_id = pe.pessoa_id
     AND nf.tipo_doc_nf_id = td.tipo_doc_nf_id
     AND nf.fi_banco_fornec_id = bf.fi_banco_id(+)
     AND nf.fi_banco_cobrador_id = bc.fi_banco_id(+);
  --
  SELECT codigo
    INTO v_cod_sist_ext
    FROM sistema_externo
   WHERE sistema_externo_id = p_sistema_externo_id;
  --
  -- verifica se tem BV/TIP nos itens da nota
  SELECT nvl(SUM(valor_bv), 0) + nvl(SUM(valor_tip), 0)
    INTO v_valor_bv_total
    FROM item_nota
   WHERE nota_fiscal_id = p_nota_fiscal_id;
  --
  v_num_dias_bv := empresa_pkg.parametro_retornar(p_empresa_id, 'NUM_DIAS_BV');
  --
  -- verifica se precisa mesmo integrar NF paga pelo cliente
  -- (apenas NF com BV)
  IF v_flag_pago_cliente = 'S'
  THEN
   IF v_valor_bv_total > 0
   THEN
    -- prossegue com a integracao
    NULL;
    --ALCBO_070125
   ELSIF v_cod_sist_ext LIKE '%INHA%' AND v_valor_bv_total = 0
   THEN
    -- prossegue com a integracao
    NULL;
   ELSE
    -- sai sem integrar a NF
    RAISE v_saida;
   END IF;
  END IF;
  --
  IF v_cod_sist_ext NOT LIKE '%BFERRAZ%'
  THEN
   v_nome_job := v_nome_job_ori;
  END IF;
  --
  -- verifica se a NF deve mesmo ser integrada a esse sistema externo,
  -- para essa empresa de faturamento (na BFERRAZ, algumas nao tem integracao).
  SELECT MAX(cod_ext_fatur)
    INTO v_cod_ext_fatur
    FROM empr_fatur_sist_ext
   WHERE sistema_externo_id = p_sistema_externo_id
     AND pessoa_id = v_emp_faturar_por_id;
  --
  IF TRIM(v_cod_ext_fatur) IS NULL
  THEN
   IF v_cod_sist_ext LIKE '%BFERRAZ%'
   THEN
    -- sai e nao faz a integracao
    p_erro_cod := '00000';
    p_erro_msg := 'Operação não se aplica.';
    RAISE v_exception;
   ELSE
    p_erro_cod := '90000';
    p_erro_msg := 'A empresa de faturamento não tem código definido para a integração ' ||
                  'com o sistema financeiro.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF v_cod_banco_fornec IS NULL
  THEN
   v_tipo_conta := NULL;
  END IF;
  --
  -- so manda o cliente para itens de A/B ou itens de C patrocinados
  IF v_tipo_item_nota = 'C' AND v_flag_item_patrocinado = 'N'
  THEN
   v_cliente_id := NULL;
  END IF;
  --
  SELECT MIN(it.tipo_item),
         MIN(it.item_id),
         SUM(no.valor_aprovado)
    INTO v_tipo_item,
         v_item_id,
         v_valor_tot_itens
    FROM item_nota no,
         item      it
   WHERE no.nota_fiscal_id = p_nota_fiscal_id
     AND no.item_id = it.item_id;
  --
  SELECT MAX(valor)
    INTO v_cdconta_naocredito
    FROM sist_ext_parametro
   WHERE sistema_externo_id = p_sistema_externo_id
     AND nome = 'ADN_CDCONTA_NAOCREDITO';
  --
  IF v_cdconta_naocredito IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Parâmetro ADN_CDCONTA_NAOCREDITO não definido para esse sistema externo.';
   RAISE v_exception;
  END IF;
  --
  -- definicao da conta gerencial enviada ao ADN.
  --
  IF v_tipo_item = 'A'
  THEN
   -- para itens de A, despreza eventual conta indicada na nota.
   v_cdconta_classificacao := NULL;
  ELSE
   -- Itens de B e C.
   IF v_cod_sist_ext LIKE '%SRCOM%'
   THEN
    -- usado na SRCOM
    IF TRIM(v_cdconta_classificacao) IS NULL AND v_cod_sist_ext LIKE '%SRCOM_SP%'
    THEN
     --IF v_cod_ext_doc IN ('REC','NFF','ND','NFP','NFS','NFL','RD') THEN
     v_cdconta_classificacao := '31150101';
     -- ELSIF v_cod_ext_doc = 'RD' THEN
     --    v_cdconta_classificacao := '39904002';
     --END IF;
    END IF;
   ELSE
    -- usado na BFerraz
    IF TRIM(v_cdconta_classificacao) IS NULL
    THEN
     -- nao veio no documento. Para as condicoes abaixo,
     -- o codigo eh fixo. Para os demais casos, vai nulo.
     IF v_flag_pessoa_jur = 'N' OR v_flag_toma_credito = 'N'
     THEN
      -- casos em que nao toma credito
      v_cdconta_classificacao := v_cdconta_naocredito;
     END IF;
    END IF;
   END IF;
  END IF;
  --
  --ALCBO_200824
  IF v_cod_sist_ext LIKE '%PROS%'
  THEN
   SELECT CASE
           WHEN codigo = 'NFS' THEN
            '41102003'
           WHEN codigo = 'NF' THEN
            '41102002'
           WHEN codigo = 'REC' THEN
            '41301070'
           WHEN codigo = 'NFL' THEN
            '41102003'
           WHEN codigo = 'TAR' THEN
            '41401010'
          END
     INTO v_cdconta_classificacao
     FROM tipo_doc_nf td
    INNER JOIN nota_fiscal nf
       ON td.tipo_doc_nf_id = nf.tipo_doc_nf_id
    WHERE nf.nota_fiscal_id = p_nota_fiscal_id;
  END IF;
  --ALCBO_120225
  --ALCBO_200824
  --
  /*IF v_cod_sist_ext LIKE '%INHA%' AND v_cod_ext_item_checkin = 'S'
  THEN
   v_cdconta_classificacao := NULL;
  END IF;*/
  --
  IF v_item_id IS NULL AND p_cod_acao IN ('I', 'A')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa nota fiscal não tem itens associados.';
   RAISE v_exception;
  END IF;
  --
  IF v_cidade IS NULL OR v_uf IS NULL
  THEN
   -- o municipio do servico nao foi definido.
   -- pega o municipio do fornecedor.
   SELECT cidade,
          uf
     INTO v_cidade,
          v_uf
     FROM pessoa
    WHERE pessoa_id = v_emp_emissora_id;
  END IF;
  --
  v_cidade       := util_pkg.acento_municipio_retirar(v_cidade);
  v_cidade       := char_especial_retirar(v_cidade);
  v_desc_servico := char_especial_retirar(v_desc_servico);
  --
  IF v_valor_mao_obra > 0
  THEN
   v_perc_mao_obra := round(v_valor_mao_obra / v_valor_bruto * 100, 2);
  END IF;
  --
  -- recupera o valor total liquido da nota
  SELECT nvl(SUM(valor_duplicata), 0),
         nvl(MAX(num_parcela), 0)
    INTO v_valor_duplicata_tot,
         v_num_parcela
    FROM duplicata
   WHERE nota_fiscal_id = p_nota_fiscal_id;

  --ALCBO_200225
  --Criacao de funcao a parte para controlar natureza de oper
  v_cd_nat_oper := obter_nat_oper(v_cod_sist_ext,
                                  v_flag_pago_cliente,
                                  v_valor_bv_total,
                                  v_tipo_item,
                                  p_nota_fiscal_id);
  --ALCBO_040825
  IF v_cod_sist_ext LIKE '%INHA%'
  THEN
   SELECT nf.modo_pagto
     INTO v_modo_pagto
     FROM nota_fiscal nf
    INNER JOIN tipo_doc_nf td
       ON nf.tipo_doc_nf_id = td.tipo_doc_nf_id
    WHERE nota_fiscal_id = p_nota_fiscal_id;
   --ALCBO_180825 Guarda o modo de pag em codigo antes da conversao em numero para testar na montagem da tag chpix 
   v_modo_pagto_old := v_modo_pagto;
   --
   v_modo_pagto := CASE v_modo_pagto
                    WHEN 'CH' THEN
                     1 -- Cheque/Dinheiro
                    WHEN 'TT' THEN
                     2 -- Títulos Terceiros
                    WHEN 'DO' THEN
                     3 -- DOC
                    WHEN 'CC' THEN
                     6 -- Crédito em Conta (mesmo banco)
                    WHEN 'TR' THEN
                     9 -- Títulos Registrados
                    WHEN 'TE' THEN
                     13 -- TED - Diferentes Titularidades
                    WHEN 'CO' THEN
                     14 -- Concessionárias
                    WHEN 'TM' THEN
                     18 -- TED - Mesma Titularidade (Itaú)
                    WHEN 'PI' THEN
                     19 -- PIX - Transferência
                    WHEN 'PQ' THEN
                     20 -- PIX - QR Code
                    WHEN 'PB' THEN
                     21 -- PIX - Mod Banco, Agência, Conta
                    WHEN 'IS' THEN
                     7 -- ISS
                    ELSE
                     NULL
                   END;
  END IF;
  --ALCBO_110724
  --ALCBO_170524 --ALCBO_190225 --280225
  BEGIN
   IF v_cod_sist_ext LIKE '%PROS%'
   THEN
    -- Primeiro pega o código do modo de pagamento da nota
    SELECT modo_pagto
      INTO v_modo_pagto
      FROM nota_fiscal
     WHERE nota_fiscal_id = p_nota_fiscal_id;
    --
    v_modo_pagto := CASE v_modo_pagto
                     WHEN 'CH' THEN
                      1 -- Cheque/Dinheiro
                     WHEN 'TT' THEN
                      2 -- Títulos Terceiros
                     WHEN 'DO' THEN
                      3 -- DOC
                     WHEN 'CC' THEN
                      6 -- Crédito em Conta (mesmo banco)
                     WHEN 'IS' THEN
                      7 -- ISS
                     WHEN 'OP' THEN
                      8 -- Ordem de Pagamento / Ch. Adm
                     WHEN 'TR' THEN
                      9 -- Títulos Registrados
                     WHEN 'DA' THEN
                      10 -- DARF
                     WHEN 'DS' THEN
                      11 -- DARF Simples
                     WHEN 'TE' THEN
                      13 -- TED
                     WHEN 'CO' THEN
                      14 -- Concessionárias
                     WHEN 'GP' THEN
                      15 -- GPS
                     WHEN 'TM' THEN
                      16 -- Títulos Terceiros 250 mil
                     WHEN 'DU' THEN
                      19 -- DARF UNICO
                     WHEN 'PT' THEN
                      20 -- PIX - Transferência
                     WHEN 'PQ' THEN
                      21 -- PIX - QR CODE
                     WHEN 'PB' THEN
                      22 -- PIX - Mod Banco, Agência, Conta
                     WHEN 'X1' THEN
                      23
                     WHEN 'X2' THEN
                      24
                     WHEN 'P1' THEN
                      25
                     WHEN 'P2' THEN
                      26
                     WHEN 'P3' THEN
                      27
                     WHEN 'T1' THEN
                      28
                     WHEN 'T2' THEN
                      29
                     WHEN 'T3' THEN
                      30
                     WHEN 'T4' THEN
                      31
                     WHEN 'T5' THEN
                      32
                     WHEN 'T6' THEN
                      33
                     WHEN 'T7' THEN
                      34
                     ELSE
                      NULL
                    END;
   END IF;
  END;
  --
  ------------------------------------------------------------
  -- monta a secao "cabecalho"
  ------------------------------------------------------------
  xml_cabecalho_gerar(p_sistema_externo_id,
                      p_empresa_id,
                      'NOTA_ENTRADA',
                      p_nota_fiscal_id,
                      v_xml_cabecalho,
                      p_erro_cod,
                      p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- monta a secao "conteudo"
  ------------------------------------------------------------
  SELECT xmlconcat(xmlelement("idnfiscal", TRIM(to_char(nf.nota_fiscal_id))),
                   xmlelement("cdfornec", TRIM(to_char(nf.emp_emissora_id))),
                   xmlelement("tpdoc", v_cod_ext_doc),
                   xmlelement("cdconta_classificacao", v_cdconta_classificacao),
                   xmlelement("nodoc", char_especial_retirar(nf.num_doc)),
                   xmlelement("cdserie", char_especial_retirar(nf.serie)),
                   xmlelement("dtemissao", to_char(nf.data_emissao, 'yyyy-mm-dd')),
                   xmlelement("dtentrada", to_char(nf.data_entrada, 'yyyy-mm-dd')),
                   xmlelement("cdempresa", TRIM(v_cod_ext_fatur)),
                   xmlelement("cdcliente", TRIM(to_char(v_cliente_id))),
                   xmlelement("cdnatureza_operacao", v_cd_nat_oper),
                   xmlelement("nojob", TRIM(to_char(v_num_job))),
                   xmlelement("tpjob", v_cod_ext_tipo_job),
                   xmlelement("cdcfo", '9999'),
                   xmlelement("vlcontabil", REPLACE(moeda_mostrar(nf.valor_bruto, 'N'), ',', '.')),
                   xmlelement("txobs", substr(v_nome_job || ': ' || v_desc_servico, 1, 255)),
                   xmlelement("sguf", v_uf),
                   xmlelement("nmmunicipio", v_cidade),
                   xmlelement("cdmeio_pagto", v_modo_pagto),
                   xmlelement("cdbanco", v_cod_banco_fornec),
                   xmlelement("noagencia", char_especial_retirar(nf.num_agencia)),
                   xmlelement("nocta_corrente", char_especial_retirar(nf.num_conta)),
                   xmlelement("tpcta_corrente", v_tipo_conta),
                   CASE
                    WHEN v_cod_sist_ext LIKE '%INHA%' AND v_modo_pagto_old = 'PI' THEN
                     xmlelement("chpix", v_chave_pix) --RP_24/07/2025
                    ELSE
                     NULL
                   END, --ALCBO_180825 
                   xmlelement("pcmob", REPLACE(taxa_mostrar(v_perc_mao_obra), ',', '.')),
                   xmlelement("vlmob", REPLACE(moeda_mostrar(v_valor_mao_obra, 'N'), ',', '.')),
                   xmlelement("flfat_pelo_pedido", 'S'),
                   xmlelement("vlbv", REPLACE(moeda_mostrar(v_valor_bv_total, 'N'), ',', '.')),
                   xmlelement("idanexo",
                              CASE
                               WHEN nf.cod_arquivo_ext IS NOT NULL THEN
                                nf.cod_arquivo_ext
                               ELSE
                                NULL
                              END), --ALCBO_011024
                   CASE
                    WHEN v_cod_sist_ext LIKE '%INHA%' AND v_cod_ext_doc = 'NFC' THEN
                     xmlelement("chavenfe", nf.chave_acesso)
                    ELSE
                     NULL
                   END) --ALCBO_170625
    INTO v_xml_conteudo_header
    FROM nota_fiscal nf
   WHERE nf.nota_fiscal_id = p_nota_fiscal_id;
  --
  ------------------------------------------------------------
  -- monta a secao "itens"
  ------------------------------------------------------------
  v_num_seq := 0;
  --
  FOR r_itn IN c_itn
  LOOP
   v_num_seq   := v_num_seq + 1;
   v_nome_item := substr(char_especial_retirar(r_itn.nome_item), 1, 255);
   --procura no campo OBS do faturamento pela tag <idnf_repasse> que pode conter
   --o código de item já fornecido ao ADNNet por outro sistema, no caso
   --te ter havido um faturamento prévio deste item antes da substituição
   --do sistema pelo JobOne (somente para migração de saldos)
   --
   --Exemplo de observação válida:
   --somente para migração de saldos: <cditem>orc|001|0000000000013354</cditem>
   --Somente para migração de saldos: <idnf_repasse>F|0012339|001|</idnf_repasse>
   IF r_itn.obs IS NOT NULL
   THEN
    SELECT substr(r_itn.obs,
                  instr(r_itn.obs, '<idnf_repasse>') + 14,
                  instr(r_itn.obs, '</idnf_repasse>') - (instr(r_itn.obs, '<idnf_repasse>') + 14))
      INTO v_idnf_repasse
      FROM dual;
   END IF;
   IF v_idnf_repasse IS NULL OR r_itn.obs IS NULL
   THEN
    SELECT COUNT(*)
      INTO v_qt
      FROM faturamento f
     INNER JOIN item_fatur i
        ON i.faturamento_id = f.faturamento_id
     WHERE i.item_id = r_itn.item_id;
    --ALCBO_060224
    IF v_qt > 0
    THEN
     SELECT MAX(f.faturamento_id)
       INTO v_idnf_repasse
       FROM faturamento f
      INNER JOIN item_fatur i
         ON i.faturamento_id = f.faturamento_id
      WHERE i.item_id = r_itn.item_id
        AND i.nota_fiscal_id = p_nota_fiscal_id;
     --
     IF v_idnf_repasse IS NULL
     THEN
      v_idnf_repasse := '';
     END IF;
    ELSE
     v_idnf_repasse := '';
    END IF;
   END IF;
   --
   v_flfat_pelo_pedido := '';
   IF r_itn.tipo_item = 'A'
   THEN
    IF v_idnf_repasse IS NULL
    THEN
     --não houve faturamento prévio
     v_flfat_pelo_pedido := 'N';
    ELSE
     --houve faturamento prévio
     v_flfat_pelo_pedido := 'S';
    END IF;
   END IF;
   --procura no campo OBS do item pela tag <cditem> que pode conter
   --o código de item já fornecido ao ADNNet por outro sistema, no caso
   --te ter havido um faturamento prévio deste item antes da substituição
   --do sistema pelo JobOne (somente para migração de saldos)
   IF r_itn.obs IS NOT NULL
   THEN
    SELECT substr(r_itn.obs,
                  instr(r_itn.obs, '<cditem>') + 8,
                  instr(r_itn.obs, '</cditem>') - (instr(r_itn.obs, '<cditem>') + 8))
      INTO v_cd_item
      FROM dual;
   END IF;
   --se o cd_item não for encontrado ou OBS do item estiver nulo
   --então montar o código do item do JobOne normalmente
   IF v_cd_item IS NULL OR r_itn.obs IS NULL
   THEN
    v_cd_item := r_itn.num_job || '-' || to_char(r_itn.num_orcamento) || '-' || r_itn.tipo_item ||
                 to_char(r_itn.num_seq);
   END IF;
   --
   v_vlcredito := 0;
   SELECT nvl(SUM(valor_sobra), 0)
     INTO v_vlcredito
     FROM (SELECT nvl(valor_sobra, 0) AS valor_sobra
             FROM sobra
            WHERE job_id = r_itn.job_id
              AND substr(justificativa,
                         instr(justificativa, '<nota_fiscal_id>') + 16,
                         instr(justificativa, '</nota_fiscal_id>') -
                         (instr(justificativa, '<nota_fiscal_id>') + 16)) = p_nota_fiscal_id);
   --ALCBO_301224
   --Evitar enviar item zerado
   SELECT xmlagg(CASE
                  WHEN r_itn.valor_aprovado > 0 THEN
                   xmlelement("itens",
                              xmlelement("noitem", to_char(v_num_seq)),
                              xmlelement("cditem", v_cd_item), --preenchido com identif. JobOne ou  código migração da OBS
                              xmlelement("tpitem",
                                         CASE
                                          WHEN v_cod_sist_ext LIKE '%INHA%' AND v_cod_ext_doc = 'NFC' THEN
                                           'P'
                                          ELSE
                                           'S'
                                         END), --RP_020625 No Caso da INHHAUS o TP_ITEM indicara 'P' ou 'S' para que o ADN seja capaz de distinguir o que é nota de PRODUTO ou SERVIÇO.
                              xmlelement("txitem", v_nome_item),
                              xmlelement("qtitem", '1'),
                              xmlelement("cdunidade", 'UN'),
                              xmlelement("prunitario",
                                         REPLACE(moeda_mostrar(r_itn.valor_aprovado, 'N'), ',', '.')),
                              xmlelement("vlitem",
                                         REPLACE(moeda_mostrar(r_itn.valor_aprovado, 'N'), ',', '.')),
                              xmlelement("idnf_repasse", v_idnf_repasse), --identificação de faturamento prévio - pode vir de OBS
                              xmlelement("vl_sobra_repasse", v_vlcredito), --valor de sobra indicado no item durante o check-in
                              xmlelement("noestimativa", to_char(r_itn.num_orcamento)),
                              xmlelement("flfat_pelo_pedido", v_flfat_pelo_pedido))
                 END)
     INTO v_xml_conteudo_itens_aux
     FROM dual;
   --
   SELECT xmlconcat(v_xml_conteudo_itens, v_xml_conteudo_itens_aux)
     INTO v_xml_conteudo_itens
     FROM dual;
  END LOOP;
  --
  ------------------------------------------------------------
  -- monta a secao "impostos"
  ------------------------------------------------------------
  IF v_calcula_imposto = 'S'
  THEN
   SELECT xmlagg(xmlelement("impostos",
                            xmlelement("noitem", '0'),
                            xmlelement("cdimposto", ti.cod_imposto),
                            xmlelement("vlbase_calculo",
                                       REPLACE(moeda_mostrar(im.valor_base_calc, 'N'), ',', '.')),
                            xmlelement("pcaliquota",
                                       REPLACE(taxa_mostrar(im.perc_imposto_nota), ',', '.')),
                            xmlelement("vldeducao",
                                       REPLACE(moeda_mostrar(im.valor_deducao, 'N'), ',', '.')),
                            xmlelement("vlimposto_bruto",
                                       REPLACE(moeda_mostrar(im.valor_imposto_base, 'N'), ',', '.')),
                            xmlelement("vlimposto_acum",
                                       REPLACE(moeda_mostrar(im.valor_imposto_acum, 'N'), ',', '.')),
                            xmlelement("vlimposto",
                                       REPLACE(moeda_mostrar(im.valor_imposto, 'N'), ',', '.')),
                            xmlelement("cdretencao", im.cod_retencao)))
     INTO v_xml_conteudo_impos
     FROM imposto_nota    im,
          fi_tipo_imposto ti
    WHERE im.nota_fiscal_id = p_nota_fiscal_id
      AND im.fi_tipo_imposto_id = ti.fi_tipo_imposto_id
      AND im.valor_imposto > 0
      AND im.flag_reter = 'S'
    ORDER BY im.num_seq;
  END IF;
  --
  ------------------------------------------------------------
  -- monta a secao "duplicatas"
  ------------------------------------------------------------
  v_num_seq := 0;
  --
  FOR r_dup IN c_dup
  LOOP
   v_valor_parcela_dup := r_dup.valor_duplicata;
   --
   IF v_valor_bv_total > 0
   THEN
    IF v_tipo_fatur_bv = 'ABA'
    THEN
     v_compl_mensagem := 'abater';
    ELSE
     v_compl_mensagem := 'pagar';
    END IF;
    --
    -- calcula o valor proporcional de BV ao valor da duplicata
    v_valor_parcela_bv  := round(r_dup.valor_duplicata / v_valor_duplicata_tot * v_valor_bv_total,
                                 2);
    v_valor_parcela_dup := r_dup.valor_duplicata - v_valor_parcela_bv;
    --
    IF v_valor_parcela_dup < 0
    THEN
     -- o valor da duplicata não é suficiente p/ abater o BV
     -- deixa passar até uma diferença de 1,00
     IF abs(v_valor_parcela_dup) <= 1
     THEN
      v_valor_parcela_bv := r_dup.valor_duplicata;
     ELSE
      p_erro_cod := '90000';
      p_erro_msg := 'O valor líquido da nota fiscal (duplicata: ' ||
                    moeda_mostrar(r_dup.valor_duplicata, 'S') || ') não é suficiente para se ' ||
                    v_compl_mensagem || ' o BV/TIP (' || moeda_mostrar(v_valor_parcela_bv, 'S') || ').';
      RAISE v_exception;
     END IF;
    END IF;
    --
    IF v_tipo_fatur_bv <> 'ABA'
    THEN
     -- restaura o valor da duplicata, sem descontar o BV
     v_valor_parcela_dup := r_dup.valor_duplicata;
    END IF;
   END IF;
   --
   IF v_valor_parcela_dup > 0
   THEN
    v_num_seq := v_num_seq + 1;
    --
    SELECT xmlagg(xmlelement("duplicatas",
                             xmlelement("noordem", TRIM(to_char(v_num_seq))),
                             xmlelement("dtvencto", to_char(r_dup.data_vencim, 'yyyy-mm-dd')),
                             xmlelement("vlduplicata",
                                        REPLACE(moeda_mostrar(v_valor_parcela_dup, 'N'), ',', '.')),
                             xmlelement("cdagente_portador", v_cod_banco_cobrador),
                             xmlelement("fltip", 'N')))
      INTO v_xml_conteudo_dupli_aux1
      FROM dual;
   END IF;
   --
   IF v_valor_bv_total > 0 AND v_tipo_fatur_bv = 'ABA'
   THEN
    -- gera as duplicatas dos BVs
    v_num_seq := v_num_seq + 1;
    --
    SELECT xmlagg(xmlelement("duplicatas",
                             xmlelement("noordem", TRIM(to_char(v_num_seq))),
                             xmlelement("dtvencto",
                                        to_char(r_dup.data_vencim + v_num_dias_bv, 'yyyy-mm-dd')),
                             xmlelement("vlduplicata",
                                        REPLACE(moeda_mostrar(v_valor_parcela_bv, 'N'), ',', '.')),
                             xmlelement("cdagente_portador", NULL),
                             xmlelement("fltip", 'S')))
      INTO v_xml_conteudo_dupli_aux2
      FROM dual;
   ELSE
    v_xml_conteudo_dupli_aux2 := NULL;
   END IF;
   --
   SELECT xmlconcat(v_xml_conteudo_dupli, v_xml_conteudo_dupli_aux1, v_xml_conteudo_dupli_aux2)
     INTO v_xml_conteudo_dupli
     FROM dual;
  END LOOP;
  --
  --
  ------------------------------------------------------------
  -- monta a secao "rateio"
  ------------------------------------------------------------
  -- para a MOMENTUM, o ADN esta desprezando o rateio
  -- para a PROS, nao manda o rateio pois nao tem integracao de EC
  IF v_cod_sist_ext NOT LIKE '%PROS%' AND v_cod_sist_ext NOT LIKE '%VITRIO%' AND
     v_cod_sist_ext NOT LIKE '%SHERPA%'
  THEN
   FOR r_ra IN c_ra
   LOOP
    --ALCBO_230524 --ALCBO_090425
    SELECT COUNT(cp.nome_classe)
      INTO v_qt
      FROM tipo_produto tp
     INNER JOIN item it
        ON tp.tipo_produto_id = it.tipo_produto_id
      LEFT JOIN categoria ca
        ON tp.categoria_id = ca.categoria_id
      LEFT JOIN classe_produto cp
        ON cp.classe_produto_id = ca.classe_produto_id
     WHERE it.item_id = r_ra.item_id;
    --SE TIVER CLASSIFICACAO PRECISA ENVIAR A CLASSIF SE NAO VAI O JOB NO CHECKIN
    IF v_qt <> 0 AND v_cod_sist_ext LIKE '%REDDOOR%'
    THEN
     --ALCBO_090425
     SELECT TRIM(cp.nome_classe || ' ' || cp.sub_classe)
       INTO v_cod_ext
       FROM tipo_produto tp
      INNER JOIN item it
         ON tp.tipo_produto_id = it.tipo_produto_id
       LEFT JOIN categoria ca
         ON tp.categoria_id = ca.categoria_id
       LEFT JOIN classe_produto cp
         ON cp.classe_produto_id = ca.classe_produto_id
      WHERE it.item_id = r_ra.item_id;
    ELSE
     v_cod_ext := NULL;
    END IF;
    /*ALCBO_210624
    ALTERACAO PARA ENVIA NUM JOB AO INVES DE ORCAMENTO NA REDOR*/
    IF v_cod_sist_ext LIKE '%REDDOOR%'
    THEN
     v_nocusto := r_ra.num_job;
    ELSE
     v_nocusto := r_ra.num_est;
    END IF;
    /*ALCBO_120225
    ALTERACAO PARA ENVIA COD_EXTERNO ITEM AO INVES DE CONTA ESPECIFICA NA INHAUS*/
    IF v_cod_sist_ext LIKE '%INHA%' AND v_cod_ext_item_checkin = 'S'
    THEN
     v_cdconta_classificacao := r_ra.cod_externo;
    ELSE
     v_cdconta_classificacao := v_cdconta_classificacao;
    END IF;
    --ALCBO_230524F
    --ALCBO_301224 - Evitar enviar vlarteio zerado
    SELECT xmlagg(CASE
                   WHEN r_ra.valor_rateio > 0 THEN
                    xmlelement("rateio",
                               xmlelement("noconta", v_cdconta_classificacao),
                               xmlelement("noccusto", TRIM(v_nocusto)),
                               xmlelement("vlrateio",
                                          REPLACE(moeda_mostrar(r_ra.valor_rateio, 'N'), ',', '.')),
                               xmlelement("tpjob", TRIM(v_cod_ext)))
                  END)
      INTO v_xml_conteudo_rat_aux1
      FROM dual;
    --
    SELECT xmlconcat(v_xml_conteudo_rat, v_xml_conteudo_rat_aux1)
      INTO v_xml_conteudo_rat
      FROM dual;
   END LOOP;
  END IF;
  --
  ------------------------------------------------------------
  -- junta tudo no conteudo
  ------------------------------------------------------------
  SELECT xmlagg(xmlelement("root",
                           v_xml_conteudo_header,
                           v_xml_conteudo_itens,
                           v_xml_conteudo_impos,
                           v_xml_conteudo_dupli,
                           v_xml_conteudo_rat))
    INTO v_xml_conteudo
    FROM dual;
  --
  SELECT xmlagg(xmlelement("conteudo", v_xml_conteudo))
    INTO v_xml_conteudo
    FROM dual;
  --
  ------------------------------------------------------------
  -- junta o cabecalho com o conteudo debaixo de "mensagem"
  ------------------------------------------------------------
  SELECT xmlagg(xmlelement("mensagem", v_xml_cabecalho, v_xml_conteudo))
    INTO v_xml_mensagem
    FROM dual;
  --
  -- acrescenta o tipo de documento
  SELECT v_xml_doc || v_xml_mensagem.getclobval()
    INTO v_xml_in
    FROM dual;
  --
  ------------------------------------------------------------
  -- chama a procedure de integracao
  ------------------------------------------------------------
  adnnet_executar(p_sistema_externo_id,
                  p_empresa_id,
                  'NF_ENTRADA',
                  p_cod_acao,
                  p_nota_fiscal_id,
                  v_xml_in,
                  v_xml_out,
                  p_erro_cod,
                  p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  IF p_cod_acao <> 'E'
  THEN
   -- recupera o codigo adn net da NF
   SELECT MAX(extractvalue(xml_out, '/mensagem/conteudo/root/idnfiscal_adn'))
     INTO v_cod_obj_adnnet
     FROM (SELECT xmltype(v_xml_out) AS xml_out
             FROM dual);
   --
   IF v_cod_obj_adnnet IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Erro na recuperação do código ADN Net da Nota Fiscal.';
    RAISE v_exception;
   END IF;
   --
   UPDATE nota_fiscal
      SET cod_ext_nf = v_cod_obj_adnnet
    WHERE nota_fiscal_id = p_nota_fiscal_id;
  END IF;
  --
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_saida THEN
   p_erro_cod := '00000';
   p_erro_msg := 'Operação realizada com sucesso.';
  WHEN v_exception THEN
   NULL;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 2000);
 END nf_entrada_integrar;
 --
 --
 --
 PROCEDURE faturamento_integrar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 25/05/2007
  -- DESCRICAO: Subrotina que gera o xml e processa a integracao de ordens de faturamento
  --   de *** JOB ***
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            13/05/2008  Agrupamento dos itens no faturamento de BV.
  -- Silvia            23/05/2008  Novo tipo de doc "NFL" (nota fiscal de locacao).
  -- Silvia            18/06/2008  Alteracao no calculo dos percentuais de encargos/honor
  --                               (nao calcula mais o valor medio - manda o maximo).
  -- Silvia            27/04/2009  Ajuste no numero da estimativa no caso de faturamneto
  --                               agrupado.
  -- Silvia            05/10/2009  Tratamento de arredondamento de BV com mais de uma
  --                               duplicata.
  -- Silvia            24/11/2014  Arredondamento de percentuais de honor/encargos devido
  --                               ao aumento de casas decimais.
  -- Silvia            15/09/2016  Nao concatenar o nome do produto no nome do job (todas
  --                               as empresas, exceto BF).
  -- Silvia            20/09/2016  Naturezas do item v3.150 (recuperacao de percentuais)
  -- Silvia            30/08/2017  Novo atributo tipo em natureza_item.
  -- Ana Luiza         24/05/2024  Adicionado informacao de rateio na ordem de faturamento
  -- Ana Luiza         16/07/2024  Modificado cursor de itens
  -- Ana Luiza         19/07/2024  Enviar numero de serie da nota de entrada
  -- Ana Luiza         30/08/2024  Limitar rateio faturamento para Reddoor
  -- Ana Luiza         22/01/2025  Verifica se flag_bv_automatico esta ligado, se nao, considera
  --                               data de vencimento do proprio bv
  -- Ana Luiza         14/07/2025  Trtamento para enviar Corporativo
  -- Ana Luiza         06/08/2025  Tratamento quando encargo enviar tpitem R
  ------------------------------------------------------------------------------------------
 (
  p_sistema_externo_id IN sistema_externo.sistema_externo_id%TYPE,
  p_empresa_id         IN empresa.empresa_id%TYPE,
  p_faturamento_id     IN faturamento.faturamento_id%TYPE,
  p_cod_acao           IN VARCHAR2,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 ) IS
  v_qt                      INTEGER;
  v_exception               EXCEPTION;
  v_xml_doc                 VARCHAR2(100);
  v_xml_cabecalho           xmltype;
  v_xml_conteudo            xmltype;
  v_xml_conteudo_header     xmltype;
  v_xml_conteudo_itens      xmltype;
  v_xml_conteudo_itens_aux  xmltype;
  v_xml_conteudo_dupli      xmltype;
  v_xml_conteudo_dupli_aux  xmltype;
  v_xml_mensagem            xmltype;
  v_xml_out                 CLOB;
  v_xml_in                  CLOB;
  v_cidade                  pessoa.cidade%TYPE;
  v_uf                      pessoa.uf%TYPE;
  v_cod_banco_cobrador      fi_banco.codigo%TYPE;
  v_valor_fatura            NUMBER;
  v_job_id                  job.job_id%TYPE;
  v_num_job                 job.numero%TYPE;
  v_nome_job_ori            job.nome%TYPE;
  v_nome_job                VARCHAR2(200);
  v_num_seq                 INTEGER;
  v_tpitem                  CHAR(1);
  v_tprepasse               CHAR(1);
  v_cdmontante              CHAR(1);
  v_vlbase_comissao_encargo NUMBER;
  v_pccomissao_encargo      NUMBER;
  v_vlitem                  NUMBER;
  v_fornecedor_id           nota_fiscal.emp_emissora_id%TYPE;
  v_num_doc                 nota_fiscal.num_doc%TYPE;
  v_serie                   nota_fiscal.serie%TYPE;
  v_nota_fiscal_id          nota_fiscal.nota_fiscal_id%TYPE;
  v_tipo_doc                tipo_doc_nf.codigo%TYPE;
  v_orcamento_id            orcamento.orcamento_id%TYPE;
  v_orcam_aux_id            orcamento.orcamento_id%TYPE;
  v_num_orcamento           orcamento.num_orcamento%TYPE;
  v_nome_item               VARCHAR2(1000);
  v_valor_aprovado_tot      NUMBER;
  v_valor_encargo_tot       NUMBER;
  v_cod_natureza_oper       faturamento.cod_natureza_oper%TYPE;
  v_descricao               faturamento.descricao%TYPE;
  v_emp_faturar_por_id      faturamento.emp_faturar_por_id%TYPE;
  v_flag_bv                 faturamento.flag_bv%TYPE;
  v_data_ordem              faturamento.data_ordem%TYPE;
  v_flag_servico            natureza_oper_fatur.flag_servico%TYPE;
  v_data_vencim             duplicata.data_vencim%TYPE;
  v_cod_ext_fatur           empr_fatur_sist_ext.cod_ext_fatur%TYPE;
  v_num_dias_bv             INTEGER;
  v_valor_bv                NUMBER;
  v_valor_duplicata_tot     NUMBER;
  v_valor_bv_dup_tot        NUMBER;
  v_valor_ajuste_bv         NUMBER;
  v_cditem                  VARCHAR2(20);
  v_cod_obj_adnnet          VARCHAR2(20);
  v_cod_ext_tipo_job        tipo_job.cod_ext_tipo_job%TYPE;
  v_cod_sist_ext            sistema_externo.codigo%TYPE;
  v_idnfe                   VARCHAR(50);
  v_obs                     faturamento.obs%TYPE;
  v_flfat_antecipado        VARCHAR(1);
  --
  v_xml_conteudo_rat      xmltype;
  v_xml_conteudo_rat_aux1 xmltype;
  v_cod_ext               VARCHAR2(100);
  v_cdconta_classificacao VARCHAR2(20);
  v_bv_fatur_autom        parametro.descricao%TYPE;
  --ALCBO_160724
  CURSOR c_itens IS
   SELECT it.item_id,
          it.tipo_item,
          it.num_seq,
          it.natureza_item,
          substr(TRIM(tp.nome || ' ' || it.complemento), 1, 255) AS nome_item,
          fa.valor_fatura,
          fa.nota_fiscal_id,
          oc.num_orcamento,
          CASE
           WHEN v_cod_sist_ext LIKE '%VITRIO%' THEN
            nvl(ino.nota_fiscal_id, 0)
           ELSE
            nvl(nf.nota_fiscal_id, 0)
          END AS nota_fiscal_e_id,
          nf.tipo_pag_pessoa
     FROM item_fatur fa
    INNER JOIN item it
       ON fa.item_id = it.item_id
    INNER JOIN tipo_produto tp
       ON it.tipo_produto_id = tp.tipo_produto_id
    INNER JOIN orcamento oc
       ON it.orcamento_id = oc.orcamento_id
     LEFT JOIN item_nota ino
       ON v_cod_sist_ext LIKE '%VITRIO%'
      AND fa.item_id = ino.item_id
     LEFT JOIN nota_fiscal nf
       ON v_cod_sist_ext NOT LIKE '%VITRIO%'
      AND fa.nota_fiscal_id = nf.nota_fiscal_id
      AND nf.tipo_ent_sai = 'E'
    WHERE fa.faturamento_id = p_faturamento_id
      AND it.natureza_item = 'CUSTO'
      AND it.tipo_item = 'A'
   UNION ALL
   SELECT it.item_id,
          it.tipo_item,
          it.num_seq,
          it.natureza_item,
          substr(TRIM(tp.nome || ' ' || it.complemento), 1, 255) AS nome_item,
          fa.valor_fatura,
          fa.nota_fiscal_id,
          oc.num_orcamento,
          0 AS nota_fiscal_e_id,
          NULL AS tipo_pag_pessoa
     FROM item_fatur fa
    INNER JOIN item it
       ON fa.item_id = it.item_id
    INNER JOIN tipo_produto tp
       ON it.tipo_produto_id = tp.tipo_produto_id
    INNER JOIN orcamento oc
       ON it.orcamento_id = oc.orcamento_id
    WHERE fa.faturamento_id = p_faturamento_id
      AND it.natureza_item = 'CUSTO'
      AND it.tipo_item IN ('B', 'C')
   UNION ALL
   SELECT it.item_id,
          'Z',
          999999,
          decode(na.tipo, 'ENCARGO', 'ENCARGO', 'HONOR', 'HONOR', 'ERRO') AS natureza_item,
          decode(na.tipo, 'ENCARGO', 'Encargos', 'HONOR', 'Honorários', 'Erro') AS nome_item,
          nvl(SUM(fa.valor_fatura), 0),
          0,
          0,
          0,
          NULL AS tipo_pag_pessoa
     FROM item_fatur    fa,
          item          it,
          natureza_item na
    WHERE fa.faturamento_id = p_faturamento_id
      AND fa.item_id = it.item_id
      AND it.natureza_item <> 'CUSTO'
      AND it.natureza_item = na.codigo(+)
      AND p_empresa_id = na.empresa_id(+)
    GROUP BY it.item_id,
             decode(na.tipo, 'ENCARGO', 'ENCARGO', 'HONOR', 'HONOR', 'ERRO'),
             decode(na.tipo, 'ENCARGO', 'Encargos', 'HONOR', 'Honorários', 'Erro')
    ORDER BY 1,
             2;
  --
  CURSOR c_dup IS
   SELECT num_parcela,
          data_vencim,
          valor_duplicata
     FROM duplicata
    WHERE nota_fiscal_id = v_nota_fiscal_id
    ORDER BY num_parcela;
  --
 BEGIN
  v_qt             := 0;
  v_xml_doc        := '<?xml version="1.0" encoding="ISO-8859-1" ?>';
  v_bv_fatur_autom := empresa_pkg.parametro_retornar(p_empresa_id, 'BV_FATUR_AUTOM');
  --
  ------------------------------------------------------------
  -- consistencias
  ------------------------------------------------------------
  IF TRIM(p_cod_acao) IS NULL OR p_cod_acao NOT IN ('I', 'A', 'E', 'C')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Código da ação inválido.';
   RAISE v_exception;
  END IF;
  --
  SELECT jo.numero,
         jo.job_id,
         jo.nome,
         job_pkg.nome_retornar(jo.job_id),
         tj.cod_ext_tipo_job,
         bc.codigo,
         pe.cidade,
         pe.uf,
         fa.cod_natureza_oper,
         fa.descricao,
         fa.emp_faturar_por_id,
         fa.flag_bv,
         fa.data_ordem,
         fa.obs
    INTO v_num_job,
         v_job_id,
         v_nome_job_ori,
         v_nome_job,
         v_cod_ext_tipo_job,
         v_cod_banco_cobrador,
         v_cidade,
         v_uf,
         v_cod_natureza_oper,
         v_descricao,
         v_emp_faturar_por_id,
         v_flag_bv,
         v_data_ordem,
         v_obs
    FROM faturamento fa,
         job         jo,
         pessoa      pe,
         fi_banco    bc,
         tipo_job    tj
   WHERE fa.faturamento_id = p_faturamento_id
     AND fa.job_id = jo.job_id
     AND jo.tipo_job_id = tj.tipo_job_id
     AND fa.emp_faturar_por_id = pe.pessoa_id
     AND pe.fi_banco_id = bc.fi_banco_id(+);
  --
  SELECT codigo
    INTO v_cod_sist_ext
    FROM sistema_externo
   WHERE sistema_externo_id = p_sistema_externo_id;
  --
  IF v_cod_sist_ext NOT LIKE '%BFERRAZ%'
  THEN
   v_nome_job := v_nome_job_ori;
  END IF;
  --
  -- verifica se o faturamento deve mesmo ser integrado a esse sistema externo,
  -- para essa empresa de faturamento (algumas nao tem integracao).
  SELECT MAX(cod_ext_fatur)
    INTO v_cod_ext_fatur
    FROM empr_fatur_sist_ext
   WHERE sistema_externo_id = p_sistema_externo_id
     AND pessoa_id = v_emp_faturar_por_id;
  --
  IF TRIM(v_cod_ext_fatur) IS NULL
  THEN
   p_erro_cod := '00000';
   p_erro_msg := 'Operação não se aplica.';
   RAISE v_exception;
  END IF;
  --
  SELECT nvl(MAX(flag_servico), 'N')
    INTO v_flag_servico
    FROM natureza_oper_fatur
   WHERE codigo = v_cod_natureza_oper
     AND pessoa_id = v_emp_faturar_por_id;
  --
  v_cidade    := util_pkg.acento_municipio_retirar(v_cidade);
  v_cidade    := char_especial_retirar(v_cidade);
  v_descricao := char_especial_retirar(v_descricao);
  --
  SELECT MIN(it.orcamento_id),
         SUM(fa.valor_fatura),
         MAX(it.orcamento_id)
    INTO v_orcamento_id,
         v_valor_fatura,
         v_orcam_aux_id
    FROM item_fatur fa,
         item       it
   WHERE fa.faturamento_id = p_faturamento_id
     AND fa.item_id = it.item_id;
  --
  IF v_orcamento_id IS NULL AND p_cod_acao IN ('I', 'A')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa ordem de faturamento não tem itens associados.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(v_orcamento_id, 0) > 0
  THEN
   SELECT num_orcamento
     INTO v_num_orcamento
     FROM orcamento
    WHERE orcamento_id = v_orcamento_id;
  END IF;
  --
  v_num_dias_bv := empresa_pkg.parametro_retornar(p_empresa_id, 'NUM_DIAS_BV');
  --
  ------------------------------------------------------------
  -- monta a secao "cabecalho"
  ------------------------------------------------------------
  xml_cabecalho_gerar(p_sistema_externo_id,
                      p_empresa_id,
                      'ORDEM_FATURA',
                      p_faturamento_id,
                      v_xml_cabecalho,
                      p_erro_cod,
                      p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  -- se a data da ordem for muito antiga, o ADN nao aceita
  IF v_data_ordem <= trunc(SYSDATE) - 60
  THEN
   v_data_ordem := trunc(SYSDATE) - 59;
  END IF;
  --
  ------------------------------------------------------------
  -- inicio da secao "conteudo"
  ------------------------------------------------------------
  SELECT xmlconcat(xmlelement("noordem", TRIM(to_char(fa.faturamento_id))),
                   xmlelement("dtordem", to_char(v_data_ordem, 'yyyy-mm-dd')),
                   xmlelement("cdempresa", TRIM(v_cod_ext_fatur)),
                   xmlelement("cdnatureza_operacao", v_cod_natureza_oper),
                   xmlelement("nojob", TRIM(to_char(v_num_job))),
                   xmlelement("tpjob", v_cod_ext_tipo_job),
                   xmlelement("cdcliente", TRIM(to_char(fa.cliente_id))),
                   xmlelement("cdcfo", '9999'),
                   xmlelement("vlcontabil", REPLACE(moeda_mostrar(v_valor_fatura, 'N'), ',', '.')),
                   xmlelement("txobs", nvl(substr(v_descricao, 1, 255), v_nome_job)),
                   xmlelement("sguf", v_uf),
                   xmlelement("nmmunicipio", v_cidade))
    INTO v_xml_conteudo_header
    FROM faturamento fa
   WHERE fa.faturamento_id = p_faturamento_id;
  --
  v_num_seq := 0;
  --
  ------------------------------------------------------------
  -- monta a secao "itens" - faturamento NAO BV
  ------------------------------------------------------------
  IF v_flag_bv = 'N'
  THEN
   FOR r_itens IN c_itens
   LOOP
    v_num_seq := v_num_seq + 1;
    --procura no campo OBS do faturamento pela tag <idnfe> que pode conter
    --o código de item já fornecido ao ADNNet por outro sistema, no caso
    --te ter havido um faturamento prévio deste item antes da substituição
    --do sistema pelo JobOne (somente para migração de saldos)
    --
    --Exemplo de observação válida:
    --somente para migração de saldos: <cditem>orc|001|0000000000013354</cditem>
    --Somente para migração de saldos: <idnfe>F|0012339|001|</idnfe>
    IF v_obs IS NOT NULL
    THEN
     SELECT substr(v_obs,
                   instr(v_obs, '<idnfe>') + 7,
                   instr(v_obs, '</idnfe>') - (instr(v_obs, '<idnfe>') + 7))
       INTO v_idnfe
       FROM dual;
    END IF;
    IF v_idnfe IS NULL OR v_obs IS NULL
    THEN
     IF r_itens.nota_fiscal_e_id = 0
     THEN
      v_idnfe := '';
      --informa que houve nota de entrada no item de A
      --e que o faturamento não foi antecipado
      v_flfat_antecipado := 'S';
     ELSE
      v_idnfe := r_itens.nota_fiscal_e_id;
      --informa que não houve nota de entrada no item de A
      --e que o faturamento foi antecipado
      v_flfat_antecipado := 'N';
     END IF;
    ELSE
     --informa que não houve nota de entrada no item de A
     --e que o faturamento foi antecipado
     v_flfat_antecipado := 'N';
    END IF;
    --procura no campo OBS do faturamento pela tag <cditem> que pode conter
    --o código de item já fornecido ao ADNNet por outro sistema, no caso
    --te ter havido um faturamento prévio deste item antes da substituição
    --do sistema pelo JobOne (somente para migração de saldos)
    --
    --Exemplo de observação válida:
    --somente para migração de saldos: <cditem>orc|001|0000000000013354</cditem>
    --Somente para migração de saldos: <idnfe>F|0012339|001|</idnfe>
    IF v_obs IS NOT NULL
    THEN
     SELECT substr(v_obs,
                   instr(v_obs, '<cditem>') + 8,
                   instr(v_obs, '</cditem>') - (instr(v_obs, '<cditem>') + 8))
       INTO v_cditem
       FROM dual;
    END IF;
    --se o cd_item não for encontrado ou OBS do item estiver nulo
    --então montar o código do item do JobOne normalmente
    IF v_cditem IS NULL OR v_obs IS NULL
    THEN
     v_cditem := to_char(v_num_job) || '-' || to_char(r_itens.num_orcamento) || '-' ||
                 r_itens.tipo_item || to_char(r_itens.num_seq);
    END IF;
    --
    --
    IF r_itens.tipo_item = 'Z'
    THEN
     -- valores agrupados nao mandam o codigo do item
     v_cditem := NULL;
    END IF;
    --
    IF r_itens.natureza_item = 'HONOR' OR v_flag_servico = 'S'
    THEN
     v_tpitem           := 'S';
     v_flfat_antecipado := '';
     v_cditem           := '';
    ELSE
     v_tpitem := 'R';
    END IF;
    --
    IF r_itens.natureza_item = 'ENCARGO'
    THEN
     v_cdmontante := 'E';
     v_tpitem     := 'R'; --ALCBBO_060825
    ELSIF r_itens.natureza_item = 'HONOR' OR v_flag_servico = 'S'
    THEN
     v_cdmontante := NULL;
    ELSE
     v_cdmontante := r_itens.tipo_item;
    END IF;
    --
    v_pccomissao_encargo      := 0;
    v_vlbase_comissao_encargo := 0;
    v_vlitem                  := r_itens.valor_fatura;
    --
    IF r_itens.natureza_item = 'HONOR'
    THEN
     v_tprepasse := 'N';
     --
     IF nvl(v_orcamento_id, 0) = nvl(v_orcam_aux_id, 0)
     THEN
      v_nome_item := 'Agenciamento/Custos do Projeto: ' || job_pkg.nome_retornar(v_job_id) ||
                     ' - Estimativa: ' || to_char(v_num_orcamento);
     ELSE
      v_nome_item := 'Agenciamento/Custos do Projeto: ' || job_pkg.nome_retornar(v_job_id) ||
                     ' - Múltiplas Estimativas';
     END IF;
     --
     SELECT round(nvl(MAX(natureza_item_pkg.valor_padrao_retornar('ORCAMENTO',
                                                                  oc.orcamento_id,
                                                                  'HONOR')),
                      0),
                  2)
       INTO v_pccomissao_encargo
       FROM item_fatur fa,
            item       it,
            orcamento  oc
      WHERE fa.faturamento_id = p_faturamento_id
        AND fa.item_id = it.item_id
        AND it.orcamento_id = oc.orcamento_id;
     --
     IF v_pccomissao_encargo > 0 AND v_pccomissao_encargo <= 100
     THEN
      v_vlbase_comissao_encargo := round(v_vlitem * 100 / v_pccomissao_encargo, 2);
     ELSE
      -- adota 10% como padrao (o honorario pode ter sido definido como indice)
      v_pccomissao_encargo      := 10;
      v_vlbase_comissao_encargo := round(v_vlitem * 100 / v_pccomissao_encargo, 2);
     END IF;
     --
    ELSIF r_itens.natureza_item = 'ENCARGO'
    THEN
     v_tprepasse := 'N';
     --
     IF nvl(v_orcamento_id, 0) = nvl(v_orcam_aux_id, 0)
     THEN
      v_nome_item := 'Encargos do Projeto: ' || job_pkg.nome_retornar(v_job_id) ||
                     ' - Estimativa: ' || to_char(v_num_orcamento);
     ELSE
      v_nome_item := 'Encargos do Projeto: ' || job_pkg.nome_retornar(v_job_id) ||
                     ' - Múltiplas Estimativas';
     END IF;
     --
     SELECT round(nvl(MAX(greatest(nvl(natureza_item_pkg.valor_padrao_retornar('ORCAMENTO',
                                                                               oc.orcamento_id,
                                                                               'ENCARGO'),
                                       0),
                                   nvl(natureza_item_pkg.valor_padrao_retornar('ORCAMENTO',
                                                                               oc.orcamento_id,
                                                                               'ENCARGO_HONOR'),
                                       0),
                                   nvl(natureza_item_pkg.valor_padrao_retornar('ORCAMENTO',
                                                                               oc.orcamento_id,
                                                                               'CPMF'),
                                       0))),
                      0),
                  2)
       INTO v_pccomissao_encargo
       FROM item_fatur fa,
            item       it,
            orcamento  oc
      WHERE fa.faturamento_id = p_faturamento_id
        AND fa.item_id = it.item_id
        AND it.orcamento_id = oc.orcamento_id;
     --
     IF v_pccomissao_encargo > 0 AND v_pccomissao_encargo <= 100
     THEN
      v_vlbase_comissao_encargo := round(v_vlitem * 100 / v_pccomissao_encargo, 2);
     ELSE
      -- adota 10% como padrao (o encargo pode ter sido definido como indice)
      v_pccomissao_encargo      := 10;
      v_vlbase_comissao_encargo := round(v_vlitem * 100 / v_pccomissao_encargo, 2);
     END IF;
    ELSE
     v_tprepasse := ' ';
     v_nome_item := r_itens.nome_item;
    END IF;
    --
    IF r_itens.tipo_item = 'A' AND r_itens.nota_fiscal_id IS NOT NULL
    THEN
     -- so manda NF de entrada para itens de A
     SELECT nf.emp_emissora_id,
            td.cod_ext_doc,
            nf.num_doc,
            nf.serie
       INTO v_fornecedor_id,
            v_tipo_doc,
            v_num_doc,
            v_serie
       FROM nota_fiscal nf,
            tipo_doc_nf td
      WHERE nf.nota_fiscal_id = r_itens.nota_fiscal_id
        AND nf.tipo_doc_nf_id = td.tipo_doc_nf_id;
     --ALCBO_190724
    ELSIF r_itens.nota_fiscal_e_id IS NOT NULL AND r_itens.nota_fiscal_e_id <> 0
    THEN
     SELECT serie
       INTO v_serie
       FROM nota_fiscal
      WHERE nota_fiscal_id = r_itens.nota_fiscal_e_id;
    ELSE
     v_fornecedor_id := NULL;
     v_tipo_doc      := NULL;
     v_num_doc       := NULL;
     v_serie         := NULL;
    END IF;
    --
    v_nome_item := substr(char_especial_retirar(v_nome_item), 1, 255);
    --
    SELECT xmlagg(xmlelement("itens",
                             xmlelement("noitem", to_char(v_num_seq)),
                             xmlelement("tpitem", v_tpitem),
                             xmlelement("tprepasse", v_tprepasse),
                             xmlelement("idnfe", v_idnfe), --identificação do check-in realizado previamente
                             xmlelement("cdmontante", v_cdmontante),
                             xmlelement("txitem", v_nome_item),
                             xmlelement("qtitem", '1'),
                             xmlelement("cdunidade", 'UN'),
                             xmlelement("vlbase_comissao_encargo",
                                        REPLACE(moeda_mostrar(v_vlbase_comissao_encargo, 'N'),
                                                ',',
                                                '.')),
                             xmlelement("pccomissao_encargo",
                                        REPLACE(taxa_mostrar(v_pccomissao_encargo), ',', '.')),
                             xmlelement("vlitem", REPLACE(moeda_mostrar(v_vlitem, 'N'), ',', '.')),
                             xmlelement("cdfornec", to_char(v_fornecedor_id)),
                             xmlelement("flfat_antecipado", v_flfat_antecipado), --S se não houve check-in; N se houve check-in
                             xmlelement("tpdoc", v_tipo_doc),
                             xmlelement("nonfiscal", char_especial_retirar(v_num_doc)),
                             xmlelement("cdserie", char_especial_retirar(v_serie)),
                             xmlelement("cditem", v_cditem), --sempre foi passado, agora pode conter código de migração de dados
                             xmlelement("noestimativa",
                                        to_char(zvl(r_itens.num_orcamento, v_num_orcamento)))))
      INTO v_xml_conteudo_itens_aux
      FROM dual;
    --
    SELECT xmlconcat(v_xml_conteudo_itens, v_xml_conteudo_itens_aux)
      INTO v_xml_conteudo_itens
      FROM dual;
    --
   --
   END LOOP;
  END IF;
  --
  ------------------------------------------------------------
  -- monta a secao "itens" - faturamento BV
  ------------------------------------------------------------
  IF v_flag_bv = 'S'
  THEN
   SELECT nvl(SUM(fa.valor_fatura), 0),
          MAX(fa.nota_fiscal_id)
     INTO v_vlitem,
          v_nota_fiscal_id
     FROM item_fatur fa,
          item       it
    WHERE fa.faturamento_id = p_faturamento_id
      AND fa.item_id = it.item_id;
   --
   IF v_nota_fiscal_id IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Erro na recuperação da nota fiscal de entrada ' ||
                  'associada ao faturamento do BV.';
    RAISE v_exception;
   END IF;
   --
   v_num_seq    := v_num_seq + 1;
   v_cditem     := NULL;
   v_tpitem     := 'S';
   v_cdmontante := NULL;
   --
   v_pccomissao_encargo      := 0;
   v_vlbase_comissao_encargo := 0;
   v_tprepasse               := ' ';
   --
   SELECT num_doc,
          serie
     INTO v_num_doc,
          v_serie
     FROM nota_fiscal
    WHERE nota_fiscal_id = v_nota_fiscal_id;
   --
   v_nome_item := TRIM('Nossos honorários sobre sua Nota Fiscal nro: ' || v_num_doc || ' ' ||
                       v_serie);
   --
   v_vlbase_comissao_encargo := v_vlitem;
   --
   v_fornecedor_id := NULL;
   v_tipo_doc      := NULL;
   v_num_doc       := NULL;
   v_serie         := NULL;
   --
   v_nome_item := substr(char_especial_retirar(v_nome_item), 1, 255);
   --
   SELECT xmlagg(xmlelement("itens",
                            xmlelement("noitem", to_char(v_num_seq)),
                            xmlelement("tpitem", v_tpitem),
                            xmlelement("tprepasse", v_tprepasse),
                            xmlelement("cdmontante", v_cdmontante),
                            xmlelement("txitem", v_nome_item),
                            xmlelement("qtitem", '1'),
                            xmlelement("cdunidade", 'UN'),
                            xmlelement("vlbase_comissao_encargo",
                                       REPLACE(moeda_mostrar(v_vlbase_comissao_encargo, 'N'),
                                               ',',
                                               '.')),
                            xmlelement("pccomissao_encargo",
                                       REPLACE(taxa_mostrar(v_pccomissao_encargo), ',', '.')),
                            xmlelement("vlitem", REPLACE(moeda_mostrar(v_vlitem, 'N'), ',', '.')),
                            xmlelement("cdfornec", to_char(v_fornecedor_id)),
                            xmlelement("tpdoc", v_tipo_doc),
                            xmlelement("nonfiscal", char_especial_retirar(v_num_doc)),
                            xmlelement("cdserie", char_especial_retirar(v_serie)),
                            xmlelement("cditem", v_cditem),
                            xmlelement("noestimativa", to_char(v_num_orcamento))))
     INTO v_xml_conteudo_itens_aux
     FROM dual;
   --
   SELECT xmlconcat(v_xml_conteudo_itens, v_xml_conteudo_itens_aux)
     INTO v_xml_conteudo_itens
     FROM dual;
  END IF;
  --
  ------------------------------------------------------------
  -- monta a secao "duplicatas"
  ------------------------------------------------------------
  IF v_flag_bv = 'N'
  THEN
   SELECT xmlagg(xmlelement("duplicatas",
                            xmlelement("noordem", '1'),
                            xmlelement("dtvencto", to_char(data_vencim, 'yyyy-mm-dd')),
                            xmlelement("vlduplicata",
                                       REPLACE(moeda_mostrar(v_valor_fatura, 'N'), ',', '.')),
                            xmlelement("cdagente_cobrador", TRIM(v_cod_banco_cobrador))))
     INTO v_xml_conteudo_dupli
     FROM faturamento
    WHERE faturamento_id = p_faturamento_id;
   --
  ELSE
   SELECT nvl(SUM(valor_duplicata), 0)
     INTO v_valor_duplicata_tot
     FROM duplicata
    WHERE nota_fiscal_id = v_nota_fiscal_id;
   --
   -- calcula o valor total do BV com base nas duplicatas, para ajustes de
   -- arredondamento.
   SELECT nvl(SUM(round(valor_duplicata / v_valor_duplicata_tot * v_valor_fatura, 2)), 0)
     INTO v_valor_bv_dup_tot
     FROM duplicata
    WHERE nota_fiscal_id = v_nota_fiscal_id;
   --
   v_valor_ajuste_bv := 0;
   --
   IF v_valor_bv_dup_tot <> v_valor_fatura
   THEN
    v_valor_ajuste_bv := v_valor_bv_dup_tot - v_valor_fatura;
   END IF;
   --
   FOR r_dup IN c_dup
   LOOP
    -- para BV, usa os vencimentos na nota fiscal do fornecedor como base
    -- para a ordem de faturamento.
    v_num_seq     := r_dup.num_parcela;
    v_data_vencim := r_dup.data_vencim + v_num_dias_bv;
    v_valor_bv    := 0;
    --
    -- o calculo do BV a ser faturado é proporcional ao valor
    -- da duplicata do fornecedor
    IF v_valor_duplicata_tot > 0
    THEN
     v_valor_bv := round(r_dup.valor_duplicata / v_valor_duplicata_tot * v_valor_fatura, 2);
    END IF;
    --
    IF v_num_seq = 1
    THEN
     v_valor_bv := v_valor_bv - v_valor_ajuste_bv;
    END IF;
    --ALCBO_220125
    IF v_bv_fatur_autom = 'N'
    THEN
     SELECT data_vencim
       INTO v_data_vencim
       FROM faturamento
      WHERE faturamento_id = p_faturamento_id;
    END IF;
    --
    SELECT xmlagg(xmlelement("duplicatas",
                             xmlelement("noordem", to_char(v_num_seq)),
                             xmlelement("dtvencto", to_char(v_data_vencim, 'yyyy-mm-dd')),
                             xmlelement("vlduplicata",
                                        REPLACE(moeda_mostrar(v_valor_bv, 'N'), ',', '.')),
                             xmlelement("cdagente_cobrador", TRIM(v_cod_banco_cobrador))))
      INTO v_xml_conteudo_dupli_aux
      FROM dual;
    --
    SELECT xmlconcat(v_xml_conteudo_dupli, v_xml_conteudo_dupli_aux)
      INTO v_xml_conteudo_dupli
      FROM dual;
   END LOOP;
  END IF;
  --
  --
  --ALCBO_240524
  ------------------------------------------------------------
  -- monta a secao "rateio"
  ------------------------------------------------------------
  --ALCBO_300824
  IF v_cod_sist_ext LIKE '%REDDOOR%'
  THEN
   FOR r_ra IN c_itens
   LOOP
    --ALCBO_230524 --ALCBO_090425
    SELECT COUNT(cp.nome_classe)
      INTO v_qt
      FROM tipo_produto tp
     INNER JOIN item it
        ON tp.tipo_produto_id = it.tipo_produto_id
      LEFT JOIN categoria ca
        ON tp.categoria_id = ca.categoria_id
      LEFT JOIN classe_produto cp
        ON cp.classe_produto_id = ca.classe_produto_id
     WHERE it.item_id = r_ra.item_id;
    --SE TIVER CLASSIFICACAO PRECISA ENVIAR A CLASSIF SE NAO VAI O JOB NO CHECKIN
    IF v_qt <> 0
    THEN
     --ALCBO_090425
     SELECT TRIM(cp.nome_classe || ' ' || cp.sub_classe)
       INTO v_cod_ext
       FROM tipo_produto tp
      INNER JOIN item it
         ON tp.tipo_produto_id = it.tipo_produto_id
       LEFT JOIN categoria ca
         ON tp.categoria_id = ca.categoria_id
       LEFT JOIN classe_produto cp
         ON cp.classe_produto_id = ca.classe_produto_id
      WHERE it.item_id = r_ra.item_id;
    ELSIF r_ra.natureza_item IN ('PLAN', 'ENCFI', 'HONOR', 'ENCARGO')
    THEN
     v_cod_ext := 'Corporativo';
    ELSE
     v_cod_ext := NULL; --TRIM(to_char(v_num_job));
    END IF;
    --
    IF v_flag_bv = 'N'
    THEN
     IF r_ra.natureza_item = 'ENCARGO'
     THEN
      v_cdmontante := 'E';
      v_tpitem     := 'R'; --ALCBO_060825
     ELSIF r_ra.natureza_item = 'HONOR' OR v_flag_servico = 'S'
     THEN
      v_cdmontante := NULL;
     ELSE
      v_cdmontante := r_ra.tipo_item;
     END IF;
    ELSE
     --v_flag_bv = 'S'
     v_cdmontante := NULL;
    END IF;
    --ALCBO_140725
    IF v_cod_ext LIKE '%Sist%'
    THEN
     v_cod_ext := 'Corporativo';
    END IF;
    --
    SELECT xmlagg(xmlelement("rateio",
                             xmlelement("montante", v_cdmontante),
                             xmlelement("noconta", v_cdconta_classificacao),
                             xmlelement("noccusto", NULL),
                             xmlelement("vlrateio",
                                        REPLACE(moeda_mostrar(r_ra.valor_fatura, 'N'), ',', '.')),
                             xmlelement("tpjob", v_cod_ext)))
      INTO v_xml_conteudo_rat_aux1
      FROM dual;
    --
    SELECT xmlconcat(v_xml_conteudo_rat, v_xml_conteudo_rat_aux1)
      INTO v_xml_conteudo_rat
      FROM dual;
   END LOOP;
   --Se Reddoor v_xml_conteudo_rat
   ------------------------------------------------------------
   -- finalizacao das secoes "conteudo" e "root"
   ------------------------------------------------------------
   SELECT xmlagg(xmlelement("root",
                            v_xml_conteudo_header,
                            v_xml_conteudo_itens,
                            v_xml_conteudo_dupli,
                            v_xml_conteudo_rat))
     INTO v_xml_conteudo
     FROM dual;
   --Se nao Reddoor tira v_xml_conteudo_rat
  ELSE
   ------------------------------------------------------------
   -- finalizacao das secoes "conteudo" e "root"
   ------------------------------------------------------------
   SELECT xmlagg(xmlelement("root",
                            v_xml_conteudo_header,
                            v_xml_conteudo_itens,
                            v_xml_conteudo_dupli))
     INTO v_xml_conteudo
     FROM dual;
  END IF;
  --
  SELECT xmlagg(xmlelement("conteudo", v_xml_conteudo))
    INTO v_xml_conteudo
    FROM dual;
  --
  ------------------------------------------------------------
  -- junta o cabecalho com o conteudo debaixo de "mensagem"
  ------------------------------------------------------------
  SELECT xmlagg(xmlelement("mensagem", v_xml_cabecalho, v_xml_conteudo))
    INTO v_xml_mensagem
    FROM dual;
  --
  -- acrescenta o tipo de documento
  SELECT v_xml_doc || v_xml_mensagem.getclobval()
    INTO v_xml_in
    FROM dual;
  --
  /*
  p_erro_cod := '90000';
  p_erro_msg := 'tamanho do XML:' || TO_CHAR(LENGTH(v_xml_in));
  RAISE v_exception;
  */
  --
  ------------------------------------------------------------
  -- chama a procedure de integracao
  ------------------------------------------------------------
  adnnet_executar(p_sistema_externo_id,
                  p_empresa_id,
                  'FATURAMENTO',
                  p_cod_acao,
                  p_faturamento_id,
                  v_xml_in,
                  v_xml_out,
                  p_erro_cod,
                  p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  IF p_cod_acao <> 'E'
  THEN
   -- recupera o codigo adn net da ordem de faturamento
   SELECT MAX(extractvalue(xml_out, '/mensagem/conteudo/root/noordem_adn'))
     INTO v_cod_obj_adnnet
     FROM (SELECT xmltype(v_xml_out) AS xml_out
             FROM dual);
   --
   IF v_cod_obj_adnnet IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Erro na recuperação do código ADN Net da ordem de faturamento.';
    RAISE v_exception;
   END IF;
   --
   UPDATE faturamento
      SET cod_ext_fatur = v_cod_obj_adnnet
    WHERE faturamento_id = p_faturamento_id;
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
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 2000) ||
                 ' - faturamento_integrar';
 END faturamento_integrar;
 --
 --
 --
 PROCEDURE faturamento_ctr_integrar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 30/06/2023
  -- DESCRICAO: Subrotina que gera o xml e processa a integracao de ordens de faturamento
  --   de *** CONTRATO ***
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_sistema_externo_id IN sistema_externo.sistema_externo_id%TYPE,
  p_empresa_id         IN empresa.empresa_id%TYPE,
  p_faturamento_ctr_id IN faturamento_ctr.faturamento_ctr_id%TYPE,
  p_cod_acao           IN VARCHAR2,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 ) IS
  v_qt                     INTEGER;
  v_exception              EXCEPTION;
  v_xml_doc                VARCHAR2(100);
  v_xml_cabecalho          xmltype;
  v_xml_conteudo           xmltype;
  v_xml_conteudo_header    xmltype;
  v_xml_conteudo_itens     xmltype;
  v_xml_conteudo_itens_aux xmltype;
  v_xml_conteudo_dupli     xmltype;
  v_xml_conteudo_dupli_aux xmltype;
  v_xml_mensagem           xmltype;
  v_xml_out                CLOB;
  v_xml_in                 CLOB;
  v_cidade                 pessoa.cidade%TYPE;
  v_uf                     pessoa.uf%TYPE;
  v_cod_banco_cobrador     fi_banco.codigo%TYPE;
  v_valor_fatura           NUMBER;
  v_num_contrato           contrato.numero%TYPE;
  v_num_contrato_adn       VARCHAR2(50);
  v_num_contrato_tela      VARCHAR2(50);
  v_num_seq                INTEGER;
  v_tpitem                 CHAR(1);
  v_tprepasse              CHAR(1);
  v_cdmontante             CHAR(1);
  v_cod_natureza_oper      faturamento_ctr.cod_natureza_oper%TYPE;
  v_descricao              faturamento_ctr.descricao%TYPE;
  v_emp_faturar_por_id     faturamento_ctr.emp_faturar_por_id%TYPE;
  v_data_ordem             faturamento_ctr.data_ordem%TYPE;
  v_emp_fatur_id           faturamento_ctr.emp_faturar_por_id%TYPE;
  v_data_vencim            duplicata.data_vencim%TYPE;
  v_cod_ext_fatur          empr_fatur_sist_ext.cod_ext_fatur%TYPE;
  v_valor_duplicata_tot    NUMBER;
  v_cod_obj_adnnet         VARCHAR2(20);
  v_cod_ext_tipo_ctr       tipo_contrato.cod_ext_tipo%TYPE;
  v_cod_sist_ext           sistema_externo.codigo%TYPE;
  --
 BEGIN
  v_qt      := 0;
  v_xml_doc := '<?xml version="1.0" encoding="ISO-8859-1" ?>';
  --
  ------------------------------------------------------------
  -- consistencias
  ------------------------------------------------------------
  IF TRIM(p_cod_acao) IS NULL OR p_cod_acao NOT IN ('I', 'E')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Código da ação inválido.';
   RAISE v_exception;
  END IF;
  --
  SELECT numero,
         contrato_pkg.numero_formatar(ct.contrato_id),
         tc.cod_ext_tipo,
         bc.codigo,
         pe.cidade,
         pe.uf,
         fa.emp_faturar_por_id,
         fa.cod_natureza_oper,
         fa.descricao,
         fa.emp_faturar_por_id,
         fa.data_ordem
    INTO v_num_contrato,
         v_num_contrato_tela,
         v_cod_ext_tipo_ctr,
         v_cod_banco_cobrador,
         v_cidade,
         v_uf,
         v_emp_fatur_id,
         v_cod_natureza_oper,
         v_descricao,
         v_emp_faturar_por_id,
         v_data_ordem
    FROM faturamento_ctr fa,
         contrato        ct,
         pessoa          pe,
         fi_banco        bc,
         tipo_contrato   tc
   WHERE fa.faturamento_ctr_id = p_faturamento_ctr_id
     AND fa.contrato_id = ct.contrato_id
     AND ct.tipo_contrato_id = tc.tipo_contrato_id
     AND fa.emp_faturar_por_id = pe.pessoa_id
     AND pe.fi_banco_id = bc.fi_banco_id(+);
  --
  SELECT codigo
    INTO v_cod_sist_ext
    FROM sistema_externo
   WHERE sistema_externo_id = p_sistema_externo_id;
  --
  -- verifica se o faturamento deve mesmo ser integrado a esse sistema externo,
  -- para essa empresa de faturamento (algumas nao tem integracao).
  SELECT MAX(cod_ext_fatur)
    INTO v_cod_ext_fatur
    FROM empr_fatur_sist_ext
   WHERE sistema_externo_id = p_sistema_externo_id
     AND pessoa_id = v_emp_faturar_por_id;
  --
  IF TRIM(v_cod_ext_fatur) IS NULL
  THEN
   p_erro_cod := '00000';
   p_erro_msg := 'Operação não se aplica.';
   RAISE v_exception;
  END IF;
  --
  v_cidade    := util_pkg.acento_municipio_retirar(v_cidade);
  v_cidade    := char_especial_retirar(v_cidade);
  v_descricao := char_especial_retirar(v_descricao);
  --
  SELECT nvl(SUM(valor_fatura), 0)
    INTO v_valor_fatura
    FROM parcela_fatur_ctr
   WHERE faturamento_ctr_id = p_faturamento_ctr_id;
  --
  ------------------------------------------------------------
  -- monta a secao "cabecalho"
  ------------------------------------------------------------
  xml_cabecalho_gerar(p_sistema_externo_id,
                      p_empresa_id,
                      'ORDEM_FATURA',
                      p_faturamento_ctr_id,
                      v_xml_cabecalho,
                      p_erro_cod,
                      p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  -- se a data da ordem for muito antiga, o ADN nao aceita
  IF v_data_ordem <= trunc(SYSDATE) - 60
  THEN
   v_data_ordem := trunc(SYSDATE) - 59;
  END IF;
  --
  -- soma 5000000 para diferenciar do nro do job
  v_num_contrato_adn := to_char(v_num_contrato + 5000000);
  --
  ------------------------------------------------------------
  -- inicio da secao "conteudo"
  ------------------------------------------------------------
  SELECT xmlconcat(xmlelement("noordem", TRIM(to_char(fa.faturamento_ctr_id))),
                   xmlelement("dtordem", to_char(v_data_ordem, 'yyyy-mm-dd')),
                   xmlelement("cdempresa", TRIM(v_cod_ext_fatur)),
                   xmlelement("cdnatureza_operacao", v_cod_natureza_oper),
                   xmlelement("nojob", TRIM(v_num_contrato_adn)),
                   xmlelement("tpjob", v_cod_ext_tipo_ctr),
                   xmlelement("cdcliente", TRIM(to_char(fa.cliente_id))),
                   --XMLElement("cdcfo",'9999'),
                   xmlelement("vlcontabil", REPLACE(moeda_mostrar(v_valor_fatura, 'N'), ',', '.')),
                   xmlelement("txobs", nvl(substr(v_descricao, 1, 255), v_num_contrato)),
                   xmlelement("sguf", v_uf),
                   xmlelement("nmmunicipio", v_cidade))
    INTO v_xml_conteudo_header
    FROM faturamento_ctr fa
   WHERE fa.faturamento_ctr_id = p_faturamento_ctr_id;
  --
  ------------------------------------------------------------
  -- monta a secao "itens"
  ------------------------------------------------------------
  v_num_seq    := 1;
  v_tpitem     := 'S';
  v_cdmontante := NULL;
  v_tprepasse  := 'N';
  --
  SELECT xmlagg(xmlelement("itens",
                           xmlelement("noitem", to_char(v_num_seq)),
                           xmlelement("tpitem", v_tpitem),
                           xmlelement("tprepasse", v_tprepasse),
                           xmlelement("cdmontante", v_cdmontante),
                           xmlelement("txitem", 'Parcelas do contrato ' || v_num_contrato_tela),
                           xmlelement("qtitem", '1'),
                           xmlelement("cdunidade", 'UN'),
                           xmlelement("vlbase_comissao_encargo", '0'),
                           xmlelement("pccomissao_encargo", '0'),
                           xmlelement("vlitem",
                                      REPLACE(moeda_mostrar(v_valor_fatura, 'N'), ',', '.')),
                           xmlelement("cdfornec", ''),
                           xmlelement("tpdoc", ''),
                           xmlelement("nonfiscal", ''),
                           xmlelement("cdserie", ''),
                           xmlelement("cditem", ''),
                           xmlelement("noestimativa", to_char(v_num_contrato_adn) || '/1')))
    INTO v_xml_conteudo_itens_aux
    FROM dual;
  --
  SELECT xmlconcat(v_xml_conteudo_itens, v_xml_conteudo_itens_aux)
    INTO v_xml_conteudo_itens
    FROM dual;
  --
  ------------------------------------------------------------
  -- monta a secao "duplicatas"
  ------------------------------------------------------------
  SELECT xmlagg(xmlelement("duplicatas",
                           xmlelement("noordem", '1'),
                           xmlelement("dtvencto", to_char(data_vencim, 'yyyy-mm-dd')),
                           xmlelement("vlduplicata",
                                      REPLACE(moeda_mostrar(v_valor_fatura, 'N'), ',', '.')),
                           xmlelement("cdagente_cobrador", TRIM(v_cod_banco_cobrador))))
    INTO v_xml_conteudo_dupli
    FROM faturamento_ctr
   WHERE faturamento_ctr_id = p_faturamento_ctr_id;
  --
  ------------------------------------------------------------
  -- finalizacao das secoes "conteudo" e "root"
  ------------------------------------------------------------
  SELECT xmlagg(xmlelement("root",
                           v_xml_conteudo_header,
                           v_xml_conteudo_itens,
                           v_xml_conteudo_dupli))
    INTO v_xml_conteudo
    FROM dual;
  --
  SELECT xmlagg(xmlelement("conteudo", v_xml_conteudo))
    INTO v_xml_conteudo
    FROM dual;
  --
  ------------------------------------------------------------
  -- junta o cabecalho com o conteudo debaixo de "mensagem"
  ------------------------------------------------------------
  SELECT xmlagg(xmlelement("mensagem", v_xml_cabecalho, v_xml_conteudo))
    INTO v_xml_mensagem
    FROM dual;
  --
  -- acrescenta o tipo de documento
  SELECT v_xml_doc || v_xml_mensagem.getclobval()
    INTO v_xml_in
    FROM dual;
  --
  ------------------------------------------------------------
  -- chama a procedure de integracao
  ------------------------------------------------------------
  adnnet_executar(p_sistema_externo_id,
                  p_empresa_id,
                  'FATURAMENTO',
                  p_cod_acao,
                  p_faturamento_ctr_id,
                  v_xml_in,
                  v_xml_out,
                  p_erro_cod,
                  p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  IF p_cod_acao <> 'E'
  THEN
   -- recupera o codigo adn net da ordem de faturamento
   SELECT MAX(extractvalue(xml_out, '/mensagem/conteudo/root/noordem_adn'))
     INTO v_cod_obj_adnnet
     FROM (SELECT xmltype(v_xml_out) AS xml_out
             FROM dual);
   --
   IF v_cod_obj_adnnet IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Erro na recuperação do código ADN Net da ordem de faturamento.';
    RAISE v_exception;
   END IF;
   --
   UPDATE faturamento_ctr
      SET cod_ext_fatur = v_cod_obj_adnnet
    WHERE faturamento_ctr_id = p_faturamento_ctr_id;
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
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 2000) ||
                 ' - faturamento_integrar';
 END faturamento_ctr_integrar;
 --
 --
 --
 PROCEDURE ordem_fatura_processar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 23/07/2007
  -- DESCRICAO: Procedure que trata o retorno de informacoes do ADN Net referentes a
  --  ordem de faturamento (Efetivação, Cancelamento).
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            12/12/2007  Nova tag retornada cdcliente
  -- Silvia            14/08/2008  Retirada de consistencia de alteracao de empresa de
  --                               faturamento.
  -- Silvia            07/08/2012  Consistencia do valor retornado na NF de saida (deve ser
  --                               igual ao da ordem de faturamento enviada).
  -- Silvia            20/03/2013  No retorno da NF de saida, se o pessoa_id retornado nao
  --                               pertencer a empresa do job, procura o pessoa_id correto
  --                               pelo CNPJ.
  -- Silvia            20/12/2013  Retirada da consistencia de valor da NF de saida.
  -- Silvia            23/11/2016  Grava no log o XML recebido (alteracao ainda nao liberada).
  -- Silvia            04/09/2020  No cancelamento da NF, exclui tb a ordem de faturamento.
  -- Silvia            07/08/2023  Recebimento de NFS de contrato.
  ------------------------------------------------------------------------------------------
 (
  p_cod_acao IN VARCHAR2,
  p_xml_in   IN CLOB,
  p_xml_out  OUT CLOB,
  p_erro_cod OUT VARCHAR2,
  p_erro_msg OUT VARCHAR2
 ) IS
  v_qt                  INTEGER;
  v_exception           EXCEPTION;
  v_xml_in              xmltype;
  v_sistema             VARCHAR2(40);
  v_processo            VARCHAR2(40);
  v_identidade          VARCHAR2(20);
  v_noordem             VARCHAR2(20);
  v_cdempresa           VARCHAR2(20);
  v_vlcontabil          VARCHAR2(20);
  v_tpdoc               VARCHAR2(20);
  v_nodoc               VARCHAR2(20);
  v_cdserie             VARCHAR2(20);
  v_dtemissao           VARCHAR2(20);
  v_txobs               VARCHAR2(4000);
  v_job_id              job.job_id%TYPE;
  v_nota_fiscal_sai_id  nota_fiscal.nota_fiscal_id%TYPE;
  v_data_emissao        nota_fiscal.data_emissao%TYPE;
  v_valor_bruto         nota_fiscal.valor_bruto%TYPE;
  v_tipo_doc_nf_id      nota_fiscal.tipo_doc_nf_id%TYPE;
  v_faturamento_id      faturamento.faturamento_id%TYPE;
  v_data_ordem          faturamento.data_ordem%TYPE;
  v_emp_faturar_por_id  faturamento.emp_faturar_por_id%TYPE;
  v_emp_faturar_por_xml faturamento.emp_faturar_por_id%TYPE;
  v_cod_natureza_oper   faturamento.cod_natureza_oper%TYPE;
  v_cliente_id          faturamento.cliente_id%TYPE;
  v_cdcliente           VARCHAR2(20);
  v_valor_fatura        NUMBER;
  v_cdimposto           VARCHAR2(20);
  v_vlbase_imposto      VARCHAR2(20);
  v_pcaliquota          VARCHAR2(20);
  v_vlimposto           VARCHAR2(20);
  v_cdretencao          VARCHAR2(20);
  v_fi_tipo_imposto_id  imposto_nota.fi_tipo_imposto_id%TYPE;
  v_num_seq             imposto_nota.num_seq%TYPE;
  v_valor_base_calc     imposto_nota.valor_base_calc%TYPE;
  v_perc_imposto_nota   imposto_nota.perc_imposto_nota%TYPE;
  v_valor_imposto       imposto_nota.valor_imposto%TYPE;
  v_noordem_dup         VARCHAR2(20);
  v_dtvencto            VARCHAR2(20);
  v_vlduplicata         VARCHAR2(20);
  v_cdagente_cobrador   VARCHAR2(20);
  v_data_vencim         duplicata.data_vencim%TYPE;
  v_valor_duplicata     duplicata.valor_duplicata%TYPE;
  v_num_parcela         duplicata.num_parcela%TYPE;
  v_fi_banco_id         fi_banco.fi_banco_id%TYPE;
  v_empresa_id          empresa.empresa_id%TYPE;
  v_pessoa_id_aux       pessoa.pessoa_id%TYPE;
  v_cnpj                pessoa.cnpj%TYPE;
  v_xml_log_id          xml_log.xml_log_id%TYPE;
  v_usuario_admin_id    usuario.usuario_id%TYPE;
  v_contrato_id         contrato.contrato_id%TYPE;
  v_tipo_fat            VARCHAR2(20);
  --
  CURSOR c_imp IS
   SELECT extractvalue(VALUE(impostos), '/impostos/cdimposto') cdimposto,
          extractvalue(VALUE(impostos), '/impostos/vlbase_imposto') vlbase_imposto,
          extractvalue(VALUE(impostos), '/impostos/pcaliquota') pcaliquota,
          extractvalue(VALUE(impostos), '/impostos/vlimposto') vlimposto,
          extractvalue(VALUE(impostos), '/impostos/cdretencao') cdretencao
     FROM TABLE(xmlsequence(extract(v_xml_in, '/mensagem/conteudo/root/impostos'))) impostos;
  --
  CURSOR c_dup IS
   SELECT extractvalue(VALUE(duplicatas), '/duplicatas/noordem') noordem,
          extractvalue(VALUE(duplicatas), '/duplicatas/dtvencto') dtvencto,
          extractvalue(VALUE(duplicatas), '/duplicatas/vlduplicata') vlduplicata,
          extractvalue(VALUE(duplicatas), '/duplicatas/cdagente_cobrador') cdagente_cobrador
     FROM TABLE(xmlsequence(extract(v_xml_in, '/mensagem/conteudo/root/duplicatas'))) duplicatas;
  --
 BEGIN
  v_qt       := 0;
  p_erro_msg := NULL;
  --
  SELECT MAX(usuario_id)
    INTO v_usuario_admin_id
    FROM usuario
   WHERE flag_admin_sistema = 'S';
  --
  ------------------------------------------------------------
  -- consistencias do XML
  ------------------------------------------------------------
  IF TRIM(p_cod_acao) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O código da ação não foi fornecido.';
   RAISE v_exception;
  END IF;
  --
  IF p_cod_acao NOT IN ('EFETIVAR', 'CANCELAR')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O código da ação inválido (' || p_cod_acao || ').';
   RAISE v_exception;
  END IF;
  --
  SELECT xmltype(TRIM(p_xml_in))
    INTO v_xml_in
    FROM dual;
  --
  /*
    SELECT seq_xml_log.NEXTVAL
      INTO v_xml_log_id
      FROM dual;
  --
    log_chegada_gravar(v_xml_log_id, 'NF_SAIDA', p_cod_acao, p_xml_in, 'S');
  */
  --
  SELECT extractvalue(v_xml_in, '/mensagem/cabecalho/sistema'),
         extractvalue(v_xml_in, '/mensagem/cabecalho/processo'),
         extractvalue(v_xml_in, '/mensagem/cabecalho/identidade'),
         extractvalue(v_xml_in, '/mensagem/conteudo/root/noordem'),
         extractvalue(v_xml_in, '/mensagem/conteudo/root/cdcliente'),
         extractvalue(v_xml_in, '/mensagem/conteudo/root/cdempresa')
    INTO v_sistema,
         v_processo,
         v_identidade,
         v_noordem,
         v_cdcliente,
         v_cdempresa
    FROM dual;
  --
  IF v_sistema IS NULL OR v_sistema <> 'ADNNET'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Código do sistema inválido (' || v_sistema || ').';
   RAISE v_exception;
  END IF;
  --
  IF v_processo IS NULL OR v_processo <> 'ORDEM_FATURA'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Código do processo inválido (' || v_processo || ').';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(v_identidade) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da identidade é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(nvl(v_identidade, 'XXX')) <> TRIM(nvl(v_noordem, 'XXX'))
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A identidade (' || v_identidade ||
                 ') deve ser igual ao número da ordem de faturamento (' || v_noordem || ').';
   RAISE v_exception;
  END IF;
  --
  IF inteiro_validar(v_noordem) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Número da ordem de faturamento inválido (' || v_noordem || ').';
   RAISE v_exception;
  END IF;
  --
  v_faturamento_id := to_number(v_noordem);
  v_tipo_fat       := 'JOB';
  --
  -- testa se eh faturamento de job
  SELECT COUNT(*)
    INTO v_qt
    FROM faturamento
   WHERE faturamento_id = v_faturamento_id;
  --
  IF v_qt = 0
  THEN
   -- testa se eh faturamento de contrato
   SELECT COUNT(*)
     INTO v_qt
     FROM faturamento_ctr
    WHERE faturamento_ctr_id = v_faturamento_id;
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Essa ordem de faturamento não existe (' || v_noordem || ').';
    RAISE v_exception;
   ELSE
    v_tipo_fat := 'CONTRATO';
   END IF;
  END IF;
  --
  IF v_tipo_fat = 'JOB'
  THEN
   SELECT fa.data_ordem,
          fa.emp_faturar_por_id,
          fa.nota_fiscal_sai_id,
          fa.job_id,
          fa.cod_natureza_oper,
          jo.empresa_id
     INTO v_data_ordem,
          v_emp_faturar_por_id,
          v_nota_fiscal_sai_id,
          v_job_id,
          v_cod_natureza_oper,
          v_empresa_id
     FROM faturamento fa,
          job         jo
    WHERE fa.faturamento_id = v_faturamento_id
      AND fa.job_id = jo.job_id;
  ELSIF v_tipo_fat = 'CONTRATO'
  THEN
   SELECT fa.data_ordem,
          fa.emp_faturar_por_id,
          fa.nota_fiscal_sai_id,
          fa.contrato_id,
          fa.cod_natureza_oper,
          ct.empresa_id
     INTO v_data_ordem,
          v_emp_faturar_por_id,
          v_nota_fiscal_sai_id,
          v_contrato_id,
          v_cod_natureza_oper,
          v_empresa_id
     FROM faturamento_ctr fa,
          contrato        ct
    WHERE fa.faturamento_ctr_id = v_faturamento_id
      AND fa.contrato_id = ct.contrato_id;
  END IF;
  --
  IF TRIM(v_cdempresa) IS NULL OR inteiro_validar(v_cdempresa) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Código da empresa de faturamento inválido (' || v_cdempresa || ').';
   RAISE v_exception;
  END IF;
  --
  v_emp_faturar_por_xml := to_number(v_cdempresa);
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM pessoa
   WHERE pessoa_id = v_emp_faturar_por_xml
     AND empresa_id = v_empresa_id;
  --
  IF v_qt = 0
  THEN
   -- procura pelo CNPJ da empresa
   SELECT MAX(cnpj)
     INTO v_cnpj
     FROM pessoa
    WHERE pessoa_id = v_emp_faturar_por_xml;
   --
   IF v_cnpj IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Essa empresa de faturamento não existe ou não pertence à empresa do job (' ||
                  to_char(v_emp_faturar_por_xml) || ').';
    RAISE v_exception;
   END IF;
   --
   -- procura pelo pessoa_id na empresa correta
   SELECT MAX(pessoa_id)
     INTO v_pessoa_id_aux
     FROM pessoa
    WHERE cnpj = v_cnpj
      AND empresa_id = v_empresa_id;
   --
   IF v_pessoa_id_aux IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Essa empresa de faturamento não existe ou não pertence à empresa do job (' ||
                  to_char(v_emp_faturar_por_xml) || ').';
    RAISE v_exception;
   END IF;
   --
   -- corrige o pessoa_id recebido
   v_emp_faturar_por_xml := v_pessoa_id_aux;
  END IF;
  --
  IF v_tipo_fat = 'JOB'
  THEN
   SELECT nvl(SUM(valor_fatura), 0)
     INTO v_valor_fatura
     FROM item_fatur
    WHERE faturamento_id = v_faturamento_id;
  ELSIF v_tipo_fat = 'CONTRATO'
  THEN
   SELECT nvl(SUM(valor_fatura), 0)
     INTO v_valor_fatura
     FROM parcela_fatur_ctr
    WHERE faturamento_ctr_id = v_faturamento_id;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco - CANCELAMENTO
  ------------------------------------------------------------
  IF p_cod_acao = 'CANCELAR'
  THEN
   IF v_nota_fiscal_sai_id IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Essa ordem de faturamento não foi efetivada (' || to_char(v_faturamento_id) || ').';
    RAISE v_exception;
   END IF;
   --
   -- NF da prefeitura cancelada. Tem que excluir tbm a ordem de
   -- faturamento do JobOne pois o ADN tbm cancela essa ordem.
   IF v_tipo_fat = 'JOB'
   THEN
    UPDATE faturamento
       SET nota_fiscal_sai_id = NULL,
           cod_ext_fatur      = NULL
     WHERE faturamento_id = v_faturamento_id;
   ELSIF v_tipo_fat = 'CONTRATO'
   THEN
    UPDATE faturamento_ctr
       SET nota_fiscal_sai_id = NULL,
           cod_ext_fatur      = NULL
     WHERE faturamento_ctr_id = v_faturamento_id;
   END IF;
   --
   DELETE FROM duplicata
    WHERE nota_fiscal_id = v_nota_fiscal_sai_id;
   --
   DELETE FROM imposto_nota
    WHERE nota_fiscal_id = v_nota_fiscal_sai_id;
   --
   DELETE FROM item_nota
    WHERE nota_fiscal_id = v_nota_fiscal_sai_id;
   --
   DELETE FROM nota_fiscal
    WHERE nota_fiscal_id = v_nota_fiscal_sai_id;
   --
   -- exclusao da respectiva ordem de faturamento
   IF v_tipo_fat = 'JOB'
   THEN
    faturamento_pkg.excluir(v_usuario_admin_id,
                            v_empresa_id,
                            'N',
                            v_faturamento_id,
                            p_erro_cod,
                            p_erro_msg);
    --
    IF p_erro_cod <> '00000'
    THEN
     RAISE v_exception;
    END IF;
   ELSIF v_tipo_fat = 'CONTRATO'
   THEN
    faturamento_ctr_pkg.excluir(v_usuario_admin_id,
                                v_empresa_id,
                                'N',
                                v_faturamento_id,
                                p_erro_cod,
                                p_erro_msg);
    --
    IF p_erro_cod <> '00000'
    THEN
     RAISE v_exception;
    END IF;
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco - EFETIVACAO
  ------------------------------------------------------------
  IF p_cod_acao = 'EFETIVAR'
  THEN
   --
   SELECT extractvalue(v_xml_in, '/mensagem/conteudo/root/nota_fiscal/tpdoc'),
          extractvalue(v_xml_in, '/mensagem/conteudo/root/nota_fiscal/nodoc'),
          extractvalue(v_xml_in, '/mensagem/conteudo/root/nota_fiscal/cdserie'),
          extractvalue(v_xml_in, '/mensagem/conteudo/root/nota_fiscal/dtemissao'),
          extractvalue(v_xml_in, '/mensagem/conteudo/root/nota_fiscal/vlcontabil'),
          extractvalue(v_xml_in, '/mensagem/conteudo/root/nota_fiscal/txobs')
     INTO v_tpdoc,
          v_nodoc,
          v_cdserie,
          v_dtemissao,
          v_vlcontabil,
          v_txobs
     FROM dual;
   --
   SELECT MAX(tipo_doc_nf_id)
     INTO v_tipo_doc_nf_id
     FROM tipo_doc_nf
    WHERE codigo = v_tpdoc
      AND flag_nf_saida = 'S';
   --
   IF TRIM(v_tpdoc) IS NULL OR v_tipo_doc_nf_id IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Tipo de documento inválido (' || v_tpdoc || ').';
    RAISE v_exception;
   END IF;
   --
   IF TRIM(v_nodoc) IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O preenchimento do número do documento é obrigatório.';
    RAISE v_exception;
   END IF;
   --
   IF TRIM(v_dtemissao) IS NULL OR data_adn_validar(v_dtemissao) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Data de emissão inválida (' || v_dtemissao || ').';
    RAISE v_exception;
   END IF;
   --
   IF TRIM(v_vlcontabil) IS NULL OR numero_adn_validar(v_vlcontabil) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Valor do documento inválido (' || v_vlcontabil || ').';
    RAISE v_exception;
   END IF;
   --
   IF inteiro_validar(v_cdcliente) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Código do cliente inválido (' || v_cdcliente || ').';
    RAISE v_exception;
   END IF;
   --
   v_cliente_id := to_number(v_cdcliente);
   --
   IF v_cliente_id IS NOT NULL
   THEN
    SELECT COUNT(*)
      INTO v_qt
      FROM pessoa
     WHERE pessoa_id = v_cliente_id
       AND empresa_id = v_empresa_id;
    --
    IF v_qt = 0
    THEN
     -- procura pelo CNPJ da empresa
     SELECT MAX(cnpj)
       INTO v_cnpj
       FROM pessoa
      WHERE pessoa_id = v_cliente_id;
     --
     IF v_cnpj IS NULL
     THEN
      p_erro_cod := '90000';
      p_erro_msg := 'Esse cliente não existe ou não pertence à empresa do job (' ||
                    to_char(v_cliente_id) || ').';
      RAISE v_exception;
     END IF;
     --
     -- procura pelo pessoa_id na empresa correta
     SELECT MAX(pessoa_id)
       INTO v_pessoa_id_aux
       FROM pessoa
      WHERE cnpj = v_cnpj
        AND empresa_id = v_empresa_id;
     --
     IF v_pessoa_id_aux IS NULL
     THEN
      p_erro_cod := '90000';
      p_erro_msg := 'Esse cliente não existe ou não pertence à empresa do job (' ||
                    to_char(v_cliente_id) || ').';
      RAISE v_exception;
     END IF;
     --
     -- corrige o pessoa_id recebido
     v_cliente_id := v_pessoa_id_aux;
    END IF;
   END IF;
   --
   v_data_emissao := data_adn_converter(v_dtemissao);
   v_valor_bruto  := round(numero_adn_converter(v_vlcontabil), 2);
   --
   IF nvl(v_valor_bruto, 0) > v_valor_fatura
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O valor da Nota Fiscal de Saída não pode ser maior que o valor da ordem ' ||
                  'de faturamento (NF saída: ' || moeda_mostrar(v_valor_bruto, 'S') ||
                  ' ; Ordem Faturamento: ' || moeda_mostrar(v_valor_fatura, 'S') || ').';
    RAISE v_exception;
   END IF;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM nota_fiscal nf,
          tipo_doc_nf td
    WHERE nf.emp_emissora_id = v_emp_faturar_por_xml
      AND nf.tipo_doc_nf_id = td.tipo_doc_nf_id
      AND td.codigo = v_tpdoc
      AND nf.num_doc = TRIM(v_nodoc)
      AND nvl(nf.serie, 'XXX') = nvl(TRIM(v_cdserie), 'XXX');
   --
   IF v_qt > 0 AND v_nota_fiscal_sai_id IS NULL
   THEN
    -- a NF de saida enviada ja existe e
    -- a ordem de faturamento nao tem nota associada (nao foi emitida).
    p_erro_cod := '90000';
    p_erro_msg := 'Esse documento já existe (' || to_char(v_emp_faturar_por_xml) || ' ' ||
                  TRIM(v_tpdoc || ' ' || v_nodoc || ' ' || v_cdserie) || ').';
    RAISE v_exception;
   END IF;
   --
   IF v_nota_fiscal_sai_id IS NOT NULL
   THEN
    -- a NFS antiga vai ser excluida para entrar a nova
    IF v_tipo_fat = 'JOB'
    THEN
     UPDATE faturamento
        SET nota_fiscal_sai_id = NULL
      WHERE faturamento_id = v_faturamento_id;
    ELSIF v_tipo_fat = 'CONTRATO'
    THEN
     UPDATE faturamento_ctr
        SET nota_fiscal_sai_id = NULL
      WHERE faturamento_ctr_id = v_faturamento_id;
    END IF;
    --
    DELETE FROM item_nota
     WHERE nota_fiscal_id = v_nota_fiscal_sai_id;
    DELETE FROM duplicata
     WHERE nota_fiscal_id = v_nota_fiscal_sai_id;
    DELETE FROM imposto_nota
     WHERE nota_fiscal_id = v_nota_fiscal_sai_id;
    DELETE FROM nota_fiscal
     WHERE nota_fiscal_id = v_nota_fiscal_sai_id;
   END IF;
   --
   SELECT seq_nota_fiscal.nextval
     INTO v_nota_fiscal_sai_id
     FROM dual;
   --
   -- o job_id vai ficar NULL em caso de contrato
   INSERT INTO nota_fiscal
    (nota_fiscal_id,
     emp_emissora_id,
     cliente_id,
     job_id,
     tipo_ent_sai,
     tipo_doc_nf_id,
     num_doc,
     serie,
     data_entrada,
     data_emissao,
     valor_bruto,
     valor_mao_obra,
     desc_servico,
     status)
   VALUES
    (v_nota_fiscal_sai_id,
     v_emp_faturar_por_xml,
     v_cliente_id,
     v_job_id,
     'S',
     v_tipo_doc_nf_id,
     TRIM(v_nodoc),
     TRIM(v_cdserie),
     NULL,
     v_data_emissao,
     v_valor_bruto,
     0,
     substr(TRIM(v_txobs), 1, 2000),
     'CONC');
   --
   ----------------------------------
   -- tratamento dos impostos
   ----------------------------------
   v_num_seq := 0;
   --
   FOR r_imp IN c_imp
   LOOP
    v_cdimposto      := r_imp.cdimposto;
    v_vlbase_imposto := r_imp.vlbase_imposto;
    v_pcaliquota     := r_imp.pcaliquota;
    v_vlimposto      := r_imp.vlimposto;
    v_cdretencao     := r_imp.cdretencao;
    --
    SELECT MAX(fi_tipo_imposto_id)
      INTO v_fi_tipo_imposto_id
      FROM fi_tipo_imposto
     WHERE flag_incide_sai = 'S'
       AND cod_imposto = v_cdimposto;
    --
    IF v_fi_tipo_imposto_id IS NULL
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Código do imposto inválido(' || v_cdimposto || ').';
     RAISE v_exception;
    END IF;
    --
    IF TRIM(v_vlbase_imposto) IS NULL OR numero_adn_validar(v_vlbase_imposto) = 0
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Valor base do imposto ' || v_cdimposto || ' inválido (' || v_vlbase_imposto || ').';
     RAISE v_exception;
    END IF;
    --
    IF TRIM(v_pcaliquota) IS NULL OR numero_adn_validar(v_pcaliquota) = 0
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Percentual da alíquota do imposto ' || v_cdimposto || ' inválido (' ||
                   v_pcaliquota || ').';
     RAISE v_exception;
    END IF;
    --
    IF TRIM(v_vlimposto) IS NULL OR numero_adn_validar(v_vlimposto) = 0
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Valor do imposto ' || v_cdimposto || ' inválido (' || v_vlimposto || ').';
     RAISE v_exception;
    END IF;
    --
    v_valor_base_calc   := round(numero_adn_converter(v_vlbase_imposto), 2);
    v_perc_imposto_nota := round(numero_adn_converter(v_pcaliquota), 2);
    v_valor_imposto     := round(numero_adn_converter(v_vlimposto), 2);
    --
    v_num_seq := v_num_seq + 1;
    --
    INSERT INTO imposto_nota
     (imposto_nota_id,
      nota_fiscal_id,
      fi_tipo_imposto_id,
      num_seq,
      valor_base_calc,
      perc_imposto_sugerido,
      perc_imposto_nota,
      valor_imposto_base,
      valor_imposto,
      cod_retencao,
      flag_reter,
      valor_tributado,
      valor_deducao,
      valor_imposto_acum)
    VALUES
     (seq_imposto_nota.nextval,
      v_nota_fiscal_sai_id,
      v_fi_tipo_imposto_id,
      v_num_seq,
      v_valor_base_calc,
      v_perc_imposto_nota,
      v_perc_imposto_nota,
      v_valor_imposto,
      v_valor_imposto,
      v_cdretencao,
      'S',
      0,
      0,
      0);
   END LOOP;
   --
   ----------------------------------
   -- tratamento das duplicatas
   ----------------------------------
   v_num_parcela := 0;
   --
   FOR r_dup IN c_dup
   LOOP
    v_noordem_dup       := r_dup.noordem;
    v_dtvencto          := r_dup.dtvencto;
    v_vlduplicata       := r_dup.vlduplicata;
    v_cdagente_cobrador := r_dup.cdagente_cobrador;
    --
    IF TRIM(v_dtvencto) IS NULL OR data_adn_validar(v_dtvencto) = 0
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Data de vencimento da duplicata inválida (' || v_dtvencto || ').';
     RAISE v_exception;
    END IF;
    --
    IF TRIM(v_vlduplicata) IS NULL OR numero_adn_validar(v_vlduplicata) = 0
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Valor da duplicata inválido (' || v_vlduplicata || ').';
     RAISE v_exception;
    END IF;
    --
    IF TRIM(v_cdagente_cobrador) IS NOT NULL
    THEN
     SELECT MAX(fi_banco_id)
       INTO v_fi_banco_id
       FROM fi_banco
      WHERE codigo = v_cdagente_cobrador;
     --
     IF v_fi_banco_id IS NULL
     THEN
      p_erro_cod := '90000';
      p_erro_msg := 'Agente cobrador inválido ou não cadastrado (' || v_cdagente_cobrador || ').';
      RAISE v_exception;
     END IF;
    END IF;
    --
    v_num_parcela     := v_num_parcela + 1;
    v_data_vencim     := data_adn_converter(v_dtvencto);
    v_valor_duplicata := round(numero_adn_converter(v_vlduplicata), 2);
    --
    SELECT COUNT(*)
      INTO v_qt
      FROM duplicata
     WHERE nota_fiscal_id = v_nota_fiscal_sai_id
       AND data_vencim = v_data_vencim;
    --
    IF v_qt > 0
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Existem duplicatas com a mesma data de vencimento (' ||
                   data_mostrar(v_data_vencim) || ').';
     RAISE v_exception;
    END IF;
    --
    INSERT INTO duplicata
     (duplicata_id,
      nota_fiscal_id,
      num_parcela,
      num_tot_parcelas,
      num_duplicata,
      valor_duplicata,
      data_vencim)
    VALUES
     (seq_duplicata.nextval,
      v_nota_fiscal_sai_id,
      v_num_parcela,
      0,
      v_noordem_dup,
      v_valor_duplicata,
      v_data_vencim);
   END LOOP;
   --
   IF v_num_parcela > 0
   THEN
    UPDATE duplicata
       SET num_tot_parcelas = v_num_parcela
     WHERE nota_fiscal_id = v_nota_fiscal_sai_id;
   END IF;
   --
   IF v_fi_banco_id IS NOT NULL
   THEN
    UPDATE nota_fiscal
       SET fi_banco_cobrador_id = v_fi_banco_id
     WHERE nota_fiscal_id = v_nota_fiscal_sai_id;
   END IF;
   --
   ----------------------------------
   -- atualizacao final
   ----------------------------------
   IF v_tipo_fat = 'JOB'
   THEN
    UPDATE faturamento
       SET nota_fiscal_sai_id = v_nota_fiscal_sai_id
     WHERE faturamento_id = v_faturamento_id;
    --
    IF v_cliente_id IS NOT NULL
    THEN
     UPDATE faturamento
        SET cliente_id = v_cliente_id
      WHERE faturamento_id = v_faturamento_id;
    END IF;
    --
    IF v_emp_faturar_por_id <> v_emp_faturar_por_xml
    THEN
     UPDATE faturamento
        SET emp_faturar_por_id = v_emp_faturar_por_xml
      WHERE faturamento_id = v_faturamento_id;
    END IF;
   ELSIF v_tipo_fat = 'CONTRATO'
   THEN
    UPDATE faturamento_ctr
       SET nota_fiscal_sai_id = v_nota_fiscal_sai_id
     WHERE faturamento_ctr_id = v_faturamento_id;
    --
    IF v_cliente_id IS NOT NULL
    THEN
     UPDATE faturamento_ctr
        SET cliente_id = v_cliente_id
      WHERE faturamento_ctr_id = v_faturamento_id;
    END IF;
    --
    IF v_emp_faturar_por_id <> v_emp_faturar_por_xml
    THEN
     UPDATE faturamento_ctr
        SET emp_faturar_por_id = v_emp_faturar_por_xml
      WHERE faturamento_ctr_id = v_faturamento_id;
    END IF;
   END IF;
   --
   UPDATE nota_fiscal nf
      SET data_pri_vencim =
          (SELECT MIN(data_vencim)
             FROM duplicata du
            WHERE du.nota_fiscal_id = nf.nota_fiscal_id)
    WHERE nota_fiscal_id = v_nota_fiscal_sai_id;
   --
  END IF; -- fim do IF p_cod_acao = 'EFETIVAR'
  --
  ------------------------------------------------------------
  -- geracao do log
  ------------------------------------------------------------
  -- log_retorno_gravar(v_xml_log_id, v_nota_fiscal_sai_id, 'OK');
  INSERT INTO xml_log
   (xml_log_id,
    data,
    texto_xml,
    sistema_origem,
    sistema_destino,
    cod_objeto,
    cod_acao,
    objeto_id)
  VALUES
   (seq_xml_log.nextval,
    SYSDATE,
    p_xml_in,
    'ADNNET',
    'JOBONE',
    'NF_SAIDA',
    p_cod_acao,
    v_nota_fiscal_sai_id);
  --
  p_xml_out  := p_xml_in;
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   p_erro_msg := 'JobOne: ' || p_erro_msg;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := 'JobOne: ' ||
                 substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 2000);
 END ordem_fatura_processar;
 --
 --
 --
 PROCEDURE arq_nf_entrada_log_registrar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Rafael               ProcessMind     DATA: 09/06/2025
  -- DESCRICAO: Subrotina que pega os parametros de entrada e saida e registra na XML_LOG.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_sistema_externo_id IN sistema_externo.sistema_externo_id%TYPE,
  p_empresa_id         IN empresa.empresa_id%TYPE,
  p_cod_objeto         IN VARCHAR2,
  p_cod_acao           IN VARCHAR2,
  p_objeto_id          IN VARCHAR2,
  p_xml_in             IN CLOB,
  p_xml_out            IN CLOB,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 ) IS
  v_qt         INTEGER;
  v_exception  EXCEPTION;
  v_xml_out    VARCHAR2(8000);
  v_xml_log_id xml_log.xml_log_id%TYPE;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  p_erro_msg := NULL;
  --
  IF TRIM(p_cod_objeto) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O código do objeto não foi fornecido.';
   RAISE v_exception;
  END IF;
  --
  IF dbms_lob.getlength(p_xml_in) >= 104000
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O tamanho do XML gerado está com mais de 104000 caracteres.';
   RAISE v_exception;
  END IF;
  --
  SELECT seq_xml_log.nextval
    INTO v_xml_log_id
    FROM dual;
  --
  log_envio_gravar(v_xml_log_id, p_cod_objeto, p_cod_acao, p_objeto_id, p_xml_in);
  --
  log_retorno_gravar(v_xml_log_id, p_objeto_id, p_xml_out);
  --
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   p_erro_msg := 'ADN Net: ' || p_erro_msg;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := 'ADN Net - outros: ' ||
                 substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 2000);
 END arq_nf_entrada_log_registrar;
 --
 --
 --
 PROCEDURE adnnet_executar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 25/05/2007
  -- DESCRICAO: Subrotina que executa a chamada de procedures no sistema ADNNET.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            13/06/2011  Configuracao da integracao para diversos sistemas
  --                               externos. A decisao de integrar ou nao passa a ser feita
  --                               atraves da tabela sist_ext_ponto_int, antes de gerar o XML.
  -- Silvia            20/06/2017  Novo parametro objeto_id
  -- Silvia            20/02/2020  Nova integracao de ORCAMENTO
  -- Silvia            27/06/2023  Integracao de CONTRATO
  ------------------------------------------------------------------------------------------
 (
  p_sistema_externo_id IN sistema_externo.sistema_externo_id%TYPE,
  p_empresa_id         IN empresa.empresa_id%TYPE,
  p_cod_objeto         IN VARCHAR2,
  p_cod_acao           IN VARCHAR2,
  p_objeto_id          IN VARCHAR2,
  p_xml_in             IN CLOB,
  p_xml_out            OUT CLOB,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 ) IS
  v_qt         INTEGER;
  v_exception  EXCEPTION;
  v_xml_out    VARCHAR2(8000);
  v_xml_log_id xml_log.xml_log_id%TYPE;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  p_erro_msg := NULL;
  p_xml_out  := NULL;
  --
  IF TRIM(p_cod_objeto) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O código do objeto não foi fornecido.';
   RAISE v_exception;
  END IF;
  --
  IF dbms_lob.getlength(p_xml_in) >= 104000
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O tamanho do XML gerado está com mais de 104000 caracteres.';
   RAISE v_exception;
  END IF;
  --
  SELECT seq_xml_log.nextval
    INTO v_xml_log_id
    FROM dual;
  --
  log_envio_gravar(v_xml_log_id, p_cod_objeto, p_cod_acao, p_objeto_id, p_xml_in);
  --
  IF p_cod_objeto = 'PESSOA'
  THEN
   webservice_pkg.chamar(p_sistema_externo_id,
                         p_empresa_id,
                         'pessoa_integrar',
                         p_cod_acao,
                         v_xml_log_id,
                         p_xml_out,
                         p_erro_msg);
  ELSIF p_cod_objeto = 'JOB'
  THEN
   webservice_pkg.chamar(p_sistema_externo_id,
                         p_empresa_id,
                         'job_integrar',
                         p_cod_acao,
                         v_xml_log_id,
                         p_xml_out,
                         p_erro_msg);
  ELSIF p_cod_objeto = 'CONTRATO'
  THEN
   -- chama o mesmo servico de JOB
   webservice_pkg.chamar(p_sistema_externo_id,
                         p_empresa_id,
                         'job_integrar',
                         p_cod_acao,
                         v_xml_log_id,
                         p_xml_out,
                         p_erro_msg);
  ELSIF p_cod_objeto = 'ORCAMENTO'
  THEN
   webservice_pkg.chamar(p_sistema_externo_id,
                         p_empresa_id,
                         'orcamento_integrar',
                         p_cod_acao,
                         v_xml_log_id,
                         p_xml_out,
                         p_erro_msg);

  ELSIF p_cod_objeto = 'NF_ENTRADA'
  THEN
   webservice_pkg.chamar(p_sistema_externo_id,
                         p_empresa_id,
                         'nf_entrada_integrar',
                         p_cod_acao,
                         v_xml_log_id,
                         v_xml_out,
                         p_erro_msg);
   --
   p_xml_out := v_xml_out;
   IF p_xml_out IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := p_erro_msg;
    RAISE v_exception;
   END IF;
   --
  ELSIF p_cod_objeto = 'FATURAMENTO'
  THEN
   webservice_pkg.chamar(p_sistema_externo_id,
                         p_empresa_id,
                         'faturamento_integrar',
                         p_cod_acao,
                         v_xml_log_id,
                         v_xml_out,
                         p_erro_msg);
   --
   p_xml_out := v_xml_out;
  ELSE
   p_erro_cod := '90000';
   p_erro_msg := 'Código do objeto inválido (' || p_cod_objeto || ').';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_erro_msg) IS NOT NULL
  THEN
   p_erro_cod := '90000';
   RAISE v_exception;
  END IF;
  --
  log_retorno_gravar(v_xml_log_id, p_objeto_id, p_xml_out);
  --UPDATE xml_log
  --   SET retorno_xml = p_xml_out
  -- WHERE xml_log_id = v_xml_log_id;
  --
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   p_erro_msg := 'ADN Net: ' || p_erro_msg;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := 'ADN Net - outros: ' ||
                 substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 2000);
 END adnnet_executar;
 --
 --
 --
 FUNCTION data_adn_converter
 -----------------------------------------------------------------------
  --   DATA_CONVERTER
  --
  --   Descricao: funcao que converte um string contendo uma data no
  --   formato 'YYYY-MM-DD'.
  -----------------------------------------------------------------------
 (p_data IN VARCHAR2) RETURN DATE IS
  --
  v_data DATE;
  --
 BEGIN
  v_data := NULL;
  v_data := to_date(p_data, 'yyyy-mm-dd');
  --
  RETURN v_data;
  --
 EXCEPTION
  WHEN OTHERS THEN
   RETURN v_data;
 END;
 --
 --
 --
 FUNCTION data_adn_validar
 -----------------------------------------------------------------------
  --   DATA_ADN_VALIDAR
  --
  --   Descricao: funcao que consiste um string contendo uma data no
  --   formato 'YYYY-MM-DD' do ADN Net. Retorna '1' caso o string seja
  --   uma data valida, e '0' caso nao seja. Para um string igual a NULL,
  --   retorna '1'.
  -----------------------------------------------------------------------
 (p_data IN VARCHAR2) RETURN INTEGER IS
  --
  v_ok   INTEGER;
  v_data DATE;
  v_ano  INTEGER;
  --
 BEGIN
  v_ok   := 0;
  v_data := to_date(p_data, 'yyyy-mm-dd');
  IF rtrim(p_data) IS NOT NULL
  THEN
   v_ano := to_number(to_char(v_data, 'yyyy'));
   IF v_ano > 1000
   THEN
    v_ok := 1;
   END IF;
  ELSE
   v_ok := 1;
  END IF;
  RETURN v_ok;
  --
 EXCEPTION
  WHEN OTHERS THEN
   RETURN v_ok;
 END;
 --
 --
 --
 FUNCTION numero_adn_converter
 -----------------------------------------------------------------------
  --   NUMERO_ADN_CONVERTER
  --
  --   Descricao: função que converte um string previamente validado
  --   em numero. O string pdeve estar tanto no formato
  --   '99999999999999999999.99999'
  -----------------------------------------------------------------------
 (p_numero IN VARCHAR2) RETURN NUMBER IS
  v_ok          INTEGER;
  v_numero      NUMBER;
  v_numero_char VARCHAR2(30);
  --
 BEGIN
  v_numero      := NULL;
  v_numero_char := rtrim(REPLACE(p_numero, ',', ''));
  --
  v_numero := to_number(v_numero_char,
                        '99999999999999999999D999999',
                        'NLS_NUMERIC_CHARACTERS = ''.,'' ');
  --
  RETURN v_numero;
 EXCEPTION
  WHEN OTHERS THEN
   v_numero := 99999999;
   RETURN v_numero;
 END;
 --
 --
 --
 FUNCTION numero_adn_validar
 -----------------------------------------------------------------------
  --   NUMERO_ADN_VALIDAR
  --
  --   Descricao: funcao que consiste uma string nos seguintes
  --   formatos moeda '99999999999999999999.99'.
  --   Retorna 1 caso o string seja um valor valido, 0 caso nao seja.
  --   Para um string igual a NULL, retorna 1.
  --   (OBS: trabalha c/ virgula como decimal e nao aceita ponto como
  --   separador de milhar).
  -----------------------------------------------------------------------
 (p_numero IN VARCHAR2) RETURN INTEGER IS
  v_ok          INTEGER;
  v_numero_char VARCHAR2(30);
  v_numero      NUMBER;
  v_pos         INTEGER;
 BEGIN
  v_ok := 0;
  --
  IF instr(p_numero, ',') > 0
  THEN
   RETURN v_ok;
  END IF;
  --
  v_numero_char := rtrim(REPLACE(p_numero, ',', ''));
  --
  v_numero := to_number(v_numero_char,
                        '99999999999999999999D999999',
                        'NLS_NUMERIC_CHARACTERS = ''.,'' ');
  v_ok     := 1;
  --
  RETURN v_ok;
 EXCEPTION
  WHEN OTHERS THEN
   RETURN v_ok;
 END;
 --
 FUNCTION obter_nat_oper
 -----------------------------------------------------------------------
  -- DESENVOLVEDOR: Ana Luiza               ProcessMind     DATA: 21/03/2025
  --   OBTER_NAT_OPER
  --
  --   Descricao: funcao que compõe natureza de operacao de acordo com o
  --   sistema financeiro cadastrado.
  -----------------------------------------------------------------------
 (
  p_cod_sist_ext      VARCHAR2,
  p_flag_pago_cliente CHAR,
  p_valor_bv_total    NUMBER,
  p_tipo_item         CHAR,
  p_nota_fiscal_id    NUMBER
 ) RETURN VARCHAR2 IS
  v_cd_nat_oper     VARCHAR2(10);
  v_modo_pagto      VARCHAR2(2); -- Alterado para VARCHAR2(2)
  v_tipo_doc_nf     tipo_doc_nf.codigo%TYPE;
  v_tipo_pag_pessoa nota_fiscal.tipo_pag_pessoa%TYPE;
 BEGIN
  --DEFAULT pata todos os clientes
  v_cd_nat_oper := 'DR' || p_tipo_item;
  BEGIN
   SELECT nf.modo_pagto,
          td.codigo,
          nf.tipo_pag_pessoa --Inplementacao para Inhaus --ALCBO_180825
     INTO v_modo_pagto,
          v_tipo_doc_nf,
          v_tipo_pag_pessoa
     FROM nota_fiscal nf
    INNER JOIN tipo_doc_nf td
       ON nf.tipo_doc_nf_id = td.tipo_doc_nf_id
    WHERE nota_fiscal_id = p_nota_fiscal_id;
  EXCEPTION
   WHEN no_data_found THEN
    v_modo_pagto := NULL;
  END;
  --
  IF p_cod_sist_ext LIKE '%INHA%' --INHAUS INICIO
  THEN
   --
   IF p_flag_pago_cliente = 'S' AND p_valor_bv_total = 0 AND p_tipo_item = 'A'
   THEN
    v_cd_nat_oper := 'DRX';
   ELSIF p_flag_pago_cliente = 'S' AND p_valor_bv_total > 0
   THEN
    v_cd_nat_oper := 'DRX';
   ELSIF v_tipo_doc_nf = 'NFC'
   THEN
    v_cd_nat_oper := 'CMUC';
   END IF;
   --
   IF v_tipo_pag_pessoa IS NOT NULL
   THEN
    CASE v_tipo_pag_pessoa
     WHEN 'X1' THEN
      v_cd_nat_oper := 'DRX1';
     WHEN 'X2' THEN
      v_cd_nat_oper := 'DRX2';
     WHEN 'P1' THEN
      v_cd_nat_oper := 'CRP1';
     WHEN 'P2' THEN
      v_cd_nat_oper := 'CRP2';
     WHEN 'P3' THEN
      v_cd_nat_oper := 'CRP3';
     WHEN 'T1' THEN
      v_cd_nat_oper := 'CRT1';
     WHEN 'T2' THEN
      v_cd_nat_oper := 'CRT2';
     WHEN 'T3' THEN
      v_cd_nat_oper := 'CRT3';
     WHEN 'T4' THEN
      v_cd_nat_oper := 'CRT4';
     WHEN 'T5' THEN
      v_cd_nat_oper := 'CRT5';
     WHEN 'T6' THEN
      v_cd_nat_oper := 'CRT6';
     WHEN 'T7' THEN
      v_cd_nat_oper := 'CRT7';
     WHEN 'T8' THEN
      v_cd_nat_oper := 'CRT8';
     WHEN 'T9' THEN
      v_cd_nat_oper := 'CRT9';
     WHEN 'P4' THEN
      v_cd_nat_oper := 'CRP4';
     WHEN 'P5' THEN
      v_cd_nat_oper := 'CRP5';
     WHEN 'P6' THEN
      v_cd_nat_oper := 'CRP6';
     WHEN 'P7' THEN
      v_cd_nat_oper := 'CRP7';
     WHEN 'P8' THEN
      v_cd_nat_oper := 'CRP8';
     WHEN 'I1' THEN
      v_cd_nat_oper := 'INC1';
     WHEN 'E1' THEN
      v_cd_nat_oper := 'ESPE';
     WHEN 'CC' THEN
      v_cd_nat_oper := 'DRB';
     ELSE
      NULL;
    END CASE;
   END IF;
   --INHAUS FIM
   --REDDOOR INICIO
  ELSIF p_cod_sist_ext LIKE '%REDDOOR%'
  THEN
   IF p_flag_pago_cliente = 'S' AND p_tipo_item = 'A'
   THEN
    v_cd_nat_oper := 'SDPD';
   ELSIF p_flag_pago_cliente = 'N' AND p_tipo_item = 'A'
   THEN
    v_cd_nat_oper := 'SEPD';
   ELSIF p_tipo_item = 'B'
   THEN
    v_cd_nat_oper := 'DPRB';
   ELSIF p_tipo_item = 'C'
   THEN
    v_cd_nat_oper := 'DPRC';
   END IF;
   --
   IF v_tipo_doc_nf = 'NFC'
   THEN
    v_cd_nat_oper := 'CMUC';
   END IF; --RP_170725
   --
   --REDDOOR FIM
   --PROS INICIO
  ELSIF p_cod_sist_ext LIKE '%PROS%'
  THEN
   IF p_flag_pago_cliente = 'S' AND p_tipo_item = 'B'
   THEN
    v_cd_nat_oper := 'DRT';
   END IF; --PROS FIM;
   --OUTROS SISTEMAS INICIO
  ELSIF p_flag_pago_cliente = 'S' AND p_valor_bv_total > 0
  THEN
   v_cd_nat_oper := 'DRX';
  END IF; --OUTROS SISTEMAS FIM
  --
  --ALCBO_110724
  --ALCBO_170524 --ALCBO_190225
  -- Removido o bloco CASE para tratar sistemas específicos, pois agora é genérico
  RETURN v_cd_nat_oper;
 END obter_nat_oper;

END; -- IT_ADNNET_PKG

/
