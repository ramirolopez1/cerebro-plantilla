<#
.SYNOPSIS
  Auditoria de secretos y datos sensibles del cerebro.

.DESCRIPTION
  Revisa los archivos que irian al repo (seguidos por git y nuevos no ignorados)
  o solo los preparados para commit (-Staged). Busca claves, tokens, direcciones
  de red, enlaces, dominios, correos, telefonos, rutas de red, numeros de
  documento y las palabras de la lista privada, que es opcional
  (sistema/privado/palabras-prohibidas.txt, una por linea, nunca se sube).

  Los nombres de personas y los montos no tienen regla: lo decide el dueño en
  yo/limites-para-agentes.md. Las IP de la red local y de Tailscale pueden
  estar; las IP publicas, no.
  Las direcciones postales no se pueden detectar con un patron: se revisan a mano.

  Sale con codigo 0 si no encontro nada y con 1 si encontro algo.
  Por defecto muestra cada hallazgo recortado; con -Detalle muestra el texto completo.

  Este archivo queda fuera de la revision de contenido porque contiene los patrones.
  Compatible con Windows PowerShell 5.1 y PowerShell 7. Solo ASCII a proposito.

.EXAMPLE
  powershell -NoProfile -File sistema\auditar-secretos.ps1
  powershell -NoProfile -File sistema\auditar-secretos.ps1 -Staged
#>
param(
    [switch]$Staged,
    [switch]$Detalle
)

$ErrorActionPreference = 'Stop'
$raiz = Split-Path -Parent $PSScriptRoot
Set-Location $raiz

$yoMismo = 'sistema/auditar-secretos.ps1'
$manifiesto = 'sistema/manifiesto.json'

# --- Archivos a revisar -------------------------------------------------------
if ($Staged) {
    $archivos = @(git diff --cached --name-only --diff-filter=ACMR)
} else {
    $archivos = @(git ls-files --cached --others --exclude-standard)
}
$archivos = @($archivos | Where-Object { $_ -and (Test-Path -LiteralPath $_ -PathType Leaf) })

# --- Listas locales -----------------------------------------------------------
$permitidos = @()
$rutaPermitidos = Join-Path $PSScriptRoot 'permitidos.txt'
if (Test-Path -LiteralPath $rutaPermitidos) {
    $permitidos = @(Get-Content -LiteralPath $rutaPermitidos -Encoding UTF8 |
        ForEach-Object { $_.Trim() } | Where-Object { $_ -and -not $_.StartsWith('#') })
}

$prohibidas = @()
$rutaProhibidas = Join-Path $PSScriptRoot 'privado\palabras-prohibidas.txt'
if (Test-Path -LiteralPath $rutaProhibidas) {
    $prohibidas = @(Get-Content -LiteralPath $rutaProhibidas -Encoding UTF8 |
        ForEach-Object { $_.Trim() } | Where-Object { $_ -and -not $_.StartsWith('#') })
}

# --- Reglas -------------------------------------------------------------------
$tld = 'com|net|org|ar|io|dev|app|xyz|me|info|co|tv|online|site|store|tech|cloud|ai|edu|gob|gov|uk|es|br|us|link|page|local|lan|internal|home'
$reglas = @(
    @{ Nombre = 'clave-privada';   Patron = '-----BEGIN [A-Z ]*PRIVATE KEY-----' },
    @{ Nombre = 'token-github';    Patron = '\b(ghp|gho|ghu|ghs|ghr)_[A-Za-z0-9]{20,}|\bgithub_pat_[A-Za-z0-9_]{20,}' },
    @{ Nombre = 'token-api';       Patron = '\bsk-[A-Za-z0-9_\-]{20,}|\bAKIA[0-9A-Z]{16}\b|\bAIza[0-9A-Za-z_\-]{30,}|\bxox[baprs]-[A-Za-z0-9\-]{10,}' },
    @{ Nombre = 'token-jwt';       Patron = '\beyJ[A-Za-z0-9_\-]{10,}\.[A-Za-z0-9_\-]{10,}\.' },
    @{ Nombre = 'asignacion-secreta'; Patron = '(?i)\b(password|passwd|pwd|contrase(\u00f1|n)a|clave|secret|secreto|token|api[_-]?key)\b\s*[:=]\s*["'']?(?=[^\s"'']*\d)[A-Za-z0-9_\-+/=.!@#%&*]{10,}' },
    @{ Nombre = 'cadena-larga';    Patron = '[A-Za-z0-9+_=\-]{40,}|[A-Za-z0-9+/]{60,}={0,2}'; MinDigitos = 3; Ignorar = '^\d{4}-\d{2}-\d{2}_\d{4}_[a-z0-9_\-]+$'; Excluir = @($manifiesto) },
    # Las IP privadas (red local, Tailscale, loopback) se permiten: van en el inventario de accesos.
    @{ Nombre = 'direccion-ip-publica'; Patron = '(?<![\d.])(\d{1,3}\.){3}\d{1,3}(?![\d.])'; Ignorar = '^(10\.|127\.|192\.168\.|169\.254\.|172\.(1[6-9]|2\d|3[01])\.|100\.(6[4-9]|[7-9]\d|1[01]\d|12[0-7])\.|0\.0\.0\.0$|255\.)' },
    @{ Nombre = 'direccion-mac';   Patron = '\b([0-9A-Fa-f]{2}[:-]){5}[0-9A-Fa-f]{2}\b' },
    @{ Nombre = 'enlace';          Patron = '(?i)\b(https?|ftp|sftp|ssh|smb|wss?)://' },
    @{ Nombre = 'dominio';         Patron = "(?i)(?<![\w@/\\.\-])([a-z0-9\-]+\.)+($tld)\b(?![\w\-])" },
    @{ Nombre = 'correo';          Patron = '[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}' },
    @{ Nombre = 'telefono';        Patron = '(?<![\w.])\+\d{2}[\d\s\-]{6,}|\b\d{10,}\b'; Excluir = @($manifiesto) },
    @{ Nombre = 'ruta-de-red';     Patron = '(?<![\w:\\])\\\\[A-Za-z0-9._\-]+\\[^\s\\]+' },
    @{ Nombre = 'documento';       Patron = '\b\d{2}\.\d{3}\.\d{3}\b|\b\d{2}-\d{8}-\d\b' },
    @{ Nombre = 'artifact';        Patron = '(?i)artifacts?/[0-9a-f\-]{8,}' }
)

$nombresProhibidos = '(?i)(^|/)(\.env(\..+)?|id_rsa.*|id_ed25519.*|.*\.(pem|key|pfx|p12|kdbx|sqlite|sqlite3|db|ovpn))$'
$binarios = '(?i)\.(png|jpg|jpeg|gif|webp|pdf|zip|7z|rar|exe|dll|mp4|mp3|wav|docx|xlsx|pptx|bin)$'

$hallazgos = New-Object System.Collections.ArrayList
function Agregar-Hallazgo($archivo, $linea, $regla, $texto) {
    if (-not $Detalle -and $texto.Length -gt 8) {
        $texto = $texto.Substring(0, 6) + '...(' + $texto.Length + ' caracteres)'
    }
    [void]$hallazgos.Add([pscustomobject]@{ Archivo = $archivo; Linea = $linea; Regla = $regla; Texto = $texto })
}

# --- Nada privado seguido por git --------------------------------------------
$privadosSeguidos = @(git ls-files -- 'sistema/privado')
foreach ($p in $privadosSeguidos) { Agregar-Hallazgo $p 0 'privado-en-git' 'sistema/privado no se sube' }

# --- Revision -----------------------------------------------------------------
$revisados = 0
foreach ($a in $archivos) {
    $rel = $a -replace '\\', '/'
    if ($rel -match $nombresProhibidos) { Agregar-Hallazgo $rel 0 'archivo-prohibido' $rel; continue }
    if ($rel -match $binarios) { Agregar-Hallazgo $rel 0 'binario-inesperado' $rel; continue }
    if ($rel -eq $yoMismo) { continue }
    # Documentos de la plantilla (instrucciones de uso): no son parte del cerebro; se pueden borrar despues de armarlo.
    if ($rel -match '^(README|GUIA-PASO-A-PASO|PROMPT-PARA-CLAUDE-CODE)\.md$') { continue }

    $revisados++
    $lineas = [System.IO.File]::ReadAllLines((Join-Path $raiz $a), [System.Text.Encoding]::UTF8)
    for ($i = 0; $i -lt $lineas.Count; $i++) {
        $l = $lineas[$i]
        if (-not $l) { continue }
        foreach ($r in $reglas) {
            if ($r.Excluir -and ($r.Excluir -contains $rel)) { continue }
            foreach ($m in [regex]::Matches($l, $r.Patron)) {
                if ($permitidos -contains $m.Value.Trim()) { continue }
                if ($r.Ignorar -and ($m.Value -match $r.Ignorar)) { continue }
                if ($r.MinDigitos -and ([regex]::Matches($m.Value, '\d').Count -lt $r.MinDigitos)) { continue }
                Agregar-Hallazgo $rel ($i + 1) $r.Nombre $m.Value
            }
        }
        foreach ($p in $prohibidas) {
            $pat = '(?i)(?<![\w])' + [regex]::Escape($p) + '(?![\w])'
            if ([regex]::IsMatch($l, $pat)) { Agregar-Hallazgo $rel ($i + 1) 'palabra-prohibida' $p }
        }
    }
}

# --- Resultado ----------------------------------------------------------------
$modo = 'repo completo'
if ($Staged) { $modo = 'solo lo preparado para commit' }
Write-Output ("Auditoria de secretos - {0} - {1}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm'), $modo)
Write-Output ("Archivos revisados: {0} | Reglas: {1} | Palabras prohibidas cargadas: {2} | Excepciones permitidas: {3}" -f $revisados, $reglas.Count, $prohibidas.Count, $permitidos.Count)

if ($hallazgos.Count -eq 0) {
    Write-Output 'Resultado: LIMPIO. Sin hallazgos.'
    exit 0
}

Write-Output ("Resultado: {0} HALLAZGOS. No subir hasta resolverlos." -f $hallazgos.Count)
$hallazgos | Sort-Object Archivo, Linea | ForEach-Object {
    Write-Output ("  {0}:{1}  [{2}]  {3}" -f $_.Archivo, $_.Linea, $_.Regla, $_.Texto)
}
exit 1
