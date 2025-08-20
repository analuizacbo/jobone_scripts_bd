--------------------------------------------------------
--  DDL for Package Body IT_JOBONE_SELF_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "IT_JOBONE_SELF_PKG" IS
 --
 --
 PROCEDURE oportunidade_job_adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Joel Dias               ProcessMind     DATA: 16/07/2023
  -- DESCRICAO: feita para uso exclusivo do cliente Grupo In Press, esta procedure
  --            cria um Job para cada Oportunidade criada, sendo que o Job é criado com
  --            atributos hard coded, como Tipo Financeiro, Tipo de Job, Cliente, Contato
  --            e outros cadastrados no ambiente deste cliente. Portanto a procedure só
  --            irá funcionar no ambiente deste cliente. Somente IPPN + FH.
  -- OBJETIVO:  abrir o Job para permitir que sejam criados workflows e tasks e a assim
  --            a criação de peças usadas no processo de venda no contexto da oportunidade
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Joel Dias         02/08/2023  a IPPN decidiu que o cliente do Job deve ser o mesmo
  --                               cliente da Oportunidade, ao invés da empresa IPPN que
  --                               estava definido anteriormente.
  -- Joel Dias         07/08/2023  inclusão da empresa FH
  -- Joel Dias         21/02/2024  Não criar contrato e JobOP dependendo do Tipo de Negócio
  -- Ana Luiza         27/02/2025  Adicionado parametro de p_flag_commit
  -- Ana Luiza         27/02/2025  Adicionado parametro de p_flag_commit na chamada de 
  --                               job_pkg.adicionar_wizard
  -- Ana Luiaz         01/04/2025  Adicao de parametro chamada adicionar wizard
  ------------------------------------------------------------------------------------------
 (
  p_oportunidade_id IN oportunidade.oportunidade_id%TYPE,
  p_flag_commit     IN VARCHAR2,
  p_erro_cod        OUT VARCHAR2,
  p_erro_msg        OUT VARCHAR2
 ) IS
  v_qt         INTEGER;
  v_exception  EXCEPTION;
  v_empresa_id empresa.empresa_id%TYPE;
  --v_cliente_job_id                 pessoa.pessoa_id%TYPE;
  v_cliente_op_id       pessoa.pessoa_id%TYPE;
  v_cliente_apelido     pessoa.apelido%TYPE;
  v_contato_id          pessoa.pessoa_id%TYPE;
  v_emp_resp_id         pessoa.pessoa_id%TYPE;
  v_usuario_id          usuario.usuario_id%TYPE;
  v_admin_id            usuario.usuario_id%TYPE;
  v_tipo_job_id         tipo_job.tipo_job_id%TYPE;
  v_tipo_financeiro_id  tipo_financeiro.tipo_financeiro_id%TYPE;
  v_contrato_id         contrato.contrato_id%TYPE;
  v_job_nome            job.nome%TYPE;
  v_job_descricao       job.descricao%TYPE;
  v_produto_cliente_id  produto_cliente.produto_cliente_id%TYPE;
  v_unidade_negocio_id  unidade_negocio.unidade_negocio_id%TYPE;
  v_servico_id          servico.servico_id%TYPE;
  v_job_id              job.job_id%TYPE;
  v_oportunidade_numero oportunidade.numero%TYPE;
  v_oportunidade_nome   oportunidade.nome%TYPE;
  v_data_entrada        oportunidade.data_entrada%TYPE;
  v_briefing_id         briefing.briefing_id%TYPE;
  v_metadado_id         metadado.metadado_id%TYPE;
  v_prefixo_job         VARCHAR2(5);
  v_apelido             pessoa.apelido%TYPE;
  v_flag_ativo          usuario.flag_ativo%TYPE;
  v_tipo_negocio        dicionario.codigo%TYPE;
  v_flag_cria_contrato  CHAR(1);
 BEGIN
  v_qt := 0;
  --ALCBO_270225
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF flag_validar(p_flag_commit) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag commit inválido.';
   RAISE v_exception;
  END IF;
  --verificar se o tipo de negócio da oportunidade permite a criação de contrato
  SELECT tipo_negocio
    INTO v_tipo_negocio
    FROM oportunidade
   WHERE oportunidade_id = p_oportunidade_id;
  --
  IF substr(v_tipo_negocio, 1, 3) = 'SCT'
  THEN
   v_flag_cria_contrato := 'N';
  ELSE
   v_flag_cria_contrato := 'S';
  END IF;
  --
  IF v_flag_cria_contrato = 'S'
  THEN
   --
   --recuperar informações da oportunidade para a abertura do Job
   SELECT empresa_id,
          cliente_id,
          numero,
          nome,
          data_entrada,
          contato_id,
          produto_cliente_id
     INTO v_empresa_id,
          v_cliente_op_id,
          v_oportunidade_numero,
          v_oportunidade_nome,
          v_data_entrada,
          v_contato_id,
          v_produto_cliente_id
     FROM oportunidade
    WHERE oportunidade_id = p_oportunidade_id;
   --definir variável de nome de JOB em função da empresa IPPN (id 1) e FH (id 3)
   IF v_empresa_id = 1
   THEN
    v_prefixo_job := 'JOB';
   END IF;
   IF v_empresa_id = 3
   THEN
    v_prefixo_job := 'PROJ';
   END IF;
   --recuperar informações padrão para a abertura do JOB
   --usuario que criou a Oportunidade
   SELECT usuario_id
     INTO v_usuario_id
     FROM historico h
    INNER JOIN evento e
       ON h.evento_id = e.evento_id
    INNER JOIN tipo_acao a
       ON a.tipo_acao_id = e.tipo_acao_id
    INNER JOIN tipo_objeto o
       ON o.tipo_objeto_id = e.tipo_objeto_id
    WHERE o.codigo = 'OPORTUNIDADE'
      AND a.codigo = 'INCLUIR'
      AND h.objeto_id = p_oportunidade_id;
   --cliente padrão INPRESS SP
   --Joel(02/08/23) por decisão do cliente, usar o cliente da OP para o Job
   /*
   SELECT pessoa_id
     INTO v_cliente_job_id
     FROM pessoa
    WHERE cnpj = '01097636000166'
      AND empresa_id = v_empresa_id;
   */
   --empresa responsável pelo Job padrão IPPN
   IF v_empresa_id = 1
   THEN
    SELECT pessoa_id
      INTO v_emp_resp_id
      FROM pessoa
     WHERE cnpj = '01097636000166'
       AND empresa_id = v_empresa_id;
   END IF;
   --empresa responsável pelo Job padrão FH
   IF v_empresa_id = 3
   THEN
    SELECT pessoa_id
      INTO v_emp_resp_id
      FROM pessoa
     WHERE cnpj = '20181055000152'
       AND empresa_id = v_empresa_id;
   END IF;
   --tipo de job padrão "Oportunidade"
   SELECT tipo_job_id
     INTO v_tipo_job_id
     FROM tipo_job
    WHERE codigo = 'OPORT'
      AND empresa_id = v_empresa_id;
   --tipo financeiro padrão "Pago pela Agência"
   SELECT tipo_financeiro_id
     INTO v_tipo_financeiro_id
     FROM tipo_financeiro
    WHERE empresa_id = v_empresa_id
      AND (codigo = 'AGE' OR codigo = 'AGEN');
   ---contrato padrão CT-0255 - IPPN
   IF v_empresa_id = 1
   THEN
    SELECT contrato_id
      INTO v_contrato_id
      FROM contrato
     WHERE empresa_id = v_empresa_id
       AND numero = 255;
   END IF;
   --contrato padrão CT-0022 - FH
   IF v_empresa_id = 3
   THEN
    SELECT contrato_id
      INTO v_contrato_id
      FROM contrato
     WHERE empresa_id = v_empresa_id
       AND numero = 22;
   END IF;
   --nome do job = número OP + apelido do cliente + nome da Oportunidade
   SELECT apelido
     INTO v_cliente_apelido
     FROM pessoa
    WHERE pessoa_id = v_cliente_op_id;
   --composição da descrição do Job
   v_job_descricao := v_oportunidade_numero || ' - ' || v_cliente_apelido || ' - ' ||
                      v_oportunidade_nome;
   --composição do nome do Job
   v_job_nome := substr(v_job_descricao, 1, 60);
   --contato do cliente fixo apelido InPress e nome InPress e contato da pessoa com cnpj '01097636000166'
   --Joel(02/08/23) por decisão do cliente, usar o cliente da OP para o Job
   /*
   SELECT p.pessoa_id
     INTO v_contato_id
     FROM pessoa p
          INNER JOIN relacao r ON r.pessoa_filho_id = p.pessoa_id
    WHERE p.apelido = 'InPress'
      AND p.nome = 'InPress'
      AND p.empresa_id = v_empresa_id
      AND r.pessoa_pai_id = v_cliente_job_id;
   */
   --produto do cliente fixo nome "Institucional" pessoa_id 23 que é do CNPJ 01097636000166
   --Joel(02/08/23) por decisão do cliente, usar o cliente da OP para o Job
   /*
   SELECT produto_cliente_id
     INTO v_produto_cliente_id
     FROM produto_cliente
    WHERE pessoa_id = v_cliente_job_id
      AND nome = 'Institucional';
   */
   --unidade de negócio fixo nome "IPPN Novos Negócios"
   IF v_empresa_id = 1
   THEN
    SELECT unidade_negocio_id
      INTO v_unidade_negocio_id
      FROM unidade_negocio
     WHERE nome = 'IPPN Novos Negócios'
       AND empresa_id = v_empresa_id;
   END IF;
   IF v_empresa_id = 3
   THEN
    SELECT unidade_negocio_id
      INTO v_unidade_negocio_id
      FROM unidade_negocio
     WHERE nome = 'FH Corporativo SP'
       AND empresa_id = v_empresa_id;
   END IF;
   --serviço fixo "OPERACOES (Uso da Área)"
   SELECT servico_id
     INTO v_servico_id
     FROM servico
    WHERE codigo = 'OPEUAREA';
   --id do usuario adminstrador do sistema]
   SELECT MAX(usuario_id)
     INTO v_admin_id
     FROM usuario
    WHERE flag_admin_sistema = 'S';
   --job_id
   v_job_id := seq_job.nextval;
   --criar JOB
   job_pkg.adicionar_wizard(v_admin_id, --p_usuario_sessao_id 
                            v_empresa_id, --p_empresa_id 
                            v_prefixo_job || v_oportunidade_numero, --p_numero_job 
                            NULL, --p_cod_ext_job 
                            v_job_nome, --p_nome 
                            v_cliente_op_id, --p_cliente_id 
                            v_emp_resp_id, --p_emp_resp_id 
                            v_contato_id, --p_contato_id 
                            v_unidade_negocio_id, --p_unidade_negocio_id 
                            v_produto_cliente_id, --p_produto_cliente_id 
                            v_tipo_job_id, --p_tipo_job_id 
                            v_servico_id, --p_servico_id 
                            v_tipo_financeiro_id, --p_tipo_financeiro_id 
                            v_contrato_id, --p_contrato_id 
                            NULL, --p_campanha_id 
                            to_char(v_data_entrada, 'dd/mm/yyyy'), --p_data_prev_ini 
                            to_char(add_months(v_data_entrada, 12), 'dd/mm/yyyy'), --p_data_prev_fim 
                            'EST', --p_tipo_data_prev 
                            'N', --p_flag_obriga_desc_horas 
                            to_char(v_data_entrada, 'dd/mm/yyyy'), --p_data_pri_aprov 
                            to_char(v_data_entrada, 'dd/mm/yyyy'), --p_data_golive 
                            NULL, --p_mod_crono_id 
                            to_char(v_data_entrada, 'dd/mm/yyyy'), --p_data_crono_base 
                            0, --p_budget 
                            'S', --p_flag_budget_nd 
                            0, --p_receita_prevista 
                            'N', --p_flag_concorrencia 
                            v_job_descricao, --p_descricao 
                            'M', --p_complex_job 
                            v_job_descricao, --p_requisicao_cliente 
                            NULL, --p_vetor_area_id 
                            NULL, --p_vetor_atributo_id 
                            NULL, --p_vetor_atributo_valor 
                            NULL, --p_vetor_dicion_emp_id 
                            NULL, --p_vetor_dicion_emp_val_id 
                            NULL, --p_nome_contexto 
                            'N', --p_flag_restringe_alt_crono 
                            p_flag_commit, --p_flag_commit
                            'BD', --p_tipo_chamada  --ALCBO_010425
                            v_job_id, --p_job_id 
                            p_erro_cod, --p_erro_cod 
                            p_erro_msg --p_erro_msg
                            );
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
   --atualiza as informações do histórico para o id do usuário que criou a oportundiade
   UPDATE historico
      SET usuario_id = v_usuario_id
    WHERE objeto_id = v_job_id
      AND identif_objeto = v_prefixo_job || v_oportunidade_numero
      AND usuario_id = v_admin_id;
   --atualiza usuario enderecado para o usuário que criou a oportunidade
   DELETE FROM job_usuario
    WHERE job_id = v_job_id;
   --endereça os mesmos usuários da Oportunidade no JOBOP, incluido a indicação
   --do mesmo usuário responsável
   FOR r_oport_usuario IN (SELECT usuario_id,
                                  flag_responsavel
                             FROM oport_usuario
                            WHERE oportunidade_id = p_oportunidade_id)
   LOOP
    SELECT nvl(apelido, 'Não Definido')
      INTO v_apelido
      FROM pessoa
     WHERE usuario_id = r_oport_usuario.usuario_id;
    SELECT flag_ativo
      INTO v_flag_ativo
      FROM usuario
     WHERE usuario_id = r_oport_usuario.usuario_id;
    IF v_flag_ativo = 'S'
    THEN
     job_pkg.enderecar_usuario(1,
                               'N',
                               'N',
                               'S',
                               v_empresa_id,
                               v_job_id,
                               r_oport_usuario.usuario_id,
                               v_apelido ||
                               ' endereçado automaticamente na abertura de Job de Oportunidade',
                               'Endereçamento Automátivo',
                               p_erro_cod,
                               p_erro_msg);
     IF p_erro_cod <> '00000'
     THEN
      RAISE v_exception;
     END IF;
     UPDATE job_usuario
        SET flag_responsavel = r_oport_usuario.flag_responsavel
      WHERE job_id = v_job_id
        AND usuario_id = r_oport_usuario.usuario_id;
    END IF;
   END LOOP;
   --inserir metadado com o número da oportunidade no briefing do Job criado
   --recupera o id do briefing
   SELECT MAX(briefing_id)
     INTO v_briefing_id
     FROM briefing
    WHERE job_id = v_job_id;
   --recupera o id do metadado para armazenar o número da oportunidade
   SELECT metadado_id
     INTO v_metadado_id
     FROM metadado
    WHERE tipo_objeto = 'TIPO_JOB'
      AND objeto_id = v_tipo_job_id
      AND grupo = 'BRIEFING'
      AND nome = 'Nº da Oportunidade';
   --insere metadado com o id da oportunidade
   INSERT INTO brief_atributo_valor
    (briefing_id,
     metadado_id,
     valor_atributo)
   VALUES
    (v_briefing_id,
     v_metadado_id,
     v_oportunidade_numero);
   --endereçar outros usuarios de acordo com regras adicionais de endereçamento
   job_pkg.enderecar_automatico(v_usuario_id, v_empresa_id, v_job_id, p_erro_cod, p_erro_msg);
  END IF; --se o tipo de negócio da Oportunidade permite a criação de JOBOP
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --ALCBO_270225
  IF p_flag_commit = 'S'
  THEN
   COMMIT;
  END IF;
  --
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END oportunidade_job_adicionar;
 --
 --
 PROCEDURE oportunidade_job_status_atu
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Joel Dias               ProcessMind     DATA: 25/07/2023
  -- DESCRICAO: feita para uso exclusivo do cliente Grupo In Press, esta procedure
  --            mantém o status da oportunidade e do job criado para ela sincronizados.
  --            Somente IPPN + FH.
  -- OBJETIVO:  manter os status sincronizados.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Joel Dias         07/08/2023  inclusão da empresa FH
  ------------------------------------------------------------------------------------------
 (
  p_oportunidade_id IN oportunidade.oportunidade_id%TYPE,
  p_erro_cod        OUT VARCHAR2,
  p_erro_msg        OUT VARCHAR2
 ) IS
  v_qt                  INTEGER;
  v_exception           EXCEPTION;
  v_job_id              job.job_id%TYPE;
  v_oportunidade_id     oportunidade.oportunidade_id%TYPE;
  v_oportunidade_numero oportunidade.numero%TYPE;
  v_oportunidade_status oportunidade.status%TYPE;
  v_usuario_id          usuario.usuario_id%TYPE;
  v_empresa_id          empresa.empresa_id%TYPE;
  v_status_aux_job_id   status_aux_job.status_aux_job_id%TYPE;
  v_motivo              VARCHAR2(100);
  v_complemento         VARCHAR2(100);
  v_prefixo_job         VARCHAR2(5);
  v_job_status_old      job.status%TYPE;
 BEGIN
  v_oportunidade_id := p_oportunidade_id;
  --recupera número e status da Oportunidade para localização posterior do Job
  SELECT empresa_id,
         numero,
         status
    INTO v_empresa_id,
         v_oportunidade_numero,
         v_oportunidade_status
    FROM oportunidade
   WHERE oportunidade_id = v_oportunidade_id;
  IF v_empresa_id = 1
  THEN
   v_prefixo_job := 'JOB';
  END IF;
  IF v_empresa_id = 3
  THEN
   v_prefixo_job := 'PROJ';
  END IF;
  --verifica se existe JOB criado para a Oportunidade
  SELECT COUNT(*)
    INTO v_qt
    FROM job
   WHERE numero = v_prefixo_job || v_oportunidade_numero;
  --executa a atualização de status se existe Job criado para a Oportunidade
  IF v_qt > 0
  THEN
   --recupera id do Job que será atualizado
   SELECT job_id,
          status
     INTO v_job_id,
          v_job_status_old
     FROM job
    WHERE numero = v_prefixo_job || v_oportunidade_numero
      AND empresa_id = v_empresa_id;
   IF v_job_status_old <> v_oportunidade_status
   THEN
    --recupera usuario responsável pelo Job que será o autor da transição do Job
    SELECT COUNT(*)
      INTO v_qt
      FROM job_usuario
     WHERE flag_responsavel = 'S'
       AND job_id = v_job_id;
    IF v_qt > 0
    THEN
     SELECT usuario_id
       INTO v_usuario_id
       FROM job_usuario
      WHERE flag_responsavel = 'S'
        AND job_id = v_job_id;
    ELSE
     v_usuario_id := 1;
    END IF;
    --recupera status auxiliar padrão para o status para o qual o job vai ser alterado
    SELECT status_aux_job_id
      INTO v_status_aux_job_id
      FROM status_aux_job
     WHERE empresa_id = v_empresa_id
       AND flag_padrao = 'S'
       AND flag_ativo = 'S'
       AND cod_status_pai = v_oportunidade_status;
    --definir motivo e complemento para mudança de status
    v_motivo      := 'Status do Job alterado automaticamente devido à alteração de status de Oportunidade vinculada.';
    v_complemento := 'O status da Oportunidade número ' || v_oportunidade_numero ||
                     ' foi alterado para o mesmo status.';
    --atualiza status do Job igual ao status da Oportunidade
    job_pkg.status_alterar(v_usuario_id --p_usuario_sessao_id
                          ,
                           v_empresa_id --p_empresa_id
                          ,
                           v_job_id --p_job_id
                          ,
                           v_oportunidade_status --p_status
                          ,
                           v_status_aux_job_id --p_status_aux_job_id
                          ,
                           v_motivo --p_motivo
                          ,
                           v_complemento --p_complemento
                          ,
                           'N' --p_flag_commit
                          ,
                           p_erro_cod --p_erro_cod
                          ,
                           p_erro_msg --p_erro_msg
                           );
   END IF;
  END IF; --se existe Job criado para a Oportunidade
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END oportunidade_job_status_atu;
 --
 --
 PROCEDURE oportunidade_job_adicionar_todos
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Joel Dias               ProcessMind     DATA: 09/08/2023
  -- DESCRICAO: executa a oportunidade_job_adicionar para todas as oportunidades em
  --            em andamento, exceto para aquelas que já possuem os jobs criados
  -- OBJETIVO:  executar uma carga inicial, somente IPPN e FH.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Joel Dias         21/02/2024  Não criar contrato e JobOP dependendo do Tipo de Negócio
  -- Ana Luiza         27/02/2025  Adicao de parametro p_flag_commit na chamada da
  --                               oportunidade_job_adicionar
  ------------------------------------------------------------------------------------------
 (
  p_erro_cod OUT VARCHAR2,
  p_erro_msg OUT VARCHAR2
 ) IS
  v_qt                 INTEGER;
  v_exception          EXCEPTION;
  v_oportunidade_id    oportunidade.oportunidade_id%TYPE;
  v_empresa_id         empresa.empresa_id%TYPE;
  v_prefixo_job        VARCHAR2(5);
  v_tipo_negocio       dicionario.codigo%TYPE;
  v_flag_cria_contrato CHAR(1);
  CURSOR c_oportunidade IS
   SELECT oportunidade_id,
          empresa_id,
          numero
     FROM oportunidade
    WHERE status = 'ANDA'
      AND empresa_id IN (1, 3); --somente IPPN e FH
 BEGIN
  v_qt := 0;
  FOR r_oportunidade IN c_oportunidade
  LOOP
   v_oportunidade_id := r_oportunidade.oportunidade_id;
   --verificar se o tipo de negócio da oportunidade permite a criação de contrato
   SELECT tipo_negocio
     INTO v_tipo_negocio
     FROM oportunidade
    WHERE oportunidade_id = v_oportunidade_id;
   --
   IF substr(v_tipo_negocio, 1, 3) = 'SCT'
   THEN
    v_flag_cria_contrato := 'N';
   ELSE
    v_flag_cria_contrato := 'S';
   END IF;
   --
   IF v_flag_cria_contrato = 'S'
   THEN
    v_empresa_id := r_oportunidade.empresa_id;
    --prefixo do número do Job na empresa IPPN
    IF v_empresa_id = 1
    THEN
     v_prefixo_job := 'JOB';
    END IF;
    --prefixo do número do Job na empresa FH
    IF v_empresa_id = 3
    THEN
     v_prefixo_job := 'PROJ';
    END IF;
    --verificar se já foi criado o Job para a Oportunidade
    SELECT COUNT(*)
      INTO v_qt
      FROM job
     WHERE numero = v_prefixo_job || r_oportunidade.numero
       AND empresa_id = v_empresa_id;
    --se o job não existe ainda, então criar
    IF v_qt = 0
    THEN
     --ALCBO_270225
     it_jobone_self_pkg.oportunidade_job_adicionar(v_oportunidade_id, 'N', p_erro_cod, p_erro_msg);
     IF p_erro_cod <> '00000'
     THEN
      RAISE v_exception;
     END IF;
    END IF;
   END IF; --se o tipo de negócio da Oportunidade permite a criação de JOBOP
  END LOOP;
  COMMIT;
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END oportunidade_job_adicionar_todos;
 --
 --
 PROCEDURE oportunidade_job_reenderecar_todos
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Joel Dias               ProcessMind     DATA: 13/09/2023
  -- DESCRICAO: reendereça os usuários das oportunidades que foram criadas automaticamente
  --            pelo procedimento oportunidade_job_adicionar_todos
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Joel Dias         21/02/2024  Não criar contrato e JobOP dependendo do Tipo de Negócio
  -- Ana Luiza         27/02/2025  Adicao de parametro p_flag_commit na chamada da
  --                               oportunidade_job_adicionar
  ------------------------------------------------------------------------------------------
 (
  p_erro_cod OUT VARCHAR2,
  p_erro_msg OUT VARCHAR2
 ) IS
  v_qt                 INTEGER;
  v_exception          EXCEPTION;
  v_oportunidade_id    oportunidade.oportunidade_id%TYPE;
  v_empresa_id         empresa.empresa_id%TYPE;
  v_prefixo_job        VARCHAR2(5);
  v_job_id             job.job_id%TYPE;
  v_apelido            pessoa.apelido%TYPE;
  v_flag_ativo         usuario.flag_ativo%TYPE;
  v_tipo_negocio       dicionario.codigo%TYPE;
  v_flag_cria_contrato CHAR(1);
  CURSOR c_oportunidade IS
   SELECT oportunidade_id,
          empresa_id,
          numero
     FROM oportunidade
    WHERE status = 'ANDA'
      AND empresa_id IN (1, 3); --somente IPPN e FH
 BEGIN
  v_qt := 0;
  FOR r_oportunidade IN c_oportunidade
  LOOP
   v_oportunidade_id := r_oportunidade.oportunidade_id;
   --verificar se o tipo de negócio da oportunidade permite a criação de contrato
   SELECT tipo_negocio
     INTO v_tipo_negocio
     FROM oportunidade
    WHERE oportunidade_id = v_oportunidade_id;
   --
   IF substr(v_tipo_negocio, 1, 3) = 'SCT'
   THEN
    v_flag_cria_contrato := 'N';
   ELSE
    v_flag_cria_contrato := 'S';
   END IF;
   --
   IF v_flag_cria_contrato = 'S'
   THEN
    v_empresa_id := r_oportunidade.empresa_id;
    --prefixo do número do Job na empresa IPPN
    IF v_empresa_id = 1
    THEN
     v_prefixo_job := 'JOB';
    END IF;
    --prefixo do número do Job na empresa FH
    IF v_empresa_id = 3
    THEN
     v_prefixo_job := 'PROJ';
    END IF;
    --verificar se já foi criado o Job para a Oportunidade
    SELECT COUNT(*)
      INTO v_qt
      FROM job
     WHERE numero = v_prefixo_job || r_oportunidade.numero
       AND empresa_id = v_empresa_id;
    --se o job não existe ainda, então criar
    IF v_qt = 0
    THEN
     --ALCBO_270225
     it_jobone_self_pkg.oportunidade_job_adicionar(v_oportunidade_id, 'N', p_erro_cod, p_erro_msg);
     IF p_erro_cod <> '00000'
     THEN
      RAISE v_exception;
     END IF;
    END IF;
    SELECT job_id
      INTO v_job_id
      FROM job
     WHERE numero = v_prefixo_job || r_oportunidade.numero
       AND empresa_id = v_empresa_id;
    DELETE FROM job_usuario
     WHERE job_id = v_job_id;
    FOR r_oport_usuario IN (SELECT usuario_id,
                                   flag_responsavel
                              FROM oport_usuario
                             WHERE oportunidade_id = v_oportunidade_id)
    LOOP
     SELECT nvl(apelido, 'Não Definido')
       INTO v_apelido
       FROM pessoa
      WHERE usuario_id = r_oport_usuario.usuario_id;
     SELECT flag_ativo
       INTO v_flag_ativo
       FROM usuario
      WHERE usuario_id = r_oport_usuario.usuario_id;
     IF v_flag_ativo = 'S'
     THEN
      job_pkg.enderecar_usuario(1,
                                'N',
                                'N',
                                'S',
                                v_empresa_id,
                                v_job_id,
                                r_oport_usuario.usuario_id,
                                v_apelido ||
                                ' endereçado automaticamente na abertura de Job de Oportunidade',
                                'Endereçamento Automátivo',
                                p_erro_cod,
                                p_erro_msg);
      IF p_erro_cod <> '00000'
      THEN
       RAISE v_exception;
      END IF;
      UPDATE job_usuario
         SET flag_responsavel = r_oport_usuario.flag_responsavel
       WHERE job_id = v_job_id
         AND usuario_id = r_oport_usuario.usuario_id;
     END IF;
    END LOOP;
   END IF; --se o tipo de negócio da Oportunidade permite a criação de JOBOP
  END LOOP;
  COMMIT;
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END oportunidade_job_reenderecar_todos;
 --
--
END it_jobone_self_pkg;

/
