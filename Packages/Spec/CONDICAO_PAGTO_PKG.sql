--------------------------------------------------------
--  DDL for Package CONDICAO_PAGTO_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "CONDICAO_PAGTO_PKG" IS
 --
 PROCEDURE adicionar
 (
  p_usuario_id       IN usuario.usuario_id%TYPE,
  p_empresa_id       IN empresa.empresa_id%TYPE,
  p_nome             IN condicao_pagto.nome%TYPE,
  p_descricao        IN condicao_pagto.descricao%TYPE,
  p_codigo           IN condicao_pagto.codigo%TYPE,
  p_cod_ext_condicao IN condicao_pagto.cod_ext_condicao%TYPE,
  p_tipo_regra       IN condicao_pagto.tipo_regra%TYPE,
  p_vetor_dia_semana IN VARCHAR2,
  p_semana_mes       IN VARCHAR2,
  p_dia_util_mes     IN VARCHAR2,
  p_flag_pag_for     IN VARCHAR2,
  p_flag_fat_cli     IN VARCHAR2,
  p_flag_ativo       IN VARCHAR2,
  p_vetor_valor_perc IN VARCHAR2,
  p_vetor_num_dias   IN VARCHAR2,
  p_ordem            IN VARCHAR2,
  p_erro_cod         OUT VARCHAR2,
  p_erro_msg         OUT VARCHAR2
 );
 --
 PROCEDURE atualizar
 (
  p_usuario_id        IN usuario.usuario_id%TYPE,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_condicao_pagto_id IN condicao_pagto.condicao_pagto_id%TYPE,
  p_nome              IN condicao_pagto.nome%TYPE,
  p_descricao         IN condicao_pagto.descricao%TYPE,
  p_codigo            IN condicao_pagto.codigo%TYPE,
  p_cod_ext_condicao  IN condicao_pagto.cod_ext_condicao%TYPE,
  p_tipo_regra        IN condicao_pagto.tipo_regra%TYPE,
  p_vetor_dia_semana  IN VARCHAR2,
  p_semana_mes        IN VARCHAR2,
  p_dia_util_mes      IN VARCHAR2,
  p_flag_pag_for      IN VARCHAR2,
  p_flag_fat_cli      IN VARCHAR2,
  p_flag_ativo        IN VARCHAR2,
  p_vetor_valor_perc  IN VARCHAR2,
  p_vetor_num_dias    IN VARCHAR2,
  p_ordem             IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE excluir
 (
  p_usuario_id        IN usuario.usuario_id%TYPE,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_condicao_pagto_id IN condicao_pagto.condicao_pagto_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 FUNCTION data_retornar
 (
  p_usuario_id        IN usuario.usuario_id%TYPE,
  p_condicao_pagto_id IN condicao_pagto.condicao_pagto_id%TYPE,
  p_data              IN DATE
 ) RETURN DATE;
 --
END; -- CONDICAO_PAGTO_PKG

/
