--------------------------------------------------------
--  DDL for Package Body WEBSERVICEUTILS_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "WEBSERVICEUTILS_PKG" AS
    PROCEDURE addparamtocollection (
        p_collection IN OUT NOCOPY service_param_list,
        p_param      IN service_param_type
    ) IS
    BEGIN
        p_collection.extend;
        p_collection(p_collection.count) := p_param;
    END;
 /*--------------------------------------*/
 /*  Generic Service Execution Function  */
 /*--------------------------------------*/
    FUNCTION executewebservice (
        p_service_def service_definition_type
    ) RETURN CLOB IS

        v_req    soap_api_pkg.t_request;
        v_resp   soap_api_pkg.t_response;
        v_result CLOB := empty_clob();
        v_env    VARCHAR2(32767) := NULL;
  -- v_env CLOB := EMPTY_CLOB();
    BEGIN
        v_req := soap_api_pkg.new_request(p_service_def.service_name, 'xmlns="'
                                                                      || p_service_def.service_ns
                                                                      || '"', nvl(p_service_def.soap_tag, soap_tag_12));

        FOR p_cnt IN 1..p_service_def.service_params.count LOOP
            soap_api_pkg.add_parameter(v_req, p_service_def.service_params(p_cnt).name, p_service_def.service_params(p_cnt).data_type
            , p_service_def.service_params(p_cnt).value);
        END LOOP;

        soap_api_pkg.generate_envelope(v_req, v_env);
        v_resp := soap_api_pkg.invoke(v_req, p_service_def.service_url, nvl(p_service_def.service_action_url, rtrim(p_service_def.service_ns
        , '/')
                                                                                                              || '/'
                                                                                                              || p_service_def.service_name
                                                                                                              ));

        IF p_service_def.result_target IS NULL THEN
            v_result := v_resp.doc.getclobval();
        ELSE
            v_result := soap_api_pkg.get_return_value(v_resp, p_service_def.result_target, 'xmlns="'
                                                                                           || p_service_def.result_ns
                                                                                           || '"');
        END IF;

        RETURN v_result;
    END;
 /*-------------*/
/* END PACKAGE */
/*-------------*/
end;


/
