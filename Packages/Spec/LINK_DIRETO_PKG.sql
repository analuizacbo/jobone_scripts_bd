--------------------------------------------------------
--  DDL for Package LINK_DIRETO_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "LINK_DIRETO_PKG" IS
 --
    PROCEDURE adicionar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN link_direto.empresa_id%TYPE,
        p_cliente_id        IN link_direto.cliente_id%TYPE,
        p_ordem_servico_id  IN link_direto.ordem_servico_id%TYPE,
        p_tipo_link         IN VARCHAR2,
        p_interface         IN VARCHAR2,
        p_link              IN VARCHAR2,
        p_cod_hash          IN VARCHAR2,
        p_link_direto_id    OUT link_direto.link_direto_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
END; -- LINK_DIRETO_PKG



/
