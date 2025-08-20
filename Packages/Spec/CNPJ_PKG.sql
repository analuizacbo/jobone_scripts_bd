--------------------------------------------------------
--  DDL for Package CNPJ_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "CNPJ_PKG" IS
    FUNCTION validar (
        p_cnpj       IN VARCHAR2,
        p_empresa_id IN empresa.empresa_id%TYPE
    ) RETURN INTEGER;

    PRAGMA restrict_references ( validar, wnds );
 --
    FUNCTION mostrar (
        p_cnpj       IN VARCHAR2,
        p_empresa_id IN empresa.empresa_id%TYPE
    ) RETURN VARCHAR2;

    PRAGMA restrict_references ( mostrar, wnds );
 --
    FUNCTION converter (
        p_cnpj       IN VARCHAR2,
        p_empresa_id IN empresa.empresa_id%TYPE
    ) RETURN VARCHAR2;

    PRAGMA restrict_references ( converter, wnds );
 --
END; -- CNPJ_PKG



/
