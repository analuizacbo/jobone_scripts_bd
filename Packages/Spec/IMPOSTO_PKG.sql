--------------------------------------------------------
--  DDL for Package IMPOSTO_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "IMPOSTO_PKG" IS
 --
 FUNCTION valor_bruto_acum_retornar(p_nota_fiscal_id IN nota_fiscal.nota_fiscal_id%TYPE)
  RETURN NUMBER;
 --
 FUNCTION imposto_retido_retornar
 (
  p_fi_tipo_imposto_id IN fi_tipo_imposto.fi_tipo_imposto_id%TYPE,
  p_nota_fiscal_id     IN nota_fiscal.nota_fiscal_id%TYPE
 ) RETURN NUMBER;
 --
--
END; -- IMPOSTO_PKG

/
