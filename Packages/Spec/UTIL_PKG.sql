--------------------------------------------------------
--  DDL for Package UTIL_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "UTIL_PKG" IS
 --
 FUNCTION texto_encriptar
 (
  p_string IN VARCHAR2,
  p_key    IN VARCHAR2
 ) RETURN VARCHAR2;
 --
 FUNCTION texto_desencriptar
 (
  p_string IN VARCHAR2,
  p_key    IN VARCHAR2
 ) RETURN VARCHAR2;
 --
 /* PROCEDURE oracletext_sincronizar;
 */ --
 FUNCTION desc_retornar
 (
  p_tipo   IN VARCHAR2,
  p_codigo IN VARCHAR2
 ) RETURN VARCHAR2;
 --
 --
 FUNCTION prox_dia_util_retornar
 (
  p_data_base          IN DATE,
  p_flag_com_data_base IN VARCHAR2
 ) RETURN DATE;
 --
 --
 FUNCTION prox_dia_semana_retornar
 (
  p_data_base IN DATE,
  p_prox_dia  IN NUMBER
 ) RETURN DATE;
 --
 --
 FUNCTION data_calcular
 (
  p_data_base    IN DATE,
  p_tipo_calculo IN VARCHAR2,
  p_num_dias     IN INTEGER
 ) RETURN DATE;
 --
 --
 FUNCTION somar
 (
  p_vetor_numero   IN VARCHAR2,
  p_casas_decimais IN INTEGER
 ) RETURN VARCHAR2;
 --
 --
 FUNCTION keywords_preparar(p_string IN VARCHAR2) RETURN VARCHAR2;
 --
 FUNCTION acento_municipio_retirar(p_string IN VARCHAR2) RETURN VARCHAR2;
 --
 --
 FUNCTION transf_montar
 (
  p_num_sai_ini IN NUMBER,
  p_pos         IN NUMBER
 ) RETURN transf_tab
 PIPELINED;
 --
 --
 FUNCTION num_encode(p_numero IN NUMBER) RETURN NUMBER;
 --
 FUNCTION num_decode
 (
  p_numero IN NUMBER,
  p_chave  IN VARCHAR2
 ) RETURN NUMBER;
 --
 FUNCTION extenso_retornar
 (
  p_num       IN NUMBER,
  p_monetario IN VARCHAR2
 ) RETURN CHAR;
 --
 FUNCTION hexa_cor(cor IN VARCHAR2) RETURN VARCHAR2;
 --
 FUNCTION entregavel_restrito_validar
 (
  p_tipo_os_id      IN ordem_servico.ordem_servico_id%TYPE,
  p_tipo_produto_id IN tipo_prod_tipo_os.tipo_produto_id%TYPE DEFAULT NULL
 ) RETURN INTEGER;

END; -- UTIL_pkg

/
