--------------------------------------------------------
--  DDL for Package Body SALARIO_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "SALARIO_PKG" IS
 --
 PROCEDURE adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                    ProcessMind     DATA: 02/10/2008
  -- DESCRICAO: Inclusão de SALARIO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            19/08/2009  Novo atributo com valor de venda mensal.
  -- Silvia            12/04/2010  Implementacao de multiagencia.
  -- Silvia            27/05/2016  Encriptacao de valores
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_usuario_id        IN salario.usuario_id%TYPE,
  p_data_ini          IN VARCHAR2,
  p_custo_mensal      IN VARCHAR2,
  p_venda_mensal      IN VARCHAR2,
  p_salario_id        OUT salario.salario_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt              INTEGER;
  v_identif_objeto  historico.identif_objeto%TYPE;
  v_compl_histor    historico.complemento%TYPE;
  v_historico_id    historico.historico_id%TYPE;
  v_exception       EXCEPTION;
  v_salario_id      salario.salario_id%TYPE;
  v_data_ini        salario.data_ini%TYPE;
  v_data_ini_ant    salario.data_ini%TYPE;
  v_custo_mensal    salario.custo_mensal%TYPE;
  v_custo_hora      salario.custo_hora%TYPE;
  v_venda_mensal    salario.venda_mensal%TYPE;
  v_venda_hora      salario.venda_hora%TYPE;
  v_custo_mensal_en salario.custo_mensal%TYPE;
  v_custo_hora_en   salario.custo_hora%TYPE;
  v_venda_mensal_en salario.venda_mensal%TYPE;
  v_venda_hora_en   salario.venda_hora%TYPE;
  v_login           usuario.login%TYPE;
  v_pessoa          pessoa.nome%TYPE;
  v_qt_horas        NUMBER;
  --
 BEGIN
  v_qt         := 0;
  p_salario_id := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'SALARIO_C', NULL, NULL, p_empresa_id) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM usuario
   WHERE usuario_id = p_usuario_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse usuário não existe.';
   RAISE v_exception;
  END IF;
  --
  v_qt_horas := numero_converter(empresa_pkg.parametro_retornar(p_empresa_id,
                                                                'QT_HORAS_MENSAIS'));
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
  IF data_validar('01' || p_data_ini) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data inválida.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_custo_mensal) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do salário é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF moeda_validar(p_custo_mensal) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Valor do salário inválido.';
   RAISE v_exception;
  END IF;
  --
  IF moeda_validar(p_venda_mensal) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Valor de venda inválido.';
   RAISE v_exception;
  END IF;
  --
  v_data_ini     := data_converter('01' || p_data_ini);
  v_custo_mensal := nvl(moeda_converter(p_custo_mensal), 0);
  v_venda_mensal := nvl(moeda_converter(p_venda_mensal), 0);
  --
  SELECT MAX(data_ini)
    INTO v_data_ini_ant
    FROM salario
   WHERE usuario_id = p_usuario_id;
  --
  IF v_data_ini <= v_data_ini_ant THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A data não pode ser anterior ou igual a datas já cadastradas.';
   RAISE v_exception;
  END IF;
  --
  SELECT us.login,
         pe.nome
    INTO v_login,
         v_pessoa
    FROM usuario us,
         pessoa  pe
   WHERE us.usuario_id = p_usuario_id
     AND us.usuario_id = pe.usuario_id;
  --
  v_custo_hora := round(v_custo_mensal / v_qt_horas, 2);
  v_venda_hora := round(v_venda_mensal / v_qt_horas, 2);
  --
  -- encripta para salvar
  v_custo_mensal_en := util_pkg.num_encode(v_custo_mensal);
  --
  IF v_custo_mensal_en = -99999 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Erro na encriptação (' || moeda_mostrar(v_custo_mensal, 'N') || ').';
   RAISE v_exception;
  END IF;
  --
  v_venda_mensal_en := util_pkg.num_encode(v_venda_mensal);
  --
  IF v_venda_mensal_en = -99999 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Erro na encriptação (' || moeda_mostrar(v_venda_mensal, 'N') || ').';
   RAISE v_exception;
  END IF;
  --
  v_custo_hora_en := util_pkg.num_encode(v_custo_hora);
  --
  IF v_custo_hora_en = -99999 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Erro na encriptação (' || moeda_mostrar(v_custo_hora, 'N') || ').';
   RAISE v_exception;
  END IF;
  --
  v_venda_hora_en := util_pkg.num_encode(v_venda_hora);
  --
  IF v_venda_hora_en = -99999 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Erro na encriptação (' || moeda_mostrar(v_venda_hora, 'N') || ').';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT seq_salario.nextval
    INTO v_salario_id
    FROM dual;
  --
  INSERT INTO salario
   (salario_id,
    usuario_id,
    data_ini,
    custo_mensal,
    custo_hora,
    venda_mensal,
    venda_hora)
  VALUES
   (v_salario_id,
    p_usuario_id,
    v_data_ini,
    v_custo_mensal_en,
    v_custo_hora_en,
    v_venda_mensal_en,
    v_venda_hora_en);
  --
  -- atualiza os custos de eventuais apontamentos realizados a partir dessa data
  apontam_pkg.apontamento_custo_atualizar(p_usuario_id,
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
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_login || ', desde: ' || mes_ano_mostrar(v_data_ini);
  v_compl_histor   := v_pessoa;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'SALARIO',
                   'INCLUIR',
                   v_identif_objeto,
                   v_salario_id,
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
  p_salario_id := v_salario_id;
  p_erro_cod   := '00000';
  p_erro_msg   := 'Operação realizada com sucesso.';
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
 END; -- adicionar
 --
 --
 PROCEDURE atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                    ProcessMind     DATA: 02/10/2008
  -- DESCRICAO: Atualização de SALARIO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            19/08/2009  Novo atributo com valor de venda mensal.
  -- Silvia            12/04/2010  Implementacao de multiagencia.
  -- Silvia            27/05/2016  Encriptacao de valores
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_salario_id        IN salario.salario_id%TYPE,
  p_data_ini          IN VARCHAR2,
  p_custo_mensal      IN VARCHAR2,
  p_venda_mensal      IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt              INTEGER;
  v_identif_objeto  historico.identif_objeto%TYPE;
  v_compl_histor    historico.complemento%TYPE;
  v_historico_id    historico.historico_id%TYPE;
  v_exception       EXCEPTION;
  v_data_ini        salario.data_ini%TYPE;
  v_data_ini_atu    salario.data_ini%TYPE;
  v_data_ini_max    salario.data_ini%TYPE;
  v_data_ini_ant    salario.data_ini%TYPE;
  v_custo_mensal    salario.custo_mensal%TYPE;
  v_custo_hora      salario.custo_hora%TYPE;
  v_venda_mensal    salario.venda_mensal%TYPE;
  v_venda_hora      salario.venda_hora%TYPE;
  v_custo_mensal_en salario.custo_mensal%TYPE;
  v_custo_hora_en   salario.custo_hora%TYPE;
  v_venda_mensal_en salario.venda_mensal%TYPE;
  v_venda_hora_en   salario.venda_hora%TYPE;
  v_usuario_id      usuario.usuario_id%TYPE;
  v_login           usuario.login%TYPE;
  v_pessoa          pessoa.nome%TYPE;
  v_qt_horas        NUMBER;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'SALARIO_C', NULL, NULL, p_empresa_id) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM salario
   WHERE salario_id = p_salario_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse salário não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT usuario_id,
         data_ini
    INTO v_usuario_id,
         v_data_ini_atu
    FROM salario
   WHERE salario_id = p_salario_id;
  --
  v_qt_horas := numero_converter(empresa_pkg.parametro_retornar(p_empresa_id,
                                                                'QT_HORAS_MENSAIS'));
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
  IF data_validar('01' || p_data_ini) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data inválida.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_custo_mensal) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do salário é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF moeda_validar(p_custo_mensal) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Valor do salário inválido.';
   RAISE v_exception;
  END IF;
  --
  IF moeda_validar(p_venda_mensal) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Valor de venda inválido.';
   RAISE v_exception;
  END IF;
  --
  v_data_ini     := data_converter('01' || p_data_ini);
  v_custo_mensal := nvl(moeda_converter(p_custo_mensal), 0);
  v_venda_mensal := nvl(moeda_converter(p_venda_mensal), 0);
  --
  SELECT us.login,
         pe.nome
    INTO v_login,
         v_pessoa
    FROM usuario us,
         pessoa  pe
   WHERE us.usuario_id = v_usuario_id
     AND us.usuario_id = pe.usuario_id;
  --
  SELECT MAX(data_ini)
    INTO v_data_ini_max
    FROM salario
   WHERE usuario_id = v_usuario_id;
  --
  IF v_data_ini_atu <> v_data_ini_max THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Apenas o salário mais recente pode ser alterado.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(data_ini)
    INTO v_data_ini_ant
    FROM salario
   WHERE usuario_id = v_usuario_id
     AND salario_id <> p_salario_id;
  --
  IF v_data_ini <= v_data_ini_ant THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A data não pode ser anterior ou igual a datas já cadastradas.';
   RAISE v_exception;
  END IF;
  --
  v_custo_hora := round(v_custo_mensal / v_qt_horas, 2);
  v_venda_hora := round(v_venda_mensal / v_qt_horas, 2);
  --
  -- encripta para salvar
  v_custo_mensal_en := util_pkg.num_encode(v_custo_mensal);
  --
  IF v_custo_mensal_en = -99999 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Erro na encriptação (' || moeda_mostrar(v_custo_mensal, 'N') || ').';
   RAISE v_exception;
  END IF;
  --
  v_venda_mensal_en := util_pkg.num_encode(v_venda_mensal);
  --
  IF v_venda_mensal_en = -99999 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Erro na encriptação (' || moeda_mostrar(v_venda_mensal, 'N') || ').';
   RAISE v_exception;
  END IF;
  --
  v_custo_hora_en := util_pkg.num_encode(v_custo_hora);
  --
  IF v_custo_hora_en = -99999 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Erro na encriptação (' || moeda_mostrar(v_custo_hora, 'N') || ').';
   RAISE v_exception;
  END IF;
  --
  v_venda_hora_en := util_pkg.num_encode(v_venda_hora);
  --
  IF v_venda_hora_en = -99999 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Erro na encriptação (' || moeda_mostrar(v_venda_hora, 'N') || ').';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE salario
     SET data_ini     = v_data_ini,
         custo_mensal = v_custo_mensal_en,
         custo_hora   = v_custo_hora_en,
         venda_mensal = v_venda_mensal_en,
         venda_hora   = v_venda_hora_en
   WHERE salario_id = p_salario_id;
  --
  IF v_data_ini_ant IS NULL THEN
   v_data_ini_ant := v_data_ini;
  END IF;
  --
  -- atualiza os custos de eventuais apontamentos realizados a partir da data anterior
  apontam_pkg.apontamento_custo_atualizar(v_usuario_id,
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
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_login || ', desde: ' || mes_ano_mostrar(v_data_ini);
  v_compl_histor   := v_pessoa;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'SALARIO',
                   'ALTERAR',
                   v_identif_objeto,
                   p_salario_id,
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
 END; -- atualizar
 --
 --
 PROCEDURE excluir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                    ProcessMind     DATA: 02/10/2008
  -- DESCRICAO: Exclusão de SALARIO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- xxxxxxxxxxxx      dd/mm/yyyy
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_salario_id        IN salario.salario_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_exception      EXCEPTION;
  v_usuario_id     usuario.usuario_id%TYPE;
  v_login          usuario.login%TYPE;
  v_pessoa         pessoa.nome%TYPE;
  v_data_ini       salario.data_ini%TYPE;
  v_data_ini_max   salario.data_ini%TYPE;
  v_data_ini_ant   salario.data_ini%TYPE;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'SALARIO_C', NULL, NULL, p_empresa_id) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM salario
   WHERE salario_id = p_salario_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse salário não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT usuario_id,
         data_ini
    INTO v_usuario_id,
         v_data_ini
    FROM salario
   WHERE salario_id = p_salario_id;
  --
  SELECT MAX(data_ini)
    INTO v_data_ini_max
    FROM salario
   WHERE usuario_id = v_usuario_id;
  --
  IF v_data_ini <> v_data_ini_max THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Apenas o salário mais recente pode ser excluído.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(data_ini)
    INTO v_data_ini_ant
    FROM salario
   WHERE usuario_id = v_usuario_id
     AND salario_id <> p_salario_id;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM apontam_data
   WHERE usuario_id = v_usuario_id;
  --
  IF v_qt > 0 AND v_data_ini_ant IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Usuário com apontamentos já registrados não pode ' ||
                 'ficar sem salário definido.';
   RAISE v_exception;
  END IF;
  --
  SELECT us.login,
         pe.nome
    INTO v_login,
         v_pessoa
    FROM usuario us,
         pessoa  pe
   WHERE us.usuario_id = v_usuario_id
     AND us.usuario_id = pe.usuario_id;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  DELETE FROM salario
   WHERE salario_id = p_salario_id;
  --
  IF v_data_ini_ant IS NOT NULL THEN
   -- atualiza os custos de eventuais apontamentos realizados a partir da data anterior
   apontam_pkg.apontamento_custo_atualizar(v_usuario_id,
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
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_login || ', desde: ' || mes_ano_mostrar(v_data_ini);
  v_compl_histor   := v_pessoa;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'SALARIO',
                   'EXCLUIR',
                   v_identif_objeto,
                   p_salario_id,
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
 END; -- excluir
 --
 --
 FUNCTION salario_id_atu_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 02/10/2008
  -- DESCRICAO: retorna o ID do salario atual, baseado na data do sistema. Se nao
  --  encontrar salario definido, retorna NULL. Em caso de erro, retorna zero.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- xxxxxxxxxxxx      dd/mm/yyyy
  ------------------------------------------------------------------------------------------
  p_usuario_id IN NUMBER
 ) RETURN INTEGER AS
  v_qt         INTEGER;
  v_salario_id salario.salario_id%TYPE;
  v_data_ini   salario.data_ini%TYPE;
  --
 BEGIN
  v_salario_id := NULL;
  --
  SELECT MAX(data_ini)
    INTO v_data_ini
    FROM salario
   WHERE usuario_id = p_usuario_id
     AND data_ini <= trunc(SYSDATE);
  --
  IF v_data_ini IS NOT NULL THEN
   SELECT salario_id
     INTO v_salario_id
     FROM salario
    WHERE usuario_id = p_usuario_id
      AND data_ini = v_data_ini;
  END IF;
  --
  RETURN v_salario_id;
  --
 EXCEPTION
  WHEN OTHERS THEN
   v_salario_id := 0;
   RETURN v_salario_id;
 END salario_id_atu_retornar;
 --
 --
 FUNCTION salario_id_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 02/10/2008
  -- DESCRICAO: retorna o ID do salario do usuario, baseado na data especificada. Se nao
  --  encontrar salario definido, retorna NULL. Em caso de erro, retorna zero.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- xxxxxxxxxxxx      dd/mm/yyyy
  ------------------------------------------------------------------------------------------
  p_usuario_id IN NUMBER,
  p_data       IN DATE
 ) RETURN INTEGER AS
  v_qt         INTEGER;
  v_salario_id salario.salario_id%TYPE;
  v_data_ini   salario.data_ini%TYPE;
  --
 BEGIN
  v_salario_id := NULL;
  --
  SELECT MAX(data_ini)
    INTO v_data_ini
    FROM salario
   WHERE usuario_id = p_usuario_id
     AND trunc(data_ini) <= trunc(p_data);
  --
  IF v_data_ini IS NOT NULL THEN
   SELECT salario_id
     INTO v_salario_id
     FROM salario
    WHERE usuario_id = p_usuario_id
      AND trunc(data_ini) = trunc(v_data_ini);
  END IF;
  --
  RETURN v_salario_id;
  --
 EXCEPTION
  WHEN OTHERS THEN
   v_salario_id := 0;
   RETURN v_salario_id;
 END salario_id_retornar;
 --
--
END; -- SALARIO_PKG



/
