--------------------------------------------------------
--  DDL for Package PARCELA_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "PARCELA_PKG" IS
 --
    PROCEDURE arredondar (
        p_usuario_sessao_id IN NUMBER,
        p_item_id           IN item.item_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE parcelado_marcar (
        p_usuario_sessao_id IN NUMBER,
        p_item_id           IN item.item_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE simular (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_job_id            IN job.job_id%TYPE,
        p_vetor_item_id     IN VARCHAR2,
        p_condicao_pagto_id IN condicao_pagto.condicao_pagto_id%TYPE,
        p_vetor_num_parcela OUT VARCHAR2,
        p_vetor_data        OUT VARCHAR2,
        p_vetor_dia_semana  OUT VARCHAR2,
        p_vetor_perc        OUT VARCHAR2,
        p_vetor_valor       OUT VARCHAR2,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE simulacao_gravar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_job_id            IN job.job_id%TYPE,
        p_vetor_item_id     IN VARCHAR2,
        p_vetor_datas       IN VARCHAR2,
        p_vetor_perc        IN VARCHAR2,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE atualizar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_item_id           IN item.item_id%TYPE,
        p_vetor_cli_valor   IN VARCHAR2,
        p_vetor_cli_data    IN VARCHAR2,
        p_vetor_for_valor   IN VARCHAR2,
        p_vetor_for_data    IN VARCHAR2,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
    PROCEDURE desparcelar (
        p_usuario_sessao_id IN NUMBER,
        p_empresa_id        IN empresa.empresa_id%TYPE,
        p_item_id           IN item.item_id%TYPE,
        p_erro_cod          OUT VARCHAR2,
        p_erro_msg          OUT VARCHAR2
    );
 --
END; -- PARCELA_PKG



/
