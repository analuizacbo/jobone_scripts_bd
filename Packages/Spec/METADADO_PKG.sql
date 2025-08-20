--------------------------------------------------------
--  DDL for Package METADADO_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "METADADO_PKG" IS
 --
    PROCEDURE adicionar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_tipo_objeto       IN metadado.tipo_objeto%TYPE,
        p_objeto_id         IN metadado.objeto_id%TYPE,
        p_grupo             IN metadado.grupo%TYPE,
        p_nome              IN metadado.nome%TYPE,
        p_tipo_dado_id      IN metadado.tipo_dado_id%TYPE,
        p_privilegio_id     IN metadado.privilegio_id%TYPE,
        p_tamanho           IN VARCHAR2,
        p_flag_obrigatorio  IN VARCHAR2,
        p_flag_ao_lado      IN VARCHAR2,
        p_flag_na_lista     IN VARCHAR2,
        p_flag_ordenar      IN VARCHAR2,
        p_sufixo            IN VARCHAR2,
        p_instrucoes        IN VARCHAR2,
        p_valores           IN VARCHAR2,
        p_ordem             IN VARCHAR2,
        p_metadado_cond_id  IN metadado.metadado_cond_id%TYPE,
        p_valor_cond        IN VARCHAR2,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE atualizar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_metadado_id       IN metadado.metadado_id%TYPE,
        p_nome              IN metadado.nome%TYPE,
        p_tipo_dado_id      IN metadado.tipo_dado_id%TYPE,
        p_privilegio_id     IN metadado.privilegio_id%TYPE,
        p_tamanho           IN VARCHAR2,
        p_flag_obrigatorio  IN VARCHAR2,
        p_flag_ao_lado      IN VARCHAR2,
        p_flag_na_lista     IN VARCHAR2,
        p_flag_ordenar      IN VARCHAR2,
        p_sufixo            IN VARCHAR2,
        p_instrucoes        IN VARCHAR2,
        p_valores           IN VARCHAR2,
        p_ordem             IN VARCHAR2,
        p_metadado_cond_id  IN metadado.metadado_cond_id%TYPE,
        p_valor_cond        IN VARCHAR2,
        p_flag_ativo        IN VARCHAR2,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE excluir (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_metadado_id       IN metadado.metadado_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE xml_gerar (
        p_metadado_id IN metadado.metadado_id%TYPE,
        p_xml         OUT CLOB,
        p_erro_cod    OUT VARCHAR2,
        p_erro_msg    OUT VARCHAR2
    );
 --
END; -- METADADO_PKG



/
