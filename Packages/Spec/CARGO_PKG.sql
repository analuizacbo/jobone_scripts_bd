--------------------------------------------------------
--  DDL for Package CARGO_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "CARGO_PKG" IS
 --
 --
 /*
 PROCEDURE adicionar
 (
   p_usuario_sessao_id IN NUMBER,
   p_empresa_id        IN empresa.empresa_id%TYPE,
   p_area_id           IN cargo.area_id%TYPE,
   p_nome              IN cargo.nome%TYPE,
   p_ordem             IN VARCHAR2,
   p_qtd_vagas_aprov   IN VARCHAR2,
   p_flag_aloc_usu_ctr IN VARCHAR2,
   p_cargo_id          OUT cargo.cargo_id%TYPE,
   p_erro_cod          OUT VARCHAR2,
   p_erro_msg          OUT VARCHAR2
 );
 */
 --
 --
 PROCEDURE adicionar
 (
  p_usuario_sessao_id    IN NUMBER,
  p_empresa_id           IN empresa.empresa_id%TYPE,
  p_area_id              IN cargo.area_id%TYPE,
  p_nome                 IN cargo.nome%TYPE,
  p_ordem                IN VARCHAR2,
  p_qtd_vagas_aprov      IN VARCHAR2,
  p_flag_aloc_usu_ctr    IN VARCHAR2,
  p_vetor_preco_id       IN VARCHAR2,
  p_vetor_nivel          IN VARCHAR2,
  p_vetor_faixa_salarial IN VARCHAR2,
  p_vetor_beneficio      IN VARCHAR2,
  p_vetor_encargo        IN VARCHAR2,
  p_vetor_dissidio       IN VARCHAR2,
  p_vetor_overhead       IN VARCHAR2,
  p_vetor_custo_mensal   IN VARCHAR2,
  p_vetor_custo_hora     IN VARCHAR2,
  p_vetor_margem_hora    IN VARCHAR2,
  p_vetor_venda_mensal   IN VARCHAR2,
  p_cargo_id             OUT cargo.cargo_id%TYPE,
  p_erro_cod             OUT VARCHAR2,
  p_erro_msg             OUT VARCHAR2
 );
 --
 --
 PROCEDURE atualizar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_cargo_id          IN cargo.cargo_id%TYPE,
  p_area_id           IN cargo.area_id%TYPE,
  p_nome              IN cargo.nome%TYPE,
  p_ordem             IN VARCHAR2,
  p_qtd_vagas_aprov   IN VARCHAR2,
  p_flag_aloc_usu_ctr IN VARCHAR2,
  p_flag_ativo        IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 --
 PROCEDURE excluir
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_cargo_id          IN cargo.cargo_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 --
 PROCEDURE salario_adicionar
 (
  p_usuario_sessao_id    IN NUMBER,
  p_empresa_id           IN empresa.empresa_id%TYPE,
  p_cargo_id             IN cargo.cargo_id%TYPE,
  p_data_ini             IN VARCHAR2,
  p_vetor_nivel          IN VARCHAR2,
  p_vetor_custo_mensal   IN VARCHAR2,
  p_vetor_venda_mensal   IN VARCHAR2,
  p_vetor_faixa_salarial IN VARCHAR2,
  p_vetor_beneficio      IN VARCHAR2,
  p_vetor_encargo        IN VARCHAR2,
  p_vetor_dissidio       IN VARCHAR2,
  p_vetor_overhead       IN VARCHAR2,
  p_vetor_margem_hora    IN VARCHAR2,
  p_vetor_margem_mensal  IN VARCHAR2,
  p_erro_cod             OUT VARCHAR2,
  p_erro_msg             OUT VARCHAR2
 );
 --
 --
 PROCEDURE salario_atualizar
 (
  p_usuario_sessao_id  IN NUMBER,
  p_empresa_id         IN empresa.empresa_id%TYPE,
  p_cargo_id           IN cargo.cargo_id%TYPE,
  p_data_ini           IN VARCHAR2,
  p_vetor_nivel        IN VARCHAR2,
  p_vetor_custo_mensal IN VARCHAR2,
  p_vetor_venda_mensal IN VARCHAR2,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 );
 --
 --
 PROCEDURE salario_excluir
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_cargo_id          IN cargo.cargo_id%TYPE,
  p_data_ini          IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 --
 PROCEDURE xml_gerar
 (
  p_cargo_id IN cargo.cargo_id%TYPE,
  p_xml      OUT CLOB,
  p_erro_cod OUT VARCHAR2,
  p_erro_msg OUT VARCHAR2
 );
 --
 --
 FUNCTION salario_id_atu_retornar
 (
  p_cargo_id IN cargo.cargo_id%TYPE,
  p_nivel    IN salario_cargo.nivel%TYPE
 ) RETURN INTEGER;
 --
 --
 FUNCTION do_usuario_retornar
 (
  p_usuario_id IN NUMBER,
  p_data       IN DATE,
  p_empresa_id IN empresa.empresa_id%TYPE
 ) RETURN INTEGER;
 --
 --
 FUNCTION nivel_usuario_retornar
 (
  p_usuario_id IN NUMBER,
  p_data       IN DATE,
  p_empresa_id IN empresa.empresa_id%TYPE
 ) RETURN VARCHAR2;
 --
--
END; -- CARGO_PKG

/
