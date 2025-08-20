--------------------------------------------------------
--  DDL for Package SOBRA_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "SOBRA_PKG" IS
 --
    PROCEDURE adicionar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_job_id            IN sobra.job_id%TYPE,
        p_carta_acordo_id   IN sobra.carta_acordo_id%TYPE,
        p_vetor_item_id     IN VARCHAR2,
        p_vetor_valor_sobra IN VARCHAR2,
        p_tipo_sobra        IN sobra.tipo_sobra%TYPE,
        p_tipo_extra        IN VARCHAR2,
        p_justificativa     IN VARCHAR2,
        p_flag_commit       IN VARCHAR2,
        p_sobra_id          OUT sobra.sobra_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE excluir (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_sobra_id          IN sobra.sobra_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE xml_gerar (
        p_sobra_id IN sobra.sobra_id%TYPE,
        p_xml      OUT CLOB,
        p_erro_cod OUT VARCHAR2,
        p_erro_msg OUT VARCHAR2
    );
 --
    FUNCTION item_id_retornar (
        p_sobra_id IN sobra.sobra_id%TYPE
    ) RETURN NUMBER;
 --
END; -- SOBRA_PKG



/
