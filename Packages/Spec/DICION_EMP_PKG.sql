--------------------------------------------------------
--  DDL for Package DICION_EMP_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "DICION_EMP_PKG" IS
 --
    PROCEDURE adicionar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_grupo             IN VARCHAR2,
        p_codigo            IN VARCHAR2,
        p_descricao         IN VARCHAR2,
        p_ordem             IN VARCHAR2,
        p_flag_ativo        IN VARCHAR2,
        p_dicion_emp_id     OUT dicion_emp.dicion_emp_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE atualizar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_dicion_emp_id     IN dicion_emp.dicion_emp_id%TYPE,
        p_codigo            IN VARCHAR2,
        p_descricao         IN VARCHAR2,
        p_ordem             IN VARCHAR2,
        p_flag_ativo        IN VARCHAR2,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE excluir (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_dicion_emp_id     IN dicion_emp.dicion_emp_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE valor_adicionar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_dicion_emp_id     IN dicion_emp.dicion_emp_id%TYPE,
        p_descricao         IN VARCHAR2,
        p_ordem             IN VARCHAR2,
        p_flag_ativo        IN VARCHAR2,
        p_dicion_emp_val_id OUT dicion_emp_val.dicion_emp_val_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE valor_atualizar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_dicion_emp_val_id IN dicion_emp_val.dicion_emp_val_id%TYPE,
        p_descricao         IN VARCHAR2,
        p_ordem             IN VARCHAR2,
        p_flag_ativo        IN VARCHAR2,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE valor_excluir (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_dicion_emp_val_id IN dicion_emp_val.dicion_emp_val_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
--
END; -- DICION_EMP_PKG



/
