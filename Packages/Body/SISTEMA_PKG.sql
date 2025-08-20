--------------------------------------------------------
--  DDL for Package Body SISTEMA_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "SISTEMA_PKG" IS
 --
 --
 PROCEDURE evento_sistema_gerar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 31/10/2011
  -- DESCRICAO: gera eventos de sistema na tabela de historico. A chamada deve ser feita
  --  via job.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            23/05/2012  Nao considera eventos de alteracao de usuario.
  ------------------------------------------------------------------------------------------
  IS
  --
  v_historico_id      historico.historico_id%TYPE;
  v_identif_objeto    historico.identif_objeto%TYPE;
  v_compl_histor      historico.complemento%TYPE;
  v_erro_cod          VARCHAR2(100);
  v_erro_msg          VARCHAR2(1000);
  v_usuario_sessao_id usuario.usuario_id%TYPE;
  v_data_ini          DATE;
  v_data_fim          DATE;
  v_empresa_id        empresa.empresa_id%TYPE;
  v_qt_usu_eve        NUMBER(5);
  v_qt_log_dis        NUMBER(5);
  v_qt_usu_ati        NUMBER(5);
  v_qt_usu_job        NUMBER(5);
  v_cliente           VARCHAR2(100);
  v_schema            VARCHAR2(100);
  v_lbl_jobs          VARCHAR2(100);
  --
 BEGIN
  --
  SELECT MIN(usuario_id)
    INTO v_usuario_sessao_id
    FROM usuario
   WHERE flag_admin_sistema = 'S';
  --
  SELECT USER
    INTO v_schema
    FROM dual;
  --
  v_data_fim := trunc(SYSDATE);
  v_data_ini := v_data_fim - 30;
  --
  v_empresa_id := usuario_pkg.empresa_padrao_retornar(v_usuario_sessao_id);
  v_lbl_jobs   := empresa_pkg.parametro_retornar(v_empresa_id, 'LABEL_JOB_PLURAL');
  v_cliente    := empresa_pkg.parametro_retornar(v_empresa_id, 'NOME_PADRAO');
  --
  SELECT COUNT(*)
    INTO v_qt_usu_ati
    FROM usuario
   WHERE flag_ativo = 'S'
     AND flag_admin = 'N';
  --
  SELECT COUNT(DISTINCT hi.usuario_id)
    INTO v_qt_log_dis
    FROM historico   hi,
         evento      ev,
         tipo_objeto ob,
         tipo_acao   ac,
         usuario     us
   WHERE hi.evento_id = ev.evento_id
     AND ev.tipo_objeto_id = ob.tipo_objeto_id
     AND ev.tipo_acao_id = ac.tipo_acao_id
     AND ob.codigo = 'USUARIO'
     AND ac.codigo = 'LOGAR'
     AND hi.usuario_id = us.usuario_id
     AND us.flag_admin = 'N'
     AND data_evento BETWEEN v_data_ini AND v_data_fim + 1;
  --
  SELECT COUNT(DISTINCT hi.usuario_id)
    INTO v_qt_usu_eve
    FROM historico   hi,
         evento      ev,
         tipo_objeto ob,
         tipo_acao   ac,
         usuario     us
   WHERE hi.evento_id = ev.evento_id
     AND ev.tipo_objeto_id = ob.tipo_objeto_id
     AND ev.tipo_acao_id = ac.tipo_acao_id
     AND NOT (ob.codigo = 'USUARIO' AND ac.codigo = 'LOGAR')
     AND NOT (ob.codigo = 'USUARIO' AND ac.codigo = 'ALTERAR')
     AND NOT (ob.codigo = 'JOB' AND ac.codigo = 'VISUALIZAR')
     AND hi.usuario_id = us.usuario_id
     AND us.flag_admin = 'N'
     AND data_evento BETWEEN v_data_ini AND v_data_fim + 1;
  --
  SELECT COUNT(DISTINCT hi.usuario_id)
    INTO v_qt_usu_job
    FROM historico   hi,
         evento      ev,
         tipo_objeto ob,
         tipo_acao   ac,
         usuario     us
   WHERE hi.evento_id = ev.evento_id
     AND ev.tipo_objeto_id = ob.tipo_objeto_id
     AND ev.tipo_acao_id = ac.tipo_acao_id
     AND ob.codigo = 'JOB'
     AND ac.codigo = 'VISUALIZAR'
     AND hi.usuario_id = us.usuario_id
     AND us.flag_admin = 'N'
     AND data_evento BETWEEN v_data_ini AND v_data_fim + 1;
  --
  v_identif_objeto := 'Login de usuários: ' || data_mostrar(v_data_ini) || ' a ' ||
                      data_mostrar(v_data_fim);
  v_compl_histor   := '*** Login de usuários nos últimos 30 dias ***' || '<br>' || 'Cliente: ' ||
                      v_cliente || '<br>' || 'Schema: ' || v_schema || '<br>' || 'Período: ' ||
                      data_mostrar(v_data_ini) || ' a ' || data_mostrar(v_data_fim) || '<br>' ||
                      'Logins Distintos: ' || to_char(v_qt_log_dis) || '<br>' ||
                      'Usuários Ativos: ' || to_char(v_qt_usu_ati) || '<br>' ||
                      'Usuários viram ' || v_lbl_jobs || ': ' || to_char(v_qt_usu_job) ||
                      '<br>' || 'Usuários com Eventos: ' || to_char(v_qt_usu_eve);
  --
  evento_pkg.gerar(v_usuario_sessao_id,
                   v_empresa_id,
                   'SISTEMA',
                   'NOTIFICAR',
                   v_identif_objeto,
                   0,
                   v_compl_histor,
                   NULL,
                   'N',
                   NULL,
                   NULL,
                   v_historico_id,
                   v_erro_cod,
                   v_erro_msg);
  --
  COMMIT;
  --
 END evento_sistema_gerar;
 --
 --
 --
 PROCEDURE logs_limpar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 29/09/2016
  -- DESCRICAO: limpa registros antigos das tabelas XML_LOG, HISTORICO, EVENTO, etc
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            01/07/2021  Limpa tabela lnk_direto
  -- Silvia            29/07/2021  Limpa tarefa temporaria
  ------------------------------------------------------------------------------------------
  AS
  v_qt           INTEGER;
  v_exception    EXCEPTION;
  v_erro_cod     VARCHAR2(100);
  v_erro_msg     VARCHAR2(2000);
  v_texto        VARCHAR2(2000);
  v_usu_admin_id usuario.usuario_id%TYPE;
  --
  CURSOR c_ta IS
   SELECT tarefa_id,
          empresa_id
     FROM tarefa
    WHERE status = 'TEMP'
    ORDER BY empresa_id;
  --
 BEGIN
  SELECT MAX(usuario_id)
    INTO v_usu_admin_id
    FROM usuario
   WHERE flag_admin_sistema = 'S';
  ------------------------------------------------------------
  -- registro do inicio do processamento
  ------------------------------------------------------------
  INSERT INTO erro_log
   (erro_log_id,
    data,
    nome_programa,
    cod_erro,
    msg_erro)
  VALUES
   (seq_erro_log.nextval,
    SYSDATE,
    'Limpeza de Logs - Início',
    NULL,
    NULL);
  COMMIT;
  --
  ------------------------------------------------------------
  -- limpeza de ERRO_LOG
  ------------------------------------------------------------
  -- limpa registros com mais de 1 ano
  DELETE FROM erro_log
   WHERE data <= add_months(trunc(SYSDATE), -12);
  COMMIT;
  --
  ------------------------------------------------------------
  -- limpeza de LINK_DIRETO
  ------------------------------------------------------------
  -- limpa registros hash expirado
  DELETE FROM link_direto
   WHERE data_validade < SYSDATE;
  COMMIT;
  --
  ------------------------------------------------------------
  -- limpeza de TAREFA temporaria
  ------------------------------------------------------------
  FOR r_ta IN c_ta
  LOOP
   tarefa_pkg.excluir(v_usu_admin_id, r_ta.empresa_id, r_ta.tarefa_id, v_erro_cod, v_erro_msg);
   IF v_erro_cod <> '00000' THEN
    INSERT INTO erro_log
     (erro_log_id,
      data,
      nome_programa,
      cod_erro,
      msg_erro)
    VALUES
     (seq_erro_log.nextval,
      SYSDATE,
      'sistema_pkg.logs_limpar',
      v_erro_cod,
      v_erro_msg);
    COMMIT;
   END IF;
  END LOOP;
  --
  ------------------------------------------------------------
  -- limpeza de XML_LOG
  ------------------------------------------------------------
  -- limpa registros com mais de 6 meses
  DELETE FROM xml_log
   WHERE cod_objeto IN ('PESSOA', 'PRODUTO_AGENCIA', 'PRODUTO_CLIENTE', 'TIPO_PRODUTO')
     AND data <= add_months(trunc(SYSDATE), -6);
  COMMIT;
  --
  -- limpa registros com mais de 1 ano
  DELETE FROM xml_log
   WHERE cod_objeto IN ('CARTA_ACORDO', 'ORDEM_SERVICO')
     AND data <= add_months(trunc(SYSDATE), -12);
  COMMIT;
  --
  -- limpa registros com mais de 3 anos
  DELETE FROM xml_log
   WHERE cod_objeto IN
         ('NF_ENTRADA', 'NOTA_ENTRADA', 'FATURAMENTO', 'ORDEM_FATURA', 'NF_SAIDA')
     AND data <= add_months(trunc(SYSDATE), -36);
  COMMIT;
  --
  ------------------------------------------------------------
  -- limpeza de NOTIFICA_FILA
  ------------------------------------------------------------
  -- limpa registros com mais de 2 meses
  DELETE FROM notifica_fila_usu n2
   WHERE EXISTS (SELECT 1
            FROM notifica_fila n1
           WHERE n1.data_evento <= add_months(trunc(SYSDATE), -2)
             AND n1.notifica_fila_id = n2.notifica_fila_id);
  --
  DELETE FROM notifica_fila_email n2
   WHERE EXISTS (SELECT 1
            FROM notifica_fila n1
           WHERE n1.data_evento <= add_months(trunc(SYSDATE), -2)
             AND n1.notifica_fila_id = n2.notifica_fila_id);
  --
  DELETE FROM notifica_usu_avulso nu
   WHERE EXISTS (SELECT 1
            FROM historico hi
           WHERE hi.data_evento <= add_months(trunc(SYSDATE), -2)
             AND hi.historico_id = nu.historico_id);
  --
  DELETE FROM notifica_fila
   WHERE data_evento <= add_months(trunc(SYSDATE), -2);
  COMMIT;
  --
  ------------------------------------------------------------
  -- limpeza de HISTORICO
  ------------------------------------------------------------
  -- limpa registros com mais de 2 meses
  DELETE FROM historico hi
   WHERE data_evento <= add_months(trunc(SYSDATE), -2)
     AND EXISTS
   (SELECT 1
            FROM evento    ev,
                 tipo_acao ta
           WHERE hi.evento_id = ev.evento_id
             AND ev.tipo_acao_id = ta.tipo_acao_id
             AND (ta.codigo LIKE 'NOTIFICAR%' OR ta.codigo LIKE 'COMENTAR%'));
  COMMIT;
  --
  -- limpa registros com mais de 1 ano
  DELETE FROM historico hi
   WHERE data_evento <= add_months(trunc(SYSDATE), -12)
     AND EXISTS (SELECT 1
            FROM evento    ev,
                 tipo_acao ta
           WHERE hi.evento_id = ev.evento_id
             AND ev.tipo_acao_id = ta.tipo_acao_id
             AND ta.codigo LIKE 'VISUALIZAR%');
  COMMIT;
  --
  -- limpa registros com mais de 1 ano
  DELETE FROM historico hi
   WHERE data_evento <= add_months(trunc(SYSDATE), -12)
     AND EXISTS (SELECT 1
            FROM evento    ev,
                 tipo_acao ta
           WHERE hi.evento_id = ev.evento_id
             AND ev.tipo_acao_id = ta.tipo_acao_id
             AND ta.codigo IN ('ENDERECAR', 'DESENDERECAR'));
  COMMIT;
  --
  -- limpa registros com mais de 2 anos
  DELETE FROM historico hi
   WHERE data_evento <= add_months(trunc(SYSDATE), -24)
     AND EXISTS (SELECT 1
            FROM evento    ev,
                 tipo_acao ta
           WHERE hi.evento_id = ev.evento_id
             AND ev.tipo_acao_id = ta.tipo_acao_id
             AND ta.codigo IN ('LOGAR', 'ALTERAR'));
  COMMIT;
  --
  ------------------------------------------------------------
  -- registro do fim do processamento
  ------------------------------------------------------------
  INSERT INTO erro_log
   (erro_log_id,
    data,
    nome_programa,
    cod_erro,
    msg_erro)
  VALUES
   (seq_erro_log.nextval,
    SYSDATE,
    'Limpeza de Logs - Término',
    NULL,
    NULL);
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
     'sistema_pkg.logs_limpar',
     v_erro_cod,
     v_erro_msg);
   COMMIT;
  WHEN OTHERS THEN
   ROLLBACK;
   v_erro_cod := SQLCODE;
   v_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace,
                        1,
                        200);
   INSERT INTO erro_log
    (erro_log_id,
     data,
     nome_programa,
     cod_erro,
     msg_erro)
   VALUES
    (seq_erro_log.nextval,
     SYSDATE,
     'sistema_pkg.logs_limpar',
     v_erro_cod,
     v_erro_msg);
   COMMIT;
 END logs_limpar;
 --
 --
 --
 PROCEDURE jobs_diarios_executar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 11/04/2017
  -- DESCRICAO: executa a chamada de diversos jobs que devem ser executados diariamente.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            05/07/2018  Marca notificacoes antigas como lidas (processamento
  --                               retirado da evento_pkg.notifica_processar).
  -- Silvia            02/10/2018  Nova procedure chamada: usuario_pkg.inativar_automatico.
  -- Silvia            05/03/2020  Nova procedure cronograma_pkg.alocacao_processar.
  -- Silvia            01/09/2021  Nova procedure chamada: contrato_pkg.concluir_automatico
  -- Silvia            19/04/2022  Nova procedure chamada: job_pkg.concluir_automatico
  -- Silvia            29/06/2022  Nova procedure chamada: apontam_pkg.data_pendente_processar
  ------------------------------------------------------------------------------------------
  IS
  v_qt NUMBER(5);
  --
  -- cursor de notificacoes antigas nao lidas
  CURSOR c_nl IS
   SELECT nu.notifica_fila_usu_id,
          nf.empresa_id
     FROM notifica_fila     nf,
          notifica_fila_usu nu
    WHERE nf.data_evento <
          trunc(SYSDATE) -
          to_number(empresa_pkg.parametro_retornar(nf.empresa_id, 'NUM_DIAS_FECHA_NOTIFICACAO'))
      AND nf.notifica_fila_id = nu.notifica_fila_id
      AND nu.flag_lido = 'N'
    ORDER BY nf.notifica_fila_id;
  --
 BEGIN
  --
  -- limpa cod hash de redefinicao de senha do usuario
  UPDATE usuario
     SET cod_hash = NULL
   WHERE cod_hash IS NOT NULL;
  --
  COMMIT;
  --
  -- cursor de notificacoes antigas nao lidas (so roda de madrugada)
  FOR r_nl IN c_nl
  LOOP
   UPDATE notifica_fila_usu
      SET flag_lido = 'S'
    WHERE notifica_fila_usu_id = r_nl.notifica_fila_usu_id;
  END LOOP;
  --
  COMMIT;
  --
  ordem_servico_pkg.concluir_automatico;
  contrato_pkg.concluir_automatico;
  job_pkg.concluir_automatico;
  usuario_pkg.inativar_automatico;
  apontam_pkg.data_pendente_processar;
  apontam_pkg.periodo_ence_criar;
  apontam_pkg.data_geral_criar;
  tipo_produto_pkg.tempo_gasto_calcular;
  relatorio_pkg.limpar;
  sistema_pkg.evento_sistema_gerar;
  cronograma_pkg.alocacao_processar;
  --
 END jobs_diarios_executar;
 --
--
END; -- SISTEMA_pkg



/
