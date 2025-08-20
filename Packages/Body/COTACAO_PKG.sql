--------------------------------------------------------
--  DDL for Package Body COTACAO_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "COTACAO_PKG" IS
--
--
--
FUNCTION numero_formatar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Rafael        ProcessMind     DATA: 14/08/2025
  -- DESCRICAO: retorna o numero formatado de uma Cotação.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_cotacao_id IN cotacao.cotacao_id%TYPE
 ) RETURN VARCHAR2 AS
  v_retorno         VARCHAR2(100);
  v_numero_job      job.numero%TYPE;
  v_numero_cotacao  cotacao.numero%TYPE;
  v_qt              INTEGER;
  --
 BEGIN
  v_retorno := NULL;
  --
  --Retorna o numero do job (verificar com o joel)
    SELECT c.numero AS numero_cotacao,
           j.numero AS numero_job
      INTO v_numero_cotacao,
           v_numero_job
      FROM cotacao c
INNER JOIN cotacao_item ci ON ci.cotacao_id = c.cotacao_id
INNER JOIN job j ON j.job_id = c.job_id
     WHERE ci.cotacao_id = p_cotacao_id;
  --
  RETURN v_numero_job || '-CO' || LPAD(v_numero_cotacao, 3, '0');
  --
  RETURN v_retorno;
 EXCEPTION
  WHEN OTHERS THEN
   v_retorno := 'ERRO';
   RETURN v_retorno;
 END numero_formatar;
--
--
--
  PROCEDURE cotacao_adicionar
 -----------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Rafel              ProcessMind     DATA: 14/08/2025
  -- DESCRICAO: Adicionar Cotacao [MÓDULO COMPRAS]
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  -------------------------------------------------------
  --
  ----------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN NUMBER,
  p_item_id           IN NUMBER,
  p_cotacao_id        OUT cotacao.cotacao_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
 
  v_qt              INTEGER;
  v_identif_objeto  historico.identif_objeto%TYPE;
  v_compl_histor    historico.complemento%TYPE;
  v_historico_id    historico.historico_id%TYPE;
  v_exception       EXCEPTION;
  v_num_cenario     cenario.num_cenario%TYPE;
  v_job_id          item.item_id%TYPE;
  v_numero_cotacao  cotacao.numero%TYPE;
  v_cotacao_id      cotacao.cotacao_id%TYPE;
  v_cotacao_item_id cotacao_item.cotacao_item_id%TYPE;
  v_num_data_prazo  NUMBER;
  v_data_prazo_fmt  cotacao.data_prazo%TYPE;
  v_nunmero_cotacao_fmt VARCHAR2(30);
  --
 BEGIN
  v_qt := 0;
  p_cotacao_id :=0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  
  v_num_data_prazo := nvl(empresa_pkg.parametro_retornar(p_empresa_id, 'COTACAO_PRAZO_DIAS_UTEIS'), 0); 
  v_data_prazo_fmt := feriado_pkg.prox_dia_util_retornar(p_usuario_sessao_id,sysdate,v_num_data_prazo,'S');
  
  --recupera o job_id pela tabela de item
  SELECT i.job_id
    INTO v_job_id
    FROM item i
   WHERE item_id = p_item_id;
   
  
  
  --
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'COTACAO_C',
                                v_job_id,
                                NULL,
                                p_empresa_id) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  --
  SELECT nvl(MAX(numero), 0) + 1
    INTO v_numero_cotacao
    FROM cotacao
    WHERE job_id = v_job_id;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM cotacao
   WHERE numero = v_numero_cotacao
   AND job_id = v_job_id;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse número de cotação já existe (' || v_numero_cotacao ||
                 '). Tente novamente.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  --
    SELECT seq_cotacao.nextval
    INTO v_cotacao_id
    FROM dual;
    
    SELECT seq_cotacao_item.nextval
    INTO v_cotacao_item_id
    FROM dual;
  --
    INSERT INTO COTACAO (
                COTACAO_ID,                
                JOB_ID,                     
                USUARIO_ID,                 
                USUARIO_REPROV_ID,                   
                USUARIO_APROV_ID,                    
                DATA_HORA,                        
                NUMERO,              
                INFO_ADICIONAL,              
                DATA_PRAZO,                             
                STATUS,             
                DATA_REPROV,                          
                MOTIVO_REPROV,              
                COMENT_REPROV,               
                DATA_APROV )
            VALUES   
               (v_cotacao_id,
                v_job_id,
                p_usuario_sessao_id,
                null,
                null,
                sysdate,
                v_numero_cotacao, -- numero da cotacao
                null,
                v_data_prazo_fmt,
                'NINI',
                NULL,
                NULL,
                NULL,
                NULL
                );
                
    INSERT INTO COTACAO_ITEM
               (COTACAO_ITEM_ID,
                COTACAO_ID,
                ITEM_ID )
            VALUES
               (v_cotacao_item_id,
                v_cotacao_id,
                p_item_id
                );
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  --
  SELECT c.numero,
         cotacao_pkg.numero_formatar(c.cotacao_id) AS numero_fmt
    INTO v_numero_cotacao,
         v_nunmero_cotacao_fmt
    FROM cotacao c
    WHERE cotacao_id = v_cotacao_id;
  --
  v_identif_objeto := to_char(v_numero_cotacao);
  v_compl_histor   := 'Inclusão de Cotação (' || v_nunmero_cotacao_fmt || ')';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'COTACAO',
                   'INCLUIR',
                   v_identif_objeto,
                   v_cotacao_id,
                   v_compl_histor,
                   NULL,
                   'N',
                   NULL,
                   NULL,
                   v_historico_id,
                   p_erro_cod,
                   p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  COMMIT;
  p_cotacao_id := v_cotacao_id;
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
  
   ROLLBACK;
 END; --cotacao_adicionar;
--
--
--
  PROCEDURE cotacao_info_atualizar
 -----------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Rafel              ProcessMind     DATA: 14/08/2025
  -- DESCRICAO: Atualiza a informação adicional para o fornecedor na Cotação [MÓDULO COMPRAS]
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  -------------------------------------------------------
  --
  ----------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN NUMBER,
  p_cotacao_id        IN NUMBER,
  p_info_adicional    IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
 
  v_qt                  INTEGER;
  v_identif_objeto      historico.identif_objeto%TYPE;
  v_compl_histor        historico.complemento%TYPE;
  v_historico_id        historico.historico_id%TYPE;
  v_exception           EXCEPTION;
  v_info_adicional      cotacao.info_adicional%TYPE;
  v_num_cotacao         cotacao.numero%TYPE;
  v_nunmero_cotacao_fmt VARCHAR2(30);
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM cotacao
   WHERE cotacao_id = p_cotacao_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa cotação não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT numero              
    INTO v_num_cotacao           
    FROM cotacao
   WHERE cotacao_id = p_cotacao_id;
  --
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'COTACAO_C',
                                p_cotacao_id,
                                NULL,
                                p_empresa_id) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF length(p_info_adicional) > 500
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A informação adicional não pode ter mais que 500 caracteres.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  --
    UPDATE COTACAO
       SET info_adicional = p_info_adicional
    WHERE cotacao_id = p_cotacao_id;
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  --
  SELECT c.numero,
         cotacao_pkg.numero_formatar(c.cotacao_id) AS numero_fmt
    INTO v_num_cotacao,
         v_nunmero_cotacao_fmt
    FROM cotacao c
    WHERE cotacao_id = p_cotacao_id;
  --
  v_identif_objeto := to_char(v_nunmero_cotacao_fmt);
  v_compl_histor   := 'Alteração da informação adicional (' || p_info_adicional || ')';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'COTACAO',
                   'ALTERAR',
                   v_identif_objeto,
                   p_cotacao_id,
                   v_compl_histor,
                   NULL,
                   'N',
                   NULL,
                   NULL,
                   v_historico_id,
                   p_erro_cod,
                   p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  COMMIT;
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
  
   ROLLBACK;
 END; --cotacao_adicionar;
--
--
--
  PROCEDURE cotacao_prazo_atualizar
 -----------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Rafel              ProcessMind     DATA: 14/08/2025
  -- DESCRICAO: Atualiza a data_prazo da Cotação [MÓDULO COMPRAS]
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  -------------------------------------------------------
  --
  ----------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN NUMBER,
  p_cotacao_id        IN NUMBER,
  p_data_prazo        IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
 
  v_qt              INTEGER;
  v_identif_objeto  historico.identif_objeto%TYPE;
  v_compl_histor    historico.complemento%TYPE;
  v_historico_id    historico.historico_id%TYPE;
  v_exception       EXCEPTION;
  v_data_prazo      cotacao.data_prazo%TYPE;
  v_num_cotacao     cotacao.numero%TYPE;
  v_nunmero_cotacao_fmt VARCHAR2(30);
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM cotacao
   WHERE cotacao_id = p_cotacao_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa cotação não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT numero              
    INTO v_num_cotacao           
    FROM cotacao
   WHERE cotacao_id = p_cotacao_id;
  --
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'COTACAO_C',
                                p_cotacao_id,
                                NULL,
                                p_empresa_id) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  --
  IF data_validar(p_data_prazo) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data prazo é inválida (' || p_data_prazo || ').';
   RAISE v_exception;
  END IF;
  --
  v_data_prazo  := data_converter(p_data_prazo);
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  --
    UPDATE COTACAO
       SET data_prazo = v_data_prazo
    WHERE cotacao_id = p_cotacao_id;
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  --
  SELECT c.numero,
         cotacao_pkg.numero_formatar(c.cotacao_id) AS numero_fmt
    INTO v_num_cotacao,
         v_nunmero_cotacao_fmt
    FROM cotacao c
    WHERE cotacao_id = p_cotacao_id;
  --
  v_identif_objeto := to_char(v_nunmero_cotacao_fmt);
  v_compl_histor   := 'Alteração do prazo da cotação (' || v_data_prazo || ')';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'COTACAO',
                   'ALTERAR',
                   v_identif_objeto,
                   p_cotacao_id,
                   v_compl_histor,
                   NULL,
                   'N',
                   NULL,
                   NULL,
                   v_historico_id,
                   p_erro_cod,
                   p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  COMMIT;
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
  
   ROLLBACK;
 END; --cotacao_prazo_atualizar;
--
--
--
  PROCEDURE fornecedor_adicionar
 -----------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Rafel              ProcessMind     DATA: 14/08/2025
  -- DESCRICAO: Adicionar fornecedor a Cotacao [MÓDULO COMPRAS]
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  -------------------------------------------------------
  --
  ----------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id           IN NUMBER,
  p_empresa_id                  IN NUMBER,
  p_cotacao_id                  IN NUMBER,
  p_pessoa_id                   IN NUMBER,
  p_erro_cod                    OUT VARCHAR2,
  p_erro_msg                    OUT VARCHAR2
 ) IS
 
  v_qt                          INTEGER;
  v_identif_objeto              historico.identif_objeto%TYPE;
  v_compl_histor                historico.complemento%TYPE;
  v_historico_id                historico.historico_id%TYPE;
  v_exception                   EXCEPTION;
  v_job_id                      item.item_id%TYPE;
  v_numero_versao               cotacao_pessoa_versao.versao%TYPE;
  v_numero_cotacao              cotacao.numero%TYPE;
  v_cotacao_id                  cotacao.cotacao_id%TYPE;
  v_cotacao_item_id             cotacao_item.cotacao_item_id%TYPE;
  v_num_data_prazo              NUMBER;
  v_nunmero_cotacao_fmt         VARCHAR2(30);
  v_cotacao_pessoa_id           cotacao_pessoa.cotacao_pessoa_id%TYPE;
  v_cotacao_pessoa_versao_id    cotacao_pessoa_versao.cotacao_pessoa_versao_id%TYPE;
  v_data_prazo_fmt              cotacao_pessoa_versao.data_prazo%TYPE;
  --
 BEGIN
  v_qt := 0;
  v_cotacao_id := p_cotacao_id;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  --
  v_num_data_prazo := nvl(empresa_pkg.parametro_retornar(p_empresa_id, 'COTACAO_PRAZO_FORNEC_DIAS_UTEIS'), 0); 
  v_data_prazo_fmt := feriado_pkg.prox_dia_util_retornar(p_usuario_sessao_id,sysdate,v_num_data_prazo,'S');
  
  --
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'COTACAO_C',
                                v_cotacao_id,
                                NULL,
                                p_empresa_id) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  --
  SELECT nvl(MAX(versao), 0) + 1
    INTO v_numero_versao
    FROM cotacao_pessoa_versao
    WHERE cotacao_pessoa_id = 0;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM cotacao_pessoa
   WHERE pessoa_id = p_pessoa_id;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse fornecedor já existe na cotação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  --
    SELECT seq_cotacao_pessoa.nextval
    INTO v_cotacao_pessoa_id
    FROM dual;
    
    SELECT seq_cotacao_pessoa_versao.nextval
    INTO v_cotacao_pessoa_versao_id
    FROM dual;
  --
    INSERT INTO COTACAO_PESSOA (
                COTACAO_PESSOA_ID,         
                COTACAO_ID,         
                PESSOA_ID,         
                CONTATO_ID,      
                INFO_ADICIONAIS,
                FLAG_PREFERENCIA,   
                DESCR_PREFERENCIA,
                USUARIO_PREFERENCIA_ID,         
                DATA_PREFERENCIA,               
                FLAG_PREF_JOBONEAI,       
                DESCR_PREF_JOBONEAI,
                DATA_PREF_JOBONEAI )
            VALUES   
               (v_cotacao_pessoa_id,
                p_cotacao_id,
                p_pessoa_id,
                null,
                null,
                'N',
                NULL,
                NULL,
                NULL,
                'N',
                NULL,
                NULL
                );
                
    INSERT INTO COTACAO_PESSOA_VERSAO(
                COTACAO_PESSOA_VERSAO_ID,         
                COTACAO_PESSOA_ID,         
                VERSAO,          
                FLAG_PADRAO,       
                FLAG_ESCOLHIDO,      
                STATUS_VERSAO,  
                DATA_PRAZO,              
                DETALHES, 
                DATA_VALIDADE,               
                PERC_BV,        
                CONDICAO_PAGTO_ID,         
                AVALIACAO, 
                FLAG_VERIF,       
                USUARIO_VERIF_ID,         
                DATA_VERIF,               
                USUARIO_ENVIO_ID,         
                DATA_ENVIO )
            VALUES
               (v_cotacao_pessoa_versao_id,
                v_cotacao_pessoa_id,
                v_numero_versao, -- verificar pq é a versão 
                'S', -- precisa ficar só na primeira
                'N', -- flag_escolhido
                'PREP',
                v_data_prazo_fmt,
                NULL,
                NULL,
                0,
                NULL,
                NULL,
                'N',
                NULL,
                NULL,
                NULL,
                NULL
                );
                
            UPDATE COTACAO
              SET  STATUS = 'ANDA'
            WHERE cotacao_id = p_cotacao_id;
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  --
  SELECT c.numero,
         cotacao_pkg.numero_formatar(c.cotacao_id) AS numero_fmt
    INTO v_numero_cotacao,
         v_nunmero_cotacao_fmt
    FROM cotacao c
    WHERE cotacao_id = p_cotacao_id;
  --
  v_identif_objeto := to_char(v_numero_cotacao);
  v_compl_histor   := 'Inclusão de fornecedor na cotação (' || v_numero_cotacao || ')';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'COTACAO',
                   'INCLUIR',
                   v_identif_objeto,
                   v_cotacao_id,
                   v_compl_histor,
                   NULL,
                   'N',
                   NULL,
                   NULL,
                   v_historico_id,
                   p_erro_cod,
                   p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  COMMIT;
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
  
   ROLLBACK;
 END; --fornecedor_adicionar;
--
--
--
PROCEDURE cotacao_item_adicionar
 -----------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Rafel              ProcessMind     DATA: 14/08/2025
  -- DESCRICAO: Adiciona item na Cotação [MÓDULO COMPRAS]
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  -------------------------------------------------------
  --
  ----------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN NUMBER,
  p_cotacao_id        IN NUMBER,
  p_vetor_item_id     IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
 
  v_qt                  INTEGER;
  v_identif_objeto      historico.identif_objeto%TYPE;
  v_compl_histor        historico.complemento%TYPE;
  v_historico_id        historico.historico_id%TYPE;
  v_exception           EXCEPTION;

  v_numero_cotacao      cotacao.numero%TYPE;
  v_cotacao_id          cotacao.cotacao_id%TYPE;
  v_cotacao_item_id     cotacao_item.cotacao_item_id%TYPE;
  v_num_data_prazo      NUMBER;
  v_nunmero_cotacao_fmt VARCHAR2(30);
  
  v_delimitador         CHAR(1);
  v_vetor_item_id       VARCHAR2(4000);
  v_item_id             NUMBER;
  v_nome_item           VARCHAR2(1000);
  v_subgrupo            VARCHAR2(1000);
  v_complemento         VARCHAR2(1000);
  --
 BEGIN
  v_qt := 0;
  v_cotacao_id := p_cotacao_id;
  v_vetor_item_id := p_vetor_item_id;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  
  /*SELECT COUNT(*)
    INTO v_qt
    FROM cotacao_item
   WHERE item_id = p_item_id;
  --
  IF v_qt = 1
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Este item já existe na cotação.';
   RAISE v_exception;
  END IF;*/
  --
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'COTACAO_C',
                                v_cotacao_id,
                                NULL,
                                p_empresa_id) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  --
  SELECT c.numero,
         cotacao_pkg.numero_formatar(c.cotacao_id) AS numero_fmt
    INTO v_numero_cotacao,
         v_nunmero_cotacao_fmt
    FROM cotacao c
    WHERE cotacao_id = p_cotacao_id;
  --
  
  ------------------------------------------------------------
  -- tratamento do vetor de item_id
  ------------------------------------------------------------
  v_delimitador       := '|';
  v_vetor_item_id     := p_vetor_item_id;
  --
  --
  WHILE nvl(length(rtrim(v_vetor_item_id)), 0) > 0
  LOOP
   v_item_id := to_number(prox_valor_retornar(v_vetor_item_id, v_delimitador));
  --
  --
  -- verifica duplicidade
    SELECT COUNT(*)
      INTO v_qt
      FROM cotacao_item
     WHERE item_id = v_item_id
       AND cotacao_id = p_cotacao_id;
  --      
  -- Retorna nome do item para a msg de já existencia na cotação.
    SELECT subgrupo,
           complemento
     INTO  v_subgrupo,
           v_complemento
    FROM ITEM 
    WHERE item_id = v_item_id;
  --  
    v_nome_item := v_subgrupo ||' '|| v_complemento;
    IF v_qt > 0 THEN
      p_erro_cod := '90000';
      p_erro_msg := 'O item ' || v_nome_item || ' já existe na cotação.';
      RAISE v_exception;
    END IF;
  --
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  --
  -- gera novo COTACAO_ITEM_ID A PARTIR DA SEQUENCE
    SELECT seq_cotacao_item.NEXTVAL
      INTO v_cotacao_item_id
      FROM dual;
  --
    INSERT INTO cotacao_item
               (
                cotacao_item_id,
                cotacao_id,
                item_id)
         VALUES(
                v_cotacao_item_id,
                p_cotacao_id,
                v_item_id
                );
  --
  END LOOP;
  --
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(v_numero_cotacao);
  v_compl_histor   := 'Inclusão de item na Cotação (' || v_nunmero_cotacao_fmt || ')';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'COTACAO',
                   'INCLUIR',
                   v_identif_objeto,
                   v_cotacao_id,
                   v_compl_histor,
                   NULL,
                   'N',
                   NULL,
                   NULL,
                   v_historico_id,
                   p_erro_cod,
                   p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  COMMIT;
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
  
   ROLLBACK;
 END; --cotacao_item_adicionar;
--
--
--
PROCEDURE cotacao_item_excluir
 -----------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Rafel              ProcessMind     DATA: 14/08/2025
  -- DESCRICAO: Exclusão do item na Cotação [MÓDULO COMPRAS]
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  -------------------------------------------------------
  --
  ----------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN NUMBER,
  p_cotacao_id        IN NUMBER,
  p_cotacao_item_id   IN NUMBER,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
 
  v_qt              INTEGER;
  v_identif_objeto  historico.identif_objeto%TYPE;
  v_compl_histor    historico.complemento%TYPE;
  v_historico_id    historico.historico_id%TYPE;
  v_exception       EXCEPTION;
  v_num_cenario     cenario.num_cenario%TYPE;
  v_job_id          item.item_id%TYPE;
  v_numero_cotacao  cotacao.numero%TYPE;
  v_cotacao_id      cotacao.cotacao_id%TYPE;
  v_cotacao_item_id cotacao_item.cotacao_item_id%TYPE;
  v_num_data_prazo  NUMBER;
  v_nunmero_cotacao_fmt VARCHAR2(30);
  --
 BEGIN
  v_qt := 0;
  v_cotacao_id := p_cotacao_id;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM cotacao_item
   WHERE cotacao_id = p_cotacao_id;
  --
  IF v_qt = 1
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Não é possivel excluir este item, a cotação precisa ter ao menos um item.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM cotacao_pessoa_item cp
   INNER JOIN cotacao_item ci ON ci.cotacao_item_id = cp.cotacao_item_id
   WHERE cp.cotacao_item_id = p_cotacao_item_id;
  --
  IF v_qt = 1
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Não é possivel excluir este item, tem registros na tabela cotacao_pessoa_item'; --(VERIFICAR FRASE CORRETA)
   RAISE v_exception;
  END IF;
   
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'COTACAO_C',
                                p_cotacao_id,
                                NULL,
                                p_empresa_id) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  --            
    DELETE FROM cotacao_item
          WHERE cotacao_item_id = p_cotacao_item_id;
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  --
  SELECT c.numero,
         cotacao_pkg.numero_formatar(c.cotacao_id) AS numero_fmt
    INTO v_numero_cotacao,
         v_nunmero_cotacao_fmt
    FROM cotacao c
    WHERE cotacao_id = p_cotacao_id;
  --
  v_identif_objeto := to_char(v_numero_cotacao);
  v_compl_histor   := 'Exclusão do item na Cotação (' || v_nunmero_cotacao_fmt || ')';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'COTACAO',
                   'EXCLUIR',
                   v_identif_objeto,
                   v_cotacao_id,
                   v_compl_histor,
                   NULL,
                   'N',
                   NULL,
                   NULL,
                   v_historico_id,
                   p_erro_cod,
                   p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  COMMIT;
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
  
   ROLLBACK;
 END; --cotacao_item_excluir;

--

END COTACAO_PKG;

/
