# scripts\move_unsaved_files.ps1

# Caminho base de onde os arquivos são salvos automaticamente pelo SQL Developer
$baseSourcePath = "C:\JobOne173Docker\object\JOBONE_V4"

# Caminho base do seu projeto versionado
$baseDestinationPath = "C:\projetos\jobone\versionamento_bd_operacional"

# Lista todos os arquivos .pkb e .pks modificados recentemente (últimos 1 minuto)
$changedFiles = Get-ChildItem -Path $baseSourcePath -Recurse -Include *.pkb, *.pks |
    Where-Object { $_.LastWriteTime -gt (Get-Date).AddMinutes(-1) }

foreach ($file in $changedFiles) {
    # Descobre se é BODY ou SPEC
    $extension = $file.Extension.ToLower()
    if ($extension -eq ".pkb") {
        $subfolder = "Packages\Body"
    } elseif ($extension -eq ".pks") {
        $subfolder = "Packages\Spec"
    } else {
        continue
    }

    # Nome do objeto (ex: ABATIMENTO_PKG.pkb)
    $fileName = $file.Name

    # Cria o caminho de destino completo
    $destinationDir = Join-Path -Path $baseDestinationPath -ChildPath $subfolder
    $destinationPath = Join-Path -Path $destinationDir -ChildPath $fileName

    # Garante que a pasta de destino exista
    if (-not (Test-Path $destinationDir)) {
        New-Item -ItemType Directory -Path $destinationDir -Force | Out-Null
    }

    # Copia o arquivo
    Copy-Item -Path $file.FullName -Destination $destinationPath -Force
    Write-Host "Arquivo '$fileName' movido para '$destinationDir'"
}

Write-Host "`nTodos os arquivos recentes foram processados com sucesso!"
