--------------------------------------------------------
--  DDL for Package Body VOLUME_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "VOLUME_PKG" IS
 --
 PROCEDURE retornar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 10/12/2004
  -- DESCRICAO: Retorna o proximo volume disponivel p/ um determinado tipo de objeto.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            02/09/2008  Criacao automatica de novo volume.
  -- Silvia            06/04/2010  Troca da barra / pela \
  -- Silvia            11/07/2013  Novo parametro servidor_arquivo_id.
  -- Silvia            15/06/2021  Troca da barra \ pela / (linux)
  ------------------------------------------------------------------------------------------
 (
  p_servidor_arquivo_id IN servidor_arquivo.servidor_arquivo_id%TYPE,
  p_tipo_objeto         IN volume.prefixo%TYPE,
  p_volume_id           OUT volume.volume_id%TYPE,
  p_numero              OUT volume.numero%TYPE,
  p_caminho             OUT volume.caminho%TYPE,
  p_erro_cod            OUT VARCHAR2,
  p_erro_msg            OUT VARCHAR2
 ) IS
  v_qt              INTEGER;
  v_exception       EXCEPTION;
  v_volume_ativo_id volume.volume_id%TYPE;
  v_numero_ativo    volume.numero%TYPE;
  v_prefixo_ativo   volume.prefixo%TYPE;
  v_caminho_ativo   volume.caminho%TYPE;
  v_volume_vazio_id volume.volume_id%TYPE;
  v_numero_vazio    volume.numero%TYPE;
  v_caminho         volume.caminho%TYPE;
  --
 BEGIN
  v_qt        := 0;
  p_volume_id := 0;
  p_numero    := 0;
  p_caminho   := ' ';
  --
  LOCK TABLE volume IN EXCLUSIVE MODE;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF rtrim(p_tipo_objeto) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do tipo de objeto obrigatório.';
   RAISE v_exception;
  END IF;
  --
  -- verifica qual o volume ativo p/ esse tipo de objeto
  SELECT MAX(volume_id),
         MAX(numero)
    INTO v_volume_ativo_id,
         v_numero_ativo
    FROM volume
   WHERE prefixo = upper(p_tipo_objeto)
     AND status = 'A'
     AND servidor_arquivo_id = p_servidor_arquivo_id;
  --
  IF v_volume_ativo_id IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Não foi encontrado um volume ativo para o tipo de objeto ' || p_tipo_objeto || '.';
   RAISE v_exception;
  END IF;
  --
  -- verifica quantos arquivos ja foram criados nesse volume
  SELECT COUNT(*)
    INTO v_qt
    FROM arquivo
   WHERE volume_id = v_volume_ativo_id;
  --
  IF v_qt >= 255 THEN
   -- o volume ativo esta no limite.
   -- seleciona o proximo volume vazio.
   SELECT MAX(volume_id),
          MAX(numero)
     INTO v_volume_vazio_id,
          v_numero_vazio
     FROM volume
    WHERE prefixo = upper(p_tipo_objeto)
      AND numero = v_numero_ativo + 1
      AND status = 'V'
      AND servidor_arquivo_id = p_servidor_arquivo_id;
   --
   IF v_volume_vazio_id IS NULL THEN
    -- nao foi encontrado o próximo volume vazio. Cria um automaticamente.
    SELECT prefixo,
           caminho
      INTO v_prefixo_ativo,
           v_caminho_ativo
      FROM volume
     WHERE volume_id = v_volume_ativo_id;
    --
    volume_pkg.adicionar(1,
                         'N',
                         p_servidor_arquivo_id,
                         v_prefixo_ativo,
                         v_numero_ativo + 1,
                         v_caminho_ativo,
                         'V',
                         v_volume_vazio_id,
                         p_erro_cod,
                         p_erro_msg);
    --
    IF p_erro_cod <> '00000' THEN
     RAISE v_exception;
    END IF;
    --
    v_numero_vazio := v_numero_ativo + 1;
   END IF;
   --
   -- marca o volume ativo como cheio
   UPDATE volume
      SET status = 'C'
    WHERE volume_id = v_volume_ativo_id;
   --
   -- marca o volume vazio como ativo
   UPDATE volume
      SET status = 'A'
    WHERE volume_id = v_volume_vazio_id;
   --
   p_volume_id := v_volume_vazio_id;
   p_numero    := v_numero_vazio;
  ELSE
   p_volume_id := v_volume_ativo_id;
   p_numero    := v_numero_ativo;
  END IF;
  --
  SELECT MAX(caminho)
    INTO v_caminho
    FROM volume
   WHERE volume_id = p_volume_id;
  --
  p_caminho := v_caminho || '/' || upper(p_tipo_objeto);
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
 END; -- retornar
 --
 --
 PROCEDURE adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 10/12/2004
  -- DESCRICAO: Inclusão de VOLUME
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- xxxxxxxxxxxx      dd/mm/yyyy
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id   IN NUMBER,
  p_flag_commit         IN VARCHAR2,
  p_servidor_arquivo_id IN servidor_arquivo.servidor_arquivo_id%TYPE,
  p_prefixo             IN volume.prefixo%TYPE,
  p_numero              IN VARCHAR2,
  p_caminho             IN volume.caminho%TYPE,
  p_status              IN volume.status%TYPE,
  p_volume_id           OUT volume.volume_id%TYPE,
  p_erro_cod            OUT VARCHAR2,
  p_erro_msg            OUT VARCHAR2
 ) IS
  v_qt        INTEGER;
  v_exception EXCEPTION;
  v_volume_id volume.volume_id%TYPE;
  --
 BEGIN
  v_qt        := 0;
  p_volume_id := 0;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF rtrim(p_prefixo) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do prefixo é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_numero) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do número é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF inteiro_validar(p_numero) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Número inválido.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_caminho) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do caminho é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_status) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do status é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_status) NOT IN ('V', 'A', 'C') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Status inválido.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM volume
   WHERE prefixo = p_prefixo
     AND numero = p_numero
     AND servidor_arquivo_id = p_servidor_arquivo_id;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse número já existe.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT seq_volume.nextval
    INTO v_volume_id
    FROM dual;
  --
  INSERT INTO volume
   (volume_id,
    servidor_arquivo_id,
    prefixo,
    numero,
    caminho,
    status)
  VALUES
   (v_volume_id,
    p_servidor_arquivo_id,
    p_prefixo,
    to_number(p_numero),
    p_caminho,
    p_status);
  --
  IF p_flag_commit = 'S' THEN
   COMMIT;
  END IF;
  --
  p_volume_id := v_volume_id;
  p_erro_cod  := '00000';
  p_erro_msg  := 'Operação realizada com sucesso.';
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
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 10/12/2004
  -- DESCRICAO: Atualização de VOLUME
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- xxxxxxxxxxxx      dd/mm/yyyy
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_volume_id         IN volume.volume_id%TYPE,
  p_prefixo           IN volume.prefixo%TYPE,
  p_numero            IN VARCHAR2,
  p_caminho           IN volume.caminho%TYPE,
  p_status            IN volume.status%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt        INTEGER;
  v_exception EXCEPTION;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM volume
   WHERE volume_id = p_volume_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse volume não existe.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF rtrim(p_prefixo) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do prefixo é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_numero) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do número é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF inteiro_validar(p_numero) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Número inválido.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_caminho) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do caminho é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_status) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do status é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_status) NOT IN ('V', 'A', 'C') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Status inválido.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM volume
   WHERE volume_id <> p_volume_id
     AND prefixo = p_prefixo
     AND numero = p_numero;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse número já existe.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE volume
     SET prefixo = p_prefixo,
         numero  = to_number(p_numero),
         caminho = p_caminho,
         status  = p_status
   WHERE volume_id = p_volume_id;
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
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 10/12/2004
  -- DESCRICAO: Exclusão de VOLUME
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- xxxxxxxxxxxx      dd/mm/yyyy
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_volume_id         IN volume.volume_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt        INTEGER;
  v_exception EXCEPTION;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM volume
   WHERE volume_id = p_volume_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse volume não existe.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM arquivo
   WHERE volume_id = p_volume_id;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse volume está sendo referenciado por arquivos.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  DELETE FROM volume
   WHERE volume_id = p_volume_id;
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
 FUNCTION caminho_completo_retornar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia            ProcessMind     DATA: 01/02/2012
  -- DESCRICAO: retorna o caminho completo de um determinado volume.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            15/06/2021  Troca da barra \ pela / (linux)
  ------------------------------------------------------------------------------------------
 (p_volume_id IN volume.volume_id%TYPE) RETURN VARCHAR2 IS
  v_caminho_completo VARCHAR2(500);
  v_caminho          volume.caminho%TYPE;
  v_prefixo          volume.prefixo%TYPE;
  v_numero           volume.numero%TYPE;
 BEGIN
  v_caminho_completo := NULL;
  --
  SELECT caminho,
         prefixo,
         numero
    INTO v_caminho,
         v_prefixo,
         v_numero
    FROM volume
   WHERE volume_id = p_volume_id;
  --
  v_caminho_completo := v_caminho || '/' || v_prefixo || '/' || to_char(v_numero);
  --
  RETURN v_caminho_completo;
 EXCEPTION
  WHEN OTHERS THEN
   v_caminho_completo := 'ERRO';
   RETURN v_caminho_completo;
 END caminho_completo_retornar;
 --
--
END; -- VOLUME_PKG



/
