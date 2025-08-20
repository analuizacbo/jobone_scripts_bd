--------------------------------------------------------
--  DDL for Package CRONOGRAMA_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "CRONOGRAMA_PKG" IS
 --
 PROCEDURE adicionar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_flag_commit       IN VARCHAR2,
  p_job_id            IN cronograma.job_id%TYPE,
  p_cronograma_id     OUT cronograma.cronograma_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE adicionar_com_modelo
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_flag_commit       IN VARCHAR2,
  p_job_id            IN cronograma.job_id%TYPE,
  p_mod_crono_id      IN mod_crono.mod_crono_id%TYPE,
  p_data_base         IN VARCHAR2,
  p_cronograma_id     OUT cronograma.cronograma_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE acrescentar_com_modelo
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_cronograma_id     IN cronograma.cronograma_id%TYPE,
  p_mod_crono_id      IN mod_crono.mod_crono_id%TYPE,
  p_data_base         IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE excluir
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_cronograma_id     IN cronograma.cronograma_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE terminar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_cronograma_id     IN cronograma.cronograma_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE retomar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_cronograma_id     IN cronograma.cronograma_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE aprovar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_flag_commit       IN VARCHAR2,
  p_cronograma_id     IN cronograma.cronograma_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE reprovar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_cronograma_id     IN cronograma.cronograma_id%TYPE,
  p_motivo_reprov     IN VARCHAR2,
  p_compl_reprov      IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE revisar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_cronograma_id     IN cronograma.cronograma_id%TYPE,
  p_motivo_rev        IN VARCHAR2,
  p_compl_rev         IN VARCHAR2,
  p_cronograma_new_id OUT cronograma.cronograma_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE item_crono_adicionar
 (
  p_usuario_sessao_id   IN NUMBER,
  p_empresa_id          IN empresa.empresa_id%TYPE,
  p_flag_commit         IN VARCHAR2,
  p_cronograma_id       IN item_crono.cronograma_id%TYPE,
  p_item_crono_pai_id   IN item_crono.item_crono_pai_id%TYPE,
  p_nome                IN item_crono.nome%TYPE,
  p_data_planej_ini     IN VARCHAR2,
  p_data_planej_fim     IN VARCHAR2,
  p_cod_objeto          IN objeto_crono.cod_objeto%TYPE,
  p_tipo_objeto_id      IN mod_item_crono.tipo_objeto_id%TYPE,
  p_sub_tipo_objeto     IN mod_item_crono.sub_tipo_objeto%TYPE,
  p_papel_resp_id       IN mod_item_crono.papel_resp_id%TYPE,
  p_vetor_papel_dest_id IN VARCHAR2,
  p_flag_enviar         IN VARCHAR2,
  p_repet_a_cada        IN VARCHAR2,
  p_frequencia_id       IN mod_item_crono.frequencia_id%TYPE,
  p_vetor_dia_semana_id IN VARCHAR2,
  p_repet_term_tipo     IN VARCHAR2,
  p_repet_term_ocor     IN VARCHAR2,
  p_obs                 IN VARCHAR2,
  p_item_crono_id       OUT item_crono.item_crono_id%TYPE,
  p_erro_cod            OUT VARCHAR2,
  p_erro_msg            OUT VARCHAR2
 );
 --
 PROCEDURE item_objeto_adicionar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_cronograma_id     IN item_crono.cronograma_id%TYPE,
  p_cod_objeto        IN objeto_crono.cod_objeto%TYPE,
  p_demanda           IN VARCHAR2,
  p_item_crono_id     OUT item_crono.item_crono_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE item_crono_atualizar
 (
  p_usuario_sessao_id  IN NUMBER,
  p_empresa_id         IN empresa.empresa_id%TYPE,
  p_item_crono_id      IN item_crono.item_crono_id%TYPE,
  p_nome               IN item_crono.nome%TYPE,
  p_data_planej_ini    IN VARCHAR2,
  p_data_planej_fim    IN VARCHAR2,
  p_flag_altera_depend IN VARCHAR2,
  p_flag_altera_filhos IN VARCHAR2,
  p_obs                IN VARCHAR2,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 );
 --
 PROCEDURE item_crono_situacao_atualizar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_item_crono_id     IN item_crono.item_crono_id%TYPE,
  p_situacao          IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE item_crono_excluir
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_item_crono_id     IN item_crono.item_crono_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE item_crono_mover
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_item_crono_ori_id IN item_crono.item_crono_id%TYPE,
  p_item_crono_des_id IN item_crono.item_crono_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE item_crono_deslocar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_item_crono_id     IN item_crono.item_crono_id%TYPE,
  p_direcao           IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE item_crono_pre_adicionar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_item_crono_id     IN item_crono_pre.item_crono_id%TYPE,
  p_item_crono_pre_id IN item_crono_pre.item_crono_pre_id%TYPE,
  p_tipo              IN item_crono_pre.tipo%TYPE,
  p_lag               IN item_crono_pre.lag%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE item_crono_pre_atualizar
 (
  p_usuario_sessao_id    IN NUMBER,
  p_empresa_id           IN empresa.empresa_id%TYPE,
  p_item_crono_id        IN item_crono.item_crono_id%TYPE,
  p_vetor_item_crono_pre IN VARCHAR2,
  p_vetor_tipo           IN VARCHAR2,
  p_vetor_lag            IN VARCHAR2,
  p_erro_cod             OUT VARCHAR2,
  p_erro_msg             OUT VARCHAR2
 );
 --
 PROCEDURE item_crono_pre_excluir
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_item_crono_id     IN item_crono_pre.item_crono_id%TYPE,
  p_item_crono_pre_id IN item_crono_pre.item_crono_pre_id%TYPE,
  p_tipo              IN item_crono_pre.tipo%TYPE,
  p_lag               IN item_crono_pre.lag%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE executores_replicar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_item_crono_id     IN item_crono.item_crono_id%TYPE,
  p_origem            IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE repeticao_processar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_cronograma_id     IN item_crono.cronograma_id%TYPE,
  p_data_mes_old      IN DATE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE datas_depend_processar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_item_crono_id     IN item_crono.item_crono_id%TYPE,
  p_num_dias_uteis    IN NUMBER,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE datas_hierarq_processar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_item_crono_id     IN item_crono.item_crono_id%TYPE,
  p_num_dias_uteis    IN NUMBER,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE dias_replanejar
 (
  p_usuario_sessao_id   IN NUMBER,
  p_empresa_id          IN empresa.empresa_id%TYPE,
  p_cronograma_id       IN cronograma.cronograma_id%TYPE,
  p_tipo_calc           IN VARCHAR2,
  p_num_dias_uteis      IN VARCHAR2,
  p_vetor_item_crono_id IN VARCHAR2,
  p_erro_cod            OUT VARCHAR2,
  p_erro_msg            OUT VARCHAR2
 );
 --
 PROCEDURE datas_replanejar
 (
  p_usuario_sessao_id   IN NUMBER,
  p_empresa_id          IN empresa.empresa_id%TYPE,
  p_cronograma_id       IN cronograma.cronograma_id%TYPE,
  p_tipo_data           IN VARCHAR2,
  p_data_nova           IN VARCHAR2,
  p_item_crono_base_id  IN item_crono.item_crono_id%TYPE,
  p_vetor_item_crono_id IN VARCHAR2,
  p_erro_cod            OUT VARCHAR2,
  p_erro_msg            OUT VARCHAR2
 );
 --
 PROCEDURE seq_renumerar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_cronograma_id     IN item_crono.cronograma_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE ordem_renumerar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_cronograma_id     IN item_crono.cronograma_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE num_gantt_processar
 (
  p_cronograma_id IN item_crono.cronograma_id%TYPE,
  p_erro_cod      OUT VARCHAR2,
  p_erro_msg      OUT VARCHAR2
 );
 --
 PROCEDURE info_pre_retornar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_cod_objeto        IN objeto_crono.cod_objeto%TYPE,
  p_objeto_id         IN NUMBER,
  p_nome_ativ_pre     OUT VARCHAR2,
  p_cod_objeto_pre    OUT VARCHAR2,
  p_nome_objeto_pre   OUT VARCHAR2,
  p_status_objeto_pre OUT VARCHAR2,
  p_objeto_pre_id     OUT NUMBER,
  p_data_fim_pre      OUT VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE usuario_adicionar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_flag_commit       IN VARCHAR2,
  p_item_crono_id     IN item_crono_usu.item_crono_id%TYPE,
  p_usuario_id        IN item_crono_usu.usuario_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE usuario_horas_atualizar
 (
  p_usuario_sessao_id   IN NUMBER,
  p_empresa_id          IN empresa.empresa_id%TYPE,
  p_item_crono_id       IN item_crono_usu.item_crono_id%TYPE,
  p_vetor_usuario_id    IN VARCHAR2,
  p_vetor_horas_diarias IN VARCHAR2,
  p_erro_cod            OUT VARCHAR2,
  p_erro_msg            OUT VARCHAR2
 );
 --
 PROCEDURE usuario_excluir
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_flag_commit       IN VARCHAR2,
  p_item_crono_id     IN item_crono_usu.item_crono_id%TYPE,
  p_usuario_id        IN item_crono_usu.usuario_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE alocacao_processar;
 --
 PROCEDURE alocacao_usu_processar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_usuario_id        IN item_crono_usu.usuario_id%TYPE,
  p_data_ini          IN DATE,
  p_data_fim          IN DATE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 FUNCTION ultimo_retornar(p_job_id IN job.job_id%TYPE) RETURN INTEGER;
 --
 FUNCTION item_duracao_retornar
 (
  p_usuario_id    IN usuario.usuario_id%TYPE,
  p_item_crono_id IN item_crono.item_crono_id%TYPE
 ) RETURN INTEGER;
 --
 FUNCTION num_seq_pre_retornar(p_item_crono_id IN item_crono.item_crono_id%TYPE) RETURN VARCHAR2;
 --
 FUNCTION ativ_do_objeto_retornar
 (
  p_job_id     IN job.job_id%TYPE,
  p_cod_objeto IN item_crono.cod_objeto%TYPE,
  p_objeto_id  IN item_crono.objeto_id%TYPE,
  p_tipo_texto IN VARCHAR2
 ) RETURN VARCHAR2;
 --
END cronograma_pkg;

/
