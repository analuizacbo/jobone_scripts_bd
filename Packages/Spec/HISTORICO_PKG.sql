--------------------------------------------------------
--  DDL for Package HISTORICO_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "HISTORICO_PKG" IS
 --
 --
    PROCEDURE hist_ender_registrar (
        p_usuario_id  IN NUMBER,
        p_tipo_objeto IN VARCHAR2,
        p_objeto_id   IN NUMBER,
        p_atuacao     IN hist_ender.atuacao%TYPE,
        p_erro_cod    OUT VARCHAR2,
        p_erro_msg    OUT VARCHAR2
    );
 --
--
END; -- HISTORICO_PKG



/
