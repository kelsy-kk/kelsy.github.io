# Build 业务流程-方案文档.docx from markdown via Open XML
$ErrorActionPreference = 'Stop'
$mdPath = if ($env:BP_DOC_MD) { $env:BP_DOC_MD } else { Join-Path $env:TEMP 'bp_doc_source.md' }
$outPath = if ($env:BP_DOC_OUT) { $env:BP_DOC_OUT } else { Join-Path $env:TEMP 'bp_doc_output.docx' }
if (-not (Test-Path -LiteralPath $mdPath)) { throw "Markdown source not found: $mdPath" }
$workDir = Join-Path $env:TEMP ('bp_docx_' + [guid]::NewGuid().ToString('N'))

function Escape-Xml([string]$s) {
  if ($null -eq $s) { return '' }
  return ($s -replace '&', '&amp;' -replace '<', '&lt;' -replace '>', '&gt;' -replace '"', '&quot;')
}

function New-Run([string]$text, [int]$size = 22, [switch]$Bold) {
  $rPr = ''
  if ($Bold -or $size -ne 22) {
    $rPr = '<w:rPr>'
    if ($Bold) { $rPr += '<w:b/>' }
    if ($size -ne 22) { $rPr += "<w:sz w:val=`"$size`"/><w:szCs w:val=`"$size`"/>" }
    $rPr += '</w:rPr>'
  }
  return "<w:r>$rPr<w:t xml:space=`"preserve`">$(Escape-Xml $text)</w:t></w:r>"
}

function New-Para([string]$text, [int]$size = 22, [switch]$Bold, [string]$style = $null) {
  $pPr = ''
  if ($style) { $pPr = "<w:pPr><w:pStyle w:val=`"$style`"/></w:pPr>" }
  elseif ($Bold -or $size -ne 22) {
    # spacing after headings
    $after = if ($size -ge 32) { '240' } elseif ($size -ge 28) { '200' } else { '120' }
    $pPr = "<w:pPr><w:spacing w:after=`"$after`"/></w:pPr>"
  }
  return "<w:p>$pPr$(New-Run $text $size $Bold)</w:p>"
}

function New-Table([object[]]$rows) {
  if (-not $rows -or $rows.Count -eq 0) { return '' }
  $cols = ($rows | ForEach-Object { $_.Count } | Measure-Object -Maximum).Maximum
  $tbl = @'
<w:tbl>
  <w:tblPr>
    <w:tblW w:w="0" w:type="auto"/>
    <w:tblBorders>
      <w:top w:val="single" w:sz="4" w:space="0" w:color="auto"/>
      <w:left w:val="single" w:sz="4" w:space="0" w:color="auto"/>
      <w:bottom w:val="single" w:sz="4" w:space="0" w:color="auto"/>
      <w:right w:val="single" w:sz="4" w:space="0" w:color="auto"/>
      <w:insideH w:val="single" w:sz="4" w:space="0" w:color="auto"/>
      <w:insideV w:val="single" w:sz="4" w:space="0" w:color="auto"/>
    </w:tblBorders>
  </w:tblPr>
  <w:tblGrid>
'@
  for ($c = 0; $c -lt $cols; $c++) { $tbl += '<w:gridCol w:w="2400"/>' }
  $tbl += '</w:tblGrid>'
  for ($r = 0; $r -lt $rows.Count; $r++) {
    $tbl += '<w:tr>'
    for ($c = 0; $c -lt $cols; $c++) {
      $cell = if ($c -lt $rows[$r].Count) { [string]$rows[$r][$c] } else { '' }
      $cell = $cell -replace '\*\*([^*]+)\*\*', '$1' -replace '`([^`]+)`', '$1'
      $bold = ($r -eq 0)
      $tbl += "<w:tc><w:tcPr><w:tcW w:w=`"2400`" w:type=`"dxa`"/></w:tcPr>$(New-Para -text $cell -size 20 -Bold:$bold)</w:tc>"
    }
    $tbl += '</w:tr>'
  }
  $tbl += '</w:tbl>'
  return $tbl
}

function Strip-Md([string]$s) {
  if (-not $s) { return '' }
  return ($s -replace '\*\*([^*]+)\*\*', '$1' -replace '`([^`]+)`', '$1' -replace '^\s*[-*]\s+', '• ')
}

$md = Get-Content -LiteralPath $mdPath -Encoding UTF8 -Raw
$body = New-Object System.Collections.Generic.List[string]
$inCode = $false
$tableRows = New-Object System.Collections.Generic.List[object]
$lines = $md -split "`r?`n"

foreach ($line in $lines) {
  if ($line -match '^```') {
    $inCode = -not $inCode
    continue
  }
  if ($inCode) {
    $body.Add((New-Para (Strip-Md $line) 20))
    continue
  }
  if ($line -match '^\|(.+)\|$') {
    if ($line -match '^\|[-:\s|]+\|$') { continue }
    $cells = @(($line.Trim('|') -split '\|') | ForEach-Object { $_.Trim() })
    [void]$tableRows.Add($cells)
    continue
  }
  if ($tableRows.Count -gt 0) {
    $body.Add((New-Table @($tableRows.ToArray())))
    $tableRows.Clear()
  }

  if ($line -match '^# (.+)$') { $body.Add((New-Para (Strip-Md $matches[1]) 36 -Bold)); continue }
  if ($line -match '^## (.+)$') { $body.Add((New-Para (Strip-Md $matches[1]) 32 -Bold)); continue }
  if ($line -match '^### (.+)$') { $body.Add((New-Para (Strip-Md $matches[1]) 28 -Bold)); continue }
  if ($line -match '^#### (.+)$') { $body.Add((New-Para (Strip-Md $matches[1]) 26 -Bold)); continue }
  if ($line -match '^---\s*$') { continue }
  if ($line -match '^>\s*(.+)$') { $body.Add((New-Para (Strip-Md $matches[1]) 22)); continue }
  if ($line -match '^[-*] (.+)$') { $body.Add((New-Para ('• ' + (Strip-Md $matches[1])) 22)); continue }
  if ($line -match '^\*\*(.+)\*\*$') { $body.Add((New-Para (Strip-Md $matches[1]) 22 -Bold)); continue }
  $plain = Strip-Md $line
  if ($plain.Trim()) { $body.Add((New-Para $plain 22)) }
}
if ($tableRows.Count -gt 0) { $body.Add((New-Table @($tableRows.ToArray()))) }

$sectPr = @'
<w:sectPr>
  <w:pgSz w:w="11906" w:h="16838"/>
  <w:pgMar w:top="1440" w:right="1440" w:bottom="1440" w:left="1440" w:header="708" w:footer="708" w:gutter="0"/>
</w:sectPr>
'@

$documentXml = @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
  <w:body>
$($body -join "`n")
$sectPr
  </w:body>
</w:document>
"@

$contentTypes = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
  <Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>
</Types>
'@

$rels = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>
'@

$docRels = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
</Relationships>
'@

$styles = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:docDefaults>
    <w:rPrDefault><w:rPr><w:rFonts w:ascii="Calibri" w:hAnsi="Calibri" w:eastAsia="微软雅黑"/><w:sz w:val="22"/><w:szCs w:val="22"/></w:rPr></w:rPrDefault>
    <w:pPrDefault><w:pPr><w:spacing w:after="120"/></w:pPr></w:pPrDefault>
  </w:docDefaults>
</w:styles>
'@

New-Item -ItemType Directory -Path $workDir -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $workDir '_rels') -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $workDir 'word\_rels') -Force | Out-Null
[System.IO.File]::WriteAllText((Join-Path $workDir '[Content_Types].xml'), $contentTypes, [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText((Join-Path $workDir '_rels\.rels'), $rels, [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText((Join-Path $workDir 'word\document.xml'), $documentXml, [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText((Join-Path $workDir 'word\styles.xml'), $styles, [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText((Join-Path $workDir 'word\_rels\document.xml.rels'), $docRels, [System.Text.UTF8Encoding]::new($false))

if (Test-Path -LiteralPath $outPath) { Remove-Item -LiteralPath $outPath -Force }
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::CreateFromDirectory($workDir, $outPath)
Remove-Item -LiteralPath $workDir -Recurse -Force
Write-Output "OK: $outPath"
