--------------------------------------------------------
--  DDL for Package MOD_CRONO_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "MOD_CRONO_PKG" IS
 --
    PROCEDURE adicionar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_nome              IN mod_crono.nome%TYPE,
        p_tipo_data_base    IN mod_crono.tipo_data_base%TYPE,
        p_mod_crono_id      OUT mod_crono.mod_crono_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE atualizar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_mod_crono_id      IN mod_crono.mod_crono_id%TYPE,
        p_nome              IN mod_crono.nome%TYPE,
        p_tipo_data_base    IN mod_crono.tipo_data_base%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE copiar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_mod_crono_id      IN mod_crono.mod_crono_id%TYPE,
        p_mod_crono_new_id  OUT mod_crono.mod_crono_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE excluir (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_mod_crono_id      IN mod_crono.mod_crono_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE item_adicionar (
        p_usuario_sessao_id     IN NUMBER,
        p_empresa_id            IN empresa.empresa_id%TYPE,
        p_mod_crono_id          IN mod_item_crono.mod_crono_id%TYPE,
        p_mod_item_crono_pai_id IN mod_item_crono.mod_item_crono_pai_id%TYPE,
        p_nome_item             IN mod_item_crono.nome%TYPE,
        p_dia_inicio            IN VARCHAR2,
        p_demanda               IN VARCHAR2,
        p_duracao               IN VARCHAR2,
        p_mod_item_crono_pre_id IN mod_item_crono_pre.mod_item_crono_pre_id%TYPE,
        p_cod_objeto            IN mod_item_crono.cod_objeto%TYPE,
        p_tipo_objeto_id        IN mod_item_crono.tipo_objeto_id%TYPE,
        p_sub_tipo_objeto       IN mod_item_crono.sub_tipo_objeto%TYPE,
        p_papel_resp_id         IN mod_item_crono.papel_resp_id%TYPE,
        p_vetor_papel_dest_id   IN VARCHAR2,
        p_flag_enviar           IN VARCHAR2,
        p_repet_a_cada          IN VARCHAR2,
        p_frequencia_id         IN mod_item_crono.frequencia_id%TYPE,
        p_vetor_dia_semana_id   IN VARCHAR2,
        p_repet_term_tipo       IN VARCHAR2,
        p_repet_term_ocor       IN VARCHAR2,
        p_mod_item_crono_id     OUT mod_item_crono.mod_item_crono_id%TYPE,
        p_erro_cod              OUT VARCHAR2,
        p_erro_msg              OUT VARCHAR2
    );
 --
    PROCEDURE item_atualizar (
        p_usuario_sessao_id     IN NUMBER,
        p_empresa_id            IN empresa.empresa_id%TYPE,
        p_mod_item_crono_id     IN mod_item_crono.mod_item_crono_id%TYPE,
        p_nome_item             IN mod_item_crono.nome%TYPE,
        p_dia_inicio            IN VARCHAR2,
        p_demanda               IN VARCHAR2,
        p_duracao               IN VARCHAR2,
        p_mod_item_crono_pre_id IN mod_item_crono_pre.mod_item_crono_pre_id%TYPE,
        p_cod_objeto            IN mod_item_crono.cod_objeto%TYPE,
        p_tipo_objeto_id        IN mod_item_crono.tipo_objeto_id%TYPE,
        p_sub_tipo_objeto       IN mod_item_crono.sub_tipo_objeto%TYPE,
        p_papel_resp_id         IN mod_item_crono.papel_resp_id%TYPE,
        p_vetor_papel_dest_id   IN VARCHAR2,
        p_flag_enviar           IN VARCHAR2,
        p_repet_a_cada          IN VARCHAR2,
        p_frequencia_id         IN mod_item_crono.frequencia_id%TYPE,
        p_vetor_dia_semana_id   IN VARCHAR2,
        p_repet_term_tipo       IN VARCHAR2,
        p_repet_term_ocor       IN VARCHAR2,
        p_erro_cod              OUT VARCHAR2,
        p_erro_msg              OUT VARCHAR2
    );
 --
    PROCEDURE item_excluir (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_mod_item_crono_id IN mod_item_crono.mod_item_crono_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE item_lista_atualizar (
        p_usuario_sessao_id           IN NUMBER,
        p_empresa_id                  IN empresa.empresa_id%TYPE,
        p_mod_crono_id                IN mod_item_crono.mod_crono_id%TYPE,
        p_vetor_mod_item_crono_id     IN VARCHAR2,
        p_vetor_dia_inicio            IN VARCHAR2,
        p_vetor_demanda               IN VARCHAR2,
        p_vetor_duracao               IN VARCHAR2,
        p_vetor_mod_item_crono_pre_id IN VARCHAR2,
        p_erro_cod                    OUT VARCHAR2,
        p_erro_msg                    OUT VARCHAR2
    );
 --
    PROCEDURE item_mover (
        p_usuario_sessao_id     IN NUMBER,
        p_empresa_id            IN empresa.empresa_id%TYPE,
        p_mod_item_crono_ori_id IN mod_item_crono.mod_item_crono_id%TYPE,
        p_mod_item_crono_des_id IN mod_item_crono.mod_item_crono_id%TYPE,
        p_erro_cod              OUT VARCHAR2,
        p_erro_msg              OUT VARCHAR2
    );
 --
    PROCEDURE item_deslocar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_mod_item_crono_id IN mod_item_crono.mod_item_crono_id%TYPE,
        p_direcao           IN VARCHAR2,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE seq_renumerar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_mod_crono_id      IN mod_item_crono.mod_crono_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE ordem_renumerar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_mod_crono_id      IN mod_item_crono.mod_crono_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
END; -- MOD_CRONO_PKG



/
