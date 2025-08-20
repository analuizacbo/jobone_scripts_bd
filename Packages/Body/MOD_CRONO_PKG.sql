--------------------------------------------------------
--  DDL for Package Body MOD_CRONO_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "MOD_CRONO_PKG" IS
 --
 --
 PROCEDURE adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia              ProcessMind     DATA: 26/11/2015
  -- DESCRICAO: Inclusão de MOD_CRONO (modelo de cronograma)
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_nome              IN mod_crono.nome%TYPE,
  p_tipo_data_base    IN mod_crono.tipo_data_base%TYPE,
  p_mod_crono_id      OUT mod_crono.mod_crono_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_exception      EXCEPTION;
  v_mod_crono_id   mod_crono.mod_crono_id%TYPE;
  --
 BEGIN
  v_qt           := 0;
  p_mod_crono_id := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'MOD_CRONO_C', NULL, NULL, p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF rtrim(p_nome) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do nome é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_tipo_data_base) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do tipo de data base é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF p_tipo_data_base NOT IN ('INI', 'FIM') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de data base inválido (' || p_tipo_data_base || ').';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM mod_crono
   WHERE empresa_id = p_empresa_id
     AND upper(nome) = upper(TRIM(p_nome));
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse nome de modelo já existe.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT seq_mod_crono.nextval
    INTO v_mod_crono_id
    FROM dual;
  --
  INSERT INTO mod_crono
   (mod_crono_id,
    empresa_id,
    nome,
    tipo_data_base)
  VALUES
   (v_mod_crono_id,
    p_empresa_id,
    TRIM(p_nome),
    p_tipo_data_base);
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := TRIM(p_nome);
  v_compl_histor   := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'MOD_CRONO',
                   'INCLUIR',
                   v_identif_objeto,
                   v_mod_crono_id,
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
  p_mod_crono_id := v_mod_crono_id;
  p_erro_cod     := '00000';
  p_erro_msg     := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace,
                        1,
                        200);
   ROLLBACK;
 END adicionar;
 --
 --
 PROCEDURE atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia              ProcessMind     DATA: 26/11/2015
  -- DESCRICAO: Atualizacao de MOD_CRONO (modelo de cronograma)
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_mod_crono_id      IN mod_crono.mod_crono_id%TYPE,
  p_nome              IN mod_crono.nome%TYPE,
  p_tipo_data_base    IN mod_crono.tipo_data_base%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_exception      EXCEPTION;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM mod_crono
   WHERE mod_crono_id = p_mod_crono_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse modelo de Cronograma não existe.';
   RAISE v_exception;
  END IF;
  --
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'MOD_CRONO_C', NULL, NULL, p_empresa_id) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF rtrim(p_nome) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do nome é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_tipo_data_base) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do tipo de data base é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF p_tipo_data_base NOT IN ('INI', 'FIM') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de data base inválido (' || p_tipo_data_base || ').';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM mod_crono
   WHERE empresa_id = p_empresa_id
     AND upper(nome) = upper(TRIM(p_nome))
     AND mod_crono_id <> p_mod_crono_id;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse nome de modelo já existe.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE mod_crono
     SET nome           = TRIM(p_nome),
         tipo_data_base = p_tipo_data_base
   WHERE mod_crono_id = p_mod_crono_id;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := TRIM(p_nome);
  v_compl_histor   := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'MOD_CRONO',
                   'ALTERAR',
                   v_identif_objeto,
                   p_mod_crono_id,
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
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace,
                        1,
                        200);
   ROLLBACK;
 END atualizar;
 --
 --
 PROCEDURE copiar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia              ProcessMind     DATA: 29/06/2016
  -- DESCRICAO: Copia o modelo de Cronograma.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            15/03/2018  Novo atributo demanda.
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_mod_crono_id      IN mod_crono.mod_crono_id%TYPE,
  p_mod_crono_new_id  OUT mod_crono.mod_crono_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt                    INTEGER;
  v_identif_objeto        historico.identif_objeto%TYPE;
  v_compl_histor          historico.complemento%TYPE;
  v_historico_id          historico.historico_id%TYPE;
  v_exception             EXCEPTION;
  v_mod_crono_new_id      mod_crono.mod_crono_id%TYPE;
  v_tipo_data_base        mod_crono.tipo_data_base%TYPE;
  v_nome                  VARCHAR2(200);
  v_mod_item_crono_id     mod_item_crono.mod_item_crono_id%TYPE;
  v_mod_item_crono_pre_id mod_item_crono.mod_item_crono_id%TYPE;
  --
  CURSOR c_it IS
   SELECT mod_item_crono_id
     FROM mod_item_crono
    WHERE mod_crono_id = p_mod_crono_id;
  --
  CURSOR c_pr IS
   SELECT pr.mod_item_crono_id,
          pr.mod_item_crono_pre_id
     FROM mod_item_crono     it,
          mod_item_crono_pre pr
    WHERE it.mod_crono_id = p_mod_crono_id
      AND it.mod_item_crono_id = pr.mod_item_crono_id;
  --
 BEGIN
  v_qt               := 0;
  p_mod_crono_new_id := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM mod_crono
   WHERE mod_crono_id = p_mod_crono_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse modelo de Cronograma não existe.';
   RAISE v_exception;
  END IF;
  --
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'MOD_CRONO_C', NULL, NULL, p_empresa_id) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT nome,
         tipo_data_base
    INTO v_nome,
         v_tipo_data_base
    FROM mod_crono
   WHERE mod_crono_id = p_mod_crono_id;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT seq_mod_crono.nextval
    INTO v_mod_crono_new_id
    FROM dual;
  --
  v_nome := 'Cópia de ' || v_nome;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM mod_crono
   WHERE empresa_id = p_empresa_id
     AND nome = v_nome;
  --
  IF v_qt > 0 THEN
   v_nome := 'Cópia de ' || v_nome || '-' || to_char(v_mod_crono_new_id);
  END IF;
  --
  INSERT INTO mod_crono
   (mod_crono_id,
    empresa_id,
    nome,
    tipo_data_base)
  VALUES
   (v_mod_crono_new_id,
    p_empresa_id,
    substr(v_nome, 1, 60),
    v_tipo_data_base);
  --
  FOR r_it IN c_it
  LOOP
   SELECT seq_mod_item_crono.nextval
     INTO v_mod_item_crono_id
     FROM dual;
   --
   -- copia os itens, guardando no campo OPER o ID original, a ser
   -- usado mais tarde para resolver as dependencias.
   INSERT INTO mod_item_crono
    (mod_item_crono_id,
     mod_crono_id,
     mod_item_crono_pai_id,
     frequencia_id,
     nome,
     dia_inicio,
     demanda,
     duracao,
     ordem,
     num_seq,
     nivel,
     cod_objeto,
     flag_obrigatorio,
     tipo_objeto_id,
     sub_tipo_objeto,
     papel_resp_id,
     flag_enviar,
     oper,
     repet_a_cada,
     repet_term_tipo,
     repet_term_ocor)
    SELECT v_mod_item_crono_id,
           v_mod_crono_new_id,
           NULL,
           frequencia_id,
           nome,
           dia_inicio,
           demanda,
           duracao,
           ordem,
           num_seq,
           nivel,
           cod_objeto,
           flag_obrigatorio,
           tipo_objeto_id,
           sub_tipo_objeto,
           papel_resp_id,
           flag_enviar,
           to_char(r_it.mod_item_crono_id),
           repet_a_cada,
           repet_term_tipo,
           repet_term_ocor
      FROM mod_item_crono
     WHERE mod_item_crono_id = r_it.mod_item_crono_id;
   --
   INSERT INTO mod_item_crono_dia
    (mod_item_crono_id,
     dia_semana_id)
    SELECT v_mod_item_crono_id,
           dia_semana_id
      FROM mod_item_crono_dia
     WHERE mod_item_crono_id = r_it.mod_item_crono_id;
   --
   INSERT INTO mod_item_crono_dest
    (mod_item_crono_id,
     papel_id)
    SELECT v_mod_item_crono_id,
           papel_id
      FROM mod_item_crono_dest
     WHERE mod_item_crono_id = r_it.mod_item_crono_id;
  END LOOP;
  --
  -- tratamento das dependencias (pai/filho)
  UPDATE mod_item_crono m1
     SET mod_item_crono_pai_id =
         (SELECT MAX(m3.mod_item_crono_id)
            FROM mod_item_crono m2,
                 mod_item_crono m3
           WHERE m2.mod_crono_id = p_mod_crono_id
             AND m2.mod_item_crono_id = to_number(m1.oper)
             AND m2.mod_item_crono_pai_id = to_number(m3.oper)
             AND m3.mod_crono_id = v_mod_crono_new_id)
   WHERE mod_crono_id = v_mod_crono_new_id;
  --
  -- copia de predecessores (o campo OPER guarda temporariamente
  --   o mod_item_crono_id original).
  FOR r_pr IN c_pr
  LOOP
   SELECT MAX(mod_item_crono_id)
     INTO v_mod_item_crono_id
     FROM mod_item_crono
    WHERE mod_crono_id = v_mod_crono_new_id
      AND to_number(oper) = r_pr.mod_item_crono_id;
   --
   SELECT MAX(mod_item_crono_id)
     INTO v_mod_item_crono_pre_id
     FROM mod_item_crono
    WHERE mod_crono_id = v_mod_crono_new_id
      AND to_number(oper) = r_pr.mod_item_crono_pre_id;
   --
   IF v_mod_item_crono_id IS NOT NULL AND v_mod_item_crono_pre_id IS NOT NULL THEN
    INSERT INTO mod_item_crono_pre
     (mod_item_crono_id,
      mod_item_crono_pre_id)
    VALUES
     (v_mod_item_crono_id,
      v_mod_item_crono_pre_id);
   END IF;
  END LOOP;
  --
  -- limpa campo auxiliar
  UPDATE mod_item_crono
     SET oper = NULL
   WHERE mod_crono_id = v_mod_crono_new_id;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := substr(v_nome, 1, 60);
  v_compl_histor   := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'MOD_CRONO',
                   'INCLUIR',
                   v_identif_objeto,
                   v_mod_crono_new_id,
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
  p_mod_crono_new_id := v_mod_crono_new_id;
  COMMIT;
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace,
                        1,
                        200);
   ROLLBACK;
 END copiar;
 --
 --
 PROCEDURE excluir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia              ProcessMind     DATA: 26/11/2015
  -- DESCRICAO: Exclusao de MOD_CRONO (modelo de cronograma)
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_mod_crono_id      IN mod_crono.mod_crono_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_exception      EXCEPTION;
  v_nome_crono     mod_crono.nome%TYPE;
  v_lbl_job        VARCHAR2(100);
  --
 BEGIN
  v_qt      := 0;
  v_lbl_job := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM mod_crono
   WHERE mod_crono_id = p_mod_crono_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse modelo de Cronograma não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT nome
    INTO v_nome_crono
    FROM mod_crono
   WHERE mod_crono_id = p_mod_crono_id;
  --
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'MOD_CRONO_C', NULL, NULL, p_empresa_id) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM tipo_job_mod_crono
   WHERE mod_crono_id = p_mod_crono_id;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse modelo de Cronograma está associado a algum tipo de ' || v_lbl_job || '.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  DELETE FROM mod_item_crono_pre mp
   WHERE EXISTS (SELECT 1
            FROM mod_item_crono mi
           WHERE mi.mod_crono_id = p_mod_crono_id
             AND mi.mod_item_crono_id = mp.mod_item_crono_id);
  DELETE FROM mod_item_crono_dia mp
   WHERE EXISTS (SELECT 1
            FROM mod_item_crono mi
           WHERE mi.mod_crono_id = p_mod_crono_id
             AND mi.mod_item_crono_id = mp.mod_item_crono_id);
  DELETE FROM mod_item_crono_dest mp
   WHERE EXISTS (SELECT 1
            FROM mod_item_crono mi
           WHERE mi.mod_crono_id = p_mod_crono_id
             AND mi.mod_item_crono_id = mp.mod_item_crono_id);
  DELETE FROM mod_item_crono
   WHERE mod_crono_id = p_mod_crono_id;
  DELETE FROM mod_crono
   WHERE mod_crono_id = p_mod_crono_id;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_nome_crono;
  v_compl_histor   := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'MOD_CRONO',
                   'EXCLUIR',
                   v_identif_objeto,
                   p_mod_crono_id,
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
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace,
                        1,
                        200);
   ROLLBACK;
 END excluir;
 --
 --
 PROCEDURE item_adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 30/11/2015
  -- DESCRICAO: Inclusao de item no modelo de cronograma.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            15/03/2018  Novo parametro demanda.
  -- Silvia            15/10/2018  Novos parametros para repeticoes.
  -- Silvia            26/10/2018  Vetor no papel destino.
  -- Silvia            28/04/2020  Retirada de obrigatoriedade de sub_tipo_objeto,
  --                               papel_resp, papel_dest, flag_enviar
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id     IN NUMBER,
  p_empresa_id            IN empresa.empresa_id%TYPE,
  p_mod_crono_id          IN mod_item_crono.mod_crono_id%TYPE,
  p_mod_item_crono_pai_id IN mod_item_crono.mod_item_crono_pai_id%TYPE,
  p_nome_item             IN mod_item_crono.nome%TYPE,
  p_dia_inicio            IN VARCHAR2,
  p_demanda               IN VARCHAR2,
  p_duracao               IN VARCHAR2,
  p_mod_item_crono_pre_id IN mod_item_crono_pre.mod_item_crono_pre_id%TYPE,
  p_cod_objeto            IN mod_item_crono.cod_objeto%TYPE,
  p_tipo_objeto_id        IN mod_item_crono.tipo_objeto_id%TYPE,
  p_sub_tipo_objeto       IN mod_item_crono.sub_tipo_objeto%TYPE,
  p_papel_resp_id         IN mod_item_crono.papel_resp_id%TYPE,
  p_vetor_papel_dest_id   IN VARCHAR2,
  p_flag_enviar           IN VARCHAR2,
  p_repet_a_cada          IN VARCHAR2,
  p_frequencia_id         IN mod_item_crono.frequencia_id%TYPE,
  p_vetor_dia_semana_id   IN VARCHAR2,
  p_repet_term_tipo       IN VARCHAR2,
  p_repet_term_ocor       IN VARCHAR2,
  p_mod_item_crono_id     OUT mod_item_crono.mod_item_crono_id%TYPE,
  p_erro_cod              OUT VARCHAR2,
  p_erro_msg              OUT VARCHAR2
 ) IS
  v_qt                    INTEGER;
  v_exception             EXCEPTION;
  v_nome_crono            mod_crono.nome%TYPE;
  v_mod_item_crono_id     mod_item_crono.mod_item_crono_id%TYPE;
  v_mod_item_crono_max_id mod_item_crono.mod_item_crono_id%TYPE;
  v_dia_inicio            mod_item_crono.dia_inicio%TYPE;
  v_duracao               mod_item_crono.duracao%TYPE;
  v_ordem                 mod_item_crono.ordem%TYPE;
  v_ordem_aux             mod_item_crono.ordem%TYPE;
  v_repet_a_cada          mod_item_crono.repet_a_cada%TYPE;
  v_repet_term_ocor       mod_item_crono.repet_term_ocor%TYPE;
  v_papel_dest_id         papel.papel_id%TYPE;
  v_dia_semana_id         dia_semana.dia_semana_id%TYPE;
  v_cod_freq              frequencia.codigo%TYPE;
  v_flag_obrigatorio      objeto_crono.flag_obrigatorio%TYPE;
  v_flag_unico            objeto_crono.flag_unico%TYPE;
  v_nome_objeto           objeto_crono.nome%TYPE;
  v_vetor_dia_semana_id   LONG;
  v_vetor_papel_dest_id   LONG;
  v_delimitador           CHAR(1);
  v_identif_objeto        historico.identif_objeto%TYPE;
  v_compl_histor          historico.complemento%TYPE;
  v_historico_id          historico.historico_id%TYPE;
  --
 BEGIN
  v_qt                := 0;
  p_mod_item_crono_id := 0;
  v_flag_obrigatorio  := 'N';
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM mod_crono
   WHERE mod_crono_id = p_mod_crono_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse modelo de Cronograma não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT nome
    INTO v_nome_crono
    FROM mod_crono
   WHERE mod_crono_id = p_mod_crono_id;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'MOD_CRONO_C', NULL, NULL, p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF TRIM(p_nome_item) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da descrição da atividade é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF length(TRIM(p_nome_item)) > 100 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A descrição da atividade não pode ter mais que 100 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF inteiro_validar(p_dia_inicio) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Dia início inválido (' || p_dia_inicio || ').';
   RAISE v_exception;
  END IF;
  --
  IF util_pkg.desc_retornar('demanda', p_demanda) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Demanda inválida (' || p_demanda || ').';
   RAISE v_exception;
  END IF;
  --
  IF inteiro_validar(p_duracao) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Duração inválida (' || p_duracao || ').';
   RAISE v_exception;
  END IF;
  --
  v_dia_inicio := to_number(p_dia_inicio);
  v_duracao    := to_number(p_duracao);
  --
  ------------------------------------------------------------
  -- consistencia dos objetos de sistema
  ------------------------------------------------------------
  IF TRIM(p_cod_objeto) IS NOT NULL THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM objeto_crono
    WHERE cod_objeto = p_cod_objeto;
   --
   IF v_qt = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse código de objeto não existe (' || p_cod_objeto || ').';
    RAISE v_exception;
   END IF;
   --
   SELECT nome,
          flag_unico,
          flag_obrigatorio
     INTO v_nome_objeto,
          v_flag_unico,
          v_flag_obrigatorio
     FROM objeto_crono
    WHERE cod_objeto = p_cod_objeto;
   --
   IF v_flag_unico = 'S' THEN
    SELECT COUNT(*)
      INTO v_qt
      FROM mod_item_crono
     WHERE mod_crono_id = p_mod_crono_id
       AND cod_objeto = p_cod_objeto;
    --
    IF v_qt > 0 THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Já existe esse tipo de atividade no modelo (' || v_nome_objeto || ').';
     RAISE v_exception;
    END IF;
   END IF;
   --
   IF p_cod_objeto = 'ORDEM_SERVICO' THEN
    IF nvl(p_tipo_objeto_id, 0) = 0 THEN
     p_erro_cod := '90000';
     p_erro_msg := 'O preenchimento do Tipo de Workflow é obrigatório.';
     RAISE v_exception;
    END IF;
    --
    IF nvl(p_papel_resp_id, 0) > 0 THEN
     SELECT COUNT(*)
       INTO v_qt
       FROM papel
      WHERE papel_id = p_papel_resp_id
        AND empresa_id = p_empresa_id;
     --
     IF v_qt = 0 THEN
      p_erro_cod := '90000';
      p_erro_msg := 'O papel responsável não existe ou não pertence a essa empresa.';
      RAISE v_exception;
     END IF;
    END IF;
    --
    IF TRIM(p_flag_enviar) IS NOT NULL AND flag_validar(p_flag_enviar) = 0 THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Flag enviar inválido (' || p_flag_enviar || ').';
     RAISE v_exception;
    END IF;
   END IF;
   --
   IF p_cod_objeto = 'TAREFA' THEN
    IF nvl(p_papel_resp_id, 0) > 0 THEN
     SELECT COUNT(*)
       INTO v_qt
       FROM papel
      WHERE papel_id = p_papel_resp_id
        AND empresa_id = p_empresa_id;
     --
     IF v_qt = 0 THEN
      p_erro_cod := '90000';
      p_erro_msg := 'O papel demandante não existe ou não pertence a essa empresa.';
      RAISE v_exception;
     END IF;
    END IF;
    --
    -- deveria vir apenas um inteiro no vetor
    IF TRIM(p_vetor_papel_dest_id) IS NOT NULL AND inteiro_validar(p_vetor_papel_dest_id) = 0 THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Papel demandado inválido (' || p_vetor_papel_dest_id || '|.';
     RAISE v_exception;
    END IF;
   END IF;
   --
   IF p_cod_objeto = 'DOCUMENTO' THEN
    IF nvl(p_tipo_objeto_id, 0) = 0 THEN
     p_erro_cod := '90000';
     p_erro_msg := 'O preenchimento do tipo de documento é obrigatório.';
     RAISE v_exception;
    END IF;
    --
    IF TRIM(p_sub_tipo_objeto) IS NOT NULL AND
       util_pkg.desc_retornar('tipo_fluxo', p_sub_tipo_objeto) IS NULL THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Fluxo inválido (' || p_sub_tipo_objeto || ').';
     RAISE v_exception;
    END IF;
   END IF;
   --
  END IF; -- fim do IF TRIM(p_cod_objeto) IS NOT NULL
  --
  ------------------------------------------------------------
  -- consistencia de repeticoes
  ------------------------------------------------------------
  v_repet_a_cada    := NULL;
  v_repet_term_ocor := NULL;
  --
  IF nvl(p_frequencia_id, 0) > 0 THEN
   SELECT MAX(codigo)
     INTO v_cod_freq
     FROM frequencia
    WHERE frequencia_id = p_frequencia_id;
   --
   IF TRIM(p_repet_a_cada) IS NULL THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O preenchimento da frequência da repetição é obrigatório.';
    RAISE v_exception;
   END IF;
   --
   IF inteiro_validar(p_repet_a_cada) = 0 OR to_number(p_repet_a_cada) > 99999 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Frequência da repetição inválida (' || p_repet_a_cada || ').';
    RAISE v_exception;
   END IF;
   --
   v_repet_a_cada := nvl(to_number(p_repet_a_cada), 0);
   --
   IF v_repet_a_cada <= 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Frequência da repetição inválida (' || p_repet_a_cada || ').';
    RAISE v_exception;
   END IF;
   --
   IF v_cod_freq = 'SEM' AND TRIM(p_vetor_dia_semana_id) IS NULL THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Para esse tipo de repetição, um ou mais dias da semana ' ||
                  'devem ser indicados.';
    RAISE v_exception;
   END IF;
   --
   IF v_cod_freq <> 'SEM' AND TRIM(p_vetor_dia_semana_id) IS NOT NULL THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Para esse tipo de repetição, os dias da semana ' ||
                  'não devem ser indicados.';
    RAISE v_exception;
   END IF;
   --
   IF TRIM(p_repet_term_tipo) IS NULL OR p_repet_term_tipo NOT IN ('FIMJOB', 'QTOCOR') THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Tipo de término da repetição inválido (' || p_repet_term_tipo || ').';
    RAISE v_exception;
   END IF;
   --
   IF p_repet_term_tipo = 'QTOCOR' THEN
    IF TRIM(p_repet_term_ocor) IS NULL THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Para esse tipo de término da repetição, a quantidade ' ||
                   'de ocorrências deve ser informada.';
     RAISE v_exception;
    END IF;
    --
    IF inteiro_validar(p_repet_term_ocor) = 0 OR to_number(p_repet_term_ocor) > 99999 THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Quantidade de ocorrências da repetição inválida (' || p_repet_term_ocor || ').';
     RAISE v_exception;
    END IF;
    --
    v_repet_term_ocor := nvl(to_number(p_repet_term_ocor), 0);
    --
    IF v_repet_term_ocor <= 1 THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Quantidade de ocorrências da repetição inválida (' || p_repet_term_ocor || ').';
     RAISE v_exception;
    END IF;
   END IF;
   --
   IF p_repet_term_tipo <> 'QTOCOR' AND TRIM(p_repet_term_ocor) IS NOT NULL THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Para esse tipo de término da repetição, a quantidade ' ||
                  'de ocorrências não deve ser informada.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- tratamento da ordem
  ------------------------------------------------------------
  IF nvl(p_mod_item_crono_pai_id, 0) > 0 THEN
   -- descobre o ultimo item do mesmo nivel
   SELECT MAX(ordem)
     INTO v_ordem
     FROM mod_item_crono
    WHERE mod_item_crono_pai_id = p_mod_item_crono_pai_id;
   --
   IF v_ordem IS NULL THEN
    -- nenhum item filho encontrado. Esse vai ser o primeiro.
    -- pega a ordem do pai
    SELECT ordem
      INTO v_ordem
      FROM mod_item_crono
     WHERE mod_item_crono_id = p_mod_item_crono_pai_id;
   END IF;
   --
   -- descobre a proxima ordem
   SELECT MIN(ordem)
     INTO v_ordem_aux
     FROM mod_item_crono
    WHERE ordem > v_ordem
      AND mod_crono_id = p_mod_crono_id;
   --
   IF v_ordem_aux IS NULL THEN
    -- proximo item nao encontrado. O novo item vai
    -- ser inserido no final.
    v_ordem := v_ordem + 100000;
   ELSE
    -- proximo item encontrado. O novo item vai ser
    -- inserido no meio.
    v_ordem := round((v_ordem + v_ordem_aux) / 2, 0);
   END IF;
  ELSE
   -- inclusao no nivel 1. Descobre a maior ordem (o item vai entrar no fim)
   SELECT MAX(ordem)
     INTO v_ordem
     FROM mod_item_crono
    WHERE mod_crono_id = p_mod_crono_id;
   --
   IF v_ordem IS NULL THEN
    -- primeiro item do cronograma
    v_ordem := 100000;
   ELSE
    v_ordem := v_ordem + 100000;
   END IF;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM mod_item_crono
   WHERE mod_crono_id = p_mod_crono_id
     AND ordem = v_ordem;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa ordem já existe (' || to_char(v_ordem) || ').';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT seq_mod_item_crono.nextval
    INTO v_mod_item_crono_id
    FROM dual;
  --
  INSERT INTO mod_item_crono
   (mod_item_crono_id,
    mod_crono_id,
    mod_item_crono_pai_id,
    nome,
    dia_inicio,
    demanda,
    duracao,
    ordem,
    num_seq,
    cod_objeto,
    flag_obrigatorio,
    tipo_objeto_id,
    sub_tipo_objeto,
    papel_resp_id,
    flag_enviar,
    frequencia_id,
    repet_a_cada,
    repet_term_tipo,
    repet_term_ocor)
  VALUES
   (v_mod_item_crono_id,
    p_mod_crono_id,
    zvl(p_mod_item_crono_pai_id, NULL),
    TRIM(p_nome_item),
    v_dia_inicio,
    p_demanda,
    v_duracao,
    v_ordem,
    0,
    p_cod_objeto,
    v_flag_obrigatorio,
    zvl(p_tipo_objeto_id, NULL),
    TRIM(p_sub_tipo_objeto),
    zvl(p_papel_resp_id, NULL),
    nvl(TRIM(p_flag_enviar), 'N'),
    zvl(p_frequencia_id, NULL),
    v_repet_a_cada,
    p_repet_term_tipo,
    v_repet_term_ocor);
  --
  IF nvl(p_mod_item_crono_pre_id, 0) > 0 THEN
   INSERT INTO mod_item_crono_pre
    (mod_item_crono_id,
     mod_item_crono_pre_id)
   VALUES
    (v_mod_item_crono_id,
     p_mod_item_crono_pre_id);
  END IF;
  --
  mod_crono_pkg.seq_renumerar(p_usuario_sessao_id,
                              p_empresa_id,
                              p_mod_crono_id,
                              p_erro_cod,
                              p_erro_msg);
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  mod_crono_pkg.ordem_renumerar(p_usuario_sessao_id,
                                p_empresa_id,
                                p_mod_crono_id,
                                p_erro_cod,
                                p_erro_msg);
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- tratamento do vetor de papel demandado (destino)
  ------------------------------------------------------------
  v_delimitador         := '|';
  v_vetor_papel_dest_id := p_vetor_papel_dest_id;
  --
  WHILE nvl(length(rtrim(v_vetor_papel_dest_id)), 0) > 0
  LOOP
   v_papel_dest_id := nvl(to_number(prox_valor_retornar(v_vetor_papel_dest_id, v_delimitador)),
                          0);
   --
   IF v_papel_dest_id > 0 THEN
    SELECT COUNT(*)
      INTO v_qt
      FROM papel
     WHERE papel_id = v_papel_dest_id
       AND empresa_id = p_empresa_id;
    --
    IF v_qt = 0 THEN
     p_erro_cod := '90000';
     p_erro_msg := 'O papel demandado não existe ou não pertence a essa empresa (' ||
                   to_char(v_papel_dest_id) || ').';
     RAISE v_exception;
    END IF;
    --
    INSERT INTO mod_item_crono_dest
     (mod_item_crono_id,
      papel_id)
    VALUES
     (v_mod_item_crono_id,
      v_papel_dest_id);
   END IF;
  END LOOP;
  --
  ------------------------------------------------------------
  -- tratamento do vetor de dia da semana (repeticoes)
  ------------------------------------------------------------
  v_delimitador         := '|';
  v_vetor_dia_semana_id := p_vetor_dia_semana_id;
  --
  WHILE nvl(length(rtrim(v_vetor_dia_semana_id)), 0) > 0
  LOOP
   v_dia_semana_id := nvl(to_number(prox_valor_retornar(v_vetor_dia_semana_id, v_delimitador)),
                          0);
   --
   IF v_dia_semana_id > 0 THEN
    INSERT INTO mod_item_crono_dia
     (mod_item_crono_id,
      dia_semana_id)
    VALUES
     (v_mod_item_crono_id,
      v_dia_semana_id);
   END IF;
  END LOOP;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_nome_crono;
  v_compl_histor   := 'Inclusão de item: ' || TRIM(p_nome_item);
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'MOD_CRONO',
                   'ALTERAR',
                   v_identif_objeto,
                   p_mod_crono_id,
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
  p_mod_item_crono_id := v_mod_item_crono_id;
  COMMIT;
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace,
                        1,
                        200);
   ROLLBACK;
 END item_adicionar;
 --
 --
 PROCEDURE item_atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 30/11/2015
  -- DESCRICAO: Atualizacao de item do modelo de cronograma.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            15/03/2018  Novo parametro demanda.
  -- Silvia            15/10/2018  Novos parametros para repeticoes.
  -- Silvia            26/10/2018  Vetor no papel destino.
  -- Silvia            28/04/2020  Retirada de obrigatoriedade de sub_tipo_objeto,
  --                               papel_resp, papel_dest, flag_enviar
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id     IN NUMBER,
  p_empresa_id            IN empresa.empresa_id%TYPE,
  p_mod_item_crono_id     IN mod_item_crono.mod_item_crono_id%TYPE,
  p_nome_item             IN mod_item_crono.nome%TYPE,
  p_dia_inicio            IN VARCHAR2,
  p_demanda               IN VARCHAR2,
  p_duracao               IN VARCHAR2,
  p_mod_item_crono_pre_id IN mod_item_crono_pre.mod_item_crono_pre_id%TYPE,
  p_cod_objeto            IN mod_item_crono.cod_objeto%TYPE,
  p_tipo_objeto_id        IN mod_item_crono.tipo_objeto_id%TYPE,
  p_sub_tipo_objeto       IN mod_item_crono.sub_tipo_objeto%TYPE,
  p_papel_resp_id         IN mod_item_crono.papel_resp_id%TYPE,
  p_vetor_papel_dest_id   IN VARCHAR2,
  p_flag_enviar           IN VARCHAR2,
  p_repet_a_cada          IN VARCHAR2,
  p_frequencia_id         IN mod_item_crono.frequencia_id%TYPE,
  p_vetor_dia_semana_id   IN VARCHAR2,
  p_repet_term_tipo       IN VARCHAR2,
  p_repet_term_ocor       IN VARCHAR2,
  p_erro_cod              OUT VARCHAR2,
  p_erro_msg              OUT VARCHAR2
 ) IS
  v_qt                  INTEGER;
  v_exception           EXCEPTION;
  v_nome_crono          mod_crono.nome%TYPE;
  v_mod_crono_id        mod_crono.mod_crono_id%TYPE;
  v_dia_inicio          mod_item_crono.dia_inicio%TYPE;
  v_duracao             mod_item_crono.duracao%TYPE;
  v_repet_a_cada        mod_item_crono.repet_a_cada%TYPE;
  v_repet_term_ocor     mod_item_crono.repet_term_ocor%TYPE;
  v_papel_dest_id       papel.papel_id%TYPE;
  v_flag_obrigatorio    objeto_crono.flag_obrigatorio%TYPE;
  v_flag_unico          objeto_crono.flag_unico%TYPE;
  v_nome_objeto         objeto_crono.nome%TYPE;
  v_dia_semana_id       dia_semana.dia_semana_id%TYPE;
  v_cod_freq            frequencia.codigo%TYPE;
  v_vetor_dia_semana_id LONG;
  v_vetor_papel_dest_id LONG;
  v_delimitador         CHAR(1);
  v_identif_objeto      historico.identif_objeto%TYPE;
  v_compl_histor        historico.complemento%TYPE;
  v_historico_id        historico.historico_id%TYPE;
  --
 BEGIN
  v_qt               := 0;
  v_flag_obrigatorio := 'N';
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM mod_item_crono
   WHERE mod_item_crono_id = p_mod_item_crono_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa atividade não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT mc.nome,
         mc.mod_crono_id
    INTO v_nome_crono,
         v_mod_crono_id
    FROM mod_crono      mc,
         mod_item_crono mi
   WHERE mi.mod_item_crono_id = p_mod_item_crono_id
     AND mi.mod_crono_id = mc.mod_crono_id;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'MOD_CRONO_C', NULL, NULL, p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF TRIM(p_nome_item) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da descrição da atividade é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF length(TRIM(p_nome_item)) > 100 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A descrição da atividade não pode ter mais que 100 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF inteiro_validar(p_dia_inicio) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Dia início inválido (' || p_dia_inicio || ').';
   RAISE v_exception;
  END IF;
  --
  IF util_pkg.desc_retornar('demanda', p_demanda) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Demanda inválida (' || p_demanda || ').';
   RAISE v_exception;
  END IF;
  --
  IF inteiro_validar(p_duracao) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Duração inválida (' || p_duracao || ').';
   RAISE v_exception;
  END IF;
  --
  v_dia_inicio := to_number(p_dia_inicio);
  v_duracao    := to_number(p_duracao);
  --
  ------------------------------------------------------------
  -- consistencia dos objetos de sistema
  ------------------------------------------------------------
  IF TRIM(p_cod_objeto) IS NOT NULL THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM objeto_crono
    WHERE cod_objeto = p_cod_objeto;
   --
   IF v_qt = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse código de objeto não existe (' || p_cod_objeto || ').';
    RAISE v_exception;
   END IF;
   --
   SELECT nome,
          flag_unico,
          flag_obrigatorio
     INTO v_nome_objeto,
          v_flag_unico,
          v_flag_obrigatorio
     FROM objeto_crono
    WHERE cod_objeto = p_cod_objeto;
   --
   IF v_flag_unico = 'S' THEN
    SELECT COUNT(*)
      INTO v_qt
      FROM mod_item_crono
     WHERE mod_crono_id = v_mod_crono_id
       AND cod_objeto = p_cod_objeto
       AND mod_item_crono_id <> p_mod_item_crono_id;
    --
    IF v_qt > 0 THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Já existe esse tipo de atividade no modelo (' || v_nome_objeto || ').';
     RAISE v_exception;
    END IF;
   END IF;
   --
   IF p_cod_objeto = 'ORDEM_SERVICO' THEN
    IF nvl(p_tipo_objeto_id, 0) = 0 THEN
     p_erro_cod := '90000';
     p_erro_msg := 'O preenchimento do Tipo de Workflow é obrigatório.';
     RAISE v_exception;
    END IF;
    --
    IF nvl(p_papel_resp_id, 0) > 0 THEN
     SELECT COUNT(*)
       INTO v_qt
       FROM papel
      WHERE papel_id = p_papel_resp_id
        AND empresa_id = p_empresa_id;
     --
     IF v_qt = 0 THEN
      p_erro_cod := '90000';
      p_erro_msg := 'O papel responsável não existe ou não pertence a essa empresa.';
      RAISE v_exception;
     END IF;
    END IF;
    --
    IF TRIM(p_flag_enviar) IS NOT NULL AND flag_validar(p_flag_enviar) = 0 THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Flag enviar inválido (' || p_flag_enviar || ').';
     RAISE v_exception;
    END IF;
   END IF;
   --
   IF p_cod_objeto = 'TAREFA' THEN
    IF nvl(p_papel_resp_id, 0) > 0 THEN
     SELECT COUNT(*)
       INTO v_qt
       FROM papel
      WHERE papel_id = p_papel_resp_id
        AND empresa_id = p_empresa_id;
     --
     IF v_qt = 0 THEN
      p_erro_cod := '90000';
      p_erro_msg := 'O papel demandante não existe ou não pertence a essa empresa.';
      RAISE v_exception;
     END IF;
    END IF;
    --
    -- deveria vir apenas um inteiro no vetor
    IF TRIM(p_vetor_papel_dest_id) IS NOT NULL AND inteiro_validar(p_vetor_papel_dest_id) = 0 THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Papel demandado inválido (' || p_vetor_papel_dest_id || '|.';
     RAISE v_exception;
    END IF;
   END IF;
   --
   IF p_cod_objeto = 'DOCUMENTO' THEN
    IF nvl(p_tipo_objeto_id, 0) = 0 THEN
     p_erro_cod := '90000';
     p_erro_msg := 'O preenchimento do tipo de documento é obrigatório.';
     RAISE v_exception;
    END IF;
    --
    IF TRIM(p_sub_tipo_objeto) IS NOT NULL AND
       util_pkg.desc_retornar('tipo_fluxo', p_sub_tipo_objeto) IS NULL THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Fluxo inválido (' || p_sub_tipo_objeto || ').';
     RAISE v_exception;
    END IF;
   END IF;
   --
  END IF; -- fim do IF TRIM(p_cod_objeto) IS NOT NULL
  --
  ------------------------------------------------------------
  -- consistencia de repeticoes
  ------------------------------------------------------------
  v_repet_a_cada    := NULL;
  v_repet_term_ocor := NULL;
  --
  IF nvl(p_frequencia_id, 0) > 0 THEN
   SELECT MAX(codigo)
     INTO v_cod_freq
     FROM frequencia
    WHERE frequencia_id = p_frequencia_id;
   --
   IF TRIM(p_repet_a_cada) IS NULL THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O preenchimento da frequência da repetição é obrigatório.';
    RAISE v_exception;
   END IF;
   --
   IF inteiro_validar(p_repet_a_cada) = 0 OR to_number(p_repet_a_cada) > 99999 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Frequência da repetição inválida (' || p_repet_a_cada || ').';
    RAISE v_exception;
   END IF;
   --
   v_repet_a_cada := nvl(to_number(p_repet_a_cada), 0);
   --
   IF v_repet_a_cada <= 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Frequência da repetição inválida (' || p_repet_a_cada || ').';
    RAISE v_exception;
   END IF;
   --
   IF v_cod_freq = 'SEM' AND TRIM(p_vetor_dia_semana_id) IS NULL THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Para esse tipo de repetição, um ou mais dias da semana ' ||
                  'devem ser indicados.';
    RAISE v_exception;
   END IF;
   --
   IF v_cod_freq <> 'SEM' AND TRIM(p_vetor_dia_semana_id) IS NOT NULL THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Para esse tipo de repetição, os dias da semana ' ||
                  'não devem ser indicados.';
    RAISE v_exception;
   END IF;
   --
   IF TRIM(p_repet_term_tipo) IS NULL OR p_repet_term_tipo NOT IN ('FIMJOB', 'QTOCOR') THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Tipo de término da repetição inválido (' || p_repet_term_tipo || ').';
    RAISE v_exception;
   END IF;
   --
   IF p_repet_term_tipo = 'QTOCOR' THEN
    IF TRIM(p_repet_term_ocor) IS NULL THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Para esse tipo de término da repetição, a quantidade ' ||
                   'de ocorrências deve ser informada.';
     RAISE v_exception;
    END IF;
    --
    IF inteiro_validar(p_repet_term_ocor) = 0 OR to_number(p_repet_term_ocor) > 99999 THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Quantidade de ocorrências da repetição inválida (' || p_repet_term_ocor || ').';
     RAISE v_exception;
    END IF;
    --
    v_repet_term_ocor := nvl(to_number(p_repet_term_ocor), 0);
    --
    IF v_repet_term_ocor <= 1 THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Quantidade de ocorrências da repetição inválida (' || p_repet_term_ocor || ').';
     RAISE v_exception;
    END IF;
   END IF;
   --
   IF p_repet_term_tipo <> 'QTOCOR' AND TRIM(p_repet_term_ocor) IS NOT NULL THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Para esse tipo de término da repetição, a quantidade ' ||
                  'de ocorrências não deve ser informada.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE mod_item_crono
     SET nome             = TRIM(p_nome_item),
         dia_inicio       = v_dia_inicio,
         demanda          = p_demanda,
         duracao          = v_duracao,
         cod_objeto       = p_cod_objeto,
         flag_obrigatorio = v_flag_obrigatorio,
         tipo_objeto_id   = zvl(p_tipo_objeto_id, NULL),
         sub_tipo_objeto  = TRIM(p_sub_tipo_objeto),
         papel_resp_id    = zvl(p_papel_resp_id, NULL),
         flag_enviar      = nvl(TRIM(p_flag_enviar), 'N'),
         frequencia_id    = zvl(p_frequencia_id, NULL),
         repet_a_cada     = v_repet_a_cada,
         repet_term_tipo  = p_repet_term_tipo,
         repet_term_ocor  = v_repet_term_ocor
   WHERE mod_item_crono_id = p_mod_item_crono_id;
  --
  DELETE FROM mod_item_crono_pre
   WHERE mod_item_crono_id = p_mod_item_crono_id;
  --
  IF nvl(p_mod_item_crono_pre_id, 0) > 0 THEN
   INSERT INTO mod_item_crono_pre
    (mod_item_crono_id,
     mod_item_crono_pre_id)
   VALUES
    (p_mod_item_crono_id,
     p_mod_item_crono_pre_id);
  END IF;
  --
  ------------------------------------------------------------
  -- tratamento do vetor de papel demandado (destino)
  ------------------------------------------------------------
  DELETE FROM mod_item_crono_dest
   WHERE mod_item_crono_id = p_mod_item_crono_id;
  --
  v_delimitador         := '|';
  v_vetor_papel_dest_id := p_vetor_papel_dest_id;
  --
  WHILE nvl(length(rtrim(v_vetor_papel_dest_id)), 0) > 0
  LOOP
   v_papel_dest_id := nvl(to_number(prox_valor_retornar(v_vetor_papel_dest_id, v_delimitador)),
                          0);
   --
   IF v_papel_dest_id > 0 THEN
    SELECT COUNT(*)
      INTO v_qt
      FROM papel
     WHERE papel_id = v_papel_dest_id
       AND empresa_id = p_empresa_id;
    --
    IF v_qt = 0 THEN
     p_erro_cod := '90000';
     p_erro_msg := 'O papel demandado não existe ou não pertence a essa empresa (' ||
                   to_char(v_papel_dest_id) || ').';
     RAISE v_exception;
    END IF;
    --
    INSERT INTO mod_item_crono_dest
     (mod_item_crono_id,
      papel_id)
    VALUES
     (p_mod_item_crono_id,
      v_papel_dest_id);
   END IF;
  END LOOP;
  --
  ------------------------------------------------------------
  -- tratamento do vetor de dia da semana (repeticoes)
  ------------------------------------------------------------
  DELETE FROM mod_item_crono_dia
   WHERE mod_item_crono_id = p_mod_item_crono_id;
  --
  v_delimitador         := '|';
  v_vetor_dia_semana_id := p_vetor_dia_semana_id;
  --
  WHILE nvl(length(rtrim(v_vetor_dia_semana_id)), 0) > 0
  LOOP
   v_dia_semana_id := nvl(to_number(prox_valor_retornar(v_vetor_dia_semana_id, v_delimitador)),
                          0);
   --
   IF v_dia_semana_id > 0 THEN
    INSERT INTO mod_item_crono_dia
     (mod_item_crono_id,
      dia_semana_id)
    VALUES
     (p_mod_item_crono_id,
      v_dia_semana_id);
   END IF;
  END LOOP;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_nome_crono;
  v_compl_histor   := 'Alteração de item: ' || TRIM(p_nome_item);
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'MOD_CRONO',
                   'ALTERAR',
                   v_identif_objeto,
                   v_mod_crono_id,
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
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace,
                        1,
                        200);
   ROLLBACK;
 END item_atualizar;
 --
 --
 PROCEDURE item_excluir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 30/11/2015
  -- DESCRICAO: Exclusao de item no modelo de cronograma.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            15/10/2018  Repeticoes (exclusao de mod_item_crono_dia).
  -- Silvia            26/10/2018  Exclusao do papel destino.
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_mod_item_crono_id IN mod_item_crono.mod_item_crono_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_exception      EXCEPTION;
  v_mod_crono_id   mod_crono.mod_crono_id%TYPE;
  v_nome_crono     mod_crono.nome%TYPE;
  v_nome_item      mod_item_crono.nome%TYPE;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  --
  CURSOR c_ic IS
   SELECT mod_item_crono_id,
          num_seq
     FROM mod_item_crono
    WHERE mod_crono_id = v_mod_crono_id
    START WITH mod_item_crono_id = p_mod_item_crono_id
   CONNECT BY PRIOR mod_item_crono_id = mod_item_crono_pai_id
    ORDER SIBLINGS BY num_seq;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM mod_item_crono
   WHERE mod_item_crono_id = p_mod_item_crono_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa atividade não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT nome,
         mod_crono_id
    INTO v_nome_item,
         v_mod_crono_id
    FROM mod_item_crono
   WHERE mod_item_crono_id = p_mod_item_crono_id;
  --
  SELECT nome
    INTO v_nome_crono
    FROM mod_crono
   WHERE mod_crono_id = v_mod_crono_id;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'MOD_CRONO_C', NULL, NULL, p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE mod_item_crono
     SET oper = NULL
   WHERE mod_crono_id = v_mod_crono_id;
  --
  FOR r_ic IN c_ic
  LOOP
   --
   UPDATE mod_item_crono
      SET oper                  = 'DEL',
          mod_item_crono_pai_id = NULL
    WHERE mod_item_crono_id = r_ic.mod_item_crono_id;
   --
   DELETE FROM mod_item_crono_pre
    WHERE mod_item_crono_id = r_ic.mod_item_crono_id;
   --
   DELETE FROM mod_item_crono_pre
    WHERE mod_item_crono_pre_id = r_ic.mod_item_crono_id;
   --
   DELETE FROM mod_item_crono_dest
    WHERE mod_item_crono_id = r_ic.mod_item_crono_id;
  END LOOP;
  --
  DELETE FROM mod_item_crono_dia md
   WHERE EXISTS (SELECT 1
            FROM mod_item_crono mc
           WHERE mc.mod_crono_id = v_mod_crono_id
             AND mc.oper = 'DEL'
             AND mc.mod_item_crono_id = md.mod_item_crono_id);
  --
  DELETE FROM mod_item_crono
   WHERE mod_crono_id = v_mod_crono_id
     AND oper = 'DEL';
  --
  mod_crono_pkg.seq_renumerar(p_usuario_sessao_id,
                              p_empresa_id,
                              v_mod_crono_id,
                              p_erro_cod,
                              p_erro_msg);
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  mod_crono_pkg.ordem_renumerar(p_usuario_sessao_id,
                                p_empresa_id,
                                v_mod_crono_id,
                                p_erro_cod,
                                p_erro_msg);
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_nome_crono;
  v_compl_histor   := 'Exclusão de item: ' || TRIM(v_nome_item);
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'MOD_CRONO',
                   'ALTERAR',
                   v_identif_objeto,
                   v_mod_crono_id,
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
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace,
                        1,
                        200);
   ROLLBACK;
 END item_excluir;
 --
 --
 PROCEDURE item_lista_atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 03/12/2015
  -- DESCRICAO: Atualizacao em lista de itens do modelo de cronograma.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            15/03/2018  Novo parametro demanda.
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id           IN NUMBER,
  p_empresa_id                  IN empresa.empresa_id%TYPE,
  p_mod_crono_id                IN mod_item_crono.mod_crono_id%TYPE,
  p_vetor_mod_item_crono_id     IN VARCHAR2,
  p_vetor_dia_inicio            IN VARCHAR2,
  p_vetor_demanda               IN VARCHAR2,
  p_vetor_duracao               IN VARCHAR2,
  p_vetor_mod_item_crono_pre_id IN VARCHAR2,
  p_erro_cod                    OUT VARCHAR2,
  p_erro_msg                    OUT VARCHAR2
 ) IS
  v_qt                          INTEGER;
  v_exception                   EXCEPTION;
  v_nome_crono                  mod_crono.nome%TYPE;
  v_mod_item_crono_id           mod_item_crono.mod_item_crono_id%TYPE;
  v_dia_inicio                  mod_item_crono.dia_inicio%TYPE;
  v_duracao                     mod_item_crono.duracao%TYPE;
  v_mod_item_crono_pre_id       mod_item_crono_pre.mod_item_crono_pre_id%TYPE;
  v_demanda                     mod_item_crono.demanda%TYPE;
  v_dia_inicio_char             VARCHAR2(20);
  v_duracao_char                VARCHAR2(20);
  v_vetor_mod_item_crono_id     LONG;
  v_vetor_dia_inicio            LONG;
  v_vetor_demanda               LONG;
  v_vetor_duracao               LONG;
  v_vetor_mod_item_crono_pre_id LONG;
  v_nome_objeto                 objeto_crono.nome%TYPE;
  v_identif_objeto              historico.identif_objeto%TYPE;
  v_compl_histor                historico.complemento%TYPE;
  v_historico_id                historico.historico_id%TYPE;
  v_delimitador                 CHAR(1);
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM mod_crono
   WHERE mod_crono_id = p_mod_crono_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse modelo de Cronograma não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT nome
    INTO v_nome_crono
    FROM mod_crono
   WHERE mod_crono_id = p_mod_crono_id;
  --
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'MOD_CRONO_C', NULL, NULL, p_empresa_id) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  v_delimitador := '|';
  --
  v_vetor_mod_item_crono_id     := p_vetor_mod_item_crono_id;
  v_vetor_dia_inicio            := p_vetor_dia_inicio;
  v_vetor_demanda               := p_vetor_demanda;
  v_vetor_duracao               := p_vetor_duracao;
  v_vetor_mod_item_crono_pre_id := p_vetor_mod_item_crono_pre_id;
  --
  WHILE nvl(length(rtrim(v_vetor_mod_item_crono_id)), 0) > 0
  LOOP
   v_mod_item_crono_id     := to_number(prox_valor_retornar(v_vetor_mod_item_crono_id,
                                                            v_delimitador));
   v_dia_inicio_char       := prox_valor_retornar(v_vetor_dia_inicio, v_delimitador);
   v_demanda               := prox_valor_retornar(v_vetor_demanda, v_delimitador);
   v_duracao_char          := prox_valor_retornar(v_vetor_duracao, v_delimitador);
   v_mod_item_crono_pre_id := nvl(to_number(prox_valor_retornar(v_vetor_mod_item_crono_pre_id,
                                                                v_delimitador)),
                                  0);
   --
   IF inteiro_validar(v_dia_inicio_char) = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Dia início inválido (' || v_dia_inicio_char || ').';
    RAISE v_exception;
   END IF;
   --
   IF util_pkg.desc_retornar('demanda', v_demanda) IS NULL THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Demanda inválida (' || v_demanda || ').';
    RAISE v_exception;
   END IF;
   --
   IF inteiro_validar(v_duracao_char) = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Duração inválida (' || v_duracao_char || ').';
    RAISE v_exception;
   END IF;
   --
   v_dia_inicio := to_number(v_dia_inicio_char);
   v_duracao    := to_number(v_duracao_char);
   --
   UPDATE mod_item_crono
      SET dia_inicio = v_dia_inicio,
          demanda    = v_demanda,
          duracao    = v_duracao
    WHERE mod_item_crono_id = v_mod_item_crono_id;
   --
   DELETE FROM mod_item_crono_pre
    WHERE mod_item_crono_id = v_mod_item_crono_id;
   --
   IF nvl(v_mod_item_crono_pre_id, 0) > 0 THEN
    INSERT INTO mod_item_crono_pre
     (mod_item_crono_id,
      mod_item_crono_pre_id)
    VALUES
     (v_mod_item_crono_id,
      v_mod_item_crono_pre_id);
   END IF;
  END LOOP;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_nome_crono;
  v_compl_histor   := 'Alteração em lista dos itens';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'MOD_CRONO',
                   'ALTERAR',
                   v_identif_objeto,
                   p_mod_crono_id,
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
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace,
                        1,
                        200);
   ROLLBACK;
 END item_lista_atualizar;
 --
 --
 PROCEDURE item_mover
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 02/12/2015
  -- DESCRICAO: Move o item de MOD_CRONO origem para baixo do item destino.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- xxxxxxxxxxxx      dd/mm/yyyy
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id     IN NUMBER,
  p_empresa_id            IN empresa.empresa_id%TYPE,
  p_mod_item_crono_ori_id IN mod_item_crono.mod_item_crono_id%TYPE,
  p_mod_item_crono_des_id IN mod_item_crono.mod_item_crono_id%TYPE,
  p_erro_cod              OUT VARCHAR2,
  p_erro_msg              OUT VARCHAR2
 ) IS
  v_qt                         INTEGER;
  v_exception                  EXCEPTION;
  v_nome_crono                 mod_crono.nome%TYPE;
  v_mod_crono_id               mod_crono.mod_crono_id%TYPE;
  v_ordem                      mod_item_crono.ordem%TYPE;
  v_nome_item                  mod_item_crono.nome%TYPE;
  v_mod_item_crono_pai_prox_id mod_item_crono.mod_item_crono_pai_id%TYPE;
  v_ordem_prox                 mod_item_crono.ordem%TYPE;
  v_nivel_prox                 mod_item_crono.nivel%TYPE;
  v_nivel_ori                  mod_item_crono.nivel%TYPE;
  v_nivel_des                  mod_item_crono.nivel%TYPE;
  v_ordem_des                  mod_item_crono.ordem%TYPE;
  v_num_seq_des                mod_item_crono.num_seq%TYPE;
  v_mod_item_crono_pai_des_id  mod_item_crono.mod_item_crono_pai_id%TYPE;
  v_tem_filho_des              NUMBER(5);
  v_identif_objeto             historico.identif_objeto%TYPE;
  v_compl_histor               historico.complemento%TYPE;
  v_historico_id               historico.historico_id%TYPE;
  --
  CURSOR c_ic IS
   SELECT mod_item_crono_id
     FROM mod_item_crono
    WHERE mod_crono_id = v_mod_crono_id
    START WITH mod_item_crono_id = p_mod_item_crono_ori_id
   CONNECT BY PRIOR mod_item_crono_id = mod_item_crono_pai_id
    ORDER SIBLINGS BY num_seq;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM mod_item_crono
   WHERE mod_item_crono_id = p_mod_item_crono_ori_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa atividade origem não existe (' || to_char(p_mod_item_crono_ori_id) || ').';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_mod_item_crono_des_id, 0) > 0 THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM mod_item_crono
    WHERE mod_item_crono_id = p_mod_item_crono_des_id;
   --
   IF v_qt = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Essa atividade destino não existe (' || to_char(p_mod_item_crono_des_id) || ').';
    RAISE v_exception;
   END IF;
  END IF;
  --
  SELECT mc.nome,
         mc.mod_crono_id,
         mi.nivel
    INTO v_nome_crono,
         v_mod_crono_id,
         v_nivel_ori
    FROM mod_crono      mc,
         mod_item_crono mi
   WHERE mi.mod_item_crono_id = p_mod_item_crono_ori_id
     AND mi.mod_crono_id = mc.mod_crono_id;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'MOD_CRONO_C', NULL, NULL, p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  v_nivel_des     := 1;
  v_ordem_des     := 0;
  v_tem_filho_des := 0;
  --
  IF nvl(p_mod_item_crono_des_id, 0) > 0 THEN
   SELECT nivel,
          ordem,
          num_seq,
          mod_item_crono_pai_id
     INTO v_nivel_des,
          v_ordem_des,
          v_num_seq_des,
          v_mod_item_crono_pai_des_id
     FROM mod_item_crono
    WHERE mod_item_crono_id = p_mod_item_crono_des_id;
   --
   -- verifica se o destino tem filhos
   SELECT COUNT(*)
     INTO v_qt
     FROM mod_item_crono
    WHERE mod_item_crono_pai_id = p_mod_item_crono_des_id;
   --
   IF v_qt > 0 THEN
    v_tem_filho_des := 1;
   END IF;
  END IF;
  --
  -- seleciona a ordem, o nivel e o pai
  -- do item abaixo ao destino
  SELECT MIN(ordem)
    INTO v_ordem_prox
    FROM mod_item_crono
   WHERE ordem > v_ordem_des
     AND mod_crono_id = v_mod_crono_id;
  --
  IF v_ordem_prox IS NULL THEN
   v_ordem_prox                 := 1000000000;
   v_nivel_prox                 := 1;
   v_mod_item_crono_pai_prox_id := NULL;
  ELSE
   SELECT nivel,
          mod_item_crono_pai_id
     INTO v_nivel_prox,
          v_mod_item_crono_pai_prox_id
     FROM mod_item_crono
    WHERE ordem = v_ordem_prox
      AND mod_crono_id = v_mod_crono_id;
  END IF;
  --
  IF v_nivel_ori = v_nivel_des AND v_tem_filho_des = 1 THEN
   -- o item acima (destino) tem o mesmo nivel do item movido.
   -- Pode mover desde que o item acima nao tenha filhos.
   p_erro_cod := '90000';
   p_erro_msg := 'Movimentação inválida.';
   RAISE v_exception;
  END IF;
  --
  IF v_nivel_ori = v_nivel_des OR v_nivel_ori = v_nivel_prox THEN
   -- o item vai manter o nivel do item abaixo ou acima, com o mesmo
   -- pai do item acima ou abaixo.
   IF v_nivel_ori = v_nivel_des THEN
    v_mod_item_crono_pai_prox_id := v_mod_item_crono_pai_des_id;
   END IF;
  ELSE
   --
   IF v_nivel_ori < v_nivel_des OR v_nivel_ori - v_nivel_des > 1 OR
      p_mod_item_crono_des_id = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Movimentação inválida.';
    RAISE v_exception;
   END IF;
   --
   v_mod_item_crono_pai_prox_id := p_mod_item_crono_des_id;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  -- a nova posicao sera entre o item destino e o proximo
  v_ordem := round((v_ordem_des + v_ordem_prox) / 2, 0);
  --
  IF v_nivel_ori = v_nivel_des THEN
   v_mod_item_crono_pai_prox_id := v_mod_item_crono_pai_des_id;
  END IF;
  --
  -- trata a arvore movida
  FOR r_ic IN c_ic
  LOOP
   IF r_ic.mod_item_crono_id = p_mod_item_crono_ori_id THEN
    -- apenas o proprio item movido muda de pai
    UPDATE mod_item_crono
       SET mod_item_crono_pai_id = v_mod_item_crono_pai_prox_id,
           ordem                 = v_ordem
     WHERE mod_item_crono_id = r_ic.mod_item_crono_id;
   ELSE
    -- acerta a ordem dos demais itens
    v_ordem := v_ordem + 10;
    --
    UPDATE mod_item_crono
       SET ordem = v_ordem
     WHERE mod_item_crono_id = r_ic.mod_item_crono_id;
   END IF;
  END LOOP;
  --
  mod_crono_pkg.seq_renumerar(p_usuario_sessao_id,
                              p_empresa_id,
                              v_mod_crono_id,
                              p_erro_cod,
                              p_erro_msg);
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  mod_crono_pkg.ordem_renumerar(p_usuario_sessao_id,
                                p_empresa_id,
                                v_mod_crono_id,
                                p_erro_cod,
                                p_erro_msg);
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_nome_crono;
  v_compl_histor   := 'Movimentação de item: ' || TRIM(v_nome_item);
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'MOD_CRONO',
                   'ALTERAR',
                   v_identif_objeto,
                   v_mod_crono_id,
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
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace,
                        1,
                        200);
   ROLLBACK;
 END item_mover;
 --
 --
 PROCEDURE item_deslocar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 02/12/2015
  -- DESCRICAO: Desloca o item de MOD_CRONO para a direita ou para a esquerda.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- xxxxxxxxxxxx      dd/mm/yyyy
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_mod_item_crono_id IN mod_item_crono.mod_item_crono_id%TYPE,
  p_direcao           IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt                         INTEGER;
  v_exception                  EXCEPTION;
  v_nome_crono                 mod_crono.nome%TYPE;
  v_mod_crono_id               mod_crono.mod_crono_id%TYPE;
  v_nome_item                  mod_item_crono.nome%TYPE;
  v_mod_item_crono_pai_id      mod_item_crono.mod_item_crono_pai_id%TYPE;
  v_mod_item_crono_pai_novo_id mod_item_crono.mod_item_crono_pai_id%TYPE;
  v_nivel                      mod_item_crono.nivel%TYPE;
  v_ordem                      mod_item_crono.ordem%TYPE;
  v_ordem_aux                  mod_item_crono.ordem%TYPE;
  v_identif_objeto             historico.identif_objeto%TYPE;
  v_compl_histor               historico.complemento%TYPE;
  v_historico_id               historico.historico_id%TYPE;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM mod_item_crono
   WHERE mod_item_crono_id = p_mod_item_crono_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa atividade não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT mc.nome,
         mc.mod_crono_id,
         mi.nivel,
         mi.ordem,
         mi.mod_item_crono_pai_id
    INTO v_nome_crono,
         v_mod_crono_id,
         v_nivel,
         v_ordem,
         v_mod_item_crono_pai_id
    FROM mod_crono      mc,
         mod_item_crono mi
   WHERE mi.mod_item_crono_id = p_mod_item_crono_id
     AND mi.mod_crono_id = mc.mod_crono_id;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'MOD_CRONO_C', NULL, NULL, p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_direcao) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Direção do deslocamento não informada.';
   RAISE v_exception;
  END IF;
  --
  IF p_direcao NOT IN ('DIR', 'ESQ') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Direção do deslocamento inválida.';
   RAISE v_exception;
  END IF;
  --
  IF p_direcao = 'ESQ' THEN
   IF v_mod_item_crono_pai_id IS NULL THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Deslocamento inválido.';
    RAISE v_exception;
   ELSE
    -- pega o avo do item atual
    SELECT mod_item_crono_pai_id
      INTO v_mod_item_crono_pai_novo_id
      FROM mod_item_crono
     WHERE mod_item_crono_id = v_mod_item_crono_pai_id;
   END IF;
  END IF;
  --
  IF p_direcao = 'DIR' THEN
   -- pega 1ro irmao acima (mesmo nivel, com mesmo pai)
   SELECT MAX(ordem)
     INTO v_ordem_aux
     FROM mod_item_crono
    WHERE mod_crono_id = v_mod_crono_id
      AND nvl(mod_item_crono_pai_id, 0) = nvl(v_mod_item_crono_pai_id, 0)
      AND nivel = v_nivel
      AND ordem < v_ordem;
   --
   IF v_ordem_aux IS NULL THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Deslocamento inválido.';
    RAISE v_exception;
   ELSE
    SELECT mod_item_crono_id
      INTO v_mod_item_crono_pai_novo_id
      FROM mod_item_crono
     WHERE mod_crono_id = v_mod_crono_id
       AND nivel = v_nivel
       AND ordem = v_ordem_aux;
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE mod_item_crono
     SET mod_item_crono_pai_id = v_mod_item_crono_pai_novo_id
   WHERE mod_item_crono_id = p_mod_item_crono_id;
  --
  mod_crono_pkg.seq_renumerar(p_usuario_sessao_id,
                              p_empresa_id,
                              v_mod_crono_id,
                              p_erro_cod,
                              p_erro_msg);
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  mod_crono_pkg.ordem_renumerar(p_usuario_sessao_id,
                                p_empresa_id,
                                v_mod_crono_id,
                                p_erro_cod,
                                p_erro_msg);
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_nome_crono;
  v_compl_histor   := 'Deslocamento de item: ' || TRIM(v_nome_item);
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'MOD_CRONO',
                   'ALTERAR',
                   v_identif_objeto,
                   v_mod_crono_id,
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
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace,
                        1,
                        200);
   ROLLBACK;
 END item_deslocar;
 --
 --
 PROCEDURE seq_renumerar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 30/11/2015
  -- DESCRICAO: subrotina que renumera a sequencia e o nivel dos itens do MOD_CRONO.
  --  NAO FAZ COMMIT.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- xxxxxxxxxxxx      dd/mm/yyyy
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_mod_crono_id      IN mod_item_crono.mod_crono_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt        INTEGER;
  v_exception EXCEPTION;
  v_num_seq   mod_item_crono.num_seq%TYPE;
  --
  CURSOR c_ic IS
   SELECT mod_item_crono_id,
          LEVEL
     FROM mod_item_crono
    WHERE mod_crono_id = p_mod_crono_id
    START WITH mod_item_crono_pai_id IS NULL
   CONNECT BY PRIOR mod_item_crono_id = mod_item_crono_pai_id
    ORDER SIBLINGS BY ordem;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  v_num_seq := 0;
  --
  FOR r_ic IN c_ic
  LOOP
   v_num_seq := v_num_seq + 1;
   --
   UPDATE mod_item_crono
      SET num_seq = v_num_seq,
          nivel   = r_ic.level
    WHERE mod_item_crono_id = r_ic.mod_item_crono_id;
  END LOOP;
  --
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   NULL;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace,
                        1,
                        200);
 END seq_renumerar;
 --
 --
 PROCEDURE ordem_renumerar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 30/11/2015
  -- DESCRICAO: subrotina que renumera a ordem dos itens do MOD_CRONO.
  --  NAO FAZ COMMIT.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- xxxxxxxxxxxx      dd/mm/yyyy
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_mod_crono_id      IN mod_item_crono.mod_crono_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt        INTEGER;
  v_exception EXCEPTION;
  v_ordem     mod_item_crono.ordem%TYPE;
  --
  CURSOR c_ic IS
   SELECT mod_item_crono_id
     FROM mod_item_crono
    WHERE mod_crono_id = p_mod_crono_id
    START WITH mod_item_crono_pai_id IS NULL
   CONNECT BY PRIOR mod_item_crono_id = mod_item_crono_pai_id
    ORDER SIBLINGS BY num_seq;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  v_ordem := 0;
  --
  FOR r_ic IN c_ic
  LOOP
   v_ordem := v_ordem + 100000;
   --
   UPDATE mod_item_crono
      SET ordem = v_ordem
    WHERE mod_item_crono_id = r_ic.mod_item_crono_id;
  END LOOP;
  --
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   NULL;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace,
                        1,
                        200);
 END ordem_renumerar;
 --
END; -- MOD_CRONO_PKG



/
