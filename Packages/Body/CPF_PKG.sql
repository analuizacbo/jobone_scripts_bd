--------------------------------------------------------
--  DDL for Package Body CPF_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "CPF_PKG" IS

    FUNCTION validar
 ------------------------------------------------------------------------------------------
  --   VALIDAR
  --   Descricao: funcao que consiste um string contendo um CPF
  --   formatado ( '999.999.999-99' ou '99999999999', ...).
  --   Retorna '1' caso o string seja um numero de
  --   CPF valido, e '0' caso nao seja. Para um string igual a NULL,
  --   retorna '1'.
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            23/06/2017  Novo parametro empresa_id
  ------------------------------------------------------------------------------------------

     (
        p_cpf        IN VARCHAR2,
        p_empresa_id IN empresa.empresa_id%TYPE
    ) RETURN INTEGER IS
  --
        ok         INTEGER;
        nrocpf     VARCHAR2(20);
        calccpf    VARCHAR2(20);
        somacpf    INTEGER;
        digtcpf    INTEGER;
        idx1       INTEGER;
        passo      INTEGER;
        qtdigt     INTEGER;
        v_cod_pais pais.codigo%TYPE;
    BEGIN
        ok := 0;
        IF rtrim(p_cpf) IS NULL THEN
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
        nrocpf := ltrim(rtrim(replace(p_cpf, '.', '')));
        nrocpf := replace(nrocpf, '/', '');
        nrocpf := replace(nrocpf, '-', '');
  --
        IF length(nrocpf) <= 11 THEN
            nrocpf := lpad(nrocpf, 11, '0');
        ELSE
            ok := 0;
            RETURN ok;
        END IF;
  --
        calccpf := substr(nrocpf, 1, 9);
  --
        FOR passo IN 0..1 LOOP
            somacpf := 0;
            qtdigt := 9 + passo;
   --
            FOR idx1 IN 1..qtdigt LOOP
                somacpf := somacpf + TO_NUMBER ( substr(calccpf, idx1, 1) ) * ( 11 + passo - idx1 );
            END LOOP;
   --
            digtcpf := 11 - MOD(somacpf, 11);
   --
            IF digtcpf IN ( 10, 11 ) THEN
                calccpf := calccpf || '0';
            ELSE
                calccpf := calccpf || to_char(digtcpf);
            END IF;

        END LOOP;
  --
        IF calccpf = nrocpf THEN
            ok := 1;
        END IF;
  --
        RETURN ok;
  --
    EXCEPTION
        WHEN OTHERS THEN
            RETURN ok;
    END validar;
 --
 --
    FUNCTION mostrar
 ------------------------------------------------------------------------------------------
  --   MOSTRAR
  --   Descricao: funcao que formata o CPF retornando um string no
  --   formato '999.999.999-99'.
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            23/06/2017  Novo parametro empresa_id
  ------------------------------------------------------------------------------------------
     (
        p_cpf        IN VARCHAR2,
        p_empresa_id IN empresa.empresa_id%TYPE
    ) RETURN VARCHAR2 IS
        v_cpf      VARCHAR2(20);
        v_cod_pais pais.codigo%TYPE;
    BEGIN
        v_cpf := '';
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
                instr(p_cpf, '.') = 0
                AND instr(p_cpf, '-') = 0
                AND instr(p_cpf, '/') = 0
            THEN
    -- nao esta formatado. Coloca a formatacao.
                v_cpf := substr(p_cpf, 1, 3)
                         || '.'
                         || substr(p_cpf, 4, 3)
                         || '.'
                         || substr(p_cpf, 7, 3)
                         || '-'
                         || substr(p_cpf, 10, 2);

            ELSE
    -- retorna do jeito que esta'.
                v_cpf := p_cpf;
            END IF;
        ELSE
   -- retorna sem formatar
            v_cpf := p_cpf;
        END IF;
  --
        RETURN v_cpf;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN v_cpf;
    END mostrar;
 --
 --
    FUNCTION converter
 ------------------------------------------------------------------------------------------
  --   CONVETER
  --   Descricao: funcao que tira a formatacao do CPF retornando um string
  --    no formato '99999999999'.
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            23/06/2017  Novo parametro empresa_id
  ------------------------------------------------------------------------------------------
     (
        p_cpf        IN VARCHAR2,
        p_empresa_id IN empresa.empresa_id%TYPE
    ) RETURN VARCHAR2 IS
        v_cpf      VARCHAR2(20);
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
            v_cpf := ltrim(rtrim(p_cpf));
            v_cpf := replace(v_cpf, '.', '');
            v_cpf := replace(v_cpf, '/', '');
            v_cpf := replace(v_cpf, '-', '');
   --
            IF length(v_cpf) <= 11 THEN
                v_cpf := lpad(v_cpf, 11, '0');
            ELSE
                v_cpf := NULL;
            END IF;

        ELSE
   -- retorna o mesmo string
            v_cpf := p_cpf;
        END IF;
  --
        RETURN v_cpf;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN v_cpf;
    END converter;
 --
END; -- CPF_PKG



/
