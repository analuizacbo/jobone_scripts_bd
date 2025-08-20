--------------------------------------------------------
--  DDL for Package TIPO_OS_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "TIPO_OS_PKG" IS
 --
 PROCEDURE adicionar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_codigo            IN tipo_os.codigo%TYPE,
  p_nome              IN tipo_os.nome%TYPE,
  p_ordem             IN VARCHAR2,
  p_cor_no_quadro     IN VARCHAR2,
  p_tipo_os_id        OUT tipo_os.tipo_os_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE atualizar
 (
  p_usuario_sessao_id         IN NUMBER,
  p_empresa_id                IN empresa.empresa_id%TYPE,
  p_tipo_os_id                IN tipo_os.tipo_os_id%TYPE,
  p_nome                      IN tipo_os.nome%TYPE,
  p_codigo                    IN tipo_os.codigo%TYPE,
  p_ordem                     IN VARCHAR2,
  p_cor_no_quadro             IN VARCHAR2,
  p_flag_ativo                IN VARCHAR2,
  p_tipo_tela_nova_os         IN VARCHAR2,
  p_flag_tem_tipo_finan       IN VARCHAR2,
  p_flag_tem_produto          IN VARCHAR2,
  p_flag_obriga_apont_exec    IN VARCHAR2,
  p_flag_depende_out          IN VARCHAR2,
  p_flag_tem_estim            IN VARCHAR2,
  p_flag_estim_horas_usu      IN VARCHAR2,
  p_flag_estim_prazo          IN VARCHAR2,
  p_flag_estim_custo          IN VARCHAR2,
  p_flag_estim_arq            IN VARCHAR2,
  p_flag_estim_obs            IN VARCHAR2,
  p_flag_exec_estim           IN VARCHAR2,
  p_flag_tem_descricao        IN VARCHAR2,
  p_flag_impr_briefing        IN VARCHAR2,
  p_flag_impr_prazo_estim     IN VARCHAR2,
  p_flag_impr_historico       IN VARCHAR2,
  p_flag_item_existente       IN VARCHAR2,
  p_flag_pode_refazer         IN VARCHAR2,
  p_flag_pode_refaz_em_novo   IN VARCHAR2,
  p_flag_pode_aval_solic      IN VARCHAR2,
  p_flag_pode_aval_exec       IN VARCHAR2,
  p_flag_tem_corpo            IN VARCHAR2,
  p_flag_tem_itens            IN VARCHAR2,
  p_flag_tem_qtd_item         IN VARCHAR2,
  p_flag_tem_desc_item        IN VARCHAR2,
  p_flag_tem_meta_item        IN VARCHAR2,
  p_flag_tem_importacao       IN VARCHAR2,
  p_num_max_itens             IN VARCHAR2,
  p_flag_solic_alt_arqref     IN VARCHAR2,
  p_flag_exec_alt_arqexe      IN VARCHAR2,
  p_tipo_termino_exec         IN VARCHAR2,
  p_modelo                    IN tipo_os.modelo%TYPE,
  p_modelo_itens              IN tipo_os.modelo_itens%TYPE,
  p_flag_tem_pontos_tam       IN VARCHAR2,
  p_flag_calc_prazo_tam       IN VARCHAR2,
  p_flag_obriga_tam           IN VARCHAR2,
  p_pontos_tam_p              IN VARCHAR2,
  p_pontos_tam_m              IN VARCHAR2,
  p_pontos_tam_g              IN VARCHAR2,
  p_flag_apont_horas_aloc     IN VARCHAR2,
  p_vetor_workflow            IN VARCHAR2,
  p_status_integracao         IN VARCHAR2,
  p_cod_ext_tipo_os           IN VARCHAR2,
  p_tam_max_arq_ref           IN VARCHAR2,
  p_qtd_max_arq_ref           IN VARCHAR2,
  p_extensoes_ref             IN VARCHAR2,
  p_tam_max_arq_exe           IN VARCHAR2,
  p_qtd_max_arq_exe           IN VARCHAR2,
  p_extensoes_exe             IN VARCHAR2,
  p_tam_max_arq_apr           IN VARCHAR2,
  p_qtd_max_arq_apr           IN VARCHAR2,
  p_extensoes_apr             IN VARCHAR2,
  p_flag_pode_anexar_arqapr   IN VARCHAR2,
  p_tam_max_arq_est           IN VARCHAR2,
  p_qtd_max_arq_est           IN VARCHAR2,
  p_extensoes_est             IN VARCHAR2,
  p_tam_max_arq_rfa           IN VARCHAR2,
  p_qtd_max_arq_rfa           IN VARCHAR2,
  p_extensoes_rfa             IN VARCHAR2,
  p_flag_pode_pular_aval      IN VARCHAR2,
  p_flag_pode_anexar_arqexe   IN VARCHAR2,
  p_flag_obriga_anexar_arqexe IN VARCHAR2,
  p_flag_aprov_refaz          IN VARCHAR2,
  p_flag_aprov_devolve        IN VARCHAR2,
  p_flag_habilita_aprov       IN VARCHAR2,
  p_flag_acei_todas           IN VARCHAR2,
  p_flag_solic_v_emaval       IN VARCHAR2,
  p_flag_faixa_aprov          IN VARCHAR2,
  p_flag_solic_pode_encam     IN VARCHAR2,
  p_flag_dist_com_ender       IN VARCHAR2,
  p_acoes_executadas          IN VARCHAR2,
  p_acoes_depois              IN VARCHAR2,
  p_num_dias_conc_os          IN VARCHAR2,
  p_erro_cod                  OUT VARCHAR2,
  p_erro_msg                  OUT VARCHAR2
 );
 --
 PROCEDURE excluir
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_tipo_os_id        IN tipo_os.tipo_os_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE privilegio_adicionar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_tipo_os_id        IN papel_priv_tos.tipo_os_id%TYPE,
  p_papel_id          IN papel_priv_tos.papel_id%TYPE,
  p_privilegio_id     IN papel_priv_tos.privilegio_id%TYPE,
  p_abrangencia       IN papel_priv_tos.abrangencia%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE privilegio_excluir
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_tipo_os_id        IN papel_priv_tos.tipo_os_id%TYPE,
  p_papel_id          IN papel_priv_tos.papel_id%TYPE,
  p_privilegio_id     IN papel_priv_tos.privilegio_id%TYPE,
  p_abrangencia       IN papel_priv_tos.abrangencia%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE xml_gerar
 (
  p_tipo_os_id IN tipo_os.tipo_os_id%TYPE,
  p_xml        OUT CLOB,
  p_erro_cod   OUT VARCHAR2,
  p_erro_msg   OUT VARCHAR2
 );
 --
 PROCEDURE duplicar
 (
  p_usuario_sessao_id   IN NUMBER,
  p_empresa_id          IN empresa.empresa_id%TYPE,
  p_codigo              IN tipo_os.codigo%TYPE,
  p_nome                IN tipo_os.nome%TYPE,
  p_tipo_os_duplicar_id IN tipo_os.tipo_os_id%TYPE,
  p_tipo_os_id          OUT tipo_os.tipo_os_id%TYPE,
  p_erro_cod            OUT VARCHAR2,
  p_erro_msg            OUT VARCHAR2
 );
 --
END; -- TIPO_OS_PKG


/
