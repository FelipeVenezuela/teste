#INCLUDE "PROTHEUS.CH"
#INCLUDE "TBICONN.CH"
#INCLUDE "COLORS.CH"
#INCLUDE "RPTDEF.CH"
#INCLUDE "FWPrintSetup.ch"   

#DEFINE PD_ORIENTATION 2
/*/{Protheus.doc} AKIOOMS1
Impressão de Produtos da Carga por lote
@author Flávio Dentello
@since 30.12.2022
/*/
User Function AKIOOMS1()

Local cStartPath  := 'C:\TEMP\'
Local cPerg		  := "AKIOOMS1"
Private lCancel
Private oArial08  := TFont():New("Arial",10,10,,.F.,,,,.T.,.F.)//Normal
Private oArial10  := TFont():New("Arial",11,11,,.F.,,,,.T.,.F.)//Normal
Private oArial10I := TFont():New("Arial",10,10,,.T.,,,,,.F.,.T.)//Negrito Italico
Private oArial10N := TFont():New("Arial",10,10,,.T.,,,,.T.,.F.)//Negrito
Private oArial12  := TFont():New("Arial",12,12,,.F.,,,,.T.,.F.)//Normal
Private oArial12N := TFont():New("Arial",12,12,,.T.,,,,.T.,.F.)//Negrito
Private oArial11  := TFont():New("Arial",11,11,,.F.,,,,.T.,.F.)//Normal
Private oArial11N := TFont():New("Arial",11,11,,.T.,,,,.T.,.F.)//Negrito
Private oArial15N := TFont():New("Arial",15,15,,.T.,,,,.T.,.F.)//Negrito
Private oArial17  := TFont():New("Arial",17,17,,.F.,,,,.T.,.F.)//Normal

ValidPerg(cPerg)
Pergunte(cPerg,.T.)

oPrint:=FWMSPrinter():New("Relatorio de Faturamento",IMP_PDF,.F.,cStartPath,,,@oPrint,,,,,.T.)
oPrint:SetResolution(72)
oPrint:SetPortrait()
oPrint:SetPaperSize(DMPAPER_A4)
oPrint:SetMargin(60,60,60,60)
oPrint:GetViewPdf()
oPrint:Cancel()
lRet := oPrint:Canceled()
If !VALTYPE(oPrint:oFilewriter) == "O"
	MsgInfo("Impressão cancelada pelo Usuário!")
	Return
EndIf
Processa({|| RelImp() }, "Aguarde o processamento...")
oPrint:Preview()
Return

Static Function RelImp()

Local nLin     := 0   
Local cAlias   := GetNextAlias()
Local nTotal   := 0
Local cProduto := ""
Local nSegun   := 0

    oPrint:Startpage()

    nLin := 040
	cQuery := " SELECT C9_PRODUTO, B1_DESC, B1_UM, C9_LOTECTL, B1_SEGUM , B1_TIPCONV , B1_CONV, SUM(C9_QTDLIB) AS QTDE FROM " + RetSqlName("SA1") + " SA1 "
	cQuery += "INNER JOIN " + RetSqlName("SC9") + " SC9 ON SC9.D_E_L_E_T_= ' '
	cQuery += "AND A1_COD = C9_CLIENTE "
	cQuery += "AND A1_LOJA = C9_LOJA "
	cQuery += "AND C9_NFISCAL <> ' ' "
	cQuery += "AND C9_CARGA >= '"+MV_PAR03+"'"
	cQuery += "AND C9_CARGA <= '"+MV_PAR04+"'"
	cQuery += "INNER JOIN " + RetSqlName("SF2") + " SF2 ON SF2.D_E_L_E_T_= ' ' "
	cQuery += "AND C9_FILIAL = F2_FILIAL "
	cQuery += "AND C9_NFISCAL = F2_DOC "
	cQuery += "AND C9_SERIENF = F2_SERIE " 
	cQuery += "AND F2_EMISSAO >= '"+DTOS(MV_PAR01)+"'" 
	cQuery += "AND F2_EMISSAO <= '"+DTOS(MV_PAR02)+"'" 
	cQuery += "INNER JOIN " + RetSqlName("SB1") + " SB1 ON SB1.D_E_L_E_T_= ' ' "
	cQuery += "AND C9_PRODUTO = B1_COD "
	cQuery += "WHERE SA1.D_E_L_E_T_= ' ' "
	cQuery += "AND A1_CGC >= '"+MV_PAR05+"'"
	cQuery += "AND A1_CGC <= '"+MV_PAR06+"'"
	
	cQuery += "GROUP BY C9_PRODU TO, B1_DESC, B1_UM, C9_LOTECTL ,B1_SEGUM, B1_TIPCONV, B1_CONV "
	cQuery += "ORDER BY C9_PRODUTO "
	
	cQuery := ChangeQuery(cQuery)
	dbUseArea( .T., "TOPCONN", TCGENQRY(,,cQuery),cAlias, .F., .T.) 

	If ! (cAlias)->(Eof())		
		//****************CABELÇALHO******************//
		oPrint:Say(nLin, 010, Replicate("_",130) ,oArial11N)
		nLin += 020
		oPrint:Say(nLin, 140, "Relatório de Faturamento agrupado por Produto" ,oArial15N)
		nLin += 020
		oPrint:Say(nLin, 160, "De "+DTOC(MV_PAR01)+ " Até "+ DTOC(MV_PAR02),oArial17)
		nLin += 020
		oPrint:Say(nLin, 160, "Carga "+MV_PAR03+ " Até "+ MV_PAR04,oArial17)
		nLin += 020
		oPrint:Say(nLin, 160, "CNPJ Cliente "+MV_PAR05+ " Até "+ MV_PAR06,oArial17)
		nLin += 020
		oPrint:Say(nLin, 010, Replicate("_",130) ,oArial11N)
		nLin += 015
		oPrint:Say(nLin, 010, "Código ",oArial12N)
		oPrint:Say(nLin, 080, "Descrição ",oArial12N)
		oPrint:Say(nLin, 330, "Qtde ",oArial12N)
		oPrint:Say(nLin, 380, "UN ",oArial12N)
		oPrint:Say(nLin, 410, "QtdSeg",oArial12N)
		oPrint:Say(nLin, 460, "Un.Segun",oArial12N)
		oPrint:Say(nLin, 510, "Lote ",oArial12N)
		nLin += 010
		oPrint:Say(nLin, 010, Replicate("_",130) ,oArial11N)
		While ! (cAlias)->(Eof())
			nSegun := 0
			If nLin + 15 >= 750
				oPrint:EndPage()
				nLin := 040
				oPrint:Startpage()
				oPrint:Say(nLin, 010, Replicate("_",130) ,oArial11N)
				nLin += 015
				oPrint:Say(nLin, 010, "Código ",oArial12N)
				oPrint:Say(nLin, 080, "Descrição ",oArial12N)
				oPrint:Say(nLin, 330, "Qtde ",oArial12N)
				oPrint:Say(nLin, 380, "UN ",oArial12N)
				oPrint:Say(nLin, 410, "QtdSeg",oArial12N)
				oPrint:Say(nLin, 460, "Un.Segun",oArial12N)
				oPrint:Say(nLin, 510, "Lote ",oArial12N)
				nLin += 010
				oPrint:Say(nLin, 010, Replicate("_",130) ,oArial11N)
				nLin += 012
			Else
				nLin += 012
			EndIf
			If cProduto <> (cAlias)->(C9_PRODUTO) .and. nTotal > 0
				//nLin += 012
				oPrint:Say(nLin, 010, Replicate("_",130) ,oArial11N)
				//nLin += 012
				///oPrint:Say(nLin, 080, "Total "+Posicione("SB1",1,xFilial("SB1")+cProduto,"B1_DESC"),oArial12)
				//oPrint:Say(nLin, 390,  alltrim(Transform(nTotal, "@E 99,999,999,999.99" )),oArial12)
				//nLin += 020
				//oPrint:Say(nLin, 010, Replicate("_",130) ,oArial11N)
				nLin += 015
				oPrint:Say(nLin, 010, "Código ",oArial12N)
				oPrint:Say(nLin, 080, "Descrição ",oArial12N)
				oPrint:Say(nLin, 330, "Qtde ",oArial12N)
				oPrint:Say(nLin, 380, "UN ",oArial12N)
				oPrint:Say(nLin, 410, "QtdSeg",oArial12N)
				oPrint:Say(nLin, 460, "Un.Segun",oArial12N)
				oPrint:Say(nLin, 510, "Lote ",oArial12N)
				nLin += 010
				oPrint:Say(nLin, 010, Replicate("_",130) ,oArial11N)
				nLin += 012
				nTotal := 0
			EndIf
			oPrint:Say(nLin, 010, (cAlias)->(C9_PRODUTO),oArial12)
			oPrint:Say(nLin, 080, (cAlias)->(B1_DESC),oArial12)
			oPrint:Say(nLin, 330,  alltrim(Transform((cAlias)->(QTDE), "@E 99,999,999,999.99" )),oArial12)
			oPrint:Say(nLin, 380, (cAlias)->(B1_UM),oArial12)
			If !Empty((cAlias)->(B1_UM))
				If (cAlias)->(B1_TIPCONV) == "M"
					nSegun := (cAlias)->(QTDE) * (cAlias)->(B1_CONV)
				ElseIf (cAlias)->(B1_TIPCONV) == "D"
					nSegun := (cAlias)->(QTDE) / (cAlias)->(B1_CONV)
				EndIf
			EndIf
			oPrint:Say(nLin, 410, alltrim(Transform(nSegun, "@E 99,999,999,999.99" )),oArial12)
			oPrint:Say(nLin, 460, (cAlias)->(B1_SEGUM),oArial12)
			oPrint:Say(nLin, 510, (cAlias)->(C9_LOTECTL),oArial12)
			nTotal += (cAlias)->(QTDE)
			cProduto := (cAlias)->(C9_PRODUTO)
			(cAlias)->(DbSkip())
		Enddo
		nLin += 012
		oPrint:Say(nLin, 010, Replicate("_",130) ,oArial11N)
		/*nLin += 012
		oPrint:Say(nLin, 080, "Total "+Posicione("SB1",1,xFilial("SB1")+cProduto,"B1_DESC"),oArial12)
		oPrint:Say(nLin, 390,  alltrim(Transform(nTotal, "@E 99,999,999,999.99" )),oArial12)
		nLin += 010
		oPrint:Say(nLin, 010, Replicate("_",130) ,oArial11N)*/
	Else
		nLin =+ 045
		oPrint:Say(nLin+27, 012, "Não há Datos" ,oArial08)
	EndIf
Return


Static Function ValidPerg(cPerg)

Local _sAlias := Alias()
Local aRegs   := {}
Local i,j   
dbSelectArea("SX1")
dbSetOrder(1)
cPerg := PADR(cPerg,10)

aAdd(aRegs,{cPerg,"01","Dt. Emissão de ?","","","mv_ch1","D",8 					 ,0,0,"G","","MV_PAR01","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})
aAdd(aRegs,{cPerg,"02","Dt. Emissão Ate?","","","mv_ch2","D",8 					 ,0,0,"G","","MV_PAR02","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})
aAdd(aRegs,{cPerg,"03","Carga de ?"		 ,"","","mv_ch3","C",TamSX3("DAK_COD")[1],0,0,"G","","MV_PAR03","","","","","","","","","","","","","","","","","","","","","","","","","DAK","","","",""})
aAdd(aRegs,{cPerg,"04","Carga Até?"		 ,"","","mv_ch4","C",TamSX3("DAK_COD")[1],0,0,"G","","MV_PAR04","","","","","","","","","","","","","","","","","","","","","","","","","DAK","","","",""})
aAdd(aRegs,{cPerg,"05","CPF/CNPJ de ?"	 ,"","","mv_ch5","C",TamSX3("A1_CGC")[1] ,0,0,"G","","MV_PAR05","","","","","","","","","","","","","","","","","","","","","","","","","DE4","","","",""})
aAdd(aRegs,{cPerg,"06","CPF/CNPJ Até?"	 ,"","","mv_ch6","C",TamSX3("A1_CGC")[1] ,0,0,"G","","MV_PAR06","","","","","","","","","","","","","","","","","","","","","","","","","DE4","","","",""})

For i:=1 to Len(aRegs)
	If !dbSeek(cPerg+aRegs[i,2])
		RecLock("SX1",.T.)
		For j:=1 to FCount()
			If j <= Len(aRegs[i])
				FieldPut(j,aRegs[i,j])
			Endif
		Next
		MsUnlock()
	Endif
Next
dbSelectArea(_sAlias)
Return()
