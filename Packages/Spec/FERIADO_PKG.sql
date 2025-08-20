--------------------------------------------------------
--  DDL for Package FERIADO_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "FERIADO_PKG" IS
 --
    PROCEDURE tab_adicionar (
        p_usuario_sessao_id   IN NUMBER,
        p_empresa_id          IN empresa.empresa_id%TYPE,
        p_nome                IN tab_feriado.nome%TYPE,
        p_flag_padrao         IN VARCHAR2,
        p_tab_feriado_base_id IN tab_feriado.tab_feriado_id%TYPE,
        p_data_base           IN VARCHAR2,
        p_tab_feriado_id      OUT tab_feriado.tab_feriado_id%TYPE,
        p_erro_cod            OUT VARCHAR2,
        p_erro_msg            OUT VARCHAR2
    );
 --
    PROCEDURE tab_atualizar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_tab_feriado_id    IN tab_feriado.tab_feriado_id%TYPE,
        p_nome              IN tab_feriado.nome%TYPE,
        p_flag_padrao       IN VARCHAR2,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE tab_excluir (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_tab_feriado_id    IN tab_feriado.tab_feriado_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE adicionar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_tab_feriado_id    IN feriado.tab_feriado_id%TYPE,
        p_data              IN VARCHAR2,
        p_nome              IN feriado.nome%TYPE,
        p_tipo              IN feriado.tipo%TYPE,
        p_feriado_id        OUT feriado.feriado_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE atualizar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_feriado_id        IN feriado.feriado_id%TYPE,
        p_data              IN VARCHAR2,
        p_nome              IN feriado.nome%TYPE,
        p_tipo              IN feriado.tipo%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE replicar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_tab_feriado_id    IN tab_feriado.tab_feriado_id%TYPE,
        p_ano_origem        IN VARCHAR2,
        p_ano_destino       IN VARCHAR2,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE excluir (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_feriado_id        IN feriado.feriado_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
 --
    FUNCTION prox_dia_util_retornar (
        p_usuario_id      IN usuario.usuario_id%TYPE,
        p_data            IN DATE,
        p_dias_uteis      IN INTEGER,
        p_feriado_interno IN VARCHAR2
    ) RETURN DATE;
 --
    FUNCTION dif_horas_uteis_retornar (
        p_usuario_id           IN usuario.usuario_id%TYPE,
        p_empresa_id           IN empresa.empresa_id%TYPE,
        p_data_inicio          IN DATE,
        p_data_fim             IN DATE,
        p_flag_considera_progr IN VARCHAR2
    ) RETURN NUMBER;
 --
    FUNCTION dia_util_verificar (
        p_usuario_id      IN usuario.usuario_id%TYPE,
        p_data            IN DATE,
        p_feriado_interno IN VARCHAR2
    ) RETURN INTEGER;
 --
 --
    FUNCTION qtd_dias_uteis_retornar (
        p_usuario_id IN usuario.usuario_id%TYPE,
        p_data_ini   IN DATE,
        p_data_fim   IN DATE
    ) RETURN INTEGER;
 --
 --
    FUNCTION prazo_em_horas_retornar (
        p_usuario_id      IN usuario.usuario_id%TYPE,
        p_empresa_id      IN empresa.empresa_id%TYPE,
        p_data            IN DATE,
        p_param_num_horas IN VARCHAR2,
        p_num_horas       NUMBER
    ) RETURN DATE;
 --
 --
    PROCEDURE xml_gerar (
        p_tab_feriado_id IN tab_feriado.tab_feriado_id%TYPE,
        p_xml            OUT CLOB,
        p_erro_cod       OUT VARCHAR2,
        p_erro_msg       OUT VARCHAR2
    );
 --
--
END; -- FERIADO_PKG



/
