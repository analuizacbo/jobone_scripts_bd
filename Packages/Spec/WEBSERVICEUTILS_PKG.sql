--------------------------------------------------------
--  DDL for Package WEBSERVICEUTILS_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "WEBSERVICEUTILS_PKG" AS
 -- Public Objects/Types
    soap_tag_11 CONSTANT VARCHAR2(8) := 'SOAP-ENV';
    soap_tag_12 CONSTANT VARCHAR2(7) := 'soapenv';
 -- Type allowing developer to define a web service parameter name,data
    TYPE service_param_type IS RECORD (
            name      VARCHAR2(100),
            data_type VARCHAR2(100),
            value     VARCHAR2(32767)
    );
 -- Collection of SERVICE_PARAM Type allowing developer to bundle service params.
    TYPE service_param_list IS
        TABLE OF service_param_type;
 -- Type that allows developer to create service end point definition for generic exection of service
    TYPE service_definition_type IS RECORD (
            service_name       VARCHAR2(100),
            service_url        VARCHAR2(100),
            soap_tag           VARCHAR2(10),
            service_action_url VARCHAR2(200),
            service_ns         VARCHAR2(200),
            service_params     service_param_list,
            result_ns          VARCHAR2(200),
            result_target      VARCHAR2(200)
    );
    PROCEDURE addparamtocollection (
        p_collection IN OUT NOCOPY service_param_list,
        p_param      service_param_type
    );

    FUNCTION executewebservice (
        p_service_def service_definition_type
    ) RETURN CLOB;

END;


/
