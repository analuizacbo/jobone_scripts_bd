--------------------------------------------------------
--  DDL for Package PESSOA_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "PESSOA_PKG" IS
 --
 PROCEDURE adicionar
 (
  p_usuario_sessao_id      IN NUMBER,
  p_empresa_id             IN empresa.empresa_id%TYPE,
  p_apelido                IN pessoa.apelido%TYPE,
  p_nome                   IN pessoa.nome%TYPE,
  p_flag_pessoa_jur        IN VARCHAR2,
  p_flag_cpom              IN VARCHAR2,
  p_cnpj                   IN pessoa.cnpj%TYPE,
  p_inscr_estadual         IN pessoa.inscr_estadual%TYPE,
  p_inscr_municipal        IN pessoa.inscr_municipal%TYPE,
  p_inscr_inss             IN pessoa.inscr_inss%TYPE,
  p_cpf                    IN pessoa.cpf%TYPE,
  p_rg                     IN pessoa.rg%TYPE,
  p_rg_org_exp             IN pessoa.rg_org_exp%TYPE,
  p_rg_uf                  IN pessoa.rg_uf%TYPE,
  p_rg_data_exp            IN VARCHAR2,
  p_flag_sem_docum         IN VARCHAR2,
  p_endereco               IN pessoa.endereco%TYPE,
  p_num_ender              IN pessoa.num_ender%TYPE,
  p_compl_ender            IN pessoa.compl_ender%TYPE,
  p_bairro                 IN pessoa.bairro%TYPE,
  p_cep                    IN pessoa.cep%TYPE,
  p_cidade                 IN pessoa.cidade%TYPE,
  p_uf                     IN pessoa.uf%TYPE,
  p_pais                   IN pessoa.pais%TYPE,
  p_website                IN pessoa.website%TYPE,
  p_email                  IN pessoa.email%TYPE,
  p_ddd_telefone           IN pessoa.ddd_telefone%TYPE,
  p_num_telefone           IN pessoa.num_telefone%TYPE,
  p_num_ramal              IN pessoa.num_ramal%TYPE,
  p_ddd_celular            IN pessoa.ddd_celular%TYPE,
  p_num_celular            IN pessoa.num_celular%TYPE,
  p_obs                    IN pessoa.obs%TYPE,
  p_fi_banco_id            IN pessoa.fi_banco_id%TYPE,
  p_num_agencia            IN pessoa.num_agencia%TYPE,
  p_num_conta              IN pessoa.num_conta%TYPE,
  p_tipo_conta             IN pessoa.tipo_conta%TYPE,
  p_nome_titular           IN pessoa.nome_titular%TYPE,
  p_cnpj_cpf_titular       IN pessoa.cnpj_cpf_titular%TYPE,
  p_vetor_tipo_pessoa      IN VARCHAR2,
  p_vetor_natureza_item_id IN VARCHAR2,
  p_vetor_tipo_produto_id  IN VARCHAR2,
  p_vetor_valor_padrao     IN VARCHAR2,
  p_num_dias_fatur         IN VARCHAR2,
  p_tipo_num_dias_fatur    IN pessoa.tipo_num_dias_fatur%TYPE,
  p_flag_fornec_interno    IN VARCHAR2,
  p_flag_emp_resp          IN VARCHAR2,
  p_flag_emp_fatur         IN VARCHAR2,
  p_flag_pago_cliente      IN VARCHAR2,
  p_flag_cli_aprov_os      IN VARCHAR2,
  p_flag_cli_aval_os       IN VARCHAR2,
  p_cod_job                IN pessoa.cod_job%TYPE,
  p_num_primeiro_job       IN VARCHAR2,
  p_data_entrada_agencia   IN VARCHAR2,
  p_emp_resp_pdr_id        IN pessoa.emp_resp_pdr_id%TYPE,
  p_emp_fatur_pdr_id       IN pessoa.emp_fatur_pdr_id%TYPE,
  p_setor_id               IN pessoa.setor_id%TYPE,
  p_cod_ext_pessoa         IN VARCHAR2,
  p_cod_ext_resp           IN VARCHAR2,
  p_cod_ext_fatur          IN VARCHAR2,
  p_tipo_publ_priv         IN VARCHAR2,
  p_flag_obriga_email      IN VARCHAR2,
  p_flag_testa_codjob      IN VARCHAR2,
  p_chave_pix              IN VARCHAR2,
  --Documentacao
  p_regime_tributario IN VARCHAR2,
  p_tipo_num_cotacoes IN VARCHAR2,
  p_num_cotacoes      IN VARCHAR2,
  --Qualificacao
  p_nivel_qualidade IN VARCHAR2,
  p_nivel_parceria  IN VARCHAR2,
  p_nivel_relac     IN VARCHAR2,
  p_nivel_custo     IN pessoa.nivel_custo%TYPE,
  p_parcela         IN pessoa.parcela%TYPE,
  p_porte           IN pessoa.porte%TYPE,
  p_aval_ai         IN pessoa.aval_ai%TYPE,
  --homologacao
  p_status_para       IN pessoa_homolog.status_para%TYPE,
  p_perc_bv           IN pessoa_homolog.perc_bv%TYPE,
  p_tipo_fatur_bv     IN pessoa_homolog.tipo_fatur_bv%TYPE,
  p_flag_tem_bv       IN pessoa_homolog.flag_tem_bv%TYPE,
  p_perc_imposto      IN pessoa_homolog.perc_imposto%TYPE,
  p_flag_nota_cobert  IN pessoa_homolog.flag_nota_cobert%TYPE,
  p_flag_tem_cobert   IN pessoa_homolog.flag_tem_cobert%TYPE,
  p_condicao_pagto_id IN pessoa_homolog.condicao_pagto_id%TYPE,
  p_obs_fornec        IN pessoa_homolog.obs%TYPE,
  p_data_validade     IN VARCHAR2,
  p_aval_ai_fornec    IN pessoa_homolog.aval_ai%TYPE,
  p_pessoa_id         OUT pessoa.pessoa_id%TYPE,
  p_pessoa_homolog_id OUT pessoa_homolog.pessoa_homolog_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE basico_adicionar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_flag_incluir      IN VARCHAR2,
  p_apelido           IN pessoa.apelido%TYPE,
  p_nome              IN pessoa.nome%TYPE,
  p_flag_simples      IN VARCHAR2,
  p_flag_cpom         IN VARCHAR2,
  p_cnpj              IN pessoa.cnpj%TYPE,
  p_inscr_estadual    IN pessoa.inscr_estadual%TYPE,
  p_inscr_municipal   IN pessoa.inscr_municipal%TYPE,
  p_inscr_inss        IN pessoa.inscr_inss%TYPE,
  p_endereco          IN pessoa.endereco%TYPE,
  p_num_ender         IN pessoa.num_ender%TYPE,
  p_compl_ender       IN pessoa.compl_ender%TYPE,
  p_bairro            IN pessoa.bairro%TYPE,
  p_cep               IN pessoa.cep%TYPE,
  p_cidade            IN pessoa.cidade%TYPE,
  p_uf                IN pessoa.uf%TYPE,
  p_obs               IN pessoa.obs%TYPE,
  p_fi_banco_id       IN pessoa.fi_banco_id%TYPE,
  p_num_agencia       IN pessoa.num_agencia%TYPE,
  p_num_conta         IN pessoa.num_conta%TYPE,
  p_tipo_conta        IN pessoa.tipo_conta%TYPE,
  p_nome_titular      IN pessoa.nome_titular%TYPE,
  p_cnpj_cpf_titular  IN pessoa.cnpj_cpf_titular%TYPE,
  p_tipo_fatur_bv     IN VARCHAR2,
  p_pessoa_id         OUT pessoa.pessoa_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE atualizar
 (
  p_usuario_sessao_id      IN NUMBER,
  p_empresa_id             IN empresa.empresa_id%TYPE,
  p_pessoa_id              IN pessoa.pessoa_id%TYPE,
  p_apelido                IN pessoa.apelido%TYPE,
  p_nome                   IN pessoa.nome%TYPE,
  p_flag_pessoa_jur        IN VARCHAR2,
  p_flag_cpom              IN VARCHAR2,
  p_cnpj                   IN pessoa.cnpj%TYPE,
  p_inscr_estadual         IN pessoa.inscr_estadual%TYPE,
  p_inscr_municipal        IN pessoa.inscr_municipal%TYPE,
  p_inscr_inss             IN pessoa.inscr_inss%TYPE,
  p_cpf                    IN pessoa.cpf%TYPE,
  p_rg                     IN pessoa.rg%TYPE,
  p_rg_org_exp             IN pessoa.rg_org_exp%TYPE,
  p_rg_uf                  IN pessoa.rg_uf%TYPE,
  p_rg_data_exp            IN VARCHAR2,
  p_flag_sem_docum         IN VARCHAR2,
  p_endereco               IN pessoa.endereco%TYPE,
  p_num_ender              IN pessoa.num_ender%TYPE,
  p_compl_ender            IN pessoa.compl_ender%TYPE,
  p_bairro                 IN pessoa.bairro%TYPE,
  p_cep                    IN pessoa.cep%TYPE,
  p_cidade                 IN pessoa.cidade%TYPE,
  p_uf                     IN pessoa.uf%TYPE,
  p_pais                   IN pessoa.pais%TYPE,
  p_website                IN pessoa.website%TYPE,
  p_email                  IN pessoa.email%TYPE,
  p_ddd_telefone           IN pessoa.ddd_telefone%TYPE,
  p_num_telefone           IN pessoa.num_telefone%TYPE,
  p_num_ramal              IN pessoa.num_ramal%TYPE,
  p_ddd_celular            IN pessoa.ddd_celular%TYPE,
  p_num_celular            IN pessoa.num_celular%TYPE,
  p_obs                    IN pessoa.obs%TYPE,
  p_fi_banco_id            IN pessoa.fi_banco_id%TYPE,
  p_num_agencia            IN pessoa.num_agencia%TYPE,
  p_num_conta              IN pessoa.num_conta%TYPE,
  p_tipo_conta             IN pessoa.tipo_conta%TYPE,
  p_nome_titular           IN pessoa.nome_titular%TYPE,
  p_cnpj_cpf_titular       IN pessoa.cnpj_cpf_titular%TYPE,
  p_vetor_natureza_item_id IN VARCHAR2,
  p_vetor_valor_padrao     IN VARCHAR2,
  p_num_dias_fatur         IN VARCHAR2,
  p_tipo_num_dias_fatur    IN pessoa.tipo_num_dias_fatur%TYPE,
  p_flag_fornec_interno    IN VARCHAR2,
  p_flag_emp_resp          IN VARCHAR2,
  p_flag_emp_fatur         IN VARCHAR2,
  p_flag_pago_cliente      IN VARCHAR2,
  p_cod_job                IN pessoa.cod_job%TYPE,
  p_num_primeiro_job       IN VARCHAR2,
  p_data_entrada_agencia   IN VARCHAR2,
  p_emp_resp_pdr_id        IN pessoa.emp_resp_pdr_id%TYPE,
  p_emp_fatur_pdr_id       IN pessoa.emp_fatur_pdr_id%TYPE,
  p_setor_id               IN pessoa.setor_id%TYPE,
  p_cod_ext_pessoa         IN VARCHAR2,
  p_cod_ext_resp           IN VARCHAR2,
  p_cod_ext_fatur          IN VARCHAR2,
  p_tipo_publ_priv         IN VARCHAR2,
  p_flag_obriga_email      IN VARCHAR2,
  p_chave_pix              IN VARCHAR2,
  p_tipo_num_cotacoes      IN VARCHAR2,
  p_num_cotacoes           IN VARCHAR2,
  p_flag_cli_aprov_os      IN VARCHAR2,
  p_flag_cli_aval_os       IN VARCHAR2,
  p_regime_tributario      IN VARCHAR2,
  p_erro_cod               OUT VARCHAR2,
  p_erro_msg               OUT VARCHAR2
 );
 --
 PROCEDURE contato_adicionar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_pessoa_pai_id     IN pessoa.pessoa_id%TYPE,
  p_apelido           IN pessoa.apelido%TYPE,
  p_nome              IN pessoa.nome%TYPE,
  p_funcao            IN pessoa.funcao%TYPE,
  p_obs               IN pessoa.obs%TYPE,
  p_ddd_telefone      IN pessoa.ddd_telefone%TYPE,
  p_num_telefone      IN pessoa.num_telefone%TYPE,
  p_num_ramal         IN pessoa.num_ramal%TYPE,
  p_ddd_cel_part      IN pessoa.ddd_cel_part%TYPE,
  p_num_cel_part      IN pessoa.num_cel_part%TYPE,
  p_ddd_celular       IN pessoa.ddd_celular%TYPE,
  p_num_celular       IN pessoa.num_celular%TYPE,
  p_email             IN pessoa.email%TYPE,
  p_cep               IN pessoa.cep%TYPE,
  p_endereco          IN pessoa.endereco%TYPE,
  p_num_ender         IN pessoa.num_ender%TYPE,
  p_compl_ender       IN pessoa.compl_ender%TYPE,
  p_bairro            IN pessoa.bairro%TYPE,
  p_cidade            IN pessoa.cidade%TYPE,
  p_uf                IN pessoa.uf%TYPE,
  p_pais              IN pessoa.pais%TYPE,
  p_pessoa_id         OUT pessoa.pessoa_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE contato_atualizar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_pessoa_pai_id     IN relacao.pessoa_pai_id%TYPE,
  p_pessoa_id         IN pessoa.pessoa_id%TYPE,
  p_apelido           IN pessoa.apelido%TYPE,
  p_nome              IN pessoa.nome%TYPE,
  p_funcao            IN pessoa.funcao%TYPE,
  p_obs               IN pessoa.obs%TYPE,
  p_ddd_telefone      IN pessoa.ddd_telefone%TYPE,
  p_num_telefone      IN pessoa.num_telefone%TYPE,
  p_num_ramal         IN pessoa.num_ramal%TYPE,
  p_ddd_cel_part      IN pessoa.ddd_cel_part%TYPE,
  p_num_cel_part      IN pessoa.num_cel_part%TYPE,
  p_ddd_celular       IN pessoa.ddd_celular%TYPE,
  p_num_celular       IN pessoa.num_celular%TYPE,
  p_email             IN pessoa.email%TYPE,
  p_cep               IN pessoa.cep%TYPE,
  p_endereco          IN pessoa.endereco%TYPE,
  p_num_ender         IN pessoa.num_ender%TYPE,
  p_compl_ender       IN pessoa.compl_ender%TYPE,
  p_bairro            IN pessoa.bairro%TYPE,
  p_cidade            IN pessoa.cidade%TYPE,
  p_uf                IN pessoa.uf%TYPE,
  p_pais              IN pessoa.pais%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE qualificacao_fornec_atualizar
 (
  p_usuario_sessao_id  IN NUMBER,
  p_empresa_id         IN empresa.empresa_id%TYPE,
  p_pessoa_id          IN pessoa.pessoa_id%TYPE,
  p_nivel_qualidade    IN VARCHAR2,
  p_nivel_parceria     IN VARCHAR2,
  p_nivel_relac        IN VARCHAR2,
  p_nivel_custo        IN pessoa.nivel_custo%TYPE,
  p_parcela            IN pessoa.parcela%TYPE,
  p_porte              IN pessoa.porte%TYPE,
  p_aval_ai            IN pessoa.aval_ai%TYPE,
  p_vetor_tipo_produto IN VARCHAR2,
  p_comentario         IN VARCHAR2,
  p_flag_commit        IN VARCHAR2,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 );
 --
 PROCEDURE homologacao_adicionar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_pessoa_id         IN pessoa.pessoa_id%TYPE,
  p_condicao_pagto_id IN pessoa_homolog.condicao_pagto_id%TYPE,
  p_status_para       IN pessoa_homolog.status_para%TYPE,
  p_data_validade     IN VARCHAR2,
  p_perc_bv           IN VARCHAR2,
  p_tipo_fatur_bv     IN VARCHAR2,
  p_flag_tem_bv       IN VARCHAR2,
  p_perc_imposto      IN VARCHAR2,
  p_flag_nota_cobert  IN VARCHAR2,
  p_flag_tem_cobert   IN VARCHAR2,
  p_obs_homolog       IN pessoa_homolog.flag_nota_cobert%TYPE,
  p_aval_ai_homolog   IN pessoa_homolog.flag_nota_cobert%TYPE,
  p_flag_commit       IN VARCHAR2,
  p_pessoa_homolog_id OUT pessoa_homolog.pessoa_homolog_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE pessoa_ativar_inativar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_pessoa_id         IN pessoa.pessoa_id%TYPE,
  p_flag_ativo        IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE tipo_pessoa_atualizar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_pessoa_id         IN pessoa.pessoa_id%TYPE,
  p_vetor_tipo_pessoa IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE perfil_atualizar
 (
  p_usuario_sessao_id   IN NUMBER,
  p_empresa_id          IN empresa.empresa_id%TYPE,
  p_pessoa_id           IN pessoa.pessoa_id%TYPE,
  p_data_nasc           IN VARCHAR2,
  p_ddd_celular         IN pessoa.ddd_celular%TYPE,
  p_num_celular         IN pessoa.num_celular%TYPE,
  p_num_ramal           IN pessoa.num_ramal%TYPE,
  p_flag_notifica_email IN usuario.flag_notifica_email%TYPE,
  p_erro_cod            OUT VARCHAR2,
  p_erro_msg            OUT VARCHAR2
 );
 --
 PROCEDURE coordenadas_atualizar
 (
  p_pessoa_id IN pessoa.pessoa_id%TYPE,
  p_longitude IN VARCHAR2,
  p_latitude  IN VARCHAR2,
  p_erro_cod  OUT VARCHAR2,
  p_erro_msg  OUT VARCHAR2
 );
 --
 PROCEDURE excluir
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_pessoa_id         IN pessoa.pessoa_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE arquivo_adicionar
 (
  p_usuario_sessao_id    IN NUMBER,
  p_empresa_id           IN empresa.empresa_id%TYPE,
  p_pessoa_id            IN arquivo_pessoa.pessoa_id%TYPE,
  p_arquivo_id           IN arquivo.arquivo_id%TYPE,
  p_volume_id            IN arquivo.volume_id%TYPE,
  p_descricao            IN arquivo.descricao%TYPE,
  p_nome_original        IN arquivo.nome_original%TYPE,
  p_nome_fisico          IN arquivo.nome_fisico%TYPE,
  p_mime_type            IN arquivo.mime_type%TYPE,
  p_tamanho              IN arquivo.tamanho%TYPE,
  p_thumb1_arquivo_id    IN arquivo.arquivo_id%TYPE,
  p_thumb1_volume_id     IN arquivo.volume_id%TYPE,
  p_thumb1_nome_original IN arquivo.nome_original%TYPE,
  p_thumb1_nome_fisico   IN arquivo.nome_fisico%TYPE,
  p_thumb1_mime_type     IN arquivo.mime_type%TYPE,
  p_thumb1_tamanho       IN arquivo.tamanho%TYPE,
  p_thumb2_arquivo_id    IN arquivo.arquivo_id%TYPE,
  p_thumb2_volume_id     IN arquivo.volume_id%TYPE,
  p_thumb2_nome_original IN arquivo.nome_original%TYPE,
  p_thumb2_nome_fisico   IN arquivo.nome_fisico%TYPE,
  p_thumb2_mime_type     IN arquivo.mime_type%TYPE,
  p_thumb2_tamanho       IN arquivo.tamanho%TYPE,
  p_thumb3_arquivo_id    IN arquivo.arquivo_id%TYPE,
  p_thumb3_volume_id     IN arquivo.volume_id%TYPE,
  p_thumb3_nome_original IN arquivo.nome_original%TYPE,
  p_thumb3_nome_fisico   IN arquivo.nome_fisico%TYPE,
  p_thumb3_mime_type     IN arquivo.mime_type%TYPE,
  p_thumb3_tamanho       IN arquivo.tamanho%TYPE,
  p_tipo_arq_pessoa      IN arquivo_pessoa.tipo_arq_pessoa%TYPE,
  p_erro_cod             OUT VARCHAR2,
  p_erro_msg             OUT VARCHAR2
 );
 --
 PROCEDURE arquivo_excluir
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_arquivo_id        IN arquivo.arquivo_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE associar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_pessoa_pai_id     IN pessoa.pessoa_id%TYPE,
  p_pessoa_filho_id   IN pessoa.pessoa_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE desassociar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_pessoa_pai_id     IN pessoa.pessoa_id%TYPE,
  p_pessoa_filho_id   IN pessoa.pessoa_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE impostos_nfe_configurar
 (
  p_usuario_sessao_id     IN NUMBER,
  p_empresa_id            IN empresa.empresa_id%TYPE,
  p_pessoa_id             IN pessoa.pessoa_id%TYPE,
  p_valor_faixa_retencao  IN VARCHAR2,
  p_vetor_tipo_imposto_id IN VARCHAR2,
  p_vetor_aliquota        IN VARCHAR2,
  p_vetor_pessoa_iss_id   IN VARCHAR2,
  p_vetor_aliquota_iss    IN VARCHAR2,
  p_vetor_flag_reter_iss  IN VARCHAR2,
  p_erro_cod              OUT VARCHAR2,
  p_erro_msg              OUT VARCHAR2
 );
 --
 PROCEDURE iss_nfe_adicionar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_pessoa_id         IN pessoa.pessoa_id%TYPE,
  p_nome_servico      IN fi_tipo_imposto_pessoa.nome_servico%TYPE,
  p_perc_imposto      IN VARCHAR2,
  p_flag_reter        IN fi_tipo_imposto_pessoa.flag_reter%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE servico_atualizar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_pessoa_id         IN pessoa_servico.pessoa_id%TYPE,
  p_servico_id        IN pessoa_servico.servico_id%TYPE,
  p_cod_ext_servico   IN VARCHAR2,
  p_flag_ativo        IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE servico_excluir
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_pessoa_id         IN pessoa_servico.pessoa_id%TYPE,
  p_servico_id        IN pessoa_servico.servico_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE config_oper_atualizar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_pessoa_id         IN pessoa.pessoa_id%TYPE,
  p_flag_cli_aprov_os IN VARCHAR2,
  p_flag_cli_aval_os  IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE email_atualizar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_pessoa_id         IN pessoa.pessoa_id%TYPE,
  p_email             IN pessoa.email%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE fornecedor_homolog_expirar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_pessoa_id         IN pessoa_homolog.pessoa_id%TYPE,
  p_data_validade     VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE pessoa_link_adicionar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN NUMBER,
  p_pessoa_id         IN pessoa_link.pessoa_id%TYPE,
  p_descricao         IN VARCHAR2,
  p_url               IN VARCHAR2,
  p_tipo_link         IN pessoa_link.tipo_link%TYPE,
  p_pessoa_link_id    OUT pessoa_link.pessoa_link_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE pessoa_link_excluir
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_pessoa_link_id    IN pessoa_link.pessoa_link_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE xml_gerar
 (
  p_pessoa_id IN pessoa.pessoa_id%TYPE,
  p_xml       OUT CLOB,
  p_erro_cod  OUT VARCHAR2,
  p_erro_msg  OUT VARCHAR2
 );
 --
 FUNCTION perc_imposto_retornar
 (
  p_pessoa_id          IN pessoa.pessoa_id%TYPE,
  p_fi_tipo_imposto_id IN fi_tipo_imposto.fi_tipo_imposto_id%TYPE
 ) RETURN NUMBER;
 --
 FUNCTION pai_retornar
 (
  p_pessoa_id    IN pessoa.pessoa_id%TYPE,
  p_tipo_retorno IN VARCHAR2
 ) RETURN VARCHAR2;
 --
 FUNCTION tipo_verificar
 (
  p_pessoa_id   IN pessoa.pessoa_id%TYPE,
  p_tipo_pessoa IN VARCHAR2
 ) RETURN INTEGER;
 --
 FUNCTION dados_integr_verificar(p_pessoa_id IN pessoa.pessoa_id%TYPE) RETURN INTEGER;
 --
 FUNCTION saldo_do_dia_retornar
 (
  p_pessoa_id IN pessoa.pessoa_id%TYPE,
  p_data      IN DATE
 ) RETURN NUMBER;
 --
 FUNCTION cnpj_raiz_retornar
 (
  p_pessoa_id  IN pessoa.pessoa_id%TYPE,
  p_empresa_id IN empresa.empresa_id%TYPE
 ) RETURN VARCHAR2;
 --
 FUNCTION cod_sist_ext_retornar
 (
  p_pessoa_id       IN pessoa.pessoa_id%TYPE,
  p_cod_tipo_pessoa IN tipo_pessoa.codigo%TYPE,
  p_cod_sist_ext    IN sistema_externo.codigo%TYPE
 ) RETURN VARCHAR2;
 --
 FUNCTION nivel_excelencia_retornar(p_pessoa_id IN pessoa.pessoa_id%TYPE) RETURN NUMBER;
 --
 FUNCTION nivel_parceria_retornar(p_pessoa_id IN pessoa.pessoa_id%TYPE) RETURN NUMBER;
 --
 FUNCTION unid_negocio_retornar
 (
  p_cliente_id IN pessoa.pessoa_id%TYPE,
  p_job_id     IN job.job_id%TYPE,
  p_usuario_id IN usuario.usuario_id%TYPE
 )
 --
  RETURN NUMBER;

 FUNCTION chave_pix_validar(p_chave_pix IN VARCHAR2) RETURN INTEGER;
 --
 PROCEDURE cadastro_atualizar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_pessoa_id         IN pessoa.pessoa_id%TYPE,
  p_flag_cad_verif    IN pessoa.flag_cad_verif%TYPE,
  p_coment_cad_verifi IN pessoa.coment_cad_verif%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
 PROCEDURE info_fiscal_atualizar
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_pessoa_id         IN pessoa.pessoa_id%TYPE,
  p_flag_fis_verif    IN pessoa.flag_fis_verif%TYPE,
  p_status_fis_verif  IN pessoa.status_fis_verif%TYPE,
  p_coment_fis_verif  IN pessoa.coment_fis_verif%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 );
 --
END; -- PESSOA_PKG

/
