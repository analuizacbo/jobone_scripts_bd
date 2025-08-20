--------------------------------------------------------
--  DDL for Package Body IT_PORTO_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "IT_PORTO_PKG" IS
 --
 v_xml_doc        VARCHAR2(100) := '<?xml version="1.0" encoding="UTF-8" ?>';
 v_charset_sisext VARCHAR2(20) := 'UTF8';
 v_charset_jobone VARCHAR2(20) := charset_retornar;
 --
 --
 PROCEDURE log_gravar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 12/04/2013
  -- DESCRICAO: Subrotina que grava no log o XML principal enviado ao sistema externo ou o
  --   XML principal recebido pelo sistema externo (transacao autonoma, que faz commit mas
  --   nao interfere no processamento da transacao original).
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            23/06/2017  Novo parametro objeto_id
  ------------------------------------------------------------------------------------------
 (
  p_xml_log_id      IN NUMBER,
  p_sistema_origem  IN VARCHAR2,
  p_sistema_destino IN VARCHAR2,
  p_cod_objeto      IN VARCHAR2,
  p_cod_acao        IN VARCHAR2,
  p_objeto_id       IN VARCHAR2,
  p_xml_in          IN CLOB
 ) IS
  PRAGMA AUTONOMOUS_TRANSACTION;
  --
 BEGIN
  --
  IF p_xml_in IS NOT NULL THEN
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
     p_sistema_origem,
     p_sistema_destino,
     p_cod_objeto,
     p_cod_acao,
     to_number(p_objeto_id));
  END IF;
  --
  COMMIT;
  --
 END log_gravar;
 --
 --
 PROCEDURE log_concluir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 12/04/2013
  -- DESCRICAO: Subrotina que grava no log o XML de retorno enviado pelo sistema externo ou
  --   o XML de retorno gerado pelo JobOne (transacao autonoma, que faz commit mas nao
  --   interfere no processamento da transacao original).
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            23/06/2017  Novo parametro objeto_id
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
  IF p_xml_out IS NOT NULL THEN
   UPDATE xml_log
      SET retorno_xml = p_xml_out,
          objeto_id   = to_number(p_objeto_id)
    WHERE xml_log_id = p_xml_log_id;
  END IF;
  --
  COMMIT;
  --
 END log_concluir;
 --
 --
 --
 PROCEDURE job_integrar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 25/07/2017
  -- DESCRICAO: Subrotina que gera o xml de envio e executa a integracao de JOB.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_sistema_externo_id IN sistema_externo.sistema_externo_id%TYPE,
  p_empresa_id         IN empresa.empresa_id%TYPE,
  p_job_id             IN job.job_id%TYPE,
  p_cod_acao           IN VARCHAR2,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 ) IS
  v_qt           INTEGER;
  v_exception    EXCEPTION;
  v_saida        EXCEPTION;
  v_xml_conteudo xmltype;
  v_xml_out      CLOB;
  v_xml_in       CLOB;
  v_xml_doc      VARCHAR2(100);
  --
 BEGIN
  v_qt      := 0;
  v_xml_doc := '<?xml version="1.0" encoding="ISO-8859-1" ?>';
  ------------------------------------------------------------
  -- consistencias
  ------------------------------------------------------------
  IF TRIM(p_cod_acao) IS NULL OR p_cod_acao NOT IN ('I') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Código da ação inválido.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- monta a secao "conteudo"
  ------------------------------------------------------------
  SELECT xmlagg(xmlelement("notificacao",
                           xmlelement("cod_objeto", 'JOB'),
                           xmlelement("objeto_id", p_job_id)))
    INTO v_xml_conteudo
    FROM dual;
  --
  -- acrescenta o tipo de documento e converte
  SELECT v_xml_doc || v_xml_conteudo.getclobval()
    INTO v_xml_in
    FROM dual;
  --
  ------------------------------------------------------------
  -- chama a procedure de integracao
  ------------------------------------------------------------
  porto_executar(p_sistema_externo_id,
                 p_empresa_id,
                 'JOB',
                 p_cod_acao,
                 p_job_id,
                 v_xml_in,
                 v_xml_out,
                 p_erro_cod,
                 p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
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
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace,
                        1,
                        2000);
 END job_integrar;
 --
 --
 --
 PROCEDURE ordem_servico_integrar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 25/07/2017
  -- DESCRICAO: Subrotina que gera o xml de envio e executa a integracao de OS.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_sistema_externo_id IN sistema_externo.sistema_externo_id%TYPE,
  p_empresa_id         IN empresa.empresa_id%TYPE,
  p_ordem_servico_id   IN ordem_servico.ordem_servico_id%TYPE,
  p_cod_acao           IN VARCHAR2,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 ) IS
  v_qt           INTEGER;
  v_exception    EXCEPTION;
  v_saida        EXCEPTION;
  v_xml_conteudo xmltype;
  v_xml_out      CLOB;
  v_xml_in       CLOB;
  v_xml_doc      VARCHAR2(100);
  --
 BEGIN
  v_qt      := 0;
  v_xml_doc := '<?xml version="1.0" encoding="ISO-8859-1" ?>';
  ------------------------------------------------------------
  -- consistencias
  ------------------------------------------------------------
  IF TRIM(p_cod_acao) IS NULL OR p_cod_acao NOT IN ('I') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Código da ação inválido.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- monta a secao "conteudo"
  ------------------------------------------------------------
  SELECT xmlagg(xmlelement("notificacao",
                           xmlelement("cod_objeto", 'ORDEM_SERVICO'),
                           xmlelement("objeto_id", p_ordem_servico_id)))
    INTO v_xml_conteudo
    FROM dual;
  --
  -- acrescenta o tipo de documento e converte
  SELECT v_xml_doc || v_xml_conteudo.getclobval()
    INTO v_xml_in
    FROM dual;
  --
  ------------------------------------------------------------
  -- chama a procedure de integracao
  ------------------------------------------------------------
  porto_executar(p_sistema_externo_id,
                 p_empresa_id,
                 'ORDEM_SERVICO',
                 p_cod_acao,
                 p_ordem_servico_id,
                 v_xml_in,
                 v_xml_out,
                 p_erro_cod,
                 p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
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
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace,
                        1,
                        2000);
 END ordem_servico_integrar;
 --
 --
 --
 PROCEDURE comentario_integrar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 25/07/2017
  -- DESCRICAO: Subrotina que gera o xml de envio e executa a integracao de COMENTARIO.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_sistema_externo_id IN sistema_externo.sistema_externo_id%TYPE,
  p_empresa_id         IN empresa.empresa_id%TYPE,
  p_comentario_id      IN comentario.comentario_id%TYPE,
  p_cod_acao           IN VARCHAR2,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 ) IS
  v_qt           INTEGER;
  v_exception    EXCEPTION;
  v_saida        EXCEPTION;
  v_xml_conteudo xmltype;
  v_xml_out      CLOB;
  v_xml_in       CLOB;
  v_xml_doc      VARCHAR2(100);
  v_texto        comentario.comentario%TYPE;
  v_job_id       job.job_id%TYPE;
  v_cod_objeto   tipo_objeto.codigo%TYPE;
  v_objeto_id    comentario.objeto_id%TYPE;
  --
 BEGIN
  v_qt      := 0;
  v_xml_doc := '<?xml version="1.0" encoding="ISO-8859-1" ?>';
  ------------------------------------------------------------
  -- consistencias
  ------------------------------------------------------------
  IF TRIM(p_cod_acao) IS NULL OR p_cod_acao NOT IN ('I') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Código da ação inválido.';
   RAISE v_exception;
  END IF;
  --
  SELECT co.comentario,
         ti.codigo,
         co.objeto_id
    INTO v_texto,
         v_cod_objeto,
         v_objeto_id
    FROM comentario  co,
         tipo_objeto ti
   WHERE co.comentario_id = p_comentario_id
     AND co.tipo_objeto_id = ti.tipo_objeto_id;
  --
  v_texto  := char_especial_retirar(v_texto);
  v_job_id := 0;
  --
  IF v_cod_objeto = 'JOB' THEN
   -- comentario feito em job
   v_job_id := v_objeto_id;
  ELSIF v_cod_objeto = 'ORDEM_SERVICO' THEN
   -- comentario feito em OS
   SELECT MAX(job_id)
     INTO v_job_id
     FROM ordem_servico
    WHERE ordem_servico_id = v_objeto_id;
  END IF;
  --
  ------------------------------------------------------------
  -- monta a secao "conteudo"
  ------------------------------------------------------------
  SELECT xmlagg(xmlelement("notificacao",
                           xmlelement("cod_objeto", 'COMENTARIO'),
                           xmlelement("objeto_id", p_comentario_id),
                           xmlelement("texto", v_texto),
                           xmlelement("job_id", v_job_id)))
    INTO v_xml_conteudo
    FROM dual;
  --
  -- acrescenta o tipo de documento e converte
  SELECT v_xml_doc || v_xml_conteudo.getclobval()
    INTO v_xml_in
    FROM dual;
  --
  ------------------------------------------------------------
  -- chama a procedure de integracao
  ------------------------------------------------------------
  porto_executar(p_sistema_externo_id,
                 p_empresa_id,
                 'COMENTARIO',
                 p_cod_acao,
                 p_comentario_id,
                 v_xml_in,
                 v_xml_out,
                 p_erro_cod,
                 p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
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
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace,
                        1,
                        2000);
 END comentario_integrar;
 --
 --
 --
 PROCEDURE porto_executar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 08/05/2013
  -- DESCRICAO: Subrotina que executa a chamada de webservices no sistema PORTO.
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
  p_xml_out            OUT CLOB,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 ) IS
  v_qt         INTEGER;
  v_exception  EXCEPTION;
  v_xml_log_id xml_log.xml_log_id%TYPE;
  v_status_ret VARCHAR2(20);
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
  IF TRIM(p_cod_objeto) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O código do objeto não foi fornecido.';
   RAISE v_exception;
  END IF;
  --
  IF dbms_lob.getlength(p_xml_in) >= 104000 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O tamanho do XML gerado está com mais de 104000 caracteres.';
   RAISE v_exception;
  END IF;
  --
  SELECT seq_xml_log.nextval
    INTO v_xml_log_id
    FROM dual;
  --
  log_gravar(v_xml_log_id, 'JOBONE', 'PORTO', p_cod_objeto, p_cod_acao, p_objeto_id, p_xml_in);
  --
  IF p_cod_objeto = 'JOB' THEN
   webservice_pkg.chamar(p_sistema_externo_id,
                         p_empresa_id,
                         'emailEnviar',
                         p_cod_acao,
                         v_xml_log_id,
                         p_xml_out,
                         p_erro_msg);
   --
   -- simula o retorno do webservice
   --p_xml_out := 'OK';
  ELSIF p_cod_objeto = 'ORDEM_SERVICO' THEN
   webservice_pkg.chamar(p_sistema_externo_id,
                         p_empresa_id,
                         'emailEnviar',
                         p_cod_acao,
                         v_xml_log_id,
                         p_xml_out,
                         p_erro_msg);
   --
   -- simula o retorno do webservice
   --p_xml_out := 'OK';
  ELSIF p_cod_objeto = 'COMENTARIO' THEN
   webservice_pkg.chamar(p_sistema_externo_id,
                         p_empresa_id,
                         'emailEnviar',
                         p_cod_acao,
                         v_xml_log_id,
                         p_xml_out,
                         p_erro_msg);
   --
   -- simula o retorno do webservice
   -- p_xml_out := 'OK';
  ELSE
   p_erro_cod := '90000';
   p_erro_msg := 'Código do objeto inválido (' || p_cod_objeto || ').';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_erro_msg) IS NOT NULL THEN
   p_erro_cod := '90000';
   RAISE v_exception;
  END IF;
  --
  --log_concluir(v_xml_log_id, p_objeto_id, p_xml_out);
  UPDATE xml_log
     SET retorno_xml = p_xml_out,
         objeto_id   = to_number(p_objeto_id)
   WHERE xml_log_id = v_xml_log_id;
  --
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   p_erro_msg := 'PORTO: ' || p_erro_msg;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := 'PORTO - outros: ' ||
                 substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace,
                        1,
                        2000);
 END porto_executar;
 --
--
END; -- IT_PORTO_PKG



/
