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
  v_string := REPLACE(v_string,' �s ',' �s ');
  --
  v_string := REPLACE(v_string,'1�','1�');
  v_string := REPLACE(v_string,'2�','2�');
  v_string := REPLACE(v_string,'3�','3�');
  --
  v_string := REPLACE(v_string,'combust�vel','combust�vel');
  v_string := REPLACE(v_string,'Combust�vel','Combust�vel');
  --
  v_string := REPLACE(v_string,'di�metro','di�metro');
  v_string := REPLACE(v_string,'Di�metro','Di�metro');
  --
  v_string := REPLACE(v_string,'ep�xi','ep�xi');
  v_string := REPLACE(v_string,'Ep�xi','Ep�xi');
  --
  v_string := REPLACE(v_string,'escrit�rio','escrit�rio');
  v_string := REPLACE(v_string,'Escrit�rio','Escrit�rio');
  --
  v_string := REPLACE(v_string,'relat�rio','relat�rio');
  v_string := REPLACE(v_string,'Relat�rio','Relat�rio');
  --
  v_string := REPLACE(v_string,'pl�stico','pl�stico');
  v_string := REPLACE(v_string,'Pl�stico','Pl�stico');
  --
  v_string := REPLACE(v_string,'r�dio','r�dio');
  v_string := REPLACE(v_string,'R�dio','R�dio');
  --
  v_string := REPLACE(v_string,'v�deo','v�deo');
  v_string := REPLACE(v_string,'V�deo','V�deo');
  v_string := REPLACE(v_string,'V�DEO','V�DEO');
  --
  v_string := REPLACE(v_string,'ribeir�o','ribeir�o');
  v_string := REPLACE(v_string,'Ribeir�o','Ribeir�o');
  --
  v_string := REPLACE(v_string,'l�mina','l�mina');
  v_string := REPLACE(v_string,'L�mina','L�mina');
  --
  v_string := REPLACE(v_string,'met�lica','met�lica');
  v_string := REPLACE(v_string,'Met�lica','Met�lica');
  --
  v_string := REPLACE(v_string,'s�bado','s�bado');
  v_string := REPLACE(v_string,'S�bado','S�bado');
  --
  v_string := REPLACE(v_string,'balc�o','balc�o');
  v_string := REPLACE(v_string,'Balc�o','Balc�o');
  --
  v_string := REPLACE(v_string,'cach�','cach�');
  v_string := REPLACE(v_string,'Cach�','Cach�');
  --
  v_string := REPLACE(v_string,'Camar�o','Camar�o');
  v_string := REPLACE(v_string,'camar�o','camar�o');
  --
  v_string := REPLACE(v_string,'card�pio','card�pio');
  v_string := REPLACE(v_string,'Card�pio','Card�pio');
  v_string := REPLACE(v_string,'CARD�PIO','CARD�PIO');
  --
  v_string := REPLACE(v_string,'t�cnico','t�cnico');
  v_string := REPLACE(v_string,'T�cnico','T�cnico');
  v_string := REPLACE(v_string,'t�cnica','t�cnica');
  v_string := REPLACE(v_string,'T�cnica','T�cnica');
  --
  v_string := REPLACE(v_string,' �nico',' �nico');
  v_string := REPLACE(v_string,' �NICO',' �NICO');
  v_string := REPLACE(v_string,' �nica',' �nica');
  v_string := REPLACE(v_string,' �NICA',' �NICA');
  --
  v_string := REPLACE(v_string,'di�ria','di�ria');
  v_string := REPLACE(v_string,'Di�ria','Di�ria');
  --
  v_string := REPLACE(v_string,'troc�nio','troc�nio');
  v_string := REPLACE(v_string,'PATROC�NIO','PATROC�NIO');
  --
  v_string := REPLACE(v_string,'cess�ria','cess�ria');
  --
  v_string := REPLACE(v_string,'cart�veis','cart�veis');
  --
  v_string := REPLACE(v_string,'ar�on','ar�on');
  --
  v_string := REPLACE(v_string,'gu�s','gu�s');
  v_string := REPLACE(v_string,'gl�s','gl�s');
  v_string := REPLACE(v_string,'ortugu�','ortugu�');
  v_string := REPLACE(v_string,'ingl�','ingl�');
  --
  v_string := REPLACE(v_string,'en�a','en�a');
  --
  v_string := REPLACE(v_string,'an�a','an�a');
  --
  v_string := REPLACE(v_string,'f�nica','f�nica');
  v_string := REPLACE(v_string,'f�nico','f�nico');
  --
  v_string := REPLACE(v_string,'fer�ncia','fer�ncia');
  --
  v_string := REPLACE(v_string,'dere�o','dere�o');
  --
  v_string := REPLACE(v_string,'espons�vel','espons�vel');
  --
  v_string := REPLACE(v_string,'u��o','u��o');
  --
  v_string := REPLACE(v_string,'i��o','i��o');
  --
  v_string := REPLACE(v_string,'en��o','en��o');
  --
  v_string := REPLACE(v_string,'or�a','or�a');
  v_string := REPLACE(v_string,'Or�a','Or�a');
  --
  v_string := REPLACE(v_string,'ou�a','ou�a');
  --
  v_string := REPLACE(v_string,'st�o','st�o');
  --
  v_string := REPLACE(v_string,'queir�o','queir�o');
  --
  v_string := REPLACE(v_string,'r�odo','r�odo');
  --
  v_string := REPLACE(v_string,'t�gica','t�gica');
  v_string := REPLACE(v_string,'t�gico','t�gico');
  --
  v_string := REPLACE(v_string,'m�tica','m�tica');
  --
  v_string := REPLACE(v_string,'a��o','a��o');
  v_string := REPLACE(v_string,'A��o','A��o');
  v_string := REPLACE(v_string,'A��O','A��O');
  --
  v_string := REPLACE(v_string,'��es','��es');
  v_string := REPLACE(v_string,'��ES','��ES');
  --
  v_string := REPLACE(v_string,'m�o','m�o');
  v_string := REPLACE(v_string,'M�o','M�o');
  --
  v_string := REPLACE(v_string,' m�s',' m�s');
  v_string := REPLACE(v_string,' M�s',' M�s');
  --
  v_string := REPLACE(v_string,' v�o ',' v�o ');
  v_string := REPLACE(v_string,' V�o ',' V�o ');
  v_string := REPLACE(v_string,' v�o.',' v�o.');
  v_string := REPLACE(v_string,' V�o.',' V�o.');
  --
  v_string := REPLACE(v_string,'a�rea','a�rea');
  v_string := REPLACE(v_string,'A�rea','A�rea');
  v_string := REPLACE(v_string,'a�reo','a�reo');
  v_string := REPLACE(v_string,'A�reo','A�reo');
  --
  v_string := REPLACE(v_string,'s�o','s�o');
  v_string := REPLACE(v_string,'S�o','S�o');
  v_string := REPLACE(v_string,'S�O','S�O');
  --
  v_string := REPLACE(v_string,'s�es','s�es');
  v_string := REPLACE(v_string,'S�ES','S�ES');
  --
  v_string := REPLACE(v_string,'ser� ','ser� ');
  v_string := REPLACE(v_string,'Ser� ','Ser� ');
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
