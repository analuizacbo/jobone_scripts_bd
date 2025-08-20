--------------------------------------------------------
--  DDL for Package FLEX_PAPER_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "FLEX_PAPER_PKG" IS
 --
    PROCEDURE adicionar (
        p_id                     IN mark.id%TYPE,
        p_ordem_servico_id       IN mark.ordem_servico_id%TYPE,
        p_arquivo_id             IN mark.arquivo_id%TYPE,
        p_status_os              IN mark.status_os%TYPE,
        p_refacao                IN mark.refacao%TYPE,
        p_document_filename      IN mark.document_filename%TYPE,
        p_document_relative_path IN mark.document_relative_path%TYPE,
        p_selection_text         IN mark.selection_text%TYPE,
        p_has_selection          IN mark.has_selection%TYPE,
        p_color                  IN mark.color%TYPE,
        p_selection_info         IN mark.selection_info%TYPE,
        p_readonly               IN mark.readonly%TYPE,
        p_type                   IN mark.type%TYPE,
        p_displayformat          IN mark.displayformat%TYPE,
        p_note                   IN mark.note%TYPE,
        p_pageindex              IN mark.pageindex%TYPE,
        p_positionx              IN mark.positionx%TYPE,
        p_positiony              IN mark.positiony%TYPE,
        p_width                  IN mark.width%TYPE,
        p_height                 IN mark.height%TYPE,
        p_collapsed              IN mark.collapsed%TYPE,
        p_points                 IN mark.points%TYPE,
        p_author                 IN mark.author%TYPE,
        p_erro_cod               OUT VARCHAR2,
        p_erro_msg               OUT VARCHAR2
    );
 --
    PROCEDURE atualizar (
        p_id             IN mark.id%TYPE,
        p_status_os      IN mark.status_os%TYPE,
        p_selection_text IN mark.selection_text%TYPE,
        p_has_selection  IN mark.has_selection%TYPE,
        p_color          IN mark.color%TYPE,
        p_selection_info IN mark.selection_info%TYPE,
        p_readonly       IN mark.readonly%TYPE,
        p_note           IN mark.note%TYPE,
        p_pageindex      IN mark.pageindex%TYPE,
        p_positionx      IN mark.positionx%TYPE,
        p_positiony      IN mark.positiony%TYPE,
        p_width          IN mark.width%TYPE,
        p_height         IN mark.height%TYPE,
        p_collapsed      IN mark.collapsed%TYPE,
        p_points         IN mark.points%TYPE,
        p_erro_cod       OUT VARCHAR2,
        p_erro_msg       OUT VARCHAR2
    );
 --
    PROCEDURE excluir (
        p_id       IN mark.id%TYPE,
        p_author   IN mark.author%TYPE,
        p_erro_cod OUT VARCHAR2,
        p_erro_msg OUT VARCHAR2
    );
 --
END; -- FLEX_PAPER_PKG



/
