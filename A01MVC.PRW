#INCLUDE 'PROTHEUS.CH'
#INCLUDE 'FWBROWSE.CH'

user Function A01MVC()
    
    Local oBrowse
    Local cteste

    oBrowse := FwmBrowse():NEW

    oBrowse:SetAlias('SB1')
    oBrowse:SetDescription("Cadastro de Produto")
    OBrowse:ACTIVATE()
    
Return
