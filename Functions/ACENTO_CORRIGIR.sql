--------------------------------------------------------
--  DDL for Function ACENTO_CORRIGIR
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE FUNCTION "ACENTO_CORRIGIR" -----------------------------------------------------------------------
-- acento_corrigir
--
--   Descricao: dado um string, corrige palavras com problemas de
--      acentuacao.
-----------------------------------------------------------------------
  (p_string in varchar2)
RETURN  varchar2 IS

v_string LONG;

BEGIN
  v_string := p_string;
  --
  v_string := REPLACE(v_string,' ¿s ',' às ');
  --
  v_string := REPLACE(v_string,'1¿','1º');
  v_string := REPLACE(v_string,'2¿','2º');
  v_string := REPLACE(v_string,'3¿','3º');
  --
  v_string := REPLACE(v_string,'combust¿vel','combustível');
  v_string := REPLACE(v_string,'Combust¿vel','Combustível');
  --
  v_string := REPLACE(v_string,'di¿metro','diâmetro');
  v_string := REPLACE(v_string,'Di¿metro','Diâmetro');
  --
  v_string := REPLACE(v_string,'ep¿xi','epóxi');
  v_string := REPLACE(v_string,'Ep¿xi','Epóxi');
  --
  v_string := REPLACE(v_string,'escrit¿rio','escritório');
  v_string := REPLACE(v_string,'Escrit¿rio','Escritório');
  --
  v_string := REPLACE(v_string,'relat¿rio','relatório');
  v_string := REPLACE(v_string,'Relat¿rio','Relatório');
  --
  v_string := REPLACE(v_string,'pl¿stico','plástico');
  v_string := REPLACE(v_string,'Pl¿stico','Plástico');
  --
  v_string := REPLACE(v_string,'r¿dio','rádio');
  v_string := REPLACE(v_string,'R¿dio','Rádio');
  --
  v_string := REPLACE(v_string,'v¿deo','vídeo');
  v_string := REPLACE(v_string,'V¿deo','Vídeo');
  v_string := REPLACE(v_string,'V¿DEO','VÍDEO');
  --
  v_string := REPLACE(v_string,'ribeir¿o','ribeirão');
  v_string := REPLACE(v_string,'Ribeir¿o','Ribeirão');
  --
  v_string := REPLACE(v_string,'l¿mina','lâmina');
  v_string := REPLACE(v_string,'L¿mina','Lâmina');
  --
  v_string := REPLACE(v_string,'met¿lica','metálica');
  v_string := REPLACE(v_string,'Met¿lica','Metálica');
  --
  v_string := REPLACE(v_string,'s¿bado','sábado');
  v_string := REPLACE(v_string,'S¿bado','Sábado');
  --
  v_string := REPLACE(v_string,'balc¿o','balcão');
  v_string := REPLACE(v_string,'Balc¿o','Balcão');
  --
  v_string := REPLACE(v_string,'cach¿','cachê');
  v_string := REPLACE(v_string,'Cach¿','Cachê');
  --
  v_string := REPLACE(v_string,'Camar¿o','Camarão');
  v_string := REPLACE(v_string,'camar¿o','camarão');
  --
  v_string := REPLACE(v_string,'card¿pio','cardápio');
  v_string := REPLACE(v_string,'Card¿pio','Cardápio');
  v_string := REPLACE(v_string,'CARD¿PIO','CARDÁPIO');
  --
  v_string := REPLACE(v_string,'t¿cnico','técnico');
  v_string := REPLACE(v_string,'T¿cnico','Técnico');
  v_string := REPLACE(v_string,'t¿cnica','técnica');
  v_string := REPLACE(v_string,'T¿cnica','Técnica');
  --
  v_string := REPLACE(v_string,' ¿nico',' único');
  v_string := REPLACE(v_string,' ¿NICO',' ÚNICO');
  v_string := REPLACE(v_string,' ¿nica',' única');
  v_string := REPLACE(v_string,' ¿NICA',' ÚNICA');
  --
  v_string := REPLACE(v_string,'di¿ria','diária');
  v_string := REPLACE(v_string,'Di¿ria','Diária');
  --
  v_string := REPLACE(v_string,'troc¿nio','trocínio');
  v_string := REPLACE(v_string,'PATROC¿NIO','PATROCÍNIO');
  --
  v_string := REPLACE(v_string,'cess¿ria','cessária');
  --
  v_string := REPLACE(v_string,'cart¿veis','cartáveis');
  --
  v_string := REPLACE(v_string,'ar¿on','arçon');
  --
  v_string := REPLACE(v_string,'gu¿s','guês');
  v_string := REPLACE(v_string,'gl¿s','glês');
  v_string := REPLACE(v_string,'ortugu¿','ortuguê');
  v_string := REPLACE(v_string,'ingl¿','inglê');
  --
  v_string := REPLACE(v_string,'en¿a','ença');
  --
  v_string := REPLACE(v_string,'an¿a','ança');
  --
  v_string := REPLACE(v_string,'f¿nica','fônica');
  v_string := REPLACE(v_string,'f¿nico','fônico');
  --
  v_string := REPLACE(v_string,'fer¿ncia','ferência');
  --
  v_string := REPLACE(v_string,'dere¿o','dereço');
  --
  v_string := REPLACE(v_string,'espons¿vel','esponsável');
  --
  v_string := REPLACE(v_string,'u¿¿o','ução');
  --
  v_string := REPLACE(v_string,'i¿¿o','ição');
  --
  v_string := REPLACE(v_string,'en¿¿o','enção');
  --
  v_string := REPLACE(v_string,'or¿a','orça');
  v_string := REPLACE(v_string,'Or¿a','Orça');
  --
  v_string := REPLACE(v_string,'ou¿a','ouça');
  --
  v_string := REPLACE(v_string,'st¿o','stão');
  --
  v_string := REPLACE(v_string,'queir¿o','queirão');
  --
  v_string := REPLACE(v_string,'r¿odo','ríodo');
  --
  v_string := REPLACE(v_string,'t¿gica','tégica');
  v_string := REPLACE(v_string,'t¿gico','tégico');
  --
  v_string := REPLACE(v_string,'m¿tica','mática');
  --
  v_string := REPLACE(v_string,'a¿¿o','ação');
  v_string := REPLACE(v_string,'A¿¿o','Ação');
  v_string := REPLACE(v_string,'A¿¿O','AÇÃO');
  --
  v_string := REPLACE(v_string,'¿¿es','ções');
  v_string := REPLACE(v_string,'¿¿ES','ÇÕES');
  --
  v_string := REPLACE(v_string,'m¿o','mão');
  v_string := REPLACE(v_string,'M¿o','Mão');
  --
  v_string := REPLACE(v_string,' m¿s',' mês');
  v_string := REPLACE(v_string,' M¿s',' Mês');
  --
  v_string := REPLACE(v_string,' v¿o ',' vôo ');
  v_string := REPLACE(v_string,' V¿o ',' Vôo ');
  v_string := REPLACE(v_string,' v¿o.',' vôo.');
  v_string := REPLACE(v_string,' V¿o.',' Vôo.');
  --
  v_string := REPLACE(v_string,'a¿rea','aérea');
  v_string := REPLACE(v_string,'A¿rea','Aérea');
  v_string := REPLACE(v_string,'a¿reo','aéreo');
  v_string := REPLACE(v_string,'A¿reo','Aéreo');
  --
  v_string := REPLACE(v_string,'s¿o','são');
  v_string := REPLACE(v_string,'S¿o','São');
  v_string := REPLACE(v_string,'S¿O','SÃO');
  --
  v_string := REPLACE(v_string,'s¿es','sões');
  v_string := REPLACE(v_string,'S¿ES','SÕES');
  --
  v_string := REPLACE(v_string,'ser¿ ','será ');
  v_string := REPLACE(v_string,'Ser¿ ','Será ');
  --

--
  RETURN v_string;
--
EXCEPTION
  WHEN OTHERS THEN
    v_string := 'ERRO string';
    RETURN v_string;
END;

/
