--------------------------------------------------------
--  DDL for Package APONTAM_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "APONTAM_PKG" IS
 --
 PROCEDURE acao_executar
 (
  p_usuario_sessao_id   IN NUMBER,
  p_empresa_id          IN empresa.empresa_id%TYPE,
  p_flag_commit         IN VARCHAR2,
  p_usuario_apontam_id  IN apontam_data.usuario_id%TYPE,
  p_data_ini            IN apontam_data.data%TYPE,
  p_data_fim            IN apontam_data.data%TYPE,
  p_cod_acao            IN ts_transicao.cod_acao%TYPE,
  p_motivo              IN apontam_data_ev.motivo%TYPE,
  p_flag_verifica_horas IN VARCHAR2,
  p_erro_cod            OUT VARCHAR2,
  p_erro_msg            OUT VARCHAR2
 );
 --
 PROCEDURE data_criar
 (
  p_usuario_id   IN usuario.usuario_id%TYPE,
  p_tipo_chamada IN VARCHAR2,
  p_erro_cod     OUT VARCHAR2,
  p_erro_msg     OUT VARCHAR2
 );
 --
 PROCEDURE data_geral_criar;
 --
 PROCEDURE data_pendente_processar;
 --
 PROCEDURE periodo_ence_criar;
 --
 PROCEDURE periodo_criar
 (
  p_usuario_id IN usuario.usuario_id%TYPE,
  p_data_ini   IN VARCHAR2,
  p_data_fim   IN VARCHAR2,
  p_erro_cod   OUT VARCHAR2,
  p_erro_msg   OUT VARCHAR2
 );
 --
 PROCEDURE periodo_excluir
 (
  p_usuario_sessao_id IN usuario.usuario_id%TYPE,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_usuario_id        IN usuario.usuario_id%TYPE,
  p_tipo_exclusao     IN VARCHAR2,
  p_data_ini          IN VARCHAR2,
  p_data_fim          IN VARCHAR2,
  p_obs               IN apontam_hora.obs%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE periodo_aprovar
 (
  p_usuario_sessao_id IN usuario.usuario_id%TYPE,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_usuario_id        IN usuario.usuario_id%TYPE,
  p_data_ini          IN VARCHAR2,
  p_data_fim          IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE encerrar
 (
  p_usuario_sessao_id IN usuario.usuario_id%TYPE,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_mes_ano           IN VARCHAR2,
  p_flag_forca_encer  IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE reabrir
 (
  p_usuario_sessao_id IN usuario.usuario_id%TYPE,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_mes_ano           IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE horas_apontar
 (
  p_usuario_sessao_id     IN usuario.usuario_id%TYPE,
  p_empresa_id            IN empresa.empresa_id%TYPE,
  p_apontam_data_id       IN apontam_data.apontam_data_id%TYPE,
  p_flag_home_office      IN VARCHAR2,
  p_vetor_tipo_apontam_id IN VARCHAR2,
  p_vetor_objeto_id       IN VARCHAR2,
  p_vetor_horas           IN VARCHAR2,
  p_vetor_obs             IN VARCHAR2,
  p_erro_cod              OUT VARCHAR2,
  p_erro_msg              OUT VARCHAR2
 );
 --
 PROCEDURE horas_semanal_apontar
 (
  p_usuario_sessao_id      IN usuario.usuario_id%TYPE,
  p_empresa_id             IN empresa.empresa_id%TYPE,
  p_vetor_data             IN VARCHAR2,
  p_vetor_flag_home_office IN VARCHAR2,
  p_vetor_tipo_apontam_id  IN VARCHAR2,
  p_vetor_objeto_id        IN VARCHAR2,
  p_vetor_horas            IN VARCHAR2,
  p_vetor_obs              IN VARCHAR2,
  p_erro_cod               OUT VARCHAR2,
  p_erro_msg               OUT VARCHAR2
 );
 --
 PROCEDURE horas_job_apontar
 (
  p_usuario_sessao_id         IN usuario.usuario_id%TYPE,
  p_empresa_id                IN empresa.empresa_id%TYPE,
  p_job_id                    IN job.job_id%TYPE,
  p_data                      IN VARCHAR2,
  p_vetor_tipo_apontam_job_id IN VARCHAR2,
  p_vetor_horas               IN VARCHAR2,
  p_obs                       IN VARCHAR2,
  p_erro_cod                  OUT VARCHAR2,
  p_erro_msg                  OUT VARCHAR2
 );
 --
 PROCEDURE horas_oport_apontar
 (
  p_usuario_sessao_id IN usuario.usuario_id%TYPE,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_oportunidade_id   IN oportunidade.oportunidade_id%TYPE,
  p_data              IN VARCHAR2,
  p_vetor_servico_id  IN VARCHAR2,
  p_vetor_horas       IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE horas_os_apontar
 (
  p_usuario_sessao_id IN usuario.usuario_id%TYPE,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_flag_commit       IN VARCHAR2,
  p_ordem_servico_id  IN ordem_servico.ordem_servico_id%TYPE,
  p_vetor_data        IN LONG,
  p_vetor_horas       IN LONG,
  p_vetor_obs         IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE horas_tarefa_apontar
 (
  p_usuario_sessao_id IN usuario.usuario_id%TYPE,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_tarefa_id         IN tarefa.tarefa_id%TYPE,
  p_vetor_data        IN LONG,
  p_vetor_horas       IN LONG,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE horas_adicionar
 (
  p_usuario_sessao_id IN usuario.usuario_id%TYPE,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_usuario_id        IN usuario.usuario_id%TYPE,
  p_data              IN VARCHAR2,
  p_horas             IN VARCHAR2,
  p_job               IN VARCHAR2,
  p_tipo_apontam_id   IN apontam_hora.tipo_apontam_id%TYPE,
  p_obs               IN apontam_hora.obs%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE horas_admin_adicionar
 (
  p_usuario_sessao_id IN usuario.usuario_id%TYPE,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_usuario_id        IN usuario.usuario_id%TYPE,
  p_tipo_apontam_id   IN apontam_hora.tipo_apontam_id%TYPE,
  p_data_ini          IN VARCHAR2,
  p_data_fim          IN VARCHAR2,
  p_obs               IN apontam_hora.obs%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE objeto_mostrar
 (
  p_usuario_sessao_id IN usuario.usuario_id%TYPE,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_tipo_objeto       IN hist_ender.tipo_objeto%TYPE,
  p_objeto_id         IN hist_ender.objeto_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE objeto_ocultar
 (
  p_usuario_sessao_id IN usuario.usuario_id%TYPE,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_tipo_objeto       IN hist_ender.tipo_objeto%TYPE,
  p_objeto_id         IN hist_ender.objeto_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE objeto_reexibir
 (
  p_usuario_sessao_id   IN usuario.usuario_id%TYPE,
  p_empresa_id          IN empresa.empresa_id%TYPE,
  p_vetor_hist_ender_id IN VARCHAR2,
  p_erro_cod            OUT VARCHAR2,
  p_erro_msg            OUT VARCHAR2
 );
 --
 PROCEDURE excluir
 (
  p_usuario_sessao_id IN usuario.usuario_id%TYPE,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_apontam_data_id   IN apontam_data.apontam_data_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE horas_pend_excluir
 (
  p_usuario_sessao_id IN usuario.usuario_id%TYPE,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_usuario_id        IN usuario.usuario_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE apontamento_horas_ajustar
 (
  p_apontam_data_id IN apontam_data.apontam_data_id%TYPE,
  p_erro_cod        OUT VARCHAR2,
  p_erro_msg        OUT VARCHAR2
 );
 --
 PROCEDURE apontamento_custo_atualizar
 (
  p_usuario_id IN usuario.usuario_id%TYPE,
  p_empresa_id IN empresa.empresa_id%TYPE,
  p_data       IN DATE,
  p_erro_cod   OUT VARCHAR2,
  p_erro_msg   OUT VARCHAR2
 );
 --
 PROCEDURE apontamento_cargo_atualizar
 (
  p_usuario_id IN usuario.usuario_id%TYPE,
  p_empresa_id IN empresa.empresa_id%TYPE,
  p_data       IN DATE,
  p_erro_cod   OUT VARCHAR2,
  p_erro_msg   OUT VARCHAR2
 );
 --
 PROCEDURE horas_job_acao_executar
 (
  p_usuario_sessao_id     IN usuario.usuario_id%TYPE,
  p_empresa_id            IN empresa.empresa_id%TYPE,
  p_vetor_apontam_hora_id IN LONG,
  p_cod_acao              IN VARCHAR2,
  p_coment_acao           IN VARCHAR2,
  p_erro_cod              OUT VARCHAR2,
  p_erro_msg              OUT VARCHAR2
 );
 --
 --
 PROCEDURE marcar_home_office
 (
  p_usuario_sessao_id IN usuario.usuario_id%TYPE,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_data_ini          IN VARCHAR2,
  p_flag_home_office  IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 --
 FUNCTION em_dia_verificar
 (
  p_usuario_id       IN usuario.usuario_id%TYPE,
  p_tipo_verificacao IN VARCHAR2
 ) RETURN INTEGER;
 --
 --
 FUNCTION apontam_ence_verificar
 (
  p_empresa_id       IN empresa.empresa_id%TYPE,
  p_mes_ano          IN apontam_ence.mes_ano%TYPE,
  p_tipo_verificacao IN VARCHAR2
 ) RETURN INTEGER;
 --
 --
 FUNCTION num_dias_status_retornar
 (
  p_usuario_id IN usuario.usuario_id%TYPE,
  p_status     IN apontam_data.status%TYPE
 ) RETURN INTEGER;
 --
 --
 FUNCTION completo_verificar
 (
  p_usuario_id IN apontam_data.usuario_id%TYPE,
  p_empresa_id IN empresa.empresa_id%TYPE,
  p_data_ini   IN apontam_data.data%TYPE,
  p_data_fim   IN apontam_data.data%TYPE
 ) RETURN INTEGER;
 --
 --
 FUNCTION horas_apontadas_retornar
 (
  p_apontam_data_id IN apontam_data.apontam_data_id%TYPE,
  p_tipo_apontam    IN VARCHAR2
 ) RETURN NUMBER;
 --
 --
 FUNCTION horas_apontadas_retornar
 (
  p_usuario_id   IN apontam_data.usuario_id%TYPE,
  p_data         IN apontam_data.data%TYPE,
  p_tipo_apontam IN VARCHAR2,
  p_objeto_id    IN NUMBER
 ) RETURN NUMBER;
 --
 --
 FUNCTION obs_retornar
 (
  p_usuario_id   IN apontam_data.usuario_id%TYPE,
  p_data         IN apontam_data.data%TYPE,
  p_tipo_apontam IN VARCHAR2,
  p_objeto_id    IN NUMBER
 ) RETURN VARCHAR2;
 --
 --
 FUNCTION data_ult_apontam_retornar(p_usuario_id IN usuario.usuario_id%TYPE) RETURN DATE;
 --
 --
 FUNCTION status_periodo_retornar
 (
  p_usuario_id IN apontam_data.usuario_id%TYPE,
  p_data_ini   IN apontam_data.data%TYPE,
  p_data_fim   IN apontam_data.data%TYPE
 ) RETURN VARCHAR2;
 --
 --
 FUNCTION custo_job_mes_retornar
 (
  p_usuario_id IN usuario.usuario_id%TYPE,
  p_job_id     IN job.job_id%TYPE,
  p_mes_ano    IN VARCHAR2
 ) RETURN NUMBER;
 --
 --
 FUNCTION custo_horario_retornar
 (
  p_usuario_id IN usuario.usuario_id%TYPE,
  p_tipo       IN VARCHAR2,
  p_mes_ano    IN VARCHAR2
 ) RETURN NUMBER;
 --
 --
 FUNCTION flag_mostrar_retornar
 (
  p_usuario_id  IN hist_ender.usuario_id%TYPE,
  p_tipo_objeto IN hist_ender.tipo_objeto%TYPE,
  p_objeto_id   IN hist_ender.objeto_id%TYPE
 ) RETURN VARCHAR2;
 --
--
END; -- APONTAM_PKG

/
