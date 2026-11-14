<#
.SYNOPSIS
  Revisa los enlaces internos del cerebro y el aislamiento de cada proyecto.

.DESCRIPTION
  1. Todo enlace relativo de un .md tiene que apuntar a un archivo o carpeta que exista.
  2. Las paginas de proyectos/<nombre>/ solo enlazan dentro de su carpeta.
     La unica excepcion es su INDICE.md, que lleva las salidas explicitas.
  3. CLAUDE.md y AGENTS.md tienen que ser copias exactas.
  4. Ninguna pagina queda huerfana: toda pagina tiene que estar enlazada desde otra.

  Sale con 0 si esta todo bien y con 1 si hay algo roto.
  Compatible con Windows PowerShell 5.1 y PowerShell 7. Solo ASCII a proposito.
#>
$ErrorActionPreference = 'Stop'
$raiz = (Resolve-Path (Split-Path -Parent $PSScriptRoot)).Path
$problemas = New-Object System.Collections.ArrayList
$enlaces = 0
$enlazadas = @{}

$archivos = Get-ChildItem -LiteralPath $raiz -Recurse -File -Filter *.md |
    Where-Object { $_.FullName -notmatch '\\\.git\\' -and $_.FullName -notmatch '\\sistema\\privado\\' }

foreach ($f in $archivos) {
    $rel = $f.FullName.Substring($raiz.Length + 1).Replace('\', '/')
    $texto = [System.IO.File]::ReadAllText($f.FullName, [System.Text.Encoding]::UTF8)
    # Quitar bloques de codigo: los ejemplos no son enlaces
    $texto = [regex]::Replace($texto, '(?s)```.*?```', '')
    $proyecto = $null
    if ($rel -match '^proyectos/([^/]+)/') { $proyecto = $Matches[1] }

    foreach ($m in [regex]::Matches($texto, '\]\(([^)\s]+)\)')) {
        $destino = $m.Groups[1].Value
        if ($destino -match '^(#|mailto:)' -or $destino -match '^[a-z]+://') { continue }
        $enlaces++
        $sinAncla = ($destino -split '#')[0]
        if (-not $sinAncla) { continue }
        $abs = [System.IO.Path]::GetFullPath((Join-Path $f.DirectoryName $sinAncla))
        if (-not (Test-Path -LiteralPath $abs)) {
            [void]$problemas.Add(("ROTO      {0} -> {1}" -f $rel, $destino))
            continue
        }
        if ($abs -ne $f.FullName) { $enlazadas[$abs.ToLowerInvariant()] = $true }
        if ($proyecto) {
            $base = Join-Path $raiz ("proyectos\" + $proyecto)
            $adentro = $abs.StartsWith($base, [System.StringComparison]::OrdinalIgnoreCase)
            if (-not $adentro -and $f.Name -ne 'INDICE.md') {
                [void]$problemas.Add(("SALE      {0} -> {1} (solo INDICE.md puede salir del proyecto)" -f $rel, $destino))
            }
        }
    }
}

$c = Join-Path $raiz 'CLAUDE.md'; $a = Join-Path $raiz 'AGENTS.md'
if ((Test-Path $c) -and (Test-Path $a)) {
    if ((Get-FileHash $c).Hash -ne (Get-FileHash $a).Hash) {
        [void]$problemas.Add('DISTINTOS CLAUDE.md y AGENTS.md no son copias exactas')
    }
} else {
    [void]$problemas.Add('FALTA     CLAUDE.md o AGENTS.md en la raiz')
}

foreach ($d in (Get-ChildItem -LiteralPath (Join-Path $raiz 'proyectos') -Directory)) {
    if (-not (Test-Path (Join-Path $d.FullName 'INDICE.md'))) {
        [void]$problemas.Add(("FALTA     proyectos/{0}/INDICE.md" -f $d.Name))
    }
}

# Paginas huerfanas: las que ninguna otra pagina enlaza.
# No cuentan los indices de la raiz, lo ya procesado del buzon, las notas sueltas
# del buzon ni los informes fechados de la revision semanal.
foreach ($f in $archivos) {
    $rel = $f.FullName.Substring($raiz.Length + 1).Replace('\', '/')
    if ($rel -match '^(AGENTS|CLAUDE|GEMINI|README|GUIA-PASO-A-PASO|PROMPT-PARA-CLAUDE-CODE)\.md$') { continue }
    if ($rel -match '^buzon/procesado/') { continue }
    if ($rel -match '^buzon/[^/]+\.md$' -and $rel -ne 'buzon/README.md') { continue }
    if ($rel -match '^sistema/informes/\d{4}-') { continue }
    if (-not $enlazadas.ContainsKey($f.FullName.ToLowerInvariant())) {
        [void]$problemas.Add(("HUERFANA  {0} (ninguna pagina la enlaza)" -f $rel))
    }
}

Write-Output ("Enlaces - {0} paginas, {1} enlaces internos revisados" -f $archivos.Count, $enlaces)
if ($problemas.Count -eq 0) { Write-Output 'Resultado: todo bien.'; exit 0 }
Write-Output ("Resultado: {0} problemas." -f $problemas.Count)
$problemas | ForEach-Object { Write-Output ("  " + $_) }
exit 1
