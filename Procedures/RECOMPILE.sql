--------------------------------------------------------
--  DDL for Procedure RECOMPILE
--------------------------------------------------------
set define off;

  CREATE OR REPLACE EDITIONABLE PROCEDURE "RECOMPILE" 
-----------------------------------------------------------------------
--   recompile
--
--   Descricao: recompile objetos c/ status INVALID
-----------------------------------------------------------------------
   (status_in IN VARCHAR2 := 'INVALID')
IS
   v_objtype             VARCHAR2(100);
   v_comando             VARCHAR2(2000);
   v_cid                 INTEGER;
   v_qt_reg              INTEGER;
--
   CURSOR obj_cur IS
      SELECT object_name, object_type
        FROM USER_OBJECTS
       WHERE status LIKE UPPER (status_in)
         AND object_type NOT IN ('SYNONYM','VIEW','MATERIALIZED VIEW')
      ORDER BY
         DECODE (object_type,
            'PACKAGE', 1, 'PACKAGE BODY', 4,
            'FUNCTION', 2, 'PROCEDURE', 3);
--
   CURSOR view_cur IS
      SELECT object_name
        FROM USER_OBJECTS
       WHERE status LIKE UPPER (status_in)
         AND object_type = 'VIEW';       
--
   CURSOR mview_cur IS
      SELECT object_name
        FROM USER_OBJECTS
       WHERE status LIKE UPPER (status_in)
         AND object_type = 'MATERIALIZED VIEW';
--
   CURSOR syn_cur IS
      SELECT object_name
        FROM USER_OBJECTS
       WHERE status LIKE UPPER (status_in)
         AND object_type = 'SYNONYM';
--
BEGIN
   FOR rec IN obj_cur
   LOOP
      IF rec.object_type = 'PACKAGE'
      THEN
         v_objtype := 'PACKAGE SPECIFICATION';
      ELSE
         v_objtype := rec.object_type;
      END IF;

      DBMS_DDL.ALTER_COMPILE (v_objtype, user, rec.object_name);

      DBMS_OUTPUT.PUT_LINE
         ('Compiled ' || v_objtype || ' of ' ||
          user || '.' || rec.object_name);
   END LOOP;
--
   FOR rec IN view_cur
   LOOP
      v_comando := 'ALTER VIEW ' || rec.object_name || ' COMPILE';
      v_cid := dbms_sql.open_cursor;
      dbms_sql.parse(v_cid, v_comando,2);
      v_qt_reg := dbms_sql.execute(v_cid);
      dbms_sql.close_cursor(v_cid);

      DBMS_OUTPUT.PUT_LINE
         ('Compiled VIEW of ' || user || '.' || rec.object_name);
   END LOOP;
--
   FOR rec IN mview_cur
   LOOP
      v_comando := 'ALTER MATERIALIZED VIEW ' || rec.object_name || ' COMPILE';
      v_cid := dbms_sql.open_cursor;
      dbms_sql.parse(v_cid, v_comando,2);
      v_qt_reg := dbms_sql.execute(v_cid);
      dbms_sql.close_cursor(v_cid);

      DBMS_OUTPUT.PUT_LINE
         ('Compiled VIEW of ' || user || '.' || rec.object_name);
   END LOOP;
--
   FOR rec IN syn_cur
   LOOP
      v_comando := 'ALTER SYNONYM ' || rec.object_name || ' COMPILE';
      v_cid := dbms_sql.open_cursor;
      dbms_sql.parse(v_cid, v_comando,2);
      v_qt_reg := dbms_sql.execute(v_cid);
      dbms_sql.close_cursor(v_cid);

      DBMS_OUTPUT.PUT_LINE
         ('Compiled VIEW of ' || user || '.' || rec.object_name);
   END LOOP;
--
END;

/
