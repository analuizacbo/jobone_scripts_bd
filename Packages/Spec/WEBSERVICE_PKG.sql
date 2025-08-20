--------------------------------------------------------
--  DDL for Package WEBSERVICE_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "WEBSERVICE_PKG" IS
 --
    PROCEDURE chamar (
        p_sistema_externo_id IN sistema_externo.sistema_externo_id%TYPE,
        p_empresa_id         IN empresa.empresa_id%TYPE,
        p_metodo             IN VARCHAR2,
        p_acao               IN VARCHAR2,
        p_xml_log_id         IN xml_log.xml_log_id%TYPE,
        p_retorno            OUT CLOB,
        p_erro_msg           OUT CLOB
    );
 --
--
END; -- WEBSERVICE_PKG



/
