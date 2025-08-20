--------------------------------------------------------
--  DDL for Package Body LIMPEZA_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "LIMPEZA_PKG" IS
 --
 --
 PROCEDURE empresa_processar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 06/08/2015
  -- DESCRICAO: apaga completamente uma determinada EMPRESA.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) AS
  v_qt             INTEGER;
  v_ok             INTEGER;
  v_exception      EXCEPTION;
  v_erro_cod       VARCHAR2(100);
  v_erro_msg       VARCHAR2(2000);
  v_texto          VARCHAR2(2000);
  v_usuario_adm_id usuario.usuario_id%TYPE;
  v_empresa_pdr_id empresa.empresa_id%TYPE;
  --
 BEGIN
  --
  SELECT MAX(usuario_id)
    INTO v_usuario_adm_id
    FROM usuario
   WHERE flag_admin_sistema = 'S';
  --
  v_empresa_pdr_id := nvl(usuario_pkg.empresa_padrao_retornar(v_usuario_adm_id), 0);
  --
  ------------------------------------------------------------
  -- marca o inicio
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
    'inicio_limpeza:' || to_char(p_empresa_id),
    NULL,
    NULL);
  --
  DELETE FROM usuario_ender u1
   WHERE EXISTS (SELECT 1
            FROM regra_coender rc
           WHERE rc.empresa_id = p_empresa_id
             AND rc.regra_coender_id = u1.regra_coender_id);
  --
  DELETE FROM usuario_coender u1
   WHERE EXISTS (SELECT 1
            FROM regra_coender rc
           WHERE rc.empresa_id = p_empresa_id
             AND rc.regra_coender_id = u1.regra_coender_id);
  --
  DELETE FROM regra_coender
   WHERE empresa_id = p_empresa_id;
  DELETE FROM notifica_desliga
   WHERE empresa_id = p_empresa_id;
  --
  --
  DELETE FROM unidade_negocio_cli uc
   WHERE EXISTS (SELECT 1
            FROM unidade_negocio un
           WHERE un.empresa_id = p_empresa_id
             AND un.unidade_negocio_id = uc.unidade_negocio_id);
  DELETE FROM unidade_negocio_usu uu
   WHERE EXISTS (SELECT 1
            FROM unidade_negocio un
           WHERE un.empresa_id = p_empresa_id
             AND un.unidade_negocio_id = uu.unidade_negocio_id);
  DELETE FROM unidade_negocio
   WHERE empresa_id = p_empresa_id;
  --
  DELETE FROM pesquisa
   WHERE empresa_id = p_empresa_id;
  --
  COMMIT;
  v_erro_cod := '00000';
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  limpeza_pkg.jobs_processar(p_usuario_sessao_id, p_empresa_id, v_erro_cod, v_erro_msg);
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
     'jobs_processar',
     v_erro_cod,
     v_erro_msg);
   /*
   p_erro_cod := v_erro_cod;
   p_erro_msg := 'jobs_processar: ' || v_erro_msg;
   RAISE v_exception;
   */
  END IF;
  --
  limpeza_pkg.oportunidades_processar(p_usuario_sessao_id, p_empresa_id, v_erro_cod, v_erro_msg);
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
     'oportunidades_processar',
     v_erro_cod,
     v_erro_msg);
  END IF;
  --
  limpeza_pkg.tasks_processar(p_usuario_sessao_id, p_empresa_id, v_erro_cod, v_erro_msg);
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
     'tasks_processar',
     v_erro_cod,
     v_erro_msg);
   /*
   p_erro_cod := v_erro_cod;
   p_erro_msg := 'tasks_processar: ' || v_erro_msg;
   RAISE v_exception;
   */
  END IF;
  --
  limpeza_pkg.milestones_processar(p_usuario_sessao_id, p_empresa_id, v_erro_cod, v_erro_msg);
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
     'milestones_processar',
     v_erro_cod,
     v_erro_msg);
   /*
   p_erro_cod := v_erro_cod;
   p_erro_msg := 'milestones_processar: ' || v_erro_msg;
   RAISE v_exception;
   */
  END IF;
  --
  limpeza_pkg.contratos_processar(p_usuario_sessao_id, p_empresa_id, v_erro_cod, v_erro_msg);
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
     'contratos_processar',
     v_erro_cod,
     v_erro_msg);
   /*
   p_erro_cod := v_erro_cod;
   p_erro_msg := 'contratos_processar: ' || v_erro_msg;
   RAISE v_exception;
   */
  END IF;
  --
  limpeza_pkg.papeis_processar(p_usuario_sessao_id, p_empresa_id, v_erro_cod, v_erro_msg);
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
     'papeis_processar',
     v_erro_cod,
     v_erro_msg);
   /*
   p_erro_cod := v_erro_cod;
   p_erro_msg := 'papeis_processar: ' || v_erro_msg;
   RAISE v_exception;
   */
  END IF;
  --
  limpeza_pkg.outros_processar(p_usuario_sessao_id, p_empresa_id, v_erro_cod, v_erro_msg);
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
     'outros_processar',
     v_erro_cod,
     v_erro_msg);
   /*
   p_erro_cod := v_erro_cod;
   p_erro_msg := 'outros_processar: ' || v_erro_msg;
   RAISE v_exception;
   */
  END IF;
  --
  limpeza_pkg.pessoas_processar(p_usuario_sessao_id, p_empresa_id, v_erro_cod, v_erro_msg);
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
     'pessoas_processar',
     v_erro_cod,
     v_erro_msg);
   /*
   p_erro_cod := v_erro_cod;
   p_erro_msg := 'pessoas_processar: ' || v_erro_msg;
   RAISE v_exception;
   */
  END IF;
  --
  IF p_empresa_id <> v_empresa_pdr_id THEN
   -- nao eh a empresa padrao do usuario admin
   DELETE FROM tipo_arquivo ta
    WHERE empresa_id = p_empresa_id
      AND NOT EXISTS (SELECT 1
             FROM arquivo ar
            WHERE ar.tipo_arquivo_id = ta.tipo_arquivo_id);
   DELETE FROM tipo_apontam ti
    WHERE empresa_id = p_empresa_id
      AND NOT EXISTS (SELECT 1
             FROM apontam_progr ap
            WHERE ap.tipo_apontam_id = ti.tipo_apontam_id)
      AND NOT EXISTS (SELECT 1
             FROM apontam_hora ah
            WHERE ah.tipo_apontam_id = ti.tipo_apontam_id);
   DELETE FROM tipo_apontam_job
    WHERE empresa_id = p_empresa_id;
   DELETE FROM fi_banco
    WHERE empresa_id = p_empresa_id;
   DELETE FROM grupo gr
    WHERE gr.empresa_id = p_empresa_id
      AND NOT EXISTS (SELECT 1
             FROM grupo_pessoa gp
            WHERE gr.grupo_id = gp.grupo_id);
   DELETE FROM status_aux_oport
    WHERE empresa_id = p_empresa_id;
   COMMIT;
   --
   DELETE FROM pessoa_nitem_pdr pp
    WHERE EXISTS (SELECT 1
             FROM natureza_item na
            WHERE na.empresa_id = p_empresa_id
              AND pp.natureza_item_id = na.natureza_item_id);
   --
   DELETE FROM natureza_item
    WHERE empresa_id = p_empresa_id;
   COMMIT;
   --
   DELETE FROM empresa_sist_ext
    WHERE empresa_id = p_empresa_id;
   DELETE FROM sist_ext_ponto_int
    WHERE empresa_id = p_empresa_id;
   COMMIT;
   DELETE FROM empresa_parametro em
    WHERE empresa_id = p_empresa_id
      AND NOT EXISTS (SELECT 1
             FROM tipo_apontam ta
            WHERE ta.empresa_id = em.empresa_id)
      AND NOT EXISTS (SELECT 1
             FROM pessoa pe
            WHERE pe.empresa_id = em.empresa_id);
   DELETE FROM empresa em
    WHERE empresa_id = p_empresa_id
      AND NOT EXISTS (SELECT 1
             FROM tipo_apontam ta
            WHERE ta.empresa_id = em.empresa_id)
      AND NOT EXISTS (SELECT 1
             FROM pessoa pe
            WHERE pe.empresa_id = em.empresa_id);
  END IF;
  --
  ------------------------------------------------------------
  -- marca o termino
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
    'termino_limpeza:' || to_char(p_empresa_id),
    NULL,
    NULL);
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
 END empresa_processar;
 --
 --
 --
 PROCEDURE jobs_processar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 06/08/2015
  -- DESCRICAO: apaga completamente os JOBs de uma empresa.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) AS
  v_qt        INTEGER;
  v_ok        INTEGER;
  v_exception EXCEPTION;
  v_erro_cod  VARCHAR2(100);
  v_erro_msg  VARCHAR2(2000);
  v_texto     VARCHAR2(2000);
  --
  CURSOR c_jo IS
   SELECT job_id,
          numero,
          status
     FROM job
    WHERE empresa_id = p_empresa_id
    ORDER BY job_id;
  --
 BEGIN
  dbms_output.put_line('jobs_processar');
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  FOR r_jo IN c_jo
  LOOP
   UPDATE carta_acordo
      SET job_id = NULL
    WHERE job_id = r_jo.job_id;
   --
   UPDATE nota_fiscal
      SET job_id = NULL
    WHERE job_id = r_jo.job_id;
   --
   limpeza_pkg.job_apagar(p_usuario_sessao_id, p_empresa_id, r_jo.job_id, v_erro_cod, v_erro_msg);
   --
   v_texto := 'LIMPEZA-JOB:' || to_char(r_jo.job_id);
   --
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
      v_texto,
      v_erro_cod,
      v_erro_msg);
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
 END jobs_processar;
 --
 --
 PROCEDURE job_apagar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 06/08/2015
  -- DESCRICAO: apaga completamente um determinado JOB.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            09/10/2018  Remocao do modulo de casting.
  -- Silvia            18/08/2020  Exclusao de os_usuario_data e tarefa_usuario_data
  -- Silvia            01/06/2022  Exclsao de orcam_aprov
  ------------------------------------------------------------------------------------------
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_job_id            IN job.job_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) AS
  v_qt         INTEGER;
  v_ok         INTEGER;
  v_numero_job job.numero%TYPE;
  v_status_job job.status%TYPE;
  v_exception  EXCEPTION;
  --
  CURSOR c_arq_doc IS
   SELECT ad.arquivo_id,
          ar.nome_fisico,
          vo.caminho || '\' || vo.prefixo || '\' || to_char(vo.numero) || '\' || ar.nome_fisico AS nome_completo
     FROM arquivo_documento ad,
          documento         dc,
          arquivo           ar,
          volume            vo
    WHERE dc.job_id = p_job_id
      AND dc.documento_id = ad.documento_id
      AND ad.arquivo_id = ar.arquivo_id
      AND ar.volume_id = vo.volume_id;
  --
  CURSOR c_arq_tas IS
   SELECT aq.arquivo_id,
          ar.nome_fisico,
          vo.caminho || '\' || vo.prefixo || '\' || to_char(vo.numero) || '\' || ar.nome_fisico AS nome_completo
     FROM arquivo_task aq,
          task         ta,
          milestone    mi,
          arquivo      ar,
          volume       vo
    WHERE mi.job_id = p_job_id
      AND mi.milestone_id = ta.milestone_id
      AND ta.task_id = aq.task_id
      AND aq.arquivo_id = ar.arquivo_id
      AND ar.volume_id = vo.volume_id;
  --
  CURSOR c_arq_tar IS
   SELECT aq.arquivo_id,
          ar.nome_fisico,
          vo.caminho || '\' || vo.prefixo || '\' || to_char(vo.numero) || '\' || ar.nome_fisico AS nome_completo
     FROM arquivo_tarefa aq,
          tarefa         ta,
          arquivo        ar,
          volume         vo
    WHERE ta.job_id = p_job_id
      AND ta.tarefa_id = aq.tarefa_id
      AND aq.arquivo_id = ar.arquivo_id
      AND ar.volume_id = vo.volume_id;
  --
  CURSOR c_arq_orc IS
   SELECT aq.arquivo_id,
          ar.nome_fisico,
          vo.caminho || '\' || vo.prefixo || '\' || to_char(vo.numero) || '\' || ar.nome_fisico AS nome_completo
     FROM arquivo_orcamento aq,
          orcamento         oc,
          arquivo           ar,
          volume            vo
    WHERE oc.job_id = p_job_id
      AND oc.orcamento_id = aq.orcamento_id
      AND aq.arquivo_id = ar.arquivo_id
      AND ar.volume_id = vo.volume_id;
  --
  CURSOR c_arq_os IS
   SELECT ao.arquivo_id,
          ar.nome_fisico,
          vo.caminho || '\' || vo.prefixo || '\' || to_char(vo.numero) || '\' || ar.nome_fisico AS nome_completo
     FROM ordem_servico os,
          arquivo_os    ao,
          arquivo       ar,
          volume        vo
    WHERE os.job_id = p_job_id
      AND os.ordem_servico_id = ao.ordem_servico_id
      AND ao.arquivo_id = ar.arquivo_id
      AND ar.volume_id = vo.volume_id;
  --
  CURSOR c_arq_ca IS
   SELECT DISTINCT ac.arquivo_id,
                   ar.nome_fisico,
                   vo.caminho || '\' || vo.prefixo || '\' || to_char(vo.numero) || '\' ||
                   ar.nome_fisico AS nome_completo
     FROM arquivo_carta ac,
          item_carta    ic,
          item          it,
          arquivo       ar,
          volume        vo
    WHERE it.job_id = p_job_id
      AND it.item_id = ic.item_id
      AND ic.carta_acordo_id = ac.carta_acordo_id
      AND ac.arquivo_id = ar.arquivo_id
      AND ar.volume_id = vo.volume_id;
  --
  CURSOR c_arq_nf IS
   SELECT DISTINCT an.arquivo_id,
                   ar.nome_fisico,
                   vo.caminho || '\' || vo.prefixo || '\' || to_char(vo.numero) || '\' ||
                   ar.nome_fisico AS nome_completo
     FROM arquivo_nf an,
          item_nota  io,
          item       it,
          arquivo    ar,
          volume     vo
    WHERE it.job_id = p_job_id
      AND it.item_id = io.item_id
      AND io.nota_fiscal_id = an.nota_fiscal_id
      AND an.arquivo_id = ar.arquivo_id
      AND ar.volume_id = vo.volume_id;
  --
  CURSOR c_arq_jo IS
   SELECT aj.arquivo_id,
          ar.nome_fisico,
          vo.caminho || '\' || vo.prefixo || '\' || to_char(vo.numero) || '\' || ar.nome_fisico AS nome_completo
     FROM arquivo_job aj,
          arquivo     ar,
          volume      vo
    WHERE aj.job_id = p_job_id
      AND aj.arquivo_id = ar.arquivo_id
      AND ar.volume_id = vo.volume_id;
  --
  CURSOR c_item IS
   SELECT item_id
     FROM item
    WHERE job_id = p_job_id;
  --
 BEGIN
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM job
   WHERE job_id = p_job_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse job não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT numero,
         status
    INTO v_numero_job,
         v_status_job
    FROM job
   WHERE job_id = p_job_id;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  FOR r_arq_doc IN c_arq_doc
  LOOP
   INSERT INTO erro_log
    (erro_log_id,
     data,
     nome_programa,
     cod_erro,
     msg_erro)
   VALUES
    (seq_erro_log.nextval,
     SYSDATE,
     'arquivo_remover',
     'DEL',
     r_arq_doc.nome_completo);
   --
   DELETE FROM arquivo_documento
    WHERE arquivo_id = r_arq_doc.arquivo_id;
   --
   DELETE FROM arquivo
    WHERE arquivo_id = r_arq_doc.arquivo_id;
  END LOOP;
  --
  FOR r_arq_tas IN c_arq_tas
  LOOP
   INSERT INTO erro_log
    (erro_log_id,
     data,
     nome_programa,
     cod_erro,
     msg_erro)
   VALUES
    (seq_erro_log.nextval,
     SYSDATE,
     'arquivo_remover',
     'DEL',
     r_arq_tas.nome_completo);
   --
   DELETE FROM arquivo_task
    WHERE arquivo_id = r_arq_tas.arquivo_id;
   --
   DELETE FROM arquivo
    WHERE arquivo_id = r_arq_tas.arquivo_id;
  END LOOP;
  --
  FOR r_arq_tar IN c_arq_tar
  LOOP
   INSERT INTO erro_log
    (erro_log_id,
     data,
     nome_programa,
     cod_erro,
     msg_erro)
   VALUES
    (seq_erro_log.nextval,
     SYSDATE,
     'arquivo_remover',
     'DEL',
     r_arq_tar.nome_completo);
   --
   DELETE FROM arquivo_tarefa
    WHERE arquivo_id = r_arq_tar.arquivo_id;
   --
   DELETE FROM arquivo
    WHERE arquivo_id = r_arq_tar.arquivo_id;
  END LOOP;
  --
  FOR r_arq_orc IN c_arq_orc
  LOOP
   INSERT INTO erro_log
    (erro_log_id,
     data,
     nome_programa,
     cod_erro,
     msg_erro)
   VALUES
    (seq_erro_log.nextval,
     SYSDATE,
     'arquivo_remover',
     'DEL',
     r_arq_orc.nome_completo);
   --
   DELETE FROM arquivo_orcamento
    WHERE arquivo_id = r_arq_orc.arquivo_id;
   --
   DELETE FROM arquivo
    WHERE arquivo_id = r_arq_orc.arquivo_id;
  END LOOP;
  --
  FOR r_arq_os IN c_arq_os
  LOOP
   INSERT INTO erro_log
    (erro_log_id,
     data,
     nome_programa,
     cod_erro,
     msg_erro)
   VALUES
    (seq_erro_log.nextval,
     SYSDATE,
     'arquivo_remover',
     'DEL',
     r_arq_os.nome_completo);
   --
   DELETE FROM arquivo_os
    WHERE arquivo_id = r_arq_os.arquivo_id;
   --
   DELETE FROM arquivo
    WHERE arquivo_id = r_arq_os.arquivo_id;
  END LOOP;
  --
  FOR r_arq_ca IN c_arq_ca
  LOOP
   INSERT INTO erro_log
    (erro_log_id,
     data,
     nome_programa,
     cod_erro,
     msg_erro)
   VALUES
    (seq_erro_log.nextval,
     SYSDATE,
     'arquivo_remover',
     'DEL',
     r_arq_ca.nome_completo);
   --
   DELETE FROM arquivo_carta
    WHERE arquivo_id = r_arq_ca.arquivo_id;
   --
   DELETE FROM arquivo
    WHERE arquivo_id = r_arq_ca.arquivo_id;
  END LOOP;
  --
  FOR r_arq_nf IN c_arq_nf
  LOOP
   INSERT INTO erro_log
    (erro_log_id,
     data,
     nome_programa,
     cod_erro,
     msg_erro)
   VALUES
    (seq_erro_log.nextval,
     SYSDATE,
     'arquivo_remover',
     'DEL',
     r_arq_nf.nome_completo);
   --
   DELETE FROM arquivo_nf
    WHERE arquivo_id = r_arq_nf.arquivo_id;
   --
   DELETE FROM arquivo
    WHERE arquivo_id = r_arq_nf.arquivo_id;
  END LOOP;
  --
  FOR r_arq_jo IN c_arq_jo
  LOOP
   INSERT INTO erro_log
    (erro_log_id,
     data,
     nome_programa,
     cod_erro,
     msg_erro)
   VALUES
    (seq_erro_log.nextval,
     SYSDATE,
     'arquivo_remover',
     'DEL',
     r_arq_jo.nome_completo);
   --
   DELETE FROM arquivo_job
    WHERE arquivo_id = r_arq_jo.arquivo_id;
   --
   DELETE FROM arquivo
    WHERE arquivo_id = r_arq_jo.arquivo_id;
  END LOOP;
  --
  DELETE FROM task_hist_ciencia tc
   WHERE EXISTS (SELECT 1
            FROM task_hist th,
                 task      ta
           WHERE ta.job_id = p_job_id
             AND ta.task_id = th.task_id
             AND th.task_hist_id = tc.task_hist_id);
  --
  DELETE FROM task_hist th
   WHERE EXISTS (SELECT 1
            FROM task ta
           WHERE ta.job_id = p_job_id
             AND ta.task_id = th.task_id);
  --
  DELETE FROM task_coment tc
   WHERE EXISTS (SELECT 1
            FROM task ta
           WHERE ta.job_id = p_job_id
             AND ta.task_id = tc.task_id);
  --
  DELETE FROM task
   WHERE job_id = p_job_id;
  --
  DELETE FROM tipific_milestone tm
   WHERE EXISTS (SELECT 1
            FROM milestone mi
           WHERE mi.job_id = p_job_id
             AND mi.milestone_id = tm.milestone_id);
  --
  DELETE FROM milestone_usuario mu
   WHERE EXISTS (SELECT 1
            FROM milestone mi
           WHERE mi.job_id = p_job_id
             AND mi.milestone_id = mu.milestone_id);
  --
  DELETE FROM brief_atributo_valor bv
   WHERE EXISTS (SELECT 1
            FROM briefing br
           WHERE br.job_id = p_job_id
             AND br.briefing_id = bv.briefing_id);
  --  
  DELETE FROM brief_dicion_valor bv
   WHERE EXISTS (SELECT 1
            FROM briefing br
           WHERE br.job_id = p_job_id
             AND br.briefing_id = bv.briefing_id);
  --  
  DELETE FROM brief_hist bh
   WHERE EXISTS (SELECT 1
            FROM briefing br
           WHERE br.job_id = p_job_id
             AND br.briefing_id = bh.briefing_id);
  --  
  DELETE FROM brief_area ba
   WHERE EXISTS (SELECT 1
            FROM briefing br
           WHERE br.job_id = p_job_id
             AND br.briefing_id = ba.briefing_id);
  --
  UPDATE ordem_servico
     SET milestone_id         = NULL,
         ordem_servico_ori_id = NULL
   WHERE job_id = p_job_id;
  --
  UPDATE tarefa
     SET ordem_servico_id = NULL
   WHERE job_id = p_job_id;
  --
  DELETE FROM milestone
   WHERE job_id = p_job_id;
  --
  DELETE FROM documento
   WHERE job_id = p_job_id;
  DELETE FROM job_usuario
   WHERE job_id = p_job_id;
  DELETE FROM job_peca
   WHERE job_id = p_job_id;
  DELETE FROM apontam_hora
   WHERE job_id = p_job_id;
  DELETE FROM apontam_job
   WHERE job_id = p_job_id;
  --
  FOR r_item IN c_item
  LOOP
   --
   DELETE FROM parcela
    WHERE item_id = r_item.item_id;
   --
   DELETE FROM item_hist
    WHERE item_id = r_item.item_id;
   --
   DELETE FROM item_decup
    WHERE item_id = r_item.item_id;
   --
   DELETE FROM item_nota
    WHERE item_id = r_item.item_id;
   --
   DELETE FROM item_fatur
    WHERE item_id = r_item.item_id;
   --
   DELETE FROM item_carta
    WHERE item_id = r_item.item_id;
   --
   DELETE FROM item_sobra
    WHERE item_id = r_item.item_id;
   --
   DELETE FROM item_abat
    WHERE item_id = r_item.item_id;
   --
   DELETE FROM item_adiant
    WHERE item_id = r_item.item_id;
   --
   DELETE FROM item
    WHERE item_id = r_item.item_id;
  END LOOP;
  --
  DELETE FROM os_usuario_data ou
   WHERE EXISTS (SELECT 1
            FROM ordem_servico os
           WHERE os.job_id = p_job_id
             AND os.ordem_servico_id = ou.ordem_servico_id);
  --
  DELETE FROM os_usuario ou
   WHERE EXISTS (SELECT 1
            FROM ordem_servico os
           WHERE os.job_id = p_job_id
             AND os.ordem_servico_id = ou.ordem_servico_id);
  --
  DELETE FROM os_atributo_valor ot
   WHERE EXISTS (SELECT 1
            FROM ordem_servico os
           WHERE os.job_id = p_job_id
             AND os.ordem_servico_id = ot.ordem_servico_id);
  --
  DELETE FROM os_tp_atributo_valor ot
   WHERE EXISTS (SELECT 1
            FROM ordem_servico os
           WHERE os.job_id = p_job_id
             AND os.ordem_servico_id = ot.ordem_servico_id);
  --
  DELETE FROM os_tipo_produto_ref ot
   WHERE EXISTS (SELECT 1
            FROM ordem_servico os
           WHERE os.job_id = p_job_id
             AND os.ordem_servico_id = ot.ordem_servico_id);
  --
  DELETE FROM os_tipo_produto ot
   WHERE EXISTS (SELECT 1
            FROM ordem_servico os
           WHERE os.job_id = p_job_id
             AND os.ordem_servico_id = ot.ordem_servico_id);
  --
  DELETE FROM os_negociacao ot
   WHERE EXISTS (SELECT 1
            FROM ordem_servico os
           WHERE os.job_id = p_job_id
             AND os.ordem_servico_id = ot.ordem_servico_id);
  --
  UPDATE ordem_servico
     SET os_evento_id = NULL
   WHERE job_id = p_job_id;
  --
  DELETE FROM os_evento oe
   WHERE EXISTS (SELECT 1
            FROM ordem_servico os
           WHERE os.job_id = p_job_id
             AND os.ordem_servico_id = oe.ordem_servico_id);
  --
  DELETE FROM os_refacao oe
   WHERE EXISTS (SELECT 1
            FROM ordem_servico os
           WHERE os.job_id = p_job_id
             AND os.ordem_servico_id = oe.ordem_servico_id);
  --
  DELETE FROM os_horas oh
   WHERE EXISTS (SELECT 1
            FROM ordem_servico os
           WHERE os.job_id = p_job_id
             AND os.ordem_servico_id = oh.ordem_servico_id);
  --
  DELETE FROM os_fluxo_aprov oe
   WHERE EXISTS (SELECT 1
            FROM ordem_servico os
           WHERE os.job_id = p_job_id
             AND os.ordem_servico_id = oe.ordem_servico_id);
  --
  DELETE FROM os_usuario_refacao oe
   WHERE EXISTS (SELECT 1
            FROM ordem_servico os
           WHERE os.job_id = p_job_id
             AND os.ordem_servico_id = oe.ordem_servico_id);
  --
  DELETE FROM os_link ol
   WHERE EXISTS (SELECT 1
            FROM ordem_servico os
           WHERE os.job_id = p_job_id
             AND os.ordem_servico_id = ol.ordem_servico_id);
  --
  DELETE FROM os_afazer oa
   WHERE EXISTS (SELECT 1
            FROM ordem_servico os
           WHERE os.job_id = p_job_id
             AND os.ordem_servico_id = oa.ordem_servico_id);
  --
  DELETE FROM orcam_nitem_pdr op
   WHERE EXISTS (SELECT 1
            FROM orcamento oc
           WHERE oc.job_id = p_job_id
             AND oc.orcamento_id = op.orcamento_id);
  --                  
  DELETE FROM orcam_usuario ou
   WHERE EXISTS (SELECT 1
            FROM orcamento oc
           WHERE oc.job_id = p_job_id
             AND oc.orcamento_id = ou.orcamento_id);
  --                  
  DELETE FROM orcam_fluxo_aprov oa
   WHERE EXISTS (SELECT 1
            FROM orcamento oc
           WHERE oc.job_id = p_job_id
             AND oc.orcamento_id = oa.orcamento_id);
  --
  DELETE FROM item_crono_dest ic
   WHERE EXISTS (SELECT 1
            FROM cronograma cr,
                 item_crono it
           WHERE cr.job_id = p_job_id
             AND cr.cronograma_id = it.cronograma_id
             AND it.item_crono_id = ic.item_crono_id);
  --
  DELETE FROM item_crono_pre ic
   WHERE EXISTS (SELECT 1
            FROM cronograma cr,
                 item_crono it
           WHERE cr.job_id = p_job_id
             AND cr.cronograma_id = it.cronograma_id
             AND it.item_crono_id = ic.item_crono_pre_id);
  --
  DELETE FROM item_crono_pre ic
   WHERE EXISTS (SELECT 1
            FROM cronograma cr,
                 item_crono it
           WHERE cr.job_id = p_job_id
             AND cr.cronograma_id = it.cronograma_id
             AND it.item_crono_id = ic.item_crono_id);
  --
  DELETE FROM item_crono_usu ic
   WHERE EXISTS (SELECT 1
            FROM cronograma cr,
                 item_crono it
           WHERE cr.job_id = p_job_id
             AND cr.cronograma_id = it.cronograma_id
             AND it.item_crono_id = ic.item_crono_id);
  --
  DELETE FROM item_crono_dia ic
   WHERE EXISTS (SELECT 1
            FROM cronograma cr,
                 item_crono it
           WHERE cr.job_id = p_job_id
             AND cr.cronograma_id = it.cronograma_id
             AND it.item_crono_id = ic.item_crono_id);
  --
  DELETE FROM item_crono ic
   WHERE EXISTS (SELECT 1
            FROM cronograma cr
           WHERE cr.job_id = p_job_id
             AND cr.cronograma_id = ic.cronograma_id);
  --
  DELETE FROM devol_realiz dr
   WHERE EXISTS (SELECT 1
            FROM adiant_desp ad
           WHERE ad.job_id = p_job_id
             AND ad.adiant_desp_id = dr.adiant_desp_id);
  --
  DELETE FROM desp_realiz dr
   WHERE EXISTS (SELECT 1
            FROM adiant_desp ad
           WHERE ad.job_id = p_job_id
             AND ad.adiant_desp_id = dr.adiant_desp_id);
  --
  DELETE FROM adiant_realiz ar
   WHERE EXISTS (SELECT 1
            FROM adiant_desp ad
           WHERE ad.job_id = p_job_id
             AND ad.adiant_desp_id = ar.adiant_desp_id);
  --
  DELETE FROM tarefa_evento te
   WHERE EXISTS (SELECT 1
            FROM tarefa ta
           WHERE ta.job_id = p_job_id
             AND ta.tarefa_id = te.tarefa_id);
  --
  DELETE FROM tarefa_usuario_data tu
   WHERE EXISTS (SELECT 1
            FROM tarefa ta
           WHERE ta.job_id = p_job_id
             AND ta.tarefa_id = tu.tarefa_id);
  --
  DELETE FROM tarefa_usuario tu
   WHERE EXISTS (SELECT 1
            FROM tarefa ta
           WHERE ta.job_id = p_job_id
             AND ta.tarefa_id = tu.tarefa_id);
  --
  DELETE FROM tarefa_link tl
   WHERE EXISTS (SELECT 1
            FROM tarefa ta
           WHERE ta.job_id = p_job_id
             AND ta.tarefa_id = tl.tarefa_id);
  --
  DELETE FROM tarefa_afazer tf
   WHERE EXISTS (SELECT 1
            FROM tarefa ta
           WHERE ta.job_id = p_job_id
             AND ta.tarefa_id = tf.tarefa_id);
  -- 
  DELETE FROM tarefa_tp_atrib_valor tv
   WHERE EXISTS (SELECT 1
            FROM tarefa_tipo_produto tt,
                 tarefa              ta
           WHERE ta.job_id = p_job_id
             AND ta.tarefa_id = tt.tarefa_id
             AND tt.tarefa_tipo_produto_id = tv.tarefa_tipo_produto_id);
  --
  DELETE FROM tarefa_tipo_produto tt
   WHERE EXISTS (SELECT 1
            FROM tarefa ta
           WHERE ta.job_id = p_job_id
             AND ta.tarefa_id = tt.tarefa_id);
  --
  DELETE FROM briefing
   WHERE job_id = p_job_id;
  DELETE FROM abatimento
   WHERE job_id = p_job_id;
  DELETE FROM sobra
   WHERE job_id = p_job_id;
  DELETE FROM carta_acordo
   WHERE job_id = p_job_id;
  DELETE FROM ordem_servico
   WHERE job_id = p_job_id;
  DELETE FROM orcamento
   WHERE job_id = p_job_id;
  --     
  DELETE FROM faturamento
   WHERE job_id = p_job_id;
  DELETE FROM ajuste_job
   WHERE job_id = p_job_id;
  DELETE FROM tarefa
   WHERE job_id = p_job_id;
  DELETE FROM job_horas
   WHERE job_id = p_job_id;
  DELETE FROM job_nitem_pdr
   WHERE job_id = p_job_id;
  DELETE FROM os_estim
   WHERE job_id = p_job_id;
  DELETE FROM cronograma
   WHERE job_id = p_job_id;
  DELETE FROM job_tipo_produto
   WHERE job_id = p_job_id;
  DELETE FROM adiant_desp
   WHERE job_id = p_job_id;
  --
  DELETE FROM job
   WHERE job_id = p_job_id;
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
 END job_apagar;
 --
 --
 --
 PROCEDURE oportunidades_processar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 11/03/2019
  -- DESCRICAO: apaga completamente as OPORTUNIDADES de uma empresa.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) AS
  v_qt        INTEGER;
  v_exception EXCEPTION;
  v_erro_cod  VARCHAR2(100);
  v_erro_msg  VARCHAR2(2000);
  v_texto     VARCHAR2(2000);
  --
  CURSOR c_op IS
   SELECT oportunidade_id,
          numero,
          status
     FROM oportunidade
    WHERE empresa_id = p_empresa_id
    ORDER BY oportunidade_id;
  --
 BEGIN
  dbms_output.put_line('oportunidades_processar');
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  FOR r_op IN c_op
  LOOP
   limpeza_pkg.oportunidade_apagar(p_usuario_sessao_id,
                                   p_empresa_id,
                                   r_op.oportunidade_id,
                                   v_erro_cod,
                                   v_erro_msg);
   --
   v_texto := 'LIMPEZA-OPORTUNIDADE:' || to_char(r_op.oportunidade_id);
   --
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
      v_texto,
      v_erro_cod,
      v_erro_msg);
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
 END oportunidades_processar;
 --
 --
 PROCEDURE oportunidade_apagar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 11/03/2019
  -- DESCRICAO: apaga completamente uma determinada OPORTUNIDADE.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            06/12/2019  Eliminacao de oport_usuario_papel
  -- Silvia            15/01/2021  Eliminacao de oport_servico
  -- Silvia            15/09/2022  Eliminacao de apontam_oport
  ------------------------------------------------------------------------------------------
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_oportunidade_id   IN oportunidade.oportunidade_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) AS
  v_qt        INTEGER;
  v_exception EXCEPTION;
  --
  CURSOR c_arq_op IS
   SELECT ao.arquivo_id,
          ar.nome_fisico,
          vo.caminho || '\' || vo.prefixo || '\' || to_char(vo.numero) || '\' || ar.nome_fisico AS nome_completo
     FROM oportunidade         op,
          arquivo_oportunidade ao,
          arquivo              ar,
          volume               vo
    WHERE op.oportunidade_id = p_oportunidade_id
      AND op.oportunidade_id = ao.oportunidade_id
      AND ao.arquivo_id = ar.arquivo_id
      AND ar.volume_id = vo.volume_id;
  --
  CURSOR c_arq_ce IS
   SELECT ac.arquivo_id,
          ar.nome_fisico,
          vo.caminho || '\' || vo.prefixo || '\' || to_char(vo.numero) || '\' || ar.nome_fisico AS nome_completo
     FROM cenario         ce,
          arquivo_cenario ac,
          arquivo         ar,
          volume          vo
    WHERE ce.oportunidade_id = p_oportunidade_id
      AND ce.cenario_id = ac.cenario_id
      AND ac.arquivo_id = ar.arquivo_id
      AND ar.volume_id = vo.volume_id;
  --
 BEGIN
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM oportunidade
   WHERE oportunidade_id = p_oportunidade_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa Oportunidade não existe.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE oportunidade
     SET arquivo_prop_id      = NULL,
         arquivo_prec_id      = NULL,
         cenario_escolhido_id = NULL
   WHERE oportunidade_id = p_oportunidade_id;
  --
  FOR r_arq_ce IN c_arq_ce
  LOOP
   INSERT INTO erro_log
    (erro_log_id,
     data,
     nome_programa,
     cod_erro,
     msg_erro)
   VALUES
    (seq_erro_log.nextval,
     SYSDATE,
     'arquivo_remover',
     'DEL',
     r_arq_ce.nome_completo);
   --
   DELETE FROM arquivo_cenario
    WHERE arquivo_id = r_arq_ce.arquivo_id;
   --
   DELETE FROM arquivo
    WHERE arquivo_id = r_arq_ce.arquivo_id;
  END LOOP;
  --
  FOR r_arq_op IN c_arq_op
  LOOP
   INSERT INTO erro_log
    (erro_log_id,
     data,
     nome_programa,
     cod_erro,
     msg_erro)
   VALUES
    (seq_erro_log.nextval,
     SYSDATE,
     'arquivo_remover',
     'DEL',
     r_arq_op.nome_completo);
   --
   DELETE FROM arquivo_oportunidade
    WHERE arquivo_id = r_arq_op.arquivo_id;
   --
   DELETE FROM arquivo
    WHERE arquivo_id = r_arq_op.arquivo_id;
  END LOOP;
  --
  DELETE FROM oport_usuario
   WHERE oportunidade_id = p_oportunidade_id;
  DELETE FROM oport_servico
   WHERE oportunidade_id = p_oportunidade_id;
  DELETE FROM cenario_servico cs
   WHERE EXISTS (SELECT 1
            FROM cenario ce
           WHERE ce.oportunidade_id = p_oportunidade_id
             AND ce.cenario_id = cs.cenario_id);
  DELETE FROM cenario_empresa cs
   WHERE EXISTS (SELECT 1
            FROM cenario ce
           WHERE ce.oportunidade_id = p_oportunidade_id
             AND ce.cenario_id = cs.cenario_id);
  --
  DELETE FROM cenario
   WHERE oportunidade_id = p_oportunidade_id;
  DELETE FROM interacao
   WHERE oportunidade_id = p_oportunidade_id;
  DELETE FROM apontam_hora
   WHERE oportunidade_id = p_oportunidade_id;
  DELETE FROM apontam_oport
   WHERE oportunidade_id = p_oportunidade_id;
  DELETE FROM oportunidade
   WHERE oportunidade_id = p_oportunidade_id;
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
 END oportunidade_apagar;
 --
 --
 --
 PROCEDURE tasks_processar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 06/08/2015
  -- DESCRICAO: apaga completamente os TASKs de uma empresa.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) AS
  v_qt        INTEGER;
  v_ok        INTEGER;
  v_exception EXCEPTION;
  v_erro_cod  VARCHAR2(100);
  v_erro_msg  VARCHAR2(2000);
  v_texto     VARCHAR2(2000);
  --
  CURSOR c_ta IS
   SELECT task_id
     FROM task
    WHERE empresa_id = p_empresa_id
    ORDER BY task_id;
  --
 BEGIN
  dbms_output.put_line('tasks_processar');
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  FOR r_ta IN c_ta
  LOOP
   limpeza_pkg.task_apagar(p_usuario_sessao_id, p_empresa_id, r_ta.task_id, v_erro_cod, v_erro_msg);
   --
   v_texto := 'LIMPEZA-TASK:' || to_char(r_ta.task_id);
   --
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
      v_texto,
      v_erro_cod,
      v_erro_msg);
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
 END tasks_processar;
 --
 --
 PROCEDURE task_apagar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 06/08/2015
  -- DESCRICAO: apaga completamente uma determinada TASK.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_task_id           IN task.task_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) AS
  v_qt        INTEGER;
  v_ok        INTEGER;
  v_exception EXCEPTION;
  --
  CURSOR c_arq_tas IS
   SELECT aq.arquivo_id,
          ar.nome_fisico,
          vo.caminho || '\' || vo.prefixo || '\' || to_char(vo.numero) || '\' || ar.nome_fisico AS nome_completo
     FROM arquivo_task aq,
          task         ta,
          arquivo      ar,
          volume       vo
    WHERE ta.task_id = p_task_id
      AND ta.task_id = aq.task_id
      AND aq.arquivo_id = ar.arquivo_id
      AND ar.volume_id = vo.volume_id;
  --
 BEGIN
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  --
  FOR r_arq_tas IN c_arq_tas
  LOOP
   INSERT INTO erro_log
    (erro_log_id,
     data,
     nome_programa,
     cod_erro,
     msg_erro)
   VALUES
    (seq_erro_log.nextval,
     SYSDATE,
     'arquivo_remover',
     'DEL',
     r_arq_tas.nome_completo);
   --
   DELETE FROM arquivo_task
    WHERE arquivo_id = r_arq_tas.arquivo_id;
   --
   DELETE FROM arquivo
    WHERE arquivo_id = r_arq_tas.arquivo_id;
  END LOOP;
  --
  DELETE FROM task_hist_ciencia tc
   WHERE EXISTS (SELECT 1
            FROM task_hist th
           WHERE th.task_id = p_task_id
             AND th.task_hist_id = tc.task_hist_id);
  --
  DELETE FROM task_hist
   WHERE task_id = p_task_id;
  --
  DELETE FROM task_coment
   WHERE task_id = p_task_id;
  --
  DELETE FROM task
   WHERE task_id = p_task_id;
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
 END task_apagar;
 --
 --
 --
 PROCEDURE milestones_processar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 06/08/2015
  -- DESCRICAO: apaga completamente os MILESTONEs de uma empresa.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) AS
  v_qt        INTEGER;
  v_ok        INTEGER;
  v_exception EXCEPTION;
  v_erro_cod  VARCHAR2(100);
  v_erro_msg  VARCHAR2(2000);
  v_texto     VARCHAR2(2000);
  --
  CURSOR c_mi IS
   SELECT milestone_id
     FROM milestone
    WHERE empresa_id = p_empresa_id
    ORDER BY milestone_id;
  --
 BEGIN
  dbms_output.put_line('milestones_processar');
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  FOR r_mi IN c_mi
  LOOP
   limpeza_pkg.task_apagar(p_usuario_sessao_id,
                           p_empresa_id,
                           r_mi.milestone_id,
                           v_erro_cod,
                           v_erro_msg);
   --
   v_texto := 'LIMPEZA-MILESTONE:' || to_char(r_mi.milestone_id);
   --
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
      v_texto,
      v_erro_cod,
      v_erro_msg);
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
 END milestones_processar;
 --
 --
 PROCEDURE milestone_apagar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 06/08/2015
  -- DESCRICAO: apaga completamente um determinado MILESTONE.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_milestone_id      IN milestone.milestone_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) AS
  v_qt        INTEGER;
  v_ok        INTEGER;
  v_exception EXCEPTION;
  --
 BEGIN
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE ordem_servico
     SET milestone_id = NULL
   WHERE milestone_id = p_milestone_id;
  --
  UPDATE task
     SET milestone_id = NULL
   WHERE milestone_id = p_milestone_id;
  --                      
  DELETE FROM tipific_milestone
   WHERE milestone_id = p_milestone_id;
  --
  DELETE FROM milestone_usuario
   WHERE milestone_id = p_milestone_id;
  --
  DELETE FROM milestone
   WHERE milestone_id = p_milestone_id;
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
 END milestone_apagar;
 --
 --
 --
 PROCEDURE contratos_processar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 25/04/2019
  -- DESCRICAO: apaga completamente os CONTRATOs de uma empresa.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) AS
  v_qt        INTEGER;
  v_ok        INTEGER;
  v_exception EXCEPTION;
  v_erro_cod  VARCHAR2(100);
  v_erro_msg  VARCHAR2(2000);
  v_texto     VARCHAR2(2000);
  --
  CURSOR c_ct IS
   SELECT contrato_id
     FROM contrato
    WHERE empresa_id = p_empresa_id
    ORDER BY contrato_id;
  --
 BEGIN
  dbms_output.put_line('contratos_processar');
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  FOR r_ct IN c_ct
  LOOP
   limpeza_pkg.contrato_apagar(p_usuario_sessao_id,
                               p_empresa_id,
                               r_ct.contrato_id,
                               v_erro_cod,
                               v_erro_msg);
   --
   v_texto := 'LIMPEZA-CONTRATO:' || to_char(r_ct.contrato_id);
   --
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
      v_texto,
      v_erro_cod,
      v_erro_msg);
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
 END contratos_processar;
 --
 --
 PROCEDURE contrato_apagar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 25/04/2019
  -- DESCRICAO: apaga completamente um determinado CONTRATO.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            06/12/2019  Eliminacao de contrato_usuario_papel
  -- Silvia            21/06/2022  Eliminacao de contrato_elab, contrato_fisico, 
  --                               arquivo_contrato_fisico e contrato_horas_usu
  ------------------------------------------------------------------------------------------
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_contrato_id       IN contrato.contrato_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) AS
  v_qt        INTEGER;
  v_ok        INTEGER;
  v_exception EXCEPTION;
  --     
  CURSOR c_arq_ct IS
   SELECT ac.arquivo_id,
          ar.nome_fisico,
          vo.caminho || '\' || vo.prefixo || '\' || to_char(vo.numero) || '\' || ar.nome_fisico AS nome_completo
     FROM arquivo_contrato ac,
          contrato         co,
          arquivo          ar,
          volume           vo
    WHERE co.contrato_id = p_contrato_id
      AND co.contrato_id = ac.contrato_id
      AND ac.arquivo_id = ar.arquivo_id
      AND ar.volume_id = vo.volume_id;
  --     
  CURSOR c_arq_fi IS
   SELECT ac.arquivo_id,
          ar.nome_fisico,
          vo.caminho || '\' || vo.prefixo || '\' || to_char(vo.numero) || '\' || ar.nome_fisico AS nome_completo
     FROM arquivo_contrato_fisico ac,
          contrato_fisico         cf,
          contrato                co,
          arquivo                 ar,
          volume                  vo
    WHERE cf.contrato_id = p_contrato_id
      AND cf.contrato_fisico_id = ac.contrato_fisico_id
      AND cf.contrato_id = co.contrato_id
      AND ac.arquivo_id = ar.arquivo_id
      AND ar.volume_id = vo.volume_id;
  --
 BEGIN
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM contrato
   WHERE contrato_id = p_contrato_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse contrato não existe.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  FOR r_arq_ct IN c_arq_ct
  LOOP
   INSERT INTO erro_log
    (erro_log_id,
     data,
     nome_programa,
     cod_erro,
     msg_erro)
   VALUES
    (seq_erro_log.nextval,
     SYSDATE,
     'arquivo_remover',
     'DEL',
     r_arq_ct.nome_completo);
   --
   DELETE FROM arquivo_contrato
    WHERE arquivo_id = r_arq_ct.arquivo_id;
   --
   DELETE FROM arquivo
    WHERE arquivo_id = r_arq_ct.arquivo_id;
  END LOOP;
  --
  FOR r_arq_fi IN c_arq_fi
  LOOP
   INSERT INTO erro_log
    (erro_log_id,
     data,
     nome_programa,
     cod_erro,
     msg_erro)
   VALUES
    (seq_erro_log.nextval,
     SYSDATE,
     'arquivo_remover',
     'DEL',
     r_arq_fi.nome_completo);
   --
   DELETE FROM arquivo_contrato_fisico
    WHERE arquivo_id = r_arq_fi.arquivo_id;
   --
   DELETE FROM arquivo
    WHERE arquivo_id = r_arq_fi.arquivo_id;
  END LOOP;
  --
  UPDATE job
     SET contrato_id = NULL
   WHERE contrato_id = p_contrato_id;
  --
  DELETE FROM contrato_horas_usu cs
   WHERE EXISTS (SELECT 1
            FROM contrato_horas ch
           WHERE ch.contrato_id = p_contrato_id
             AND ch.contrato_horas_id = cs.contrato_horas_id);
  DELETE FROM contrato_horas
   WHERE contrato_id = p_contrato_id;
  DELETE FROM abatimento_ctr ab
   WHERE EXISTS (SELECT 1
            FROM parcela_contrato pc
           WHERE pc.contrato_id = p_contrato_id
             AND pc.parcela_contrato_id = ab.parcela_contrato_id);
  DELETE FROM parcela_fatur_ctr pf
   WHERE EXISTS (SELECT 1
            FROM faturamento_ctr fa
           WHERE fa.contrato_id = p_contrato_id
             AND fa.faturamento_ctr_id = pf.faturamento_ctr_id);
  DELETE FROM parcela_contrato
   WHERE contrato_id = p_contrato_id;
  DELETE FROM faturamento_ctr
   WHERE contrato_id = p_contrato_id;
  DELETE FROM contrato_usuario
   WHERE contrato_id = p_contrato_id;
  DELETE FROM contrato_nitem_pdr
   WHERE contrato_id = p_contrato_id;
  DELETE FROM contrato_serv_valor cv
   WHERE EXISTS (SELECT 1
            FROM contrato_servico cs
           WHERE cs.contrato_id = p_contrato_id
             AND cs.contrato_servico_id = cv.contrato_servico_id);
  DELETE FROM contrato_servico
   WHERE contrato_id = p_contrato_id;
  DELETE FROM apontam_hora
   WHERE contrato_id = p_contrato_id;
  DELETE FROM contrato_elab
   WHERE contrato_id = p_contrato_id;
  DELETE FROM contrato_fisico
   WHERE contrato_id = p_contrato_id;
  DELETE FROM contrato
   WHERE contrato_id = p_contrato_id;
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
 END contrato_apagar;
 --
 --
 --
 PROCEDURE papeis_processar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 06/08/2015
  -- DESCRICAO: apaga completamente os PAPEIS de uma empresa.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) AS
  v_qt        INTEGER;
  v_ok        INTEGER;
  v_exception EXCEPTION;
  v_erro_cod  VARCHAR2(100);
  v_erro_msg  VARCHAR2(2000);
  v_texto     VARCHAR2(2000);
  --
  CURSOR c_pa IS
   SELECT papel_id
     FROM papel
    WHERE empresa_id = p_empresa_id
    ORDER BY papel_id;
  --
 BEGIN
  dbms_output.put_line('papeis_processar');
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  FOR r_pa IN c_pa
  LOOP
   limpeza_pkg.papel_apagar(p_usuario_sessao_id,
                            p_empresa_id,
                            r_pa.papel_id,
                            v_erro_cod,
                            v_erro_msg);
   --
   v_texto := 'LIMPEZA-PAPEL:' || to_char(r_pa.papel_id);
   --
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
      v_texto,
      v_erro_cod,
      v_erro_msg);
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
 END papeis_processar;
 --
 --
 PROCEDURE papel_apagar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 06/08/2015
  -- DESCRICAO: apaga completamente um determinado PAPEL.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            03/03/3030  Eliminacao de painel
  -- Silvia            28/04/2020  Eliminacao de inbox
  -- Silvia            10/06/2020  Eliminacao de papel_nivel
  ------------------------------------------------------------------------------------------
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_papel_id          IN papel.papel_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) AS
  v_qt        INTEGER;
  v_ok        INTEGER;
  v_exception EXCEPTION;
  --
  CURSOR c_arq_doc IS
   SELECT ad.arquivo_id,
          ar.nome_fisico,
          vo.caminho || '\' || vo.prefixo || '\' || to_char(vo.numero) || '\' || ar.nome_fisico AS nome_completo
     FROM arquivo_documento ad,
          documento         dc,
          arquivo           ar,
          volume            vo
    WHERE dc.papel_resp_id = p_papel_id
      AND dc.documento_id = ad.documento_id
      AND ad.arquivo_id = ar.arquivo_id
      AND ar.volume_id = vo.volume_id;
  --
 BEGIN
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  FOR r_arq_doc IN c_arq_doc
  LOOP
   INSERT INTO erro_log
    (erro_log_id,
     data,
     nome_programa,
     cod_erro,
     msg_erro)
   VALUES
    (seq_erro_log.nextval,
     SYSDATE,
     'arquivo_remover',
     'DEL',
     r_arq_doc.nome_completo);
   --
   DELETE FROM arquivo_documento
    WHERE arquivo_id = r_arq_doc.arquivo_id;
   --
   DELETE FROM arquivo
    WHERE arquivo_id = r_arq_doc.arquivo_id;
  END LOOP;
  --
  UPDATE milestone
     SET papel_resp_id = NULL
   WHERE papel_resp_id = p_papel_id;
  --
  UPDATE task
     SET papel_resp_id = NULL
   WHERE papel_resp_id = p_papel_id;
  --
  UPDATE mod_item_crono
     SET papel_resp_id = NULL
   WHERE papel_resp_id = p_papel_id;
  --
  UPDATE item_crono
     SET papel_resp_id = NULL
   WHERE papel_resp_id = p_papel_id;
  --
  DELETE FROM mod_item_crono_dest
   WHERE papel_id = p_papel_id;
  DELETE FROM documento
   WHERE papel_resp_id = p_papel_id;
  DELETE FROM apontam_hora
   WHERE papel_id = p_papel_id;
  DELETE FROM notifica_papel
   WHERE papel_id = p_papel_id;
  DELETE FROM usuario_papel
   WHERE papel_id = p_papel_id;
  DELETE FROM papel_priv_tpessoa
   WHERE papel_id = p_papel_id;
  DELETE FROM papel_priv_tdoc
   WHERE papel_id = p_papel_id;
  DELETE FROM papel_priv_tfin
   WHERE papel_id = p_papel_id;
  DELETE FROM papel_priv_tjob
   WHERE papel_id = p_papel_id;
  DELETE FROM papel_priv_tos
   WHERE papel_id = p_papel_id;
  DELETE FROM papel_priv_area
   WHERE papel_id = p_papel_id;
  DELETE FROM papel_priv
   WHERE papel_id = p_papel_id;
  DELETE FROM faixa_aprov_papel
   WHERE papel_id = p_papel_id;
  DELETE FROM carta_fluxo_aprov
   WHERE papel_id = p_papel_id;
  DELETE FROM papel
   WHERE papel_id = p_papel_id;
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
 END papel_apagar;
 --
 --
 --
 PROCEDURE pessoas_processar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 06/08/2015
  -- DESCRICAO: apaga completamente as PESSOAS de uma empresa.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) AS
  v_qt             INTEGER;
  v_ok             INTEGER;
  v_exception      EXCEPTION;
  v_erro_cod       VARCHAR2(100);
  v_erro_msg       VARCHAR2(2000);
  v_texto          VARCHAR2(2000);
  v_usuario_adm_id usuario.usuario_id%TYPE;
  v_empresa_pdr_id empresa.empresa_id%TYPE;
  --
  CURSOR c_pe IS
   SELECT pessoa_id,
          nvl(usuario_pkg.empresa_padrao_retornar(usuario_id), 0) AS empresa_pdr_id
     FROM pessoa pe
    WHERE empresa_id = p_empresa_id
      AND NOT EXISTS (SELECT 1
             FROM usuario us
            WHERE us.usuario_id = pe.usuario_id
              AND us.flag_admin_sistema = 'S')
    ORDER BY pessoa_id;
  --
 BEGIN
  dbms_output.put_line('pessoas_processar');
  --
  SELECT MAX(usuario_id)
    INTO v_usuario_adm_id
    FROM usuario
   WHERE flag_admin_sistema = 'S';
  --
  v_empresa_pdr_id := nvl(usuario_pkg.empresa_padrao_retornar(v_usuario_adm_id), 0);
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  FOR r_pe IN c_pe
  LOOP
   IF r_pe.empresa_pdr_id = 0 OR r_pe.empresa_pdr_id = p_empresa_id THEN
    -- pessoa nao eh um usuario ou eh usuario da mesma empresa que esta sendo apagada
    limpeza_pkg.pessoa_apagar(p_usuario_sessao_id,
                              p_empresa_id,
                              r_pe.pessoa_id,
                              v_erro_cod,
                              v_erro_msg);
    --
    v_texto := 'LIMPEZA-PESSOA:' || to_char(r_pe.pessoa_id);
    --
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
       v_texto,
       v_erro_cod,
       v_erro_msg);
    END IF;
   END IF;
  END LOOP;
  COMMIT;
  --
  --
  DELETE FROM usuario_empresa
   WHERE empresa_id = p_empresa_id
     AND (usuario_id <> v_usuario_adm_id OR flag_padrao = 'N');
  --
  DELETE FROM tarefa_evento te
   WHERE NOT EXISTS (SELECT 1
            FROM pessoa pe
           WHERE pe.usuario_id = te.usuario_id)
     AND NOT EXISTS (SELECT 1
            FROM usuario_empresa ue
           WHERE ue.usuario_id = te.usuario_id);
  --
  DELETE FROM ts_equipe us
   WHERE NOT EXISTS (SELECT 1
            FROM pessoa pe
           WHERE pe.usuario_id = us.usuario_id)
     AND NOT EXISTS (SELECT 1
            FROM usuario_empresa ue
           WHERE ue.usuario_id = us.usuario_id);
  --
  DELETE FROM ts_aprovador us
   WHERE NOT EXISTS (SELECT 1
            FROM pessoa pe
           WHERE pe.usuario_id = us.usuario_id)
     AND NOT EXISTS (SELECT 1
            FROM usuario_empresa ue
           WHERE ue.usuario_id = us.usuario_id);
  --
  DELETE FROM ts_grupo us
   WHERE NOT EXISTS (SELECT 1
            FROM pessoa pe
           WHERE pe.usuario_id = us.usuario_resp_id)
     AND NOT EXISTS (SELECT 1
            FROM usuario_empresa ue
           WHERE ue.usuario_id = us.usuario_resp_id)
     AND NOT EXISTS (SELECT 1
            FROM ts_aprovador ta
           WHERE ta.ts_grupo_id = us.ts_grupo_id)
     AND NOT EXISTS (SELECT 1
            FROM ts_equipe te
           WHERE te.ts_grupo_id = us.ts_grupo_id);
  --
  DELETE FROM hist_senha us
   WHERE NOT EXISTS (SELECT 1
            FROM pessoa pe
           WHERE pe.usuario_id = us.usuario_id)
     AND NOT EXISTS (SELECT 1
            FROM usuario_empresa ue
           WHERE ue.usuario_id = us.usuario_id);
  --
  DELETE FROM coment_usuario us
   WHERE NOT EXISTS (SELECT 1
            FROM pessoa pe
           WHERE pe.usuario_id = us.usuario_id)
     AND NOT EXISTS (SELECT 1
            FROM usuario_empresa ue
           WHERE ue.usuario_id = us.usuario_id);
  --
  DELETE FROM coment_usuario us
   WHERE EXISTS (SELECT 1
            FROM comentario co
           WHERE NOT EXISTS (SELECT 1
                    FROM pessoa pe
                   WHERE pe.usuario_id = co.usuario_id)
             AND NOT EXISTS (SELECT 1
                    FROM usuario_empresa ue
                   WHERE ue.usuario_id = co.usuario_id)
             AND co.comentario_id = us.comentario_id);
  --
  UPDATE comentario us
     SET comentario_pai_id = NULL
   WHERE NOT EXISTS (SELECT 1
            FROM pessoa pe
           WHERE pe.usuario_id = us.usuario_id)
     AND NOT EXISTS (SELECT 1
            FROM usuario_empresa ue
           WHERE ue.usuario_id = us.usuario_id);
  --
  DELETE FROM comentario us
   WHERE NOT EXISTS (SELECT 1
            FROM pessoa pe
           WHERE pe.usuario_id = us.usuario_id)
     AND NOT EXISTS (SELECT 1
            FROM usuario_empresa ue
           WHERE ue.usuario_id = us.usuario_id)
     AND NOT EXISTS (SELECT 1
            FROM comentario c2
           WHERE c2.comentario_pai_id = us.comentario_id);
  --
  COMMIT;
  --
  DELETE FROM dia_alocacao us
   WHERE NOT EXISTS (SELECT 1
            FROM pessoa pe
           WHERE pe.usuario_id = us.usuario_id)
     AND NOT EXISTS (SELECT 1
            FROM usuario_empresa ue
           WHERE ue.usuario_id = us.usuario_id)
     AND NOT EXISTS (SELECT 1
            FROM usuario_cargo uc
           WHERE uc.usuario_id = us.usuario_id)
     AND NOT EXISTS (SELECT 1
            FROM job_usuario ju
           WHERE ju.usuario_id = us.usuario_id)
     AND NOT EXISTS (SELECT 1
            FROM historico ue
           WHERE ue.usuario_id = us.usuario_id)
     AND NOT EXISTS (SELECT 1
            FROM comentario co
           WHERE co.usuario_id = us.usuario_id)
     AND NOT EXISTS (SELECT 1
            FROM apontam_data ad
           WHERE ad.usuario_aprov_id = us.usuario_id)
     AND NOT EXISTS (SELECT 1
            FROM os_evento oe
           WHERE oe.usuario_id = us.usuario_id);
  COMMIT;
  --
  DELETE FROM usuario us
   WHERE NOT EXISTS (SELECT 1
            FROM pessoa pe
           WHERE pe.usuario_id = us.usuario_id)
     AND NOT EXISTS (SELECT 1
            FROM usuario_empresa ue
           WHERE ue.usuario_id = us.usuario_id)
     AND NOT EXISTS (SELECT 1
            FROM usuario_cargo uc
           WHERE uc.usuario_id = us.usuario_id)
     AND NOT EXISTS (SELECT 1
            FROM job_usuario ju
           WHERE ju.usuario_id = us.usuario_id)
     AND NOT EXISTS (SELECT 1
            FROM historico ue
           WHERE ue.usuario_id = us.usuario_id)
     AND NOT EXISTS (SELECT 1
            FROM comentario co
           WHERE co.usuario_id = us.usuario_id)
     AND NOT EXISTS (SELECT 1
            FROM apontam_data ad
           WHERE ad.usuario_aprov_id = us.usuario_id)
     AND NOT EXISTS (SELECT 1
            FROM dia_alocacao ad
           WHERE ad.usuario_id = us.usuario_id)
     AND NOT EXISTS (SELECT 1
            FROM ts_grupo tg
           WHERE tg.usuario_resp_id = us.usuario_id)
     AND NOT EXISTS (SELECT 1
            FROM cronograma cr
           WHERE cr.usuario_status_id = us.usuario_id)
     AND NOT EXISTS (SELECT 1
            FROM os_evento oe
           WHERE oe.usuario_id = us.usuario_id);
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
 END pessoas_processar;
 --
 --
 PROCEDURE pessoa_apagar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 06/08/2015
  -- DESCRICAO: apaga completamente um determinada PESSOA.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_pessoa_id         IN pessoa.pessoa_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) AS
  v_qt                 INTEGER;
  v_ok                 INTEGER;
  v_exception          EXCEPTION;
  v_usuario_id         pessoa.usuario_id%TYPE;
  v_flag_admin_sistema usuario.flag_admin_sistema%TYPE;
  --
  CURSOR c_arq_pe IS
   SELECT aq.arquivo_id,
          ar.nome_fisico,
          vo.caminho || '\' || vo.prefixo || '\' || to_char(vo.numero) || '\' || ar.nome_fisico AS nome_completo
     FROM arquivo_pessoa aq,
          pessoa         pe,
          arquivo        ar,
          volume         vo
    WHERE pe.pessoa_id = p_pessoa_id
      AND pe.pessoa_id = aq.pessoa_id
      AND aq.arquivo_id = ar.arquivo_id
      AND ar.volume_id = vo.volume_id;
  --
 BEGIN
  SELECT usuario_id
    INTO v_usuario_id
    FROM pessoa
   WHERE pessoa_id = p_pessoa_id;
  --
  v_flag_admin_sistema := 'N';
  IF v_usuario_id IS NOT NULL THEN
   SELECT flag_admin_sistema
     INTO v_flag_admin_sistema
     FROM usuario
    WHERE usuario_id = v_usuario_id;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  --
  FOR r_arq_pe IN c_arq_pe
  LOOP
   INSERT INTO erro_log
    (erro_log_id,
     data,
     nome_programa,
     cod_erro,
     msg_erro)
   VALUES
    (seq_erro_log.nextval,
     SYSDATE,
     'arquivo_remover',
     'DEL',
     r_arq_pe.nome_completo);
   --
   DELETE FROM arquivo_pessoa
    WHERE arquivo_id = r_arq_pe.arquivo_id;
   --
   DELETE FROM arquivo
    WHERE arquivo_id = r_arq_pe.arquivo_id;
  END LOOP;
  --
  IF v_usuario_id IS NOT NULL AND v_flag_admin_sistema = 'N' THEN
   DELETE FROM apontam_hora ah
    WHERE EXISTS (SELECT 1
             FROM apontam_data ad
            WHERE usuario_id = v_usuario_id
              AND ad.apontam_data_id = ah.apontam_data_id);
   DELETE FROM apontam_data_ev ev
    WHERE EXISTS (SELECT 1
             FROM apontam_data ad
            WHERE usuario_id = v_usuario_id
              AND ad.apontam_data_id = ev.apontam_data_id);
   DELETE FROM apontam_data
    WHERE usuario_id = v_usuario_id;
   --                  
   DELETE FROM historico
    WHERE usuario_id = v_usuario_id;
   DELETE FROM usuario_papel
    WHERE usuario_id = v_usuario_id;
   DELETE FROM apontam_progr
    WHERE usuario_id = v_usuario_id;
   DELETE FROM usuario_pref
    WHERE usuario_id = v_usuario_id;
   DELETE FROM salario
    WHERE usuario_id = v_usuario_id;
   DELETE FROM equipe_usuario
    WHERE usuario_id = v_usuario_id;
   --
   UPDATE comentario
      SET comentario_pai_id = NULL
    WHERE usuario_id = v_usuario_id;
   --
   UPDATE comentario c1
      SET comentario_pai_id = NULL
    WHERE EXISTS (SELECT 1
             FROM comentario c2
            WHERE c2.usuario_id = v_usuario_id
              AND c1.comentario_pai_id = c2.comentario_id);
  END IF;
  --
  DELETE FROM apontam_hora
   WHERE cliente_id = p_pessoa_id;
  --
  DELETE FROM relacao
   WHERE pessoa_filho_id = p_pessoa_id;
  DELETE FROM relacao
   WHERE pessoa_pai_id = p_pessoa_id;
  DELETE FROM tipific_pessoa
   WHERE pessoa_id = p_pessoa_id;
  --
  DELETE FROM lancamento
   WHERE pessoa_id = p_pessoa_id;
  DELETE FROM fi_tipo_imposto_pessoa
   WHERE pessoa_id = p_pessoa_id;
  --
  DELETE FROM empr_fatur_sist_ext
   WHERE pessoa_id = p_pessoa_id;
  DELETE FROM empr_resp_sist_ext
   WHERE pessoa_id = p_pessoa_id;
  DELETE FROM pessoa_sist_ext
   WHERE pessoa_id = p_pessoa_id;
  DELETE FROM sa_emp_resp
   WHERE pessoa_id = p_pessoa_id;
  DELETE FROM natureza_oper_fatur
   WHERE pessoa_id = p_pessoa_id;
  --
  DELETE FROM produto_cliente
   WHERE pessoa_id = p_pessoa_id;
  --
  DELETE FROM pessoa_nitem_pdr
   WHERE pessoa_id = p_pessoa_id;
  DELETE FROM campanha
   WHERE cliente_id = p_pessoa_id;
  DELETE FROM aval_fornec
   WHERE pessoa_id = p_pessoa_id;
  DELETE FROM grupo_pessoa
   WHERE pessoa_id = p_pessoa_id;
  --
  UPDATE pessoa
     SET emp_resp_pdr_id = NULL
   WHERE emp_resp_pdr_id = p_pessoa_id;
  --
  UPDATE pessoa
     SET emp_fatur_pdr_id = NULL
   WHERE emp_fatur_pdr_id = p_pessoa_id;
  --
  IF v_flag_admin_sistema = 'N' THEN
   DELETE FROM pessoa
    WHERE pessoa_id = p_pessoa_id;
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
 END pessoa_apagar;
 --
 --
 --
 PROCEDURE outros_processar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 06/08/2015
  -- DESCRICAO: apaga completamente outras tabelas de uma empresa.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            19/07/2021  Exclusao de quadro
  ------------------------------------------------------------------------------------------
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) AS
  v_qt             INTEGER;
  v_ok             INTEGER;
  v_exception      EXCEPTION;
  v_erro_cod       VARCHAR2(100);
  v_erro_msg       VARCHAR2(2000);
  v_texto          VARCHAR2(2000);
  v_usuario_adm_id usuario.usuario_id%TYPE;
  v_empresa_pdr_id empresa.empresa_id%TYPE;
  --
  CURSOR c_arq_em IS
   SELECT aq.arquivo_id,
          ar.nome_fisico,
          vo.caminho || '\' || vo.prefixo || '\' || to_char(vo.numero) || '\' || ar.nome_fisico AS nome_completo
     FROM arquivo_empresa aq,
          arquivo         ar,
          volume          vo
    WHERE aq.empresa_id = p_empresa_id
      AND aq.arquivo_id = ar.arquivo_id
      AND ar.volume_id = vo.volume_id;
  --
  CURSOR c_arq_tar IS
   SELECT aq.arquivo_id,
          ar.nome_fisico,
          vo.caminho || '\' || vo.prefixo || '\' || to_char(vo.numero) || '\' || ar.nome_fisico AS nome_completo
     FROM arquivo_tarefa aq,
          tarefa         ta,
          arquivo        ar,
          volume         vo
    WHERE ta.empresa_id = p_empresa_id
      AND ta.tarefa_id = aq.tarefa_id
      AND aq.arquivo_id = ar.arquivo_id
      AND ar.volume_id = vo.volume_id;
  --
 BEGIN
  dbms_output.put_line('outros_processar');
  --
  SELECT MAX(usuario_id)
    INTO v_usuario_adm_id
    FROM usuario
   WHERE flag_admin_sistema = 'S';
  --
  v_empresa_pdr_id := nvl(usuario_pkg.empresa_padrao_retornar(v_usuario_adm_id), 0);
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  FOR r_arq_em IN c_arq_em
  LOOP
   INSERT INTO erro_log
    (erro_log_id,
     data,
     nome_programa,
     cod_erro,
     msg_erro)
   VALUES
    (seq_erro_log.nextval,
     SYSDATE,
     'arquivo_remover',
     'DEL',
     r_arq_em.nome_completo);
   --
   DELETE FROM arquivo_empresa
    WHERE arquivo_id = r_arq_em.arquivo_id;
   --
   DELETE FROM arquivo
    WHERE arquivo_id = r_arq_em.arquivo_id;
  END LOOP;
  COMMIT;
  --
  -- arquivos de tarefas sem job
  FOR r_arq_tar IN c_arq_tar
  LOOP
   INSERT INTO erro_log
    (erro_log_id,
     data,
     nome_programa,
     cod_erro,
     msg_erro)
   VALUES
    (seq_erro_log.nextval,
     SYSDATE,
     'arquivo_remover',
     'DEL',
     r_arq_tar.nome_completo);
   --
   DELETE FROM arquivo_tarefa
    WHERE arquivo_id = r_arq_tar.arquivo_id;
   --
   DELETE FROM arquivo
    WHERE arquivo_id = r_arq_tar.arquivo_id;
  END LOOP;
  COMMIT;
  --
  -- carta acordo
  DELETE FROM parcela_carta pc
   WHERE NOT EXISTS (SELECT 1
            FROM item_carta ic
           WHERE ic.carta_acordo_id = pc.carta_acordo_id);
  --
  DELETE FROM email_carta ec
   WHERE NOT EXISTS (SELECT 1
            FROM item_carta ic
           WHERE ic.carta_acordo_id = ec.carta_acordo_id);
  --
  DELETE FROM carta_fluxo_aprov cf
   WHERE NOT EXISTS (SELECT 1
            FROM item_carta ic
           WHERE ic.carta_acordo_id = cf.carta_acordo_id);
  --
  DELETE FROM carta_acordo ca
   WHERE NOT EXISTS (SELECT 1
            FROM item_carta ic
           WHERE ic.carta_acordo_id = ca.carta_acordo_id);
  COMMIT;
  --
  -- nota_fiscal
  DELETE FROM imposto_nota ip
   WHERE NOT EXISTS (SELECT 1
            FROM item_nota io
           WHERE io.nota_fiscal_id = ip.nota_fiscal_id);
  --
  DELETE FROM duplicata dp
   WHERE NOT EXISTS (SELECT 1
            FROM item_nota io
           WHERE io.nota_fiscal_id = dp.nota_fiscal_id);
  --
  DELETE FROM parcela_nf pa
   WHERE NOT EXISTS (SELECT 1
            FROM item_nota io
           WHERE io.nota_fiscal_id = pa.nota_fiscal_id);
  --
  DELETE FROM nota_fiscal nf
   WHERE NOT EXISTS (SELECT 1
            FROM item_nota io
           WHERE io.nota_fiscal_id = nf.nota_fiscal_id)
     AND NOT EXISTS (SELECT 1
            FROM faturamento fa
           WHERE fa.nota_fiscal_sai_id = nf.nota_fiscal_id)
     AND NOT EXISTS (SELECT 1
            FROM faturamento_ctr fa
           WHERE fa.nota_fiscal_sai_id = nf.nota_fiscal_id);
  COMMIT;
  --
  DELETE FROM area_dicion_valor ad
   WHERE EXISTS (SELECT 1
            FROM area ar
           WHERE ar.empresa_id = p_empresa_id
             AND ar.area_id = ad.area_id);
  --  
  DELETE FROM evento_motivo
   WHERE empresa_id = p_empresa_id;
  --
  DELETE FROM notifica_usuario nu
   WHERE EXISTS (SELECT 1
            FROM evento_config   ev,
                 notifica_config nc
           WHERE ev.empresa_id = p_empresa_id
             AND ev.evento_config_id = nc.evento_config_id
             AND nc.notifica_config_id = nu.notifica_config_id);
  DELETE FROM notifica_config nc
   WHERE EXISTS (SELECT 1
            FROM evento_config ev
           WHERE ev.empresa_id = p_empresa_id
             AND ev.evento_config_id = nc.evento_config_id);
  DELETE FROM evento_config
   WHERE empresa_id = p_empresa_id;
  DELETE FROM pessoa_transferencia
   WHERE empresa_id = p_empresa_id;
  DELETE FROM ctx_arquivo
   WHERE empresa_id = p_empresa_id;
  DELETE FROM categoria
   WHERE empresa_id = p_empresa_id;
  COMMIT;
  --
  DELETE FROM tipo_job_mod_crono tm
   WHERE EXISTS (SELECT 1
            FROM tipo_job tj
           WHERE tj.empresa_id = p_empresa_id
             AND tj.tipo_job_id = tm.tipo_job_id);
  --
  DELETE FROM tipo_contrato
   WHERE empresa_id = p_empresa_id;
  --
  DELETE FROM tipo_prod_tipo_os ts
   WHERE EXISTS (SELECT 1
            FROM tipo_os ti
           WHERE ti.empresa_id = p_empresa_id
             AND ti.tipo_os_id = ts.tipo_os_id);
  DELETE FROM tipo_os_transicao ts
   WHERE EXISTS (SELECT 1
            FROM tipo_os ti
           WHERE ti.empresa_id = p_empresa_id
             AND ti.tipo_os_id = ts.tipo_os_id);
  COMMIT;
  --
  DELETE FROM tarefa_evento te
   WHERE EXISTS (SELECT 1
            FROM tarefa ta
           WHERE ta.empresa_id = p_empresa_id
             AND ta.tarefa_id = te.tarefa_id);
  --
  DELETE FROM tarefa_usuario tu
   WHERE EXISTS (SELECT 1
            FROM tarefa ta
           WHERE ta.empresa_id = p_empresa_id
             AND ta.tarefa_id = tu.tarefa_id);
  --
  DELETE FROM tarefa_link tl
   WHERE EXISTS (SELECT 1
            FROM tarefa ta
           WHERE ta.empresa_id = p_empresa_id
             AND ta.tarefa_id = tl.tarefa_id);
  --
  DELETE FROM tarefa_tp_atrib_valor tv
   WHERE EXISTS (SELECT 1
            FROM tarefa_tipo_produto tt,
                 tarefa              ta
           WHERE ta.empresa_id = p_empresa_id
             AND ta.tarefa_id = tt.tarefa_id
             AND tt.tarefa_tipo_produto_id = tv.tarefa_tipo_produto_id);
  --
  DELETE FROM tarefa_tipo_produto tt
   WHERE EXISTS (SELECT 1
            FROM tarefa ta
           WHERE ta.empresa_id = p_empresa_id
             AND ta.tarefa_id = tt.tarefa_id);
  --                 
  DELETE FROM tarefa
   WHERE empresa_id = p_empresa_id;
  COMMIT;
  --
  DELETE FROM condicao_pagto_det cd
   WHERE EXISTS (SELECT 1
            FROM condicao_pagto co
           WHERE co.empresa_id = p_empresa_id
             AND co.condicao_pagto_id = cd.condicao_pagto_id);
  --
  DELETE FROM condicao_pagto_dia cd
   WHERE EXISTS (SELECT 1
            FROM condicao_pagto co
           WHERE co.empresa_id = p_empresa_id
             AND co.condicao_pagto_id = cd.condicao_pagto_id);
  --
  DELETE FROM condicao_pagto
   WHERE empresa_id = p_empresa_id;
  COMMIT;
  --
  DELETE FROM feriado fe
   WHERE EXISTS (SELECT 1
            FROM tab_feriado tf
           WHERE tf.empresa_id = p_empresa_id
             AND tf.tab_feriado_id = fe.tab_feriado_id);
  --
  UPDATE usuario
     SET tab_feriado_id = NULL
   WHERE tab_feriado_id IN (SELECT tab_feriado_id
                              FROM tab_feriado
                             WHERE empresa_id = p_empresa_id);
  --
  DELETE FROM tab_feriado
   WHERE empresa_id = p_empresa_id;
  COMMIT;
  --
  DELETE FROM tipo_produto_var va
   WHERE EXISTS (SELECT 1
            FROM tipo_produto tp
           WHERE tp.empresa_id = p_empresa_id
             AND tp.tipo_produto_id = va.tipo_produto_id);
  --
  DELETE FROM tipo_produto
   WHERE empresa_id = p_empresa_id;
  DELETE FROM classe_produto
   WHERE empresa_id = p_empresa_id;
  DELETE FROM tipo_financeiro
   WHERE empresa_id = p_empresa_id;
  DELETE FROM tipo_documento
   WHERE empresa_id = p_empresa_id;
  DELETE FROM apontam_ence
   WHERE empresa_id = p_empresa_id;
  COMMIT;
  --
  --
  DELETE FROM quadro_os_config qo
   WHERE EXISTS (SELECT 1
            FROM quadro_coluna qc,
                 quadro        qd
           WHERE qd.empresa_id = p_empresa_id
             AND qc.quadro_id = qc.quadro_id
             AND qc.quadro_coluna_id = qo.quadro_coluna_id);
  DELETE FROM quadro_tarefa_config qt
   WHERE EXISTS (SELECT 1
            FROM quadro_coluna qc,
                 quadro        qd
           WHERE qd.empresa_id = p_empresa_id
             AND qd.quadro_id = qc.quadro_id
             AND qc.quadro_coluna_id = qt.quadro_coluna_id);
  DELETE FROM quadro_coluna qc
   WHERE EXISTS (SELECT 1
            FROM quadro qd
           WHERE qd.empresa_id = p_empresa_id
             AND qd.quadro_id = qc.quadro_id);
  DELETE FROM quadro_equipe qe
   WHERE EXISTS (SELECT 1
            FROM quadro qd
           WHERE qd.empresa_id = p_empresa_id
             AND qd.quadro_id = qe.quadro_id);
  DELETE FROM quadro
   WHERE empresa_id = p_empresa_id;
  COMMIT;
  --
  DELETE FROM papel_painel pp
   WHERE EXISTS (SELECT 1
            FROM painel pa
           WHERE pa.empresa_id = p_empresa_id);
  DELETE FROM painel
   WHERE empresa_id = p_empresa_id;
  COMMIT;
  -- 
  --
  DELETE FROM tipo_os
   WHERE empresa_id = p_empresa_id;
  DELETE FROM historico
   WHERE empresa_id = p_empresa_id;
  DELETE FROM padrao_planilha
   WHERE empresa_id = p_empresa_id;
  --
  COMMIT;
  --
  --
  DELETE FROM faixa_aprov_papel f2
   WHERE EXISTS (SELECT 1
            FROM faixa_aprov fa
           WHERE fa.faixa_aprov_id = f2.faixa_aprov_id
             AND fa.empresa_id = p_empresa_id);
  --
  DELETE FROM faixa_aprov_ao f2
   WHERE EXISTS (SELECT 1
            FROM faixa_aprov fa
           WHERE fa.faixa_aprov_id = f2.faixa_aprov_id
             AND fa.empresa_id = p_empresa_id);
  --
  DELETE FROM faixa_aprov_os f2
   WHERE EXISTS (SELECT 1
            FROM faixa_aprov fa
           WHERE fa.faixa_aprov_id = f2.faixa_aprov_id
             AND fa.empresa_id = p_empresa_id);
  --
  DELETE FROM faixa_aprov
   WHERE empresa_id = p_empresa_id;
  COMMIT;
  --
  --
  DELETE FROM mod_item_crono_pre mp
   WHERE EXISTS (SELECT 1
            FROM mod_crono      mc,
                 mod_item_crono mi
           WHERE mc.mod_crono_id = mi.mod_crono_id
             AND mc.empresa_id = p_empresa_id
             AND mi.mod_item_crono_id = mp.mod_item_crono_pre_id);
  --
  DELETE FROM mod_item_crono_pre mp
   WHERE EXISTS (SELECT 1
            FROM mod_crono      mc,
                 mod_item_crono mi
           WHERE mc.mod_crono_id = mi.mod_crono_id
             AND mc.empresa_id = p_empresa_id
             AND mi.mod_item_crono_id = mp.mod_item_crono_id);
  --
  DELETE FROM mod_item_crono_dia md
   WHERE EXISTS (SELECT 1
            FROM mod_crono      mc,
                 mod_item_crono mi
           WHERE mc.mod_crono_id = mi.mod_crono_id
             AND mc.empresa_id = p_empresa_id
             AND mi.mod_item_crono_id = md.mod_item_crono_id);
  --
  DELETE FROM mod_item_crono mi
   WHERE EXISTS (SELECT 1
            FROM mod_crono mc
           WHERE mc.mod_crono_id = mi.mod_crono_id
             AND mc.empresa_id = p_empresa_id);
  --
  DELETE FROM mod_crono
   WHERE empresa_id = p_empresa_id;
  COMMIT;
  --
  --
  DELETE FROM salario_cargo sc
   WHERE EXISTS (SELECT 1
            FROM cargo ca
           WHERE ca.cargo_id = sc.cargo_id
             AND ca.empresa_id = p_empresa_id);
  --
  DELETE FROM usuario_cargo uc
   WHERE EXISTS (SELECT 1
            FROM cargo ca
           WHERE ca.cargo_id = uc.cargo_id
             AND ca.empresa_id = p_empresa_id);
  -- 
  UPDATE usuario us
     SET departamento_id = NULL
   WHERE EXISTS (SELECT 1
            FROM departamento dp
           WHERE dp.departamento_id = us.departamento_id
             AND dp.empresa_id = p_empresa_id);
  -- 
  UPDATE usuario us
     SET area_id = NULL
   WHERE EXISTS (SELECT 1
            FROM area ar
           WHERE ar.area_id = us.area_id
             AND ar.empresa_id = p_empresa_id);
  COMMIT;
  --                  
  DELETE FROM dicion_emp_val dv
   WHERE EXISTS (SELECT 1
            FROM dicion_emp di
           WHERE di.empresa_id = p_empresa_id
             AND di.dicion_emp_id = dv.dicion_emp_id);
  --
  DELETE FROM equipe_usuario eu
   WHERE EXISTS (SELECT 1
            FROM equipe eq
           WHERE eq.empresa_id = p_empresa_id
             AND eq.equipe_id = eu.equipe_id);
  --
  DELETE FROM tipo_job_usuario tu
   WHERE EXISTS (SELECT 1
            FROM tipo_job tj
           WHERE tj.empresa_id = p_empresa_id
             AND tj.tipo_job_id = tu.tipo_job_id);
  --               
  DELETE FROM apontam_hora ah
   WHERE EXISTS (SELECT 1
            FROM apontam_data ad,
                 cargo        ca
           WHERE ad.cargo_id = ca.cargo_id
             AND ca.empresa_id = p_empresa_id
             AND ad.apontam_data_id = ah.apontam_data_id);
  DELETE FROM apontam_data_ev ev
   WHERE EXISTS (SELECT 1
            FROM apontam_data ad,
                 cargo        ca
           WHERE ad.cargo_id = ca.cargo_id
             AND ca.empresa_id = p_empresa_id
             AND ad.apontam_data_id = ev.apontam_data_id);
  DELETE FROM apontam_data ad
   WHERE EXISTS (SELECT 1
            FROM cargo ca
           WHERE ca.empresa_id = p_empresa_id
             AND ca.cargo_id = ad.cargo_id);
  COMMIT;
  --
  DELETE FROM equipe
   WHERE empresa_id = p_empresa_id;
  DELETE FROM dicion_emp
   WHERE empresa_id = p_empresa_id;
  DELETE FROM cargo ca
   WHERE empresa_id = p_empresa_id
     AND NOT EXISTS (SELECT 1
            FROM apontam_data ad
           WHERE ca.cargo_id = ad.cargo_id);
  DELETE FROM area
   WHERE empresa_id = p_empresa_id;
  DELETE FROM departamento
   WHERE empresa_id = p_empresa_id;
  DELETE FROM status_aux_job
   WHERE empresa_id = p_empresa_id;
  DELETE FROM produto_fiscal
   WHERE empresa_id = p_empresa_id;
  DELETE FROM metadado
   WHERE empresa_id = p_empresa_id;
  DELETE FROM tipo_job
   WHERE empresa_id = p_empresa_id;
  DELETE FROM tipo_tarefa
   WHERE empresa_id = p_empresa_id;
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
 END outros_processar;
 --
--
END; -- LIMPEZA_PKG



/
