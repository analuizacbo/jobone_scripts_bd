--------------------------------------------------------
--  DDL for Package Body CEP_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "CEP_PKG" IS
 --
    PROCEDURE codigo_pesquisar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia          ProcessMind     DATA: 16/07/2001
  -- DESCRICAO: Pesquisa de CEP. Dado um codigo de CEP, que pode ser fornecido no
  --  formato "99999999" ou "99999-999", retorna o respectivo logradouro, bairro,
  --  localidade e uf.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- xxxxxxxxxxxx      dd/mm/yyyy
  ------------------------------------------------------------------------------------------
     (
        p_codigo     IN cep.codigo%TYPE,
        p_logradouro OUT cep.logradouro%TYPE,
        p_bairro     OUT cep.bairro%TYPE,
        p_localidade OUT cep.localidade%TYPE,
        p_uf         OUT cep.uf%TYPE
    ) IS

        v_qt         INTEGER;
        v_codigo     VARCHAR2(10);
        v_logradouro cep.logradouro%TYPE;
        v_bairro     cep.bairro%TYPE;
        v_localidade cep.localidade%TYPE;
        v_uf         cep.uf%TYPE;
  --
    BEGIN
        p_logradouro := ' ';
        p_bairro := ' ';
        p_localidade := ' ';
        p_uf := ' ';
  --
  -- verifica se o cep foi digitado com '-' ou nao
        IF substr(p_codigo, 6, 1) = '-' THEN
            v_codigo := substr(p_codigo, 1, 5)
                        || substr(p_codigo, 7, 3);
        ELSE
            v_codigo := substr(p_codigo, 1, 8);
        END IF;
  --
        SELECT
            nvl(MAX(logradouro),
                ' '),
            nvl(MAX(localidade),
                ' '),
            nvl(to_char(MAX(uf)),
                ' '),
            nvl(MAX(bairro),
                ' ')
        INTO
            v_logradouro,
            v_localidade,
            v_uf,
            v_bairro
        FROM
            cep
        WHERE
            codigo = v_codigo;
  --
        p_logradouro := cap_iniciar(v_logradouro);
        p_localidade := cap_iniciar(v_localidade);
        p_uf := upper(v_uf);
        p_bairro := cap_iniciar(v_bairro);
  --
    EXCEPTION
        WHEN OTHERS THEN
            NULL;
    END; -- codigo_pesquisar
 --
 --
    PROCEDURE codigo_novo_pesquisar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia          ProcessMind     DATA: 16/07/2001
  -- DESCRICAO: Pesquisa de CEP. Dado um codigo de CEP, que pode ser fornecido no
  --  formato "99999999" ou "99999-999", retorna o respectivo logradouro, bairro,
  --  localidade e uf.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- xxxxxxxxxxxx      dd/mm/yyyy
  ------------------------------------------------------------------------------------------
     (
        p_codigo     IN VARCHAR2,
        p_logradouro OUT VARCHAR2,
        p_bairro     OUT VARCHAR2,
        p_localidade OUT VARCHAR2,
        p_uf         OUT VARCHAR2
    ) IS

        v_qt         INTEGER;
        v_codigo     VARCHAR2(10);
        v_logradouro VARCHAR2(100);
        v_bairro     VARCHAR2(100);
        v_localidade VARCHAR2(100);
        v_uf         VARCHAR2(2);
  --
    BEGIN
        p_logradouro := ' ';
        p_bairro := ' ';
        p_localidade := ' ';
        p_uf := ' ';
  --
  -- verifica se o cep foi digitado com '-' ou nao
        IF substr(p_codigo, 6, 1) = '-' THEN
            v_codigo := substr(p_codigo, 1, 5)
                        || substr(p_codigo, 7, 3);
        ELSE
            v_codigo := substr(p_codigo, 1, 8);
        END IF;
  --
        SELECT
            nvl(MAX(en.endereco_logradouro),
                ' '),
            nvl(MAX(ci.cidade_descricao),
                ' '),
            nvl(MAX(uf_sigla),
                ' '),
            nvl(MAX(ba.bairro_descricao),
                ' ')
        INTO
            v_logradouro,
            v_localidade,
            v_uf,
            v_bairro
        FROM
            cep_endereco en,
            cep_bairro   ba,
            cep_cidade   ci,
            cep_uf       uf
        WHERE
                en.bairro_id = ba.bairro_id
            AND ba.cidade_id = ci.cidade_id
            AND ci.uf_id = uf.uf_id
            AND en.endereco_cep = v_codigo;
  --
        IF TRIM(v_logradouro) IS NULL THEN
            SELECT
                MAX(' '),
                nvl(MAX(ci.cidade_descricao),
                    ' '),
                nvl(MAX(uf_sigla),
                    ' '),
                MAX(' ')
            INTO
                v_logradouro,
                v_localidade,
                v_uf,
                v_bairro
            FROM
                cep_cidade ci,
                cep_uf     uf
            WHERE
                    ci.cidade_cep = v_codigo
                AND ci.uf_id = uf.uf_id
                AND ci.cidade_cep <> '00000000';

        END IF;
  --
        p_logradouro := cap_iniciar(v_logradouro);
        p_localidade := cap_iniciar(v_localidade);
        p_uf := upper(v_uf);
        p_bairro := cap_iniciar(v_bairro);
  --
    EXCEPTION
        WHEN OTHERS THEN
            NULL;
    END; -- codigo_novo_pesquisar
 --
 --
    FUNCTION mostrar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia          ProcessMind     DATA: 19/10/2004
  -- DESCRICAO: Funcao que mostra um codigo de CEP, no formato "99999-999"
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- xxxxxxxxxxxx      dd/mm/yyyy
  ------------------------------------------------------------------------------------------
     (
        p_cep IN VARCHAR2
    ) RETURN VARCHAR2 IS
        v_cep VARCHAR2(10);
    BEGIN
        v_cep := '';
  --
        IF TRIM(p_cep) IS NOT NULL THEN
            v_cep := substr(p_cep, 1, 5)
                     || '-'
                     || substr(p_cep, 6, 3);

        END IF;
  --
        RETURN v_cep;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN v_cep;
    END mostrar;
 --
 --
    FUNCTION converter
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia          ProcessMind     DATA: 19/10/2004
  -- DESCRICAO: Funcao que retira a formatacao de um codigo de CEP, retornando "99999999"
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- xxxxxxxxxxxx      dd/mm/yyyy
  ------------------------------------------------------------------------------------------
     (
        p_cep IN VARCHAR2
    ) RETURN VARCHAR2 IS
        v_cep VARCHAR2(10);
    BEGIN
        v_cep := replace(p_cep, '-', '');
        v_cep := replace(v_cep, '.', '');
        v_cep := replace(v_cep, '/', '');
  --
        RETURN v_cep;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN v_cep;
    END converter;
 --
 --
    FUNCTION validar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia          ProcessMind     DATA: 19/10/2004
  -- DESCRICAO: Funcao que valida um codigo de CEP, que pode ser fornecido no
  --  formato "99999999" ou "99999-999", retornando 1 p/ valido e 0 invalido.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            03/10/2005  O numero a ser validado nao precisa mais estar cadastrado
  --                               na tabela CEP.
  ------------------------------------------------------------------------------------------
     (
        p_cep IN VARCHAR2
    ) RETURN INTEGER IS
        v_ok  INTEGER;
        v_cep VARCHAR2(20);
  --
    BEGIN
        v_ok := 0;
        v_cep := trim(replace(p_cep, '-', ''));
        v_cep := replace(v_cep, '.', '');
        v_cep := replace(v_cep, '/', '');
  --
        IF length(v_cep) = 8 THEN
            IF inteiro_validar(v_cep) = 1 THEN
                v_ok := 1;
            END IF;
        END IF;
  --
        IF v_ok > 0 THEN
            v_ok := 1;
        END IF;
  --
        RETURN v_ok;
  --
    EXCEPTION
        WHEN OTHERS THEN
            RETURN v_ok;
    END validar;
 --
 --
    FUNCTION municipio_validar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia          ProcessMind     DATA: 19/10/2004
  -- DESCRICAO: Funcao que um municipio/uf, retornando 1 p/ valido e 0 invalido.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
     (
        p_uf        IN VARCHAR2,
        p_municipio IN VARCHAR2
    ) RETURN INTEGER IS
        v_ok INTEGER;
        v_qt INTEGER;
  --
    BEGIN
        v_ok := 0;
  --
        SELECT
            COUNT(*)
        INTO v_qt
        FROM
            cep_uf     uf,
            cep_cidade mu
        WHERE
                uf.uf_sigla = upper(p_uf)
            AND uf.uf_id = mu.uf_id
            AND util_pkg.acento_municipio_retirar(mu.cidade_descricao) = util_pkg.acento_municipio_retirar(TRIM(p_municipio));
  --
        IF v_qt > 0 THEN
            v_ok := 1;
        END IF;
  --
        RETURN v_ok;
  --
    EXCEPTION
        WHEN OTHERS THEN
            RETURN v_ok;
    END municipio_validar;
 --
 --
    FUNCTION proximidade_retornar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia          ProcessMind     DATA: 28/09/2012
  -- DESCRICAO: Funcao que retorna uma nota indicando a proximidade do CEP analisado em
  --   relacao ao CEP de referencia.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
     (
        p_cep_referencia IN VARCHAR2,
        p_cep_analisado  IN VARCHAR2
    ) RETURN INTEGER IS
  --
        v_exception EXCEPTION;
        v_nota           INTEGER;
        v_fim            INTEGER;
        v_ind            INTEGER;
        v_cep_analisado  VARCHAR2(20);
        v_cep_referencia VARCHAR2(20);
  --
    BEGIN
        v_nota := 0;
        v_ind := 1;
        v_fim := 0;
  --
        v_cep_referencia := trim(replace(p_cep_referencia, '-', ''));
        v_cep_referencia := replace(v_cep_referencia, '.', '');
        v_cep_referencia := replace(v_cep_referencia, '/', '');
  --
        v_cep_analisado := trim(replace(p_cep_analisado, '-', ''));
        v_cep_analisado := replace(v_cep_analisado, '.', '');
        v_cep_analisado := replace(v_cep_analisado, '/', '');
  --
        IF length(v_cep_referencia) <> 8 OR length(v_cep_analisado) <> 8 THEN
            RAISE v_exception;
        END IF;
  --
        WHILE
            v_ind <= 8
            AND v_fim = 0
        LOOP
            IF substr(v_cep_referencia, v_ind, 1) = substr(v_cep_analisado, v_ind, 1) THEN
                v_nota := v_nota + 1;
            ELSE
                v_fim := 1;
            END IF;
   --
            v_ind := v_ind + 1;
        END LOOP;
  --
        RETURN v_nota;
  --
    EXCEPTION
        WHEN v_exception THEN
            RETURN v_nota;
        WHEN OTHERS THEN
            RETURN v_nota;
    END proximidade_retornar;
 --
END; -- CEP_PKG

/
