--------------------------------------------------------
--  DDL for Package Body CNPJ_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "CNPJ_PKG" IS

    FUNCTION validar
 ------------------------------------------------------------------------------------------
  --   VALIDAR
  --   Descricao: funcao que consiste um string contendo um CNPJ formatado
  --   ou nao ('99.999.999/9999-99' ou '99999999999999', ...).
  --   Retorna '1' caso o string seja um numero de
  --   CGC valido, e '0' caso nao seja. Para um string igual a NULL,
  --   retorna '1'.
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            23/06/2017  Novo parametro empresa_id
  ------------------------------------------------------------------------------------------

     (
        p_cnpj       IN VARCHAR2,
        p_empresa_id IN empresa.empresa_id%TYPE
    ) RETURN INTEGER IS
  --
        ok         INTEGER;
        nrocnpj    VARCHAR2(20);
        calccnpj   VARCHAR2(20);
        somacnpj   INTEGER;
        digtcnpj   INTEGER;
        idx1       INTEGER;
        passo      INTEGER;
        qtdigt     INTEGER;
        v_cod_pais pais.codigo%TYPE;
    BEGIN
        ok := 0;
        IF rtrim(p_cnpj) IS NULL THEN
            ok := 1;
            RETURN ok;
        END IF;
  --
        SELECT
            MAX(pa.codigo)
        INTO v_cod_pais
        FROM
            empresa em,
            pais    pa
        WHERE
                em.empresa_id = p_empresa_id
            AND em.pais_id = pa.pais_id;
  --
        IF v_cod_pais <> 'BRA' THEN
            ok := 1;
            RETURN ok;
        END IF;
  --
        nrocnpj := ltrim(rtrim(replace(p_cnpj, '.', '')));
        nrocnpj := replace(nrocnpj, '/', '');
        nrocnpj := replace(nrocnpj, '-', '');
  --
        IF length(nrocnpj) <= 14 THEN
            nrocnpj := lpad(nrocnpj, 14, '0');
        ELSE
            ok := 0;
            RETURN ok;
        END IF;
  --
        calccnpj := substr(nrocnpj, 1, 12);
  --
        FOR passo IN 0..1 LOOP
            somacnpj := 0;
            qtdigt := 4 + passo;
            FOR idx1 IN 1..qtdigt LOOP
                somacnpj := somacnpj + TO_NUMBER ( substr(calccnpj, idx1, 1) ) * ( 6 + passo - idx1 );
            END LOOP;

            FOR idx1 IN 1..8 LOOP
                somacnpj := somacnpj + TO_NUMBER ( substr(calccnpj, idx1 + 4 + passo, 1) ) * ( 10 - idx1 );
            END LOOP;

            digtcnpj := 11 - MOD(somacnpj, 11);
            IF digtcnpj IN ( 10, 11 ) THEN
                calccnpj := calccnpj || '0';
            ELSE
                calccnpj := calccnpj || to_char(digtcnpj);
            END IF;

        END LOOP;
  --
        IF calccnpj = nrocnpj THEN
            ok := 1;
        END IF;
  --
        RETURN ok;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN ok;
    END;
 --
 --
    FUNCTION mostrar
 ------------------------------------------------------------------------------------------
  --   MOSTRAR
  --   Descricao: funcao que formata o CNPJ retornando um string no
  --   formato '99.999.999/9999-99'.
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            23/06/2017  Novo parametro empresa_id
  ------------------------------------------------------------------------------------------
     (
        p_cnpj       IN VARCHAR2,
        p_empresa_id IN empresa.empresa_id%TYPE
    ) RETURN VARCHAR2 IS
        v_cnpj     VARCHAR2(20);
        v_cod_pais pais.codigo%TYPE;
    BEGIN
        v_cnpj := '';
  --
        SELECT
            MAX(pa.codigo)
        INTO v_cod_pais
        FROM
            empresa em,
            pais    pa
        WHERE
                em.empresa_id = p_empresa_id
            AND em.pais_id = pa.pais_id;
  --
        IF v_cod_pais = 'BRA' THEN
            IF
                instr(p_cnpj, '.') = 0
                AND instr(p_cnpj, '-') = 0
                AND instr(p_cnpj, '/') = 0
            THEN
    -- nao esta formatado. Coloca a formatacao.
                v_cnpj := substr(p_cnpj, 1, 2)
                          || '.'
                          || substr(p_cnpj, 3, 3)
                          || '.'
                          || substr(p_cnpj, 6, 3)
                          || '/'
                          || substr(p_cnpj, 9, 4)
                          || '-'
                          || substr(p_cnpj, 13, 2);

            ELSE
    -- retorna do jeito que esta'.
                v_cnpj := p_cnpj;
            END IF;
        ELSE
   -- retorna sem formatar
            v_cnpj := p_cnpj;
        END IF;
  --
        RETURN v_cnpj;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN v_cnpj;
    END;
 --
 --
    FUNCTION converter
 ------------------------------------------------------------------------------------------
  --   CONVETER
  --   Descricao: funcao que tira a formatacao do CNPJ retornando um string
  --    no formato '99999999999999'.
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            23/06/2017  Novo parametro empresa_id
  ------------------------------------------------------------------------------------------
     (
        p_cnpj       IN VARCHAR2,
        p_empresa_id IN empresa.empresa_id%TYPE
    ) RETURN VARCHAR2 IS
        v_cnpj     VARCHAR2(20);
        v_cod_pais pais.codigo%TYPE;
    BEGIN
  --
        SELECT
            MAX(pa.codigo)
        INTO v_cod_pais
        FROM
            empresa em,
            pais    pa
        WHERE
                em.empresa_id = p_empresa_id
            AND em.pais_id = pa.pais_id;
  --
        IF v_cod_pais = 'BRA' THEN
            v_cnpj := ltrim(rtrim(p_cnpj));
            v_cnpj := replace(v_cnpj, '.', '');
            v_cnpj := replace(v_cnpj, '/', '');
            v_cnpj := replace(v_cnpj, '-', '');
   --
            IF length(v_cnpj) <= 14 THEN
                v_cnpj := lpad(v_cnpj, 14, '0');
            ELSE
                v_cnpj := NULL;
            END IF;

        ELSE
   -- retorna o mesmo string
            v_cnpj := p_cnpj;
        END IF;
  --
        RETURN v_cnpj;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN v_cnpj;
    END;
 --
END; -- CNPJ_PKG



/
