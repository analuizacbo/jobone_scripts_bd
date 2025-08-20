--------------------------------------------------------
--  DDL for Package Body HISTORICO_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "HISTORICO_PKG" IS
 --
 --
 PROCEDURE hist_ender_registrar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 30/04/2013
  -- DESCRICAO: subrotina que registra o historico de enderecamentos.
  --            NAO FAZ COMMIT;
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            16/04/2020  Novo parametro atuacao
  ------------------------------------------------------------------------------------------
 (
  p_usuario_id  IN NUMBER,
  p_tipo_objeto IN VARCHAR2,
  p_objeto_id   IN NUMBER,
  p_atuacao     IN hist_ender.atuacao%TYPE,
  p_erro_cod    OUT VARCHAR2,
  p_erro_msg    OUT VARCHAR2
 ) IS
  v_qt        INTEGER;
  v_exception EXCEPTION;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM hist_ender
   WHERE usuario_id = p_usuario_id
     AND tipo_objeto = p_tipo_objeto
     AND objeto_id = p_objeto_id
     AND nvl(atuacao, 'ZZZ') = nvl(TRIM(p_atuacao), 'ZZZ');
  --
  IF v_qt = 0 THEN
   INSERT INTO hist_ender
    (hist_ender_id,
     usuario_id,
     tipo_objeto,
     objeto_id,
     atuacao,
     data_entrada,
     flag_mostrar)
   VALUES
    (seq_hist_ender.nextval,
     p_usuario_id,
     p_tipo_objeto,
     p_objeto_id,
     TRIM(p_atuacao),
     trunc(SYSDATE),
     'S');
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
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace,
                        1,
                        200);
 END hist_ender_registrar;
 --
--
END; -- HISTORICO_PKG



/
