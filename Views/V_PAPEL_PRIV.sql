--------------------------------------------------------
--  DDL for View V_PAPEL_PRIV
--------------------------------------------------------

  CREATE OR REPLACE FORCE EDITIONABLE VIEW "V_PAPEL_PRIV" ("PAPEL_ID", "EMPRESA_ID", "PRIVILEGIO_ID", "CODIGO_PRIV", "NOME_PRIV", "DESCRICAO_PRIV", "ORDEM_PRIV", "GRUPO_PRIV", "ABRANGENCIA") AS 
  SELECT
-----------------------------------------------------------------------
-- lista os privilegios de cada papel
-----------------------------------------------------------------------
       pp.papel_id,
       pa.empresa_id,
       pr.privilegio_id,
       pr.codigo,
       pr.nome,
       pr.descricao,
       pr.ordem,
       pr.grupo,
       pp.abrangencia
  FROM papel_priv pp,
       privilegio pr,
       papel pa
 WHERE pp.privilegio_id = pr.privilegio_id
   AND pp.papel_id = pa.papel_id

;
