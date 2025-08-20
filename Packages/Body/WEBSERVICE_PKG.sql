--------------------------------------------------------
--  DDL for Package Body WEBSERVICE_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "WEBSERVICE_PKG" IS
 --
 --
 PROCEDURE chamar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia            ProcessMind     DATA: 24/04/2011
  -- DESCRICAO: chama o webservice passando o metodo e os parametros.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            12/06/2023  Novo parametro WS1_SERVICE_WALLET
  ------------------------------------------------------------------------------------------
 (
  p_sistema_externo_id IN sistema_externo.sistema_externo_id%TYPE,
  p_empresa_id         IN empresa.empresa_id%TYPE,
  p_metodo             IN VARCHAR2,
  p_acao               IN VARCHAR2,
  p_xml_log_id         IN xml_log.xml_log_id%TYPE,
  p_retorno            OUT CLOB,
  p_erro_msg           OUT CLOB
 ) IS
  --
  v_tipo_retorno        VARCHAR2(10);
  v_exception           EXCEPTION;
  v_service_data_source VARCHAR2(100);
  v_service_name_space  VARCHAR2(100);
  v_service_url         VARCHAR2(200);
  v_service_url_action  VARCHAR2(200);
  v_service_wallet      VARCHAR2(200);
  v_service_def         webserviceutils_pkg.service_definition_type;
  v_param               webserviceutils_pkg.service_param_type;
  v_param_list          webserviceutils_pkg.service_param_list := webserviceutils_pkg.service_param_list();
  v_retorno1            CLOB;
  v_retorno2            CLOB;
 BEGIN
  --
  SELECT MAX(valor)
    INTO v_service_data_source
    FROM sist_ext_parametro
   WHERE sistema_externo_id = p_sistema_externo_id
     AND nome = 'WS1_SERVICE_DATA_SOURCE';
  --
  IF v_service_data_source IS NULL THEN
   p_erro_msg := 'Parâmetro WS1_SERVICE_DATA_SOURCE não definido para esse sistema externo.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(valor)
    INTO v_service_name_space
    FROM sist_ext_parametro
   WHERE sistema_externo_id = p_sistema_externo_id
     AND nome = 'WS1_SERVICE_NAME_SPACE';
  --
  IF v_service_name_space IS NULL THEN
   p_erro_msg := 'Parâmetro WS1_SERVICE_NAME_SPACE não definido para esse sistema externo.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(valor)
    INTO v_service_url
    FROM sist_ext_parametro
   WHERE sistema_externo_id = p_sistema_externo_id
     AND nome = 'WS1_SERVICE_URL';
  --
  IF v_service_url IS NULL THEN
   p_erro_msg := 'Parâmetro WS1_SERVICE_URL não definido para esse sistema externo.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(valor)
    INTO v_service_url_action
    FROM sist_ext_parametro
   WHERE sistema_externo_id = p_sistema_externo_id
     AND nome = 'WS1_SERVICE_URL_ACTION';
  --
  IF v_service_url_action IS NULL THEN
   p_erro_msg := 'Parâmetro WS1_SERVICE_URL_ACTION não definido para esse sistema externo.';
   RAISE v_exception;
  END IF;
  --
  SELECT TRIM(MAX(valor))
    INTO v_service_wallet
    FROM sist_ext_parametro
   WHERE sistema_externo_id = p_sistema_externo_id
     AND nome = 'WS1_SERVICE_WALLET';
  --
  IF v_service_wallet IS NOT NULL THEN
   utl_http.set_wallet('file:' || v_service_wallet, NULL);
  END IF;
  --
  v_service_def.service_name       := p_metodo;
  v_service_def.service_url        := v_service_url;
  v_service_def.service_action_url := v_service_url_action || '/' || p_metodo;
  v_service_def.service_ns         := v_service_name_space;
  --
  v_param.name      := 'dsn_remoto';
  v_param.data_type := 's:string';
  v_param.value     := v_service_data_source;
  --
  webserviceutils_pkg.addparamtocollection(v_param_list, v_param);
  --
  v_param.name      := 'acao';
  v_param.data_type := 's:string';
  v_param.value     := p_acao;
  --
  webserviceutils_pkg.addparamtocollection(v_param_list, v_param);
  --
  v_param.name      := 'xml_log_id';
  v_param.data_type := 's:string';
  v_param.value     := p_xml_log_id;
  --
  webserviceutils_pkg.addparamtocollection(v_param_list, v_param);
  --
  -- INVOKE DO WEBSERVICE
  --
  utl_http.set_transfer_timeout(180);
  v_service_def.service_params := v_param_list;
  --
  -- RETORNO DO WEBSERVICE
  --
  --p_erro_msg := 'antes de chamar';
  --RAISE v_exception;
  v_retorno1 := webserviceutils_pkg.executewebservice(v_service_def);
  --
  SELECT extractvalue(xmltype(v_retorno1),
                      '/ns1:' || p_metodo || 'Response/' || p_metodo || 'Return',
                      'xmlns:ns1="' || v_service_name_space || '"')
    INTO v_retorno2
    FROM dual;
  --
  --v_tipo_retorno := SUBSTR(v_retorno2,1,3);
  v_tipo_retorno := dbms_lob.substr(v_retorno2, 3, 1);
  IF v_tipo_retorno = 'ERR' THEN
   p_retorno  := NULL;
   p_erro_msg := dbms_lob.substr(v_retorno2, 32767, 4);
   --p_erro_msg := SUBSTR(v_retorno2,4);
  ELSIF v_tipo_retorno = 'XML' THEN
   --p_retorno := SUBSTR(v_retorno2,4);
   p_retorno  := dbms_lob.substr(v_retorno2, 32767, 4);
   p_erro_msg := NULL;
  ELSE
   p_retorno  := v_retorno2;
   p_erro_msg := NULL;
  END IF;
  --
 EXCEPTION
  WHEN v_exception THEN
   p_erro_msg := 'WEBSERVICE_PKG: ' || p_erro_msg;
  WHEN OTHERS THEN
   p_erro_msg := 'WEBSERVICE_PKG: ' || SQLCODE || ' - ' ||
                 substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace,
                        1,
                        2000);
 END; -- chamar
--
--
END; -- WEBSERVICE_PKG



/
