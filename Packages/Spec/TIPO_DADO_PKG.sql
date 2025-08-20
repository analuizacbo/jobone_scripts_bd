--------------------------------------------------------
--  DDL for Package TIPO_DADO_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "TIPO_DADO_PKG" IS
 --
    PROCEDURE validar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_codigo            IN VARCHAR2,
        p_flag_obrigatorio  IN VARCHAR2,
        p_flag_ignora_obrig IN VARCHAR2,
        p_tamanho           IN NUMBER,
        p_valor             IN VARCHAR2,
        p_valor_saida       OUT VARCHAR2,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
END tipo_dado_pkg;


/
