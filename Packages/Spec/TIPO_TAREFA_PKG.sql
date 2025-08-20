--------------------------------------------------------
--  DDL for Package TIPO_TAREFA_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "TIPO_TAREFA_PKG" IS
 --
 PROCEDURE adicionar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_nome              IN tipo_tarefa.nome%TYPE,
  p_tipo_tarefa_id    OUT tipo_tarefa.tipo_tarefa_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE atualizar
 (
  p_usuario_sessao_id     IN NUMBER,
  p_empresa_id            IN empresa.empresa_id%TYPE,
  p_tipo_tarefa_id        IN tipo_tarefa.tipo_tarefa_id%TYPE,
  p_nome                  IN tipo_tarefa.nome%TYPE,
  p_flag_ativo            IN VARCHAR2,
  p_flag_tem_descricao    IN VARCHAR2,
  p_flag_tem_corpo        IN VARCHAR2,
  p_flag_tem_itens        IN VARCHAR2,
  p_flag_obriga_item      IN VARCHAR2,
  p_flag_tem_desc_item    IN VARCHAR2,
  p_flag_tem_meta_item    IN VARCHAR2,
  p_flag_auto_ender       IN VARCHAR2,
  p_flag_pode_ender_exec  IN VARCHAR2,
  p_flag_abre_arq_refer   IN VARCHAR2,
  p_flag_abre_arq_exec    IN VARCHAR2,
  p_flag_abre_afazer      IN VARCHAR2,
  p_flag_abre_repet       IN VARCHAR2,
  p_num_max_itens         IN VARCHAR2,
  p_num_max_dias_prazo    IN VARCHAR2,
  p_flag_apont_horas_aloc IN VARCHAR2,
  p_erro_cod              OUT VARCHAR2,
  p_erro_msg              OUT VARCHAR2
 );
 --
 PROCEDURE excluir
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_tipo_tarefa_id    IN tipo_tarefa.tipo_tarefa_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE padrao_definir
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_tipo_tarefa_id    IN tipo_tarefa.tipo_tarefa_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE xml_gerar
 (
  p_tipo_tarefa_id IN tipo_tarefa.tipo_tarefa_id%TYPE,
  p_xml            OUT CLOB,
  p_erro_cod       OUT VARCHAR2,
  p_erro_msg       OUT VARCHAR2
 );
 --
END; -- TIPO_TAREFA_PKG

/
