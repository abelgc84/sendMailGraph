[CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [object]$ToUser,

    [Parameter(Mandatory=$true, Position=1)]
    [string]$FromUser,

    [Parameter(Mandatory=$true, Position=2)]
    [string]$Subject,

    [Parameter(Mandatory=$true, Position=3)]
    [string]$HtmlBody,

    [Parameter(Mandatory=$false, Position=4)]
    [object]$CcUser,

    [Parameter(Mandatory=$false, Position=5)]
    [string]$AttachmentPath
)

# --- CONFIGURACIÓN INTERNA ---
$LogPath = "C:\COMANDOS POWERSHELL\sendMailGraph_log.txt" # Reemplazar con la ruta deseada del archivo de log

# --- VARIABLES DE AUTENTICACIÓN GRAPH ---
$Thumb = "****************************************" # Reemplazar con el thumbprint real del certificado
$TenantId = "********-****-****-****-************" # Reemplazar con el Tenant ID real
$ClientIdGraph = "********-****-****-****-************" # Reemplazar con el Client ID real

# --- FUNCIÓN DE LOG INTERNA ---
function Write-LocalLog {
    param (
        [string]$Message,
        [ValidateSet("INFO", "ERROR", "EXITO")]
        [string]$Level = "INFO"
    )
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $Entry = "[$Timestamp] [$Level] $Message"
    
    try {
        $Entry | Out-File -FilePath $LogPath -Append -Encoding utf8 -ErrorAction SilentlyContinue
    }
    catch {
        Write-Warning "No se pudo escribir en el archivo de log: $LogPath"
    }
}

try {
    Write-LocalLog -Message "Iniciando proceso de envío. De: $FromUser | Para: $($ToUser -join ';')" -Level "INFO"

    # Función auxiliar para asegurar que tengamos un array de strings limpio
    function Get-CleanArray {
        param($InputObject)
        if ($null -eq $InputObject) { return @() }
        if ($InputObject -is [string]) {
            return $InputObject.Split(',') | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }
        }
        return $InputObject | ForEach-Object { $_.ToString().Trim() }
    }

    $cleanTo = Get-CleanArray -InputObject $ToUser
    $cleanCc = Get-CleanArray -InputObject $CcUser

    # Importación de módulos necesarios
    Import-Module Microsoft.Graph.Authentication -ErrorAction SilentlyContinue
    Import-Module Microsoft.Graph.Users.Actions -ErrorAction SilentlyContinue

    # Conexión a Microsoft Graph
    Connect-MgGraph -TenantId $TenantId -ClientId $ClientIdGraph -CertificateThumbprint $Thumb -NoWelcome -ErrorAction Stop

    # Construir ToRecipients
    $toRecipients = $cleanTo | ForEach-Object {
        @{ EmailAddress = @{ Address = $_ } }
    }

    # Construir mensaje BASE sin CcRecipients
    $mailMessage = [ordered]@{
        Subject      = $Subject
        Body         = @{ ContentType = "HTML"; Content = $HtmlBody }
        ToRecipients = @($toRecipients)  
    }

    # Añadir CcRecipients SOLO si hay destinatarios
    if ($cleanCc.Count -gt 0) {
        $ccRecipients = @($cleanCc | ForEach-Object {
            @{ EmailAddress = @{ Address = $_ } }
        })
        $mailMessage["CcRecipients"] = $ccRecipients  
        Write-LocalLog -Message "CcRecipients añadidos: $($cleanCc -join ', ')" -Level "INFO"
    }

    # Procesamiento de adjuntos
    if (-not [string]::IsNullOrWhiteSpace($AttachmentPath) -and (Test-Path $AttachmentPath)) {
        $fileBytes = [System.IO.File]::ReadAllBytes($AttachmentPath)
        $base64 = [System.Convert]::ToBase64String($fileBytes)
        $fileName = Split-Path $AttachmentPath -Leaf

        $mailMessage.Attachments = @(
            @{
                "@odata.type" = "#microsoft.graph.fileAttachment"
                Name          = $fileName
                ContentType   = "application/octet-stream"
                ContentBytes  = $base64
            }
        )
        Write-LocalLog -Message "Adjunto procesado: $fileName" -Level "INFO"
    }

    # Envío del correo
    $sendParams = @{
        UserId          = $FromUser
        BodyParameter   = @{ Message = $mailMessage; SaveToSentItems = $true }
        ErrorAction     = 'Stop'
    }

    Send-MgUserMail @sendParams
    
    $ccMsg = if ($cleanCc.Count -gt 0) { " | CC: $($cleanCc -join ', ')" } else { "" }
    $successMsg = "EXITO: Correo enviado correctamente a: $($cleanTo -join ', ')$ccMsg"
    Write-LocalLog -Message $successMsg -Level "EXITO"
    Write-Output $successMsg
}
catch {
    $errMsg = $_.Exception.Message
    if ($null -ne $_.Exception.InnerException) { $errMsg += " | " + $_.Exception.InnerException.Message }
    
    $logError = "ERROR al enviar correo: $errMsg"
    Write-LocalLog -Message $logError -Level "ERROR"
    Write-Error $logError
}