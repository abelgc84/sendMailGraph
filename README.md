# sendMailGraph

Script reutilizable en PowerShell para enviar correos electrónicos mediante Microsoft Graph desde otros scripts de automatización.

## Descripción

`sendMailGraph.ps1` permite enviar correos HTML utilizando Microsoft Graph y autenticación mediante certificado. Está pensado como un módulo auxiliar para integrarse fácilmente en otros scripts, por ejemplo procesos de reporting, monitorización, backup, auditoría o automatizaciones corporativas.

## Características

- Envío de correos mediante Microsoft Graph.
- Soporte para cuerpo HTML.
- Destinatarios múltiples.
- Copia CC opcional.
- Envío de adjuntos.
- Autenticación con certificado.
- Registro de ejecución en log.
- Control básico de errores.

## Tecnologías

- PowerShell
- Microsoft Graph PowerShell SDK
- Microsoft 365
- Autenticación mediante certificado
- HTML
- Logging

## Uso básico

```powershell
.\sendMailGraph.ps1 `
    -ToUser "usuario@dominio.com" `
    -FromUser "remitente@dominio.com" `
    -Subject "Informe automático" `
    -HtmlBody "<h1>Proceso finalizado</h1><p>El script terminó correctamente.</p>"
```

## Uso con varios destinatarios

```powershell
.\sendMailGraph.ps1 `
    -ToUser "usuario1@dominio.com,usuario2@dominio.com" `
    -FromUser "remitente@dominio.com" `
    -Subject "Notificación automática" `
    -HtmlBody "<p>Correo enviado desde Microsoft Graph.</p>"
```

## Uso con CC y adjunto

```powershell
.\sendMailGraph.ps1 `
    -ToUser "usuario@dominio.com" `
    -FromUser "remitente@dominio.com" `
    -Subject "Informe con adjunto" `
    -HtmlBody "<p>Se adjunta el informe generado.</p>" `
    -CcUser "responsable@dominio.com" `
    -AttachmentPath "C:\Informes\reporte.csv"
```

## Parámetros

| Parámetro | Obligatorio | Descripción |
|---|---|---|
| `ToUser` | Sí | Destinatario o lista de destinatarios. Puede recibir una cadena separada por comas. |
| `FromUser` | Sí | Cuenta desde la que se envía el correo. |
| `Subject` | Sí | Asunto del correo. |
| `HtmlBody` | Sí | Cuerpo del correo en formato HTML. |
| `CcUser` | No | Destinatario o lista de destinatarios en copia. |
| `AttachmentPath` | No | Ruta local del archivo adjunto. |

## Configuración previa

Antes de utilizar el script es necesario configurar las variables internas:

```powershell
$Thumb = "THUMBPRINT_CERTIFICADO"
$TenantId = "TENANT_ID"
$ClientIdGraph = "CLIENT_ID_APP"
```

También se debe ajustar la ruta del log:

```powershell
$LogPath = "C:\COMANDOS POWERSHELL\sendMailGraph_log.txt"
```

## Requisitos

Instalar los módulos necesarios:

```powershell
Install-Module Microsoft.Graph.Authentication -Scope CurrentUser
Install-Module Microsoft.Graph.Users.Actions -Scope CurrentUser
```

La aplicación registrada en Microsoft Entra ID debe tener permisos para enviar correo mediante Microsoft Graph.

Permiso habitual:

```text
Mail.Send
```

## Integración desde otros scripts

Este script está pensado para ser llamado desde otros procesos:

```powershell
& ".\sendMailGraph.ps1" `
    -ToUser $destinatarios `
    -FromUser $remitente `
    -Subject $asunto `
    -HtmlBody $html `
    -AttachmentPath $rutaAdjunto
```

## Ejemplo de uso en automatizaciones

Puede utilizarse en scripts que generen:

- Informes CSV.
- Alertas de errores.
- Reportes de backup.
- Avisos de monitorización.
- Resultados de auditorías.
- Notificaciones de procesos programados.

## Logs

El script registra eventos de ejecución en un archivo de log, incluyendo:

- Inicio del proceso.
- Destinatarios.
- CC añadidos.
- Adjuntos procesados.
- Envío correcto.
- Errores durante la ejecución.
