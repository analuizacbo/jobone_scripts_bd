--------------------------------------------------------
--  DDL for Package QUADRO_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "QUADRO_PKG" IS
 --
    PROCEDURE adicionar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_nome              IN VARCHAR2,
        p_quadro_id         OUT quadro.quadro_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
 --
    PROCEDURE atualizar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_quadro_id         IN quadro.quadro_id%TYPE,
        p_nome              IN VARCHAR2,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
 --
    PROCEDURE excluir (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_quadro_id         IN quadro.quadro_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
 --
    PROCEDURE equipe_adicionar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_quadro_id         IN quadro.quadro_id%TYPE,
        p_equipe_id         IN equipe.equipe_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
 --
    PROCEDURE equipe_excluir (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_quadro_id         IN quadro.quadro_id%TYPE,
        p_equipe_id         IN equipe.equipe_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
 --
    PROCEDURE coluna_adicionar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_quadro_id         IN quadro.quadro_id%TYPE,
        p_nome              IN VARCHAR2,
        p_ordem             IN VARCHAR2,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
 --
    PROCEDURE coluna_atualizar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_quadro_coluna_id  IN quadro_coluna.quadro_coluna_id%TYPE,
        p_nome              IN VARCHAR2,
        p_ordem             IN VARCHAR2,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
 --
    PROCEDURE coluna_excluir (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_quadro_coluna_id  IN quadro_coluna.quadro_coluna_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
 --
    PROCEDURE config_os_adicionar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_quadro_coluna_id  IN quadro_os_config.quadro_coluna_id%TYPE,
        p_tipo_os_id        IN quadro_os_config.tipo_os_id%TYPE,
        p_status            IN quadro_os_config.status%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
 --
    PROCEDURE config_os_excluir (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_quadro_coluna_id  IN quadro_os_config.quadro_coluna_id%TYPE,
        p_tipo_os_id        IN quadro_os_config.tipo_os_id%TYPE,
        p_status            IN quadro_os_config.status%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
 --
    PROCEDURE config_tarefa_adicionar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_quadro_coluna_id  IN quadro_tarefa_config.quadro_coluna_id%TYPE,
        p_status            IN quadro_tarefa_config.status%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
 --
    PROCEDURE config_tarefa_excluir (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_quadro_coluna_id  IN quadro_tarefa_config.quadro_coluna_id%TYPE,
        p_status            IN quadro_tarefa_config.status%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
 --
    PROCEDURE xml_gerar (
        p_quadro_id IN quadro.quadro_id%TYPE,
        p_xml       OUT CLOB,
        p_erro_cod  OUT VARCHAR2,
        p_erro_msg  OUT VARCHAR2
    );
 --
 --
    PROCEDURE duplicar (
        p_usuario_sessao_id  IN NUMBER,
        p_empresa_id         IN empresa.empresa_id%TYPE,
        p_nome               IN VARCHAR2,
        p_quadro_duplicar_id IN quadro.quadro_id%TYPE,
        p_quadro_id          OUT quadro.quadro_id%TYPE,
        p_erro_cod           OUT VARCHAR2,
        p_erro_msg           OUT VARCHAR2
    );
 --
END; -- QUADRO_PKG



/
