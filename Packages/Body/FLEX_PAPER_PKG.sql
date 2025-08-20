--------------------------------------------------------
--  DDL for Package Body FLEX_PAPER_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "FLEX_PAPER_PKG" IS
 --
 --
 PROCEDURE adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia              ProcessMind     DATA: 10/03/2015
  -- DESCRICAO: Inclusão de MARK
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_id                     IN mark.id%TYPE,
  p_ordem_servico_id       IN mark.ordem_servico_id%TYPE,
  p_arquivo_id             IN mark.arquivo_id%TYPE,
  p_status_os              IN mark.status_os%TYPE,
  p_refacao                IN mark.refacao%TYPE,
  p_document_filename      IN mark.document_filename%TYPE,
  p_document_relative_path IN mark.document_relative_path%TYPE,
  p_selection_text         IN mark.selection_text%TYPE,
  p_has_selection          IN mark.has_selection%TYPE,
  p_color                  IN mark.color%TYPE,
  p_selection_info         IN mark.selection_info%TYPE,
  p_readonly               IN mark.readonly%TYPE,
  p_type                   IN mark.type%TYPE,
  p_displayformat          IN mark.displayformat%TYPE,
  p_note                   IN mark.note%TYPE,
  p_pageindex              IN mark.pageindex%TYPE,
  p_positionx              IN mark.positionx%TYPE,
  p_positiony              IN mark.positiony%TYPE,
  p_width                  IN mark.width%TYPE,
  p_height                 IN mark.height%TYPE,
  p_collapsed              IN mark.collapsed%TYPE,
  p_points                 IN mark.points%TYPE,
  p_author                 IN mark.author%TYPE,
  p_erro_cod               OUT VARCHAR2,
  p_erro_msg               OUT VARCHAR2
 ) IS
  v_qt        INTEGER;
  v_exception EXCEPTION;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- consistencias
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM mark
   WHERE id = p_id;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Ess ID já existe na tabela MARK (' || p_id || ').';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  INSERT INTO mark
   (id,
    ordem_servico_id,
    arquivo_id,
    status_os,
    refacao,
    document_filename,
    document_relative_path,
    selection_text,
    has_selection,
    color,
    selection_info,
    readonly,
    TYPE,
    displayformat,
    note,
    pageindex,
    positionx,
    positiony,
    width,
    height,
    collapsed,
    points,
    datecreated,
    datechanged,
    author)
  VALUES
   (TRIM(p_id),
    p_ordem_servico_id,
    p_arquivo_id,
    p_status_os,
    p_refacao,
    TRIM(p_document_filename),
    TRIM(p_document_relative_path),
    p_selection_text,
    p_has_selection,
    TRIM(p_color),
    TRIM(p_selection_info),
    p_readonly,
    TRIM(p_type),
    TRIM(p_displayformat),
    p_note,
    p_pageindex,
    p_positionx,
    p_positiony,
    p_width,
    p_height,
    p_collapsed,
    p_points,
    SYSDATE,
    NULL,
    TRIM(p_author));
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
 END; -- adicionar
 --
 --
 PROCEDURE atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia              ProcessMind     DATA: 10/03/2015
  -- DESCRICAO: Atualização de MARK
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_id             IN mark.id%TYPE,
  p_status_os      IN mark.status_os%TYPE,
  p_selection_text IN mark.selection_text%TYPE,
  p_has_selection  IN mark.has_selection%TYPE,
  p_color          IN mark.color%TYPE,
  p_selection_info IN mark.selection_info%TYPE,
  p_readonly       IN mark.readonly%TYPE,
  p_note           IN mark.note%TYPE,
  p_pageindex      IN mark.pageindex%TYPE,
  p_positionx      IN mark.positionx%TYPE,
  p_positiony      IN mark.positiony%TYPE,
  p_width          IN mark.width%TYPE,
  p_height         IN mark.height%TYPE,
  p_collapsed      IN mark.collapsed%TYPE,
  p_points         IN mark.points%TYPE,
  p_erro_cod       OUT VARCHAR2,
  p_erro_msg       OUT VARCHAR2
 ) IS
  v_qt        INTEGER;
  v_exception EXCEPTION;
  --
 BEGIN
  --
  ------------------------------------------------------------
  -- consistencias
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM mark
   WHERE id = p_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Ess ID não existe na tabela MARK (' || p_id || ').';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE mark
     SET selection_text = p_selection_text,
         has_selection  = p_has_selection,
         color          = TRIM(p_color),
         selection_info = TRIM(p_selection_info),
         readonly       = p_readonly,
         note           = p_note,
         pageindex      = p_pageindex,
         positionx      = p_positionx,
         positiony      = p_positiony,
         width          = p_width,
         height         = p_height,
         collapsed      = p_collapsed,
         points         = p_points,
         datechanged    = SYSDATE,
         status_os      = p_status_os
   WHERE id = p_id;
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
  -- DESENVOLVEDOR: Silvia              ProcessMind     DATA: 10/03/2015
  -- DESCRICAO: Exclusão de MARK
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_id       IN mark.id%TYPE,
  p_author   IN mark.author%TYPE,
  p_erro_cod OUT VARCHAR2,
  p_erro_msg OUT VARCHAR2
 ) IS
  v_qt        INTEGER;
  v_exception EXCEPTION;
  v_author    mark.author%TYPE;
  --
 BEGIN
  --
  ------------------------------------------------------------
  -- consistencias
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM mark
   WHERE id = p_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse ID não existe na tabela MARK (' || p_id || ').';
   RAISE v_exception;
  END IF;
  --
  SELECT author
    INTO v_author
    FROM mark
   WHERE id = p_id;
  --
  IF v_author <> p_author THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Apenas o autor da anotação pode fazer a exclusão.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  DELETE FROM mark
   WHERE id = p_id;
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
END; -- FLEX_PAPER_PKG



/
