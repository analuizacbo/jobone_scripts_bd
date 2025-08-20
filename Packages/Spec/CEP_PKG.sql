--------------------------------------------------------
--  DDL for Package CEP_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "CEP_PKG" IS
    PROCEDURE codigo_pesquisar (
        p_codigo     IN cep.codigo%TYPE,
        p_logradouro OUT cep.logradouro%TYPE,
        p_bairro     OUT cep.bairro%TYPE,
        p_localidade OUT cep.localidade%TYPE,
        p_uf         OUT cep.uf%TYPE
    );
 --
    PROCEDURE codigo_novo_pesquisar (
        p_codigo     IN VARCHAR2,
        p_logradouro OUT VARCHAR2,
        p_bairro     OUT VARCHAR2,
        p_localidade OUT VARCHAR2,
        p_uf         OUT VARCHAR2
    );
 --
 --
    FUNCTION mostrar (
        p_cep IN VARCHAR2
    ) RETURN VARCHAR2;
 --
 --
    FUNCTION converter (
        p_cep IN VARCHAR2
    ) RETURN VARCHAR2;
 --
 --
    FUNCTION validar (
        p_cep IN VARCHAR2
    ) RETURN INTEGER;
 --
 --
    FUNCTION municipio_validar (
        p_uf        IN VARCHAR2,
        p_municipio IN VARCHAR2
    ) RETURN INTEGER;
 --
 --
    FUNCTION proximidade_retornar (
        p_cep_referencia IN VARCHAR2,
        p_cep_analisado  IN VARCHAR2
    ) RETURN INTEGER;
 --
END; -- CEP_PKG



/
