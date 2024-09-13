param (
    [string]$SourceFolder,
    [string]$ReplicaFolder,
    [string]$LogFile
)

# Initialize logging
if (-not (Test-Path $LogFile)) {
    "" | Out-File -FilePath $LogFile
}

# Start logging to console and log file
Start-Transcript -Path $LogFile -Append

try {
    # Synchronize folders
    $sourceItems = Get-ChildItem -Path $SourceFolder -Recurse
    $replicaItems = Get-ChildItem -Path $ReplicaFolder -Recurse

    # Copy files from source to replica
    foreach ($sourceItem in $sourceItems) {
        $replicaPath = $sourceItem.FullName.Replace($SourceFolder, $ReplicaFolder)
        if (-not (Test-Path $replicaPath) -or ($sourceItem.LastWriteTime -ne (Get-Item $replicaPath).LastWriteTime)) {
            # Ensure the directory exists
            $replicaDir = Split-Path $replicaPath -Parent
            if (-not (Test-Path $replicaDir)) {
                New-Item -Path $replicaDir -ItemType Directory -Force
            }
            Copy-Item -Path $sourceItem.FullName -Destination $replicaPath -Force
            Write-Output "Copied: $($sourceItem.FullName) to $replicaPath"
        }
    }

    # Remove files from replica that are not in source
    foreach ($replicaItem in $replicaItems) {
        $sourcePath = $replicaItem.FullName.Replace($ReplicaFolder, $SourceFolder)
        if (-not (Test-Path $sourcePath)) {
            Remove-Item -Path $replicaItem.FullName -Force
            Write-Output "Removed: $($replicaItem.FullName)"
        }
    }
}
finally {
    # Stop logging to console
    Stop-Transcript
}
