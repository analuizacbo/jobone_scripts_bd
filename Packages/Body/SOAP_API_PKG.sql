--------------------------------------------------------
--  DDL for Package Body SOAP_API_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "SOAP_API_PKG" AS
 -- --------------------------------------------------------------------------
 -- Name         : http://www.oracle-base.com/dba/miscellaneous/soap_api
 -- Author       : DR Timothy S Hall
 -- Description  : SOAP related functions for consuming web services.
 -- Ammedments   :
 --   When         Who       What
 --   ===========  ========  =================================================
 --   04-OCT-2003  Tim Hall      Initial Creation
 --   23-FEB-2006  Tim Hall      Parameterized the "soap" envelope tags.
 --   08-JUN-2006  Tim Hall      Add proxy authentication functionality.
 --   11-MAY-2009  Jason Bennett Update the invoke procedure to use CLOB value
 --                              instead of VARCHAR2 to accomodate responses
 --                              larger than 32K.
 -- --------------------------------------------------------------------------
 g_proxy_username VARCHAR2(50) := NULL;
 g_proxy_password VARCHAR2(50) := NULL;
 -- ---------------------------------------------------------------------
 PROCEDURE set_proxy_authentication
 (
  p_username IN VARCHAR2,
  p_password IN VARCHAR2
 ) AS
  -- ---------------------------------------------------------------------
 BEGIN
  g_proxy_username := p_username;
  g_proxy_password := p_password;
 END;
 -- ---------------------------------------------------------------------
 -- ---------------------------------------------------------------------
 FUNCTION new_request
 (
  p_method       IN VARCHAR2,
  p_namespace    IN VARCHAR2,
  p_envelope_tag IN VARCHAR2 DEFAULT 'SOAP-ENV'
 ) RETURN t_request AS
  -- ---------------------------------------------------------------------
  l_request t_request;
 BEGIN
  l_request.method       := p_method;
  l_request.namespace    := p_namespace;
  l_request.envelope_tag := p_envelope_tag;
  RETURN l_request;
 END;
 -- ---------------------------------------------------------------------
 -- ---------------------------------------------------------------------
 PROCEDURE add_parameter
 (
  p_request IN OUT NOCOPY t_request,
  p_name    IN VARCHAR2,
  p_type    IN VARCHAR2,
  p_value   IN VARCHAR2
 ) AS
  -- ---------------------------------------------------------------------
  -- v_parametro             VARCHAR2(32767);
 BEGIN
  p_request.body := p_request.body || '<' || p_name || ' xsi:type="' || p_type || '">' ||
                    p_value || '</' || p_name || '>';
  --
  /*
  v_parametro := '<'||p_name||' xsi:type="'||p_type||'">'||p_value||'</'||p_name||'>';
  --
  IF LENGTH(p_request.body) IS NULL THEN
     DBMS_LOB.createtemporary(p_request.body, FALSE);
  END IF;
  --
  DBMS_LOB.WRITEAPPEND (p_request.body, LENGTH(v_parametro), v_parametro);
  */
 END;
 -- ---------------------------------------------------------------------
 -- ---------------------------------------------------------------------
 PROCEDURE generate_envelope
 (
  p_request IN OUT NOCOPY t_request,
  p_env     IN OUT NOCOPY CLOB
 ) AS
  -- ---------------------------------------------------------------------
  -- v_parte1                 VARCHAR2(32767);
  -- v_parte2                 VARCHAR2(32767);
 BEGIN
  p_env := '<' || p_request.envelope_tag || ':Envelope xmlns:' || p_request.envelope_tag ||
           '="http://schemas.xmlsoap.org/soap/envelope/" ' ||
           'xmlns:xsi="http://www.w3.org/1999/XMLSchema-instance" xmlns:xsd="http://www.w3.org/1999/XMLSchema">' || '<' ||
           p_request.envelope_tag || ':Body>' || '<' || p_request.method || ' ' ||
           p_request.namespace || ' ' || p_request.envelope_tag ||
           ':encodingStyle="http://schemas.xmlsoap.org/soap/encoding">' || p_request.body || '</' ||
           p_request.method || '>' || '</' || p_request.envelope_tag || ':Body>' || '</' ||
           p_request.envelope_tag || ':Envelope>';
  --
  /*
  IF LENGTH(p_env) IS NULL THEN
     DBMS_LOB.createtemporary(p_env, FALSE);
  END IF;
  --
  v_parte1 := '<'||p_request.envelope_tag||':Envelope xmlns:'||p_request.envelope_tag||
              '="http://schemas.xmlsoap.org/soap/envelope/" ' ||
              'xmlns:xsi="http://www.w3.org/1999/XMLSchema-instance" xmlns:xsd="http://www.w3.org/1999/XMLSchema">' ||
              '<'||p_request.envelope_tag||':Body>' ||
              '<'||p_request.method||' '||p_request.namespace||' '||p_request.envelope_tag||
              ':encodingStyle="http://schemas.xmlsoap.org/soap/encoding">';
  --
  v_parte2 := '</'||p_request.method||'>' ||
              '</'||p_request.envelope_tag||':Body>' ||
              '</'||p_request.envelope_tag||':Envelope>';
  --
  DBMS_LOB.WRITEAPPEND (p_env, LENGTH(v_parte1), v_parte1);
  DBMS_LOB.WRITEAPPEND (p_env, LENGTH(p_request.body), p_request.body);
  DBMS_LOB.WRITEAPPEND (p_env, LENGTH(v_parte2), v_parte2);
  */
 END;
 -- ---------------------------------------------------------------------
 -- ---------------------------------------------------------------------
 PROCEDURE show_envelope(p_env IN VARCHAR2) AS
  -- ---------------------------------------------------------------------
  i     PLS_INTEGER;
  l_len PLS_INTEGER;
 BEGIN
  i     := 1;
  l_len := length(p_env);
  WHILE (i <= l_len)
  LOOP
   dbms_output.put_line(substr(p_env, i, 400));
   i := i + 400;
  END LOOP;
 END;
 -- ---------------------------------------------------------------------
 -- ---------------------------------------------------------------------
 PROCEDURE check_fault(p_response IN OUT NOCOPY t_response) AS
  -- ---------------------------------------------------------------------
  l_fault_node   xmltype;
  l_fault_code   VARCHAR2(256);
  l_fault_string VARCHAR2(32767);
 BEGIN
  l_fault_node := p_response.doc.extract('/' || p_response.envelope_tag || ':Fault',
                                         'xmlns:' || p_response.envelope_tag ||
                                         '="http://schemas.xmlsoap.org/soap/envelope/');
  IF (l_fault_node IS NOT NULL) THEN
   l_fault_code   := l_fault_node.extract('/' || p_response.envelope_tag ||':Fault/faultcode/child::text()','xmlns:' || p_response.envelope_tag ||'="http://schemas.xmlsoap.org/soap/envelope/').getstringval();
   l_fault_string := l_fault_node.extract('/' || p_response.envelope_tag ||':Fault/faultstring/child::text()','xmlns:' || p_response.envelope_tag ||'="http://schemas.xmlsoap.org/soap/envelope/').getstringval();
   raise_application_error(-20000, l_fault_code || ' - ' || l_fault_string);
  END IF;
 END;
 -- ---------------------------------------------------------------------
 -- ---------------------------------------------------------------------
 FUNCTION invoke
 (
  p_request IN OUT NOCOPY t_request,
  p_url     IN VARCHAR2,
  p_action  IN VARCHAR2
 ) RETURN t_response AS
  -- ---------------------------------------------------------------------
  l_buffer        VARCHAR2(32767);
  l_envelope      CLOB;
  l_http_request  utl_http.req;
  l_http_response utl_http.resp;
  l_response      t_response;
 BEGIN
  dbms_output.put_line(p_url);
  dbms_output.put_line(p_action);
  utl_http.set_transfer_timeout(180);
  generate_envelope(p_request, l_envelope);
  --show_envelope(l_envelope);
  l_http_request := utl_http.begin_request(p_url, 'POST', 'HTTP/1.1');
  IF g_proxy_username IS NOT NULL THEN
   utl_http.set_authentication(r         => l_http_request,
                               username  => g_proxy_username,
                               password  => g_proxy_password,
                               scheme    => 'Basic',
                               for_proxy => TRUE);
  END IF;
  utl_http.set_header(l_http_request, 'Content-Type', 'text/xml; charset="ISO-8859-1"');
  utl_http.set_header(l_http_request, 'Content-Length', length(l_envelope));
  utl_http.set_header(l_http_request, 'SOAPAction', p_action);
  utl_http.write_text(l_http_request, l_envelope);
  -- Updated by Jason Bennett
  -- to handle response larger than 32K
  l_http_response := utl_http.get_response(l_http_request);
  dbms_lob.createtemporary(l_envelope, FALSE, dbms_lob.call);
  LOOP
   l_buffer := NULL;
   BEGIN
    utl_http.read_text(l_http_response, l_buffer);
    --DBMS_OUTPUT.PUT_LINE(l_buffer);
    dbms_lob.writeappend(l_envelope, length(l_buffer), l_buffer);
   EXCEPTION
    WHEN OTHERS THEN
     IF SQLCODE = -29266 THEN
      NULL;
     ELSE
      RAISE;
     END IF;
   END;
   EXIT WHEN l_buffer IS NULL;
  END LOOP;
  --  show_envelope(l_envelope);
  utl_http.end_response(l_http_response);
  l_response.doc          := xmltype.createxml(l_envelope);
  l_response.envelope_tag := p_request.envelope_tag;
  l_response.doc          := l_response.doc.extract('/' || l_response.envelope_tag ||
                                                    ':Envelope/' || l_response.envelope_tag ||
                                                    ':Body/child::node()',
                                                    'xmlns:' || l_response.envelope_tag ||
                                                    '="http://schemas.xmlsoap.org/soap/envelope/"');
  check_fault(l_response);
  RETURN l_response;
 END;
 -- ---------------------------------------------------------------------
 -- ---------------------------------------------------------------------
 FUNCTION get_return_value
 (
  p_response  IN OUT NOCOPY t_response,
  p_name      IN VARCHAR2,
  p_namespace IN VARCHAR2
 ) RETURN VARCHAR2 AS
  -- ---------------------------------------------------------------------
 BEGIN
  RETURN p_response.doc.extract('//' || p_name || '/child::text()', p_namespace).getstringval();
 END;
END soap_api_pkg;



/
