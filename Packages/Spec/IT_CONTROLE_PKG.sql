--------------------------------------------------------
--  DDL for Package IT_CONTROLE_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "IT_CONTROLE_PKG" IS
 --
 PROCEDURE integrar
 (
  p_ponto_integracao IN ponto_integracao.codigo%TYPE,
  p_empresa_id       IN empresa.empresa_id%TYPE,
  p_objeto_id        IN NUMBER,
  p_parametros       IN VARCHAR2,
  p_erro_cod         OUT VARCHAR2,
  p_erro_msg         OUT VARCHAR2
 );
 --
END; -- IT_CONTROLE_PKG

/
