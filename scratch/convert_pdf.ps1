$docxPath = "G:\PROJETOS\CENTRO-DISTRIBUICAO\docs\CRONOGRAMA_ENTREGA_CENTRO_DISTRIBUICAO.docx"
$pdfPath  = "G:\PROJETOS\CENTRO-DISTRIBUICAO\docs\CRONOGRAMA_ENTREGA_CENTRO_DISTRIBUICAO.pdf"

try {
    $word = New-Object -ComObject Word.Application
    $word.Visible = $false
    $doc = $word.Documents.Open($docxPath)
    $wdFormatPDF = 17
    $doc.SaveAs([ref]$pdfPath, [ref]$wdFormatPDF)
    $doc.Close()
    $word.Quit()
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($word) | Out-Null
    Write-Host "PDF gerado com sucesso: $pdfPath"
} catch {
    Write-Host "Word COM nao disponivel ou erro: $_"
}
