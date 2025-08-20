--------------------------------------------------------
--  DDL for Package USUARIO_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "USUARIO_PKG" IS
 --
 FUNCTION priv_verificar
 (
  p_usuario_sessao_id IN usuario.usuario_id%TYPE,
  p_codigo            IN privilegio.codigo%TYPE,
  p_objeto_id         IN NUMBER,
  p_outros            IN VARCHAR2,
  p_empresa_id        IN NUMBER
 ) RETURN INTEGER;
 --
 FUNCTION priv_tipo_pessoa_verificar
 (
  p_usuario_sessao_id IN NUMBER,
  p_cod_priv          IN VARCHAR2,
  p_tipo_pessoa       IN VARCHAR2,
  p_empresa_id        IN NUMBER
 ) RETURN INTEGER;
 --
 FUNCTION acesso_grupo_verificar
 (
  p_usuario_sessao_id IN usuario.usuario_id%TYPE,
  p_grupo             IN VARCHAR2,
  p_empresa_id        IN NUMBER
 ) RETURN INTEGER;
 --
 PROCEDURE adicionar
 (
  p_usuario_sessao_id    IN usuario.usuario_id%TYPE,
  p_empresa_id           IN empresa.empresa_id%TYPE,
  p_pessoa_id            IN pessoa.pessoa_id%TYPE,
  p_flag_admin           IN VARCHAR2,
  p_login                IN usuario.login%TYPE,
  p_senha                IN usuario.senha%TYPE,
  p_resenha              IN usuario.senha%TYPE,
  p_flag_sem_bloq_apont  IN VARCHAR2,
  p_flag_sem_bloq_aprov  IN VARCHAR2,
  p_flag_sem_aprov_horas IN VARCHAR2,
  p_flag_permite_home    IN VARCHAR2,
  p_flag_acesso_pri      IN VARCHAR2,
  p_flag_acesso_cli      IN VARCHAR2,
  p_flag_acesso_wall     IN VARCHAR2,
  p_cod_hash_wallboard   IN VARCHAR2,
  p_painel_wallboard_id  IN NUMBER,
  p_flag_simula_cli      IN VARCHAR2,
  p_data_apontam_ini     IN VARCHAR2,
  p_data_apontam_fim     IN VARCHAR2,
  p_min_horas_apont_dia  IN VARCHAR2,
  p_categoria            IN VARCHAR2,
  p_tipo_relacao         IN VARCHAR2,
  p_cod_ext_usuario      IN usuario.cod_ext_usuario%TYPE,
  p_cod_funcionario      IN usuario.cod_funcionario%TYPE,
  p_vetor_papeis         IN VARCHAR2,
  p_vetor_empresas       IN VARCHAR2,
  p_empresa_padrao_id    IN empresa.empresa_id%TYPE,
  p_departamento_id      IN usuario.departamento_id%TYPE,
  p_tab_feriado_id       IN usuario.tab_feriado_id%TYPE,
  p_funcao               IN usuario.funcao%TYPE,
  p_area_id              IN usuario.area_id%TYPE,
  p_usuario_id           OUT usuario.usuario_id%TYPE,
  p_erro_cod             OUT VARCHAR2,
  p_erro_msg             OUT VARCHAR2
 );
 --
 PROCEDURE atualizar
 (
  p_usuario_sessao_id    IN usuario.usuario_id%TYPE,
  p_empresa_id           IN empresa.empresa_id%TYPE,
  p_usuario_id           IN usuario.usuario_id%TYPE,
  p_login                IN usuario.login%TYPE,
  p_flag_admin           IN VARCHAR2,
  p_flag_ativo           IN usuario.flag_ativo%TYPE,
  p_flag_notifica_email  IN usuario.flag_notifica_email%TYPE,
  p_flag_sem_bloq_apont  IN VARCHAR2,
  p_flag_sem_bloq_aprov  IN VARCHAR2,
  p_flag_sem_aprov_horas IN VARCHAR2,
  p_flag_permite_home    IN VARCHAR2,
  p_flag_acesso_pri      IN VARCHAR2,
  p_flag_acesso_cli      IN VARCHAR2,
  p_flag_acesso_wall     IN VARCHAR2,
  p_cod_hash_wallboard   IN VARCHAR2,
  p_painel_wallboard_id  IN NUMBER,
  p_flag_simula_cli      IN VARCHAR2,
  p_data_apontam_ini     IN VARCHAR2,
  p_data_apontam_fim     IN VARCHAR2,
  p_categoria            IN VARCHAR2,
  p_tipo_relacao         IN VARCHAR2,
  p_cod_ext_usuario      IN usuario.cod_ext_usuario%TYPE,
  p_cod_funcionario      IN usuario.cod_funcionario%TYPE,
  p_vetor_papeis         IN VARCHAR2,
  p_vetor_empresas       IN VARCHAR2,
  p_empresa_padrao_id    IN empresa.empresa_id%TYPE,
  p_departamento_id      IN usuario.departamento_id%TYPE,
  p_tab_feriado_id       IN usuario.tab_feriado_id%TYPE,
  p_funcao               IN usuario.funcao%TYPE,
  p_area_id              IN usuario.area_id%TYPE,
  p_erro_cod             OUT VARCHAR2,
  p_erro_msg             OUT VARCHAR2
 );
 --
 PROCEDURE min_horas_apont_atualizar
 (
  p_usuario_sessao_id   IN usuario.usuario_id%TYPE,
  p_empresa_id          IN empresa.empresa_id%TYPE,
  p_usuario_id          IN usuario.usuario_id%TYPE,
  p_min_horas_apont_dia IN VARCHAR2,
  p_data_refer          IN VARCHAR2,
  p_erro_cod            OUT VARCHAR2,
  p_erro_msg            OUT VARCHAR2
 );
 --
 PROCEDURE num_horas_prod_atualizar
 (
  p_usuario_sessao_id  IN usuario.usuario_id%TYPE,
  p_empresa_id         IN empresa.empresa_id%TYPE,
  p_usuario_id         IN usuario.usuario_id%TYPE,
  p_num_horas_prod_dia IN VARCHAR2,
  p_data_refer         IN VARCHAR2,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 );
 --
 PROCEDURE excluir
 (
  p_usuario_sessao_id IN usuario.usuario_id%TYPE,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_usuario_id        IN usuario.usuario_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE cargo_adicionar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_usuario_id        IN usuario.usuario_id%TYPE,
  p_cargo_id          IN cargo.cargo_id%TYPE,
  p_data_ini          IN VARCHAR2,
  p_nivel             IN VARCHAR2,
  p_usuario_cargo_id  OUT usuario_cargo.usuario_cargo_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE cargo_atualizar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_usuario_cargo_id  IN usuario_cargo.usuario_cargo_id%TYPE,
  p_cargo_id          IN usuario_cargo.cargo_id%TYPE,
  p_data_ini          IN VARCHAR2,
  p_nivel             IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE cargo_excluir
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_usuario_cargo_id  IN usuario_cargo.usuario_cargo_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE autenticar
 (
  p_tipo_acesso        IN VARCHAR2,
  p_login              IN usuario.login%TYPE,
  p_senha              IN usuario.senha%TYPE,
  p_cod_hash_wallboard IN VARCHAR2,
  p_usuario_id         OUT usuario.usuario_id%TYPE,
  p_apelido            OUT pessoa.apelido%TYPE,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 );
 --
 PROCEDURE login_registrar
 (
  p_tipo_acesso IN VARCHAR2,
  p_usuario_id  IN usuario.usuario_id%TYPE,
  p_erro_cod    OUT VARCHAR2,
  p_erro_msg    OUT VARCHAR2
 );
 --
 PROCEDURE senha_atualizar
 (
  p_usuario_sessao_id IN usuario.usuario_id%TYPE,
  p_senha_old         IN VARCHAR2,
  p_senha_new         IN usuario.senha%TYPE,
  p_senha_new_conf    IN usuario.senha%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE senha_configurar
 (
  p_usuario_sessao_id IN usuario.usuario_id%TYPE,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_usuario_id        IN usuario.usuario_id%TYPE,
  p_senha_new         IN usuario.senha%TYPE,
  p_senha_new_conf    IN usuario.senha%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE senha_redefinir
 (
  p_email_login IN VARCHAR2,
  p_cod_hash    OUT usuario.cod_hash%TYPE,
  p_erro_cod    OUT VARCHAR2,
  p_erro_msg    OUT VARCHAR2
 );
 --
 PROCEDURE senha_validar
 (
  p_empresa_id       IN empresa.empresa_id%TYPE,
  p_nome_completo    IN pessoa.nome%TYPE,
  p_apelido_completo IN pessoa.apelido%TYPE,
  p_login            IN usuario.login%TYPE,
  p_senha            IN VARCHAR2,
  p_erro_cod         OUT VARCHAR2,
  p_erro_msg         OUT VARCHAR2
 );
 --
 PROCEDURE desbloquear
 (
  p_usuario_sessao_id IN usuario.usuario_id%TYPE,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_usuario_id        IN usuario.usuario_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE email_bloquear
 (
  p_usuario_sessao_id IN usuario.usuario_id%TYPE,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_usuario_id        IN usuario.usuario_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE email_desbloquear
 (
  p_usuario_sessao_id IN usuario.usuario_id%TYPE,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_usuario_id        IN usuario.usuario_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE inativar_automatico;
 --
 PROCEDURE preferencia_atualizar
 (
  p_usuario_id    IN usuario.usuario_id%TYPE,
  p_nome_pref     IN preferencia.nome%TYPE,
  p_valor_usuario IN usuario_pref.valor_usuario%TYPE,
  p_empresa_id    IN NUMBER,
  p_erro_cod      OUT VARCHAR2,
  p_erro_msg      OUT VARCHAR2
 );
 --
 PROCEDURE notifica_regra_adicionar
 (
  p_usuario_sessao_id IN usuario.usuario_id%TYPE,
  p_empresa_id        IN notifica_desliga.empresa_id%TYPE,
  p_cliente_id        IN notifica_desliga.cliente_id%TYPE,
  p_job_id            IN notifica_desliga.job_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE notifica_regra_excluir
 (
  p_usuario_sessao_id   IN usuario.usuario_id%TYPE,
  p_empresa_id          IN notifica_desliga.empresa_id%TYPE,
  p_notifica_desliga_id IN notifica_desliga.notifica_desliga_id%TYPE,
  p_erro_cod            OUT VARCHAR2,
  p_erro_msg            OUT VARCHAR2
 );
 --
 PROCEDURE enderecar_em_todos_jobs
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN job.empresa_id%TYPE,
  p_usuario_id        IN usuario.usuario_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE enderecar_nos_jobs_marcados
 (
  p_usuario_sessao_id IN usuario.usuario_id%TYPE,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_usuario_id        IN usuario.usuario_id%TYPE,
  p_vetor_job         IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE desenderecar_nos_jobs_marcados
 (
  p_usuario_sessao_id IN usuario.usuario_id%TYPE,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_usuario_id        IN usuario.usuario_id%TYPE,
  p_vetor_job         IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE substituir_nos_jobs_marcados
 (
  p_usuario_sessao_id IN usuario.usuario_id%TYPE,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_usuario_ori_id    IN usuario.usuario_id%TYPE,
  p_usuario_sub_id    IN usuario.usuario_id%TYPE,
  p_vetor_job         IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE substituir_nos_jobs
 (
  p_usuario_sessao_id IN usuario.usuario_id%TYPE,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_usuario_ori_id    IN usuario.usuario_id%TYPE,
  p_cliente_job_id    IN job.cliente_id%TYPE,
  p_usuario_sub_id    IN usuario.usuario_id%TYPE,
  p_pos_resp_int      IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE substituir_nas_ca
 (
  p_usuario_sessao_id IN usuario.usuario_id%TYPE,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_usuario_ori_id    IN usuario.usuario_id%TYPE,
  p_usuario_sub_id    IN usuario.usuario_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE substituir_nas_os
 (
  p_usuario_sessao_id IN usuario.usuario_id%TYPE,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_usuario_ori_id    IN usuario.usuario_id%TYPE,
  p_tipo_ender        IN os_usuario.tipo_ender%TYPE,
  p_tipo_os_id        IN ordem_servico.tipo_os_id%TYPE,
  p_usuario_sub_id    IN usuario.usuario_id%TYPE,
  p_cliente_id        IN job.cliente_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE substituir_nas_tarefas
 (
  p_usuario_sessao_id IN usuario.usuario_id%TYPE,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_usuario_ori_id    IN usuario.usuario_id%TYPE,
  p_usuario_sub_id    IN usuario.usuario_id%TYPE,
  p_tipo_usuario      IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE ts_grupo_adicionar
 (
  p_usuario_sessao_id IN usuario.usuario_id%TYPE,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_usuario_aprov_id  IN usuario.usuario_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE ts_grupo_excluir
 (
  p_usuario_sessao_id IN usuario.usuario_id%TYPE,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_ts_grupo_id       IN ts_grupo.ts_grupo_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE ts_aprovador_atualizar
 (
  p_usuario_sessao_id IN usuario.usuario_id%TYPE,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_ts_grupo_id       IN ts_grupo.ts_grupo_id%TYPE,
  p_vetor_usuario_id  IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE ts_equipe_atualizar
 (
  p_usuario_sessao_id IN usuario.usuario_id%TYPE,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_ts_grupo_id       IN ts_grupo.ts_grupo_id%TYPE,
  p_vetor_usuario_id  IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE ts_sem_aprov_atualizar
 (
  p_usuario_sessao_id IN usuario.usuario_id%TYPE,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_vetor_usuario_id  IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE xml_gerar
 (
  p_usuario_id IN usuario.usuario_id%TYPE,
  p_xml        OUT CLOB,
  p_erro_cod   OUT VARCHAR2,
  p_erro_msg   OUT VARCHAR2
 );
 --
 PROCEDURE xml_ts_gerar
 (
  p_ts_grupo_id IN ts_grupo.ts_grupo_id%TYPE,
  p_xml         OUT CLOB,
  p_erro_cod    OUT VARCHAR2,
  p_erro_msg    OUT VARCHAR2
 );
 --
 FUNCTION numero_enderecamentos_retornar
 (
  p_usuario_id IN usuario.usuario_id%TYPE,
  p_empresa_id IN empresa.empresa_id%TYPE
 ) RETURN INTEGER;
 --
 FUNCTION numero_os_executor_retornar
 (
  p_usuario_id IN usuario.usuario_id%TYPE,
  p_empresa_id IN empresa.empresa_id%TYPE
 ) RETURN INTEGER;
 --
 FUNCTION preferencia_retornar
 (
  p_usuario_id IN usuario.usuario_id%TYPE,
  p_nome_pref  IN preferencia.nome%TYPE,
  p_empresa_id IN NUMBER
 ) RETURN CLOB;
 --
 FUNCTION empresa_padrao_retornar(p_usuario_id IN usuario.usuario_id%TYPE) RETURN NUMBER;
 --
 FUNCTION unid_negocio_retornar
 (
  p_usuario_id IN usuario.usuario_id%TYPE,
  p_empresa_id IN empresa.empresa_id%TYPE,
  p_cliente_id IN pessoa.pessoa_id%TYPE,
  p_job_id     IN job.job_id%TYPE
 ) RETURN NUMBER;
 --
END usuario_pkg;

/
