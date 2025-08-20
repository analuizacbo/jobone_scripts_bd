--------------------------------------------------------
--  DDL for Package STATUS_AUX_OPORT_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "STATUS_AUX_OPORT_PKG" IS
 --
    PROCEDURE adicionar (
        p_usuario_sessao_id        IN NUMBER,
        p_empresa_id               IN empresa.empresa_id%TYPE,
        p_cod_status_pai           IN status_aux_oport.cod_status_pai%TYPE,
        p_nome                     IN status_aux_oport.nome%TYPE,
        p_ordem                    IN VARCHAR2,
        p_flag_obriga_cenario      IN VARCHAR2,
        p_flag_obriga_preco_manual IN VARCHAR2,
        p_flag_padrao              IN VARCHAR2,
        p_status_aux_oport_id      OUT status_aux_oport.status_aux_oport_id%TYPE,
        p_erro_cod                 OUT VARCHAR2,
        p_erro_msg                 OUT VARCHAR2
    );
 --
    PROCEDURE atualizar (
        p_usuario_sessao_id        IN NUMBER,
        p_empresa_id               IN empresa.empresa_id%TYPE,
        p_status_aux_oport_id      IN status_aux_oport.status_aux_oport_id%TYPE,
        p_nome                     IN status_aux_oport.nome%TYPE,
        p_ordem                    IN VARCHAR2,
        p_flag_obriga_cenario      IN VARCHAR2,
        p_flag_obriga_preco_manual IN VARCHAR2,
        p_flag_padrao              IN VARCHAR2,
        p_flag_ativo               IN VARCHAR2,
        p_erro_cod                 OUT VARCHAR2,
        p_erro_msg                 OUT VARCHAR2
    );
 --
    PROCEDURE excluir (
        p_usuario_sessao_id   IN NUMBER,
        p_empresa_id          IN empresa.empresa_id%TYPE,
        p_status_aux_oport_id IN status_aux_oport.status_aux_oport_id%TYPE,
        p_erro_cod            OUT VARCHAR2,
        p_erro_msg            OUT VARCHAR2
    );
 --
END; -- STTAUS_AUX_OPORT_PKG



/
