param (
    [Parameter(Mandatory)][string]$sourceFolder,
    [Parameter(Mandatory)][string]$replicaFolder,
    [Parameter(Mandatory)][string]$logFile        
)

# Function to log messages with a clear, concise, and insightful tone
function Log-Message {
    param (
        [string]$message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp - $message"
    Add-Content -Path $logFile -Value $logMessage
    Write-Output $logMessage  # Also echoing the log to console for real-time feedback
}

# Attempt to create or access the log file
try {
    if (-Not (Test-Path -Path $logFile)) {
        Write-Output "Creating log file at '$logFile' as it does not exist."
        New-Item -ItemType File -Path $logFile -Force > $null
        Log-Message "Log file successfully created at '$logFile'."
    }
} catch {
    Write-Output "Could not create or access log file '$logFile'. Please check file permissions or path. Error: $_"
    exit 1
}

# Ensure the source folder exists
if (-Not (Test-Path -Path $sourceFolder)) {
    Log-Message "Error: Source folder '$sourceFolder' does not exist. Exiting gracefully."
    exit 1
}

# Ensure the replica folder exists, or try to create it
if (-Not (Test-Path -Path $replicaFolder)) {
    try {
        Log-Message "Replica folder '$replicaFolder' does not exist. Attempting to create the folder."
        New-Item -ItemType Directory -Path $replicaFolder -ErrorAction Stop > $null
        Log-Message "Replica folder created at '$replicaFolder'."
    } catch {
        Log-Message "Failed to create replica folder '$replicaFolder'. Exiting script. Error: $_"
        exit 1
    }
}

# Function to synchronize folders with thoughtful logging and clarity
function Sync-Folders {
    param (
        [string]$source,
        [string]$replica
    )

    $sourceItems = Get-ChildItem -Path $source -Recurse
    $replicaItems = Get-ChildItem -Path $replica -Recurse

    try {
        # Synchronize files from source to replica
        foreach ($sourceItem in $sourceItems) {
            $relativePath = $sourceItem.FullName.Substring($source.Length + 1)
            $replicaItemPath = Join-Path -Path $replica -ChildPath $relativePath

            $replicaItem = $replicaItems | Where-Object { $_.FullName -eq $replicaItemPath }

            if (-not $replicaItem) {
                if ($sourceItem.PSIsContainer) {
                    New-Item -ItemType Directory -Path $replicaItemPath > $null
                    Log-Message "Created new directory at '$replicaItemPath' to mirror the source."
                } else {
                    Copy-Item -Path $sourceItem.FullName -Destination $replicaItemPath
                    Log-Message "Copied file '$($sourceItem.FullName)' to replica '$replicaItemPath'."
                }
            } elseif (-not $sourceItem.PSIsContainer) {
                Copy-Item -Path $sourceItem.FullName -Destination $replicaItemPath -Force
                Log-Message "Updated file '$($sourceItem.FullName)' in the replica."
            }
        }

        # Remove items from replica that are no longer in the source
        foreach ($replicaItem in $replicaItems) {
            $relativePath = $replicaItem.FullName.Substring($replica.Length + 1)
            $sourceItemPath = Join-Path -Path $source -ChildPath $relativePath

            $sourceExists = $sourceItems | Where-Object { $_.FullName -eq $sourceItemPath }

            if (-not $sourceExists) {
                if ($replicaItem.PSIsContainer) {
                    Remove-Item -Path $replicaItem.FullName -Recurse -Force
                    Log-Message "Removed directory '$($replicaItem.FullName)' from the replica as it no longer exists in the source."
                } else {
                    Remove-Item -Path $replicaItem.FullName -Force
                    Log-Message "Removed file '$($replicaItem.FullName)' from the replica since it was deleted from the source."
                }
            }
        }
    } catch {
        Log-Message "An error occurred during synchronization. Details: $_"
    }
}

# Start synchronization with clear messages and smart logging
Log-Message "Initiating synchronization from '$sourceFolder' to '$replicaFolder'."
Sync-Folders -source $sourceFolder -replica $replicaFolder
Log-Message "Synchronization completed successfully."
Write-Output "Synchronization process has been completed. All operations logged at '$logFile'."
