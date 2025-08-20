--------------------------------------------------------
--  DDL for Package SALARIO_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "SALARIO_PKG" IS
 --
    PROCEDURE adicionar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_usuario_id        IN salario.usuario_id%TYPE,
        p_data_ini          IN VARCHAR2,
        p_custo_mensal      IN VARCHAR2,
        p_venda_mensal      IN VARCHAR2,
        p_salario_id        OUT salario.salario_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE atualizar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_salario_id        IN salario.salario_id%TYPE,
        p_data_ini          IN VARCHAR2,
        p_custo_mensal      IN VARCHAR2,
        p_venda_mensal      IN VARCHAR2,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE excluir (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_salario_id        IN salario.salario_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    FUNCTION salario_id_atu_retornar (
        p_usuario_id IN NUMBER
    ) RETURN INTEGER;
 --
    FUNCTION salario_id_retornar (
        p_usuario_id IN NUMBER,
        p_data       IN DATE
    ) RETURN INTEGER;
 --
END; -- SALARIO_PKG



/
