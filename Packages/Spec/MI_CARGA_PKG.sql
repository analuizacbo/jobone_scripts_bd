--------------------------------------------------------
--  DDL for Package MI_CARGA_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "MI_CARGA_PKG" IS
 --
    PROCEDURE arquivo_carregar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_ano               IN VARCHAR2,
        p_tipo              IN VARCHAR2,
        p_arquivo           IN VARCHAR2,
        p_mi_carga_id       OUT mi_carga.mi_carga_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE metas_ooh_limpar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_ano               IN VARCHAR2,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE metas_ooh_carregar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_mi_carga_id       IN mi_carga.mi_carga_id%TYPE,
        p_ano               IN VARCHAR2,
        p_veiculo           IN VARCHAR2,
        p_praca             IN VARCHAR2,
        p_formato           IN VARCHAR2,
        p_periodicidade     IN VARCHAR2,
        p_valor_unit_neg    IN VARCHAR2,
        p_perc_negoc        IN VARCHAR2,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE metas_ooh_calcular (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_ano               IN VARCHAR2,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE metas_radio_limpar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_ano               IN VARCHAR2,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE metas_radio_carregar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_mi_carga_id       IN mi_carga.mi_carga_id%TYPE,
        p_ano               IN VARCHAR2,
        p_veiculo           IN VARCHAR2,
        p_praca             IN VARCHAR2,
        p_formato           IN VARCHAR2,
        p_valor_unit_neg    IN VARCHAR2,
        p_daypart           IN VARCHAR2,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE metas_radio_calcular (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_ano               IN VARCHAR2,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE metas_print_limpar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_ano               IN VARCHAR2,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE metas_print_carregar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_mi_carga_id       IN mi_carga.mi_carga_id%TYPE,
        p_ano               IN VARCHAR2,
        p_veiculo           IN VARCHAR2,
        p_praca             IN VARCHAR2,
        p_formato           IN VARCHAR2,
        p_valor_unit_neg    IN VARCHAR2,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE metas_print_calcular (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_ano               IN VARCHAR2,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE metas_digital_limpar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_ano               IN VARCHAR2,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE metas_digital_carregar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_mi_carga_id       IN mi_carga.mi_carga_id%TYPE,
        p_ano               IN VARCHAR2,
        p_veiculo           IN VARCHAR2,
        p_formato           IN VARCHAR2,
        p_negociacao        IN VARCHAR2,
        p_valor_unit_neg    IN VARCHAR2,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE metas_digital_calcular (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_ano               IN VARCHAR2,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE metas_tv_limpar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_ano               IN VARCHAR2,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE metas_tv_calcular (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_ano               IN VARCHAR2,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE metas_tv_carregar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_mi_carga_id       IN mi_carga.mi_carga_id%TYPE,
        p_ano               IN VARCHAR2,
        p_meio              IN VARCHAR2,
        p_meio_compl        IN VARCHAR2,
        p_target            IN VARCHAR2,
        p_rede              IN VARCHAR2,
        p_praca             IN VARCHAR2,
        p_daypart           IN VARCHAR2,
        p_cpp_q1            IN VARCHAR2,
        p_cpp_q2            IN VARCHAR2,
        p_cpp_q3            IN VARCHAR2,
        p_cpp_q4            IN VARCHAR2,
        p_trp_q1            IN VARCHAR2,
        p_trp_q2            IN VARCHAR2,
        p_trp_q3            IN VARCHAR2,
        p_trp_q4            IN VARCHAR2,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE pi_limpar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_periodo           IN VARCHAR2,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE pi_carregar (
        p_usuario_sessao_id  IN NUMBER,
        p_empresa_id         IN empresa.empresa_id%TYPE,
        p_mi_carga_id        IN mi_carga.mi_carga_id%TYPE,
        p_periodo            IN VARCHAR2,
        p_cod_cliente        IN VARCHAR2,
        p_cliente            IN VARCHAR2,
        p_cod_produto        IN VARCHAR2,
        p_produto            IN VARCHAR2,
        p_num_ap             IN VARCHAR2,
        p_num_pi             IN VARCHAR2,
        p_periodo_tab        IN VARCHAR2,
        p_campanha           IN VARCHAR2,
        p_tipo_pi            IN VARCHAR2,
        p_meio               IN VARCHAR2,
        p_cod_emissora       IN VARCHAR2,
        p_rede               IN VARCHAR2,
        p_uf                 IN VARCHAR2,
        p_cod_praca          IN VARCHAR2,
        p_praca              IN VARCHAR2,
        p_cod_veiculo        IN VARCHAR2,
        p_veiculo            IN VARCHAR2,
        p_cod_representante  IN VARCHAR2,
        p_representante      IN VARCHAR2,
        p_cnpj_representante IN VARCHAR2,
        p_faturavel          IN VARCHAR2,
        p_cod_programa       IN VARCHAR2,
        p_descricao          IN VARCHAR2,
        p_negociacao         IN VARCHAR2,
        p_hora_inicio        IN VARCHAR2,
        p_hora_fim           IN VARCHAR2,
        p_titulo             IN VARCHAR2,
        p_formato            IN VARCHAR2,
        p_cod_tipo_comerc    IN VARCHAR2,
        p_tipo_comercial     IN VARCHAR2,
        p_data               IN VARCHAR2,
        p_valor_unit_tab     IN VARCHAR2,
        p_perc_negoc         IN VARCHAR2,
        p_valor_unit_neg     IN VARCHAR2,
        p_aud_dom            IN VARCHAR2,
        p_target             IN VARCHAR2,
        p_aud_targ           IN VARCHAR2,
        p_tot_ins            IN VARCHAR2,
        p_qtd_impressoes     IN VARCHAR2,
        p_valor_total        IN VARCHAR2,
        p_semana_ano         IN VARCHAR2,
        p_erro_cod           OUT VARCHAR2,
        p_erro_msg           OUT VARCHAR2
    );
 --
    PROCEDURE pi_descartar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_ano               IN VARCHAR2,
        p_vetor_num_pi      IN VARCHAR2,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    FUNCTION numero_validar (
        p_numero IN VARCHAR2
    ) RETURN INTEGER;
 --
    FUNCTION numero_converter (
        p_numero IN VARCHAR2
    ) RETURN NUMBER;
 --
    FUNCTION daypart_id_retornar (
        p_empresa_id IN NUMBER,
        p_daypart    IN VARCHAR2,
        p_rede       IN VARCHAR2
    ) RETURN NUMBER;
 --
END; -- MI_CARGA_PKG



/
