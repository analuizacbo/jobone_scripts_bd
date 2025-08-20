--------------------------------------------------------
--  DDL for Package FAIXA_APROV_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "FAIXA_APROV_PKG" IS
 --
    PROCEDURE ao_adicionar (
        p_usuario_sessao_id  IN NUMBER,
        p_empresa_id         IN empresa.empresa_id%TYPE,
        p_faixa_aprov_ori_id IN faixa_aprov.faixa_aprov_id%TYPE,
        p_valor_de           IN VARCHAR2,
        p_valor_ate          IN VARCHAR2,
        p_cliente_id         IN faixa_aprov_ao.cliente_id%TYPE,
        p_flag_itens_a       IN VARCHAR2,
        p_flag_itens_bc      IN VARCHAR2,
        p_fornec_homolog     IN VARCHAR2,
        p_fornec_interno     IN VARCHAR2,
        p_resultado_de       IN VARCHAR2,
        p_resultado_ate      IN VARCHAR2,
        p_faixa_aprov_id     OUT faixa_aprov.faixa_aprov_id%TYPE,
        p_erro_cod           OUT VARCHAR2,
        p_erro_msg           OUT VARCHAR2
    );
 --
    PROCEDURE ao_atualizar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_faixa_aprov_id    IN faixa_aprov.faixa_aprov_id%TYPE,
        p_valor_de          IN VARCHAR2,
        p_valor_ate         IN VARCHAR2,
        p_cliente_id        IN faixa_aprov_ao.cliente_id%TYPE,
        p_flag_itens_a      IN VARCHAR2,
        p_flag_itens_bc     IN VARCHAR2,
        p_fornec_homolog    IN VARCHAR2,
        p_fornec_interno    IN VARCHAR2,
        p_resultado_de      IN VARCHAR2,
        p_resultado_ate     IN VARCHAR2,
        p_flag_ativo        IN VARCHAR2,
        p_comentario        IN VARCHAR2,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE os_adicionar (
        p_usuario_sessao_id  IN NUMBER,
        p_empresa_id         IN empresa.empresa_id%TYPE,
        p_faixa_aprov_ori_id IN faixa_aprov.faixa_aprov_id%TYPE,
        p_cliente_id         IN faixa_aprov_os.cliente_id%TYPE,
        p_tipo_job_id        IN faixa_aprov_os.tipo_job_id%TYPE,
        p_complex_job        IN VARCHAR2,
        p_flag_aprov_est     IN VARCHAR2,
        p_flag_aprov_exe     IN VARCHAR2,
        p_faixa_aprov_id     OUT faixa_aprov.faixa_aprov_id%TYPE,
        p_erro_cod           OUT VARCHAR2,
        p_erro_msg           OUT VARCHAR2
    );
 --
    PROCEDURE os_atualizar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_faixa_aprov_id    IN faixa_aprov.faixa_aprov_id%TYPE,
        p_cliente_id        IN faixa_aprov_os.cliente_id%TYPE,
        p_tipo_job_id       IN faixa_aprov_os.tipo_job_id%TYPE,
        p_complex_job       IN VARCHAR2,
        p_flag_aprov_est    IN VARCHAR2,
        p_flag_aprov_exe    IN VARCHAR2,
        p_flag_ativo        IN VARCHAR2,
        p_comentario        IN VARCHAR2,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE flag_ativo_atualizar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_faixa_aprov_id    IN faixa_aprov.faixa_aprov_id%TYPE,
        p_flag_ativo        IN VARCHAR2,
        p_comentario        IN VARCHAR2,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE ec_adicionar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_faixa_aprov_id    OUT faixa_aprov.faixa_aprov_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE excluir (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_faixa_aprov_id    IN faixa_aprov.faixa_aprov_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE papel_adicionar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_faixa_aprov_id    IN faixa_aprov.faixa_aprov_id%TYPE,
        p_papel_id          IN papel.papel_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE papel_excluir (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_flag_commit       IN VARCHAR2,
        p_faixa_aprov_id    IN faixa_aprov.faixa_aprov_id%TYPE,
        p_papel_id          IN papel.papel_id%TYPE,
        p_seq_aprov         IN faixa_aprov_papel.seq_aprov%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE papel_geral_excluir (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_tipo_faixa        IN faixa_aprov.tipo_faixa%TYPE,
        p_papel_id          IN papel.papel_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE seq_aprov_atualizar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_faixa_aprov_id    IN faixa_aprov.faixa_aprov_id%TYPE,
        p_flag_sequencial   IN faixa_aprov.flag_sequencial%TYPE,
        p_vetor_papel_id    IN VARCHAR2,
        p_vetor_seq_aprov   IN VARCHAR2,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE xml_gerar (
        p_faixa_aprov_id IN faixa_aprov.faixa_aprov_id%TYPE,
        p_xml            OUT CLOB,
        p_erro_cod       OUT VARCHAR2,
        p_erro_msg       OUT VARCHAR2
    );
 --
END faixa_aprov_pkg;


/
