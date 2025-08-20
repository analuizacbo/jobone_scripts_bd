--------------------------------------------------------
--  DDL for Procedure SP_EXPURGO_GALERIA
--------------------------------------------------------
set define off;

  CREATE OR REPLACE EDITIONABLE PROCEDURE "SP_EXPURGO_GALERIA" AS

-----------------------------------------------------------------------
--- EMPRESA     : PROCESSMIND
--- SISTEMA     : JOBONE
--- OBJETO      : PROCEDURE
--- DESCRICAO   : ROTINA PARA REALIZACAO DO EXPURGO DE DADOS DA EMPRESA
---               GALERIA
--- SGDB        : Oracle Database 18c Express Edition 
---               Release 18.0.0.0.0 - Production
--- AUTOR       : 
--- CRIACAO     : 29/09/2021
--- OBSERVACAO  : 
-----------------------------------------------------------------------

/*
19	1	Itaú
43	1	Itaú Vivasix
27	1	McDonald's LATAM
15	1	McDonald's
37	1	McDonald’s LATAM PACKAGING
20	1	Natura
49	1	ByteDance Brasil
*/


   CURSOR CUR_PESSOA IS
   SELECT PE.PESSOA_ID
     FROM PESSOA PE
    INNER
     JOIN GRUPO_PESSOA GP ON GP.PESSOA_ID = PE.PESSOA_ID
    WHERE GP.GRUPO_ID NOT IN (19,43,27,15,37,20,49);

   RCUR_PESSOA CUR_PESSOA%ROWTYPE;

   VN_USUARIO_ID      USUARIO.USUARIO_ID%TYPE := 1;
   VN_EMPRESA_ID      EMPRESA.EMPRESA_ID%TYPE;
   VC_ERRO_COD        VARCHAR2(32672);
   VC_ERRO_MSG        VARCHAR2(32672);  
   
BEGIN
      OPEN CUR_PESSOA;
      LOOP
         FETCH CUR_PESSOA INTO RCUR_PESSOA;
         EXIT WHEN CUR_PESSOA%NOTFOUND;

         FOR RJOB IN (SELECT JOB_ID
                        FROM JOB
                       WHERE CLIENTE_ID = RCUR_PESSOA.PESSOA_ID)
         LOOP              
         -- EXCLUI JOB

/*
            SELECT NVL(PE.USUARIO_ID, 0)
              INTO VN_USUARIO_ID
              FROM PESSOA PE
             WHERE PE.PESSOA_ID = RCUR_PESSOA.PESSOA_ID;
*/
            SELECT NVL(PE.EMPRESA_ID, 0)
              INTO VN_EMPRESA_ID
              FROM PESSOA PE
             WHERE PE.PESSOA_ID = RCUR_PESSOA.PESSOA_ID;

            LIMPEZA_PKG.job_apagar(VN_USUARIO_ID, VN_EMPRESA_ID, RJOB.JOB_ID, VC_ERRO_COD, VC_ERRO_MSG);
         
         END LOOP;

         FOR RCONTRATO IN (SELECT CONTRATO_ID
                             FROM CONTRATO
                            WHERE CONTRATANTE_ID = RCUR_PESSOA.PESSOA_ID)
         LOOP
	         -- EXCLUI CONTRATO
           
/*
            SELECT NVL(PE.USUARIO_ID, 0)
              INTO VN_USUARIO_ID
              FROM PESSOA PE
             WHERE PE.PESSOA_ID = RCUR_PESSOA.PESSOA_ID;
*/
            SELECT NVL(PE.EMPRESA_ID, 0)
              INTO VN_EMPRESA_ID
              FROM PESSOA PE
             WHERE PE.PESSOA_ID = RCUR_PESSOA.PESSOA_ID;

         LIMPEZA_PKG.CONTRATO_APAGAR(VN_USUARIO_ID, VN_EMPRESA_ID, RCONTRATO.CONTRATO_ID, VC_ERRO_COD, VC_ERRO_MSG);

         -- EXCLUI PESSOA
         
/*
         SELECT NVL(PE.USUARIO_ID, 0)
           INTO VN_USUARIO_ID
           FROM PESSOA PE
          WHERE PE.PESSOA_ID = RCUR_PESSOA.PESSOA_ID;
*/
         SELECT NVL(PE.EMPRESA_ID, 0)
           INTO VN_EMPRESA_ID
           FROM PESSOA PE
          WHERE PE.PESSOA_ID = RCUR_PESSOA.PESSOA_ID;

          LIMPEZA_PKG.PESSOA_APAGAR(VN_USUARIO_ID, VN_EMPRESA_ID, RCUR_PESSOA.PESSOA_ID, VC_ERRO_COD, VC_ERRO_MSG);
         
         END LOOP;
      END LOOP;
      CLOSE CUR_PESSOA;

EXCEPTION
   WHEN OTHERS THEN
      DBMS_OUTPUT.put_line(SQLERRM);
      DBMS_OUTPUT.put_line(VC_ERRO_COD);
      DBMS_OUTPUT.put_line(VC_ERRO_MSG);
END SP_EXPURGO_GALERIA;

/
