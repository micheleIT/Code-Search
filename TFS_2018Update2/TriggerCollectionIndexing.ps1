[CmdletBinding()]
Param(
    [Parameter(Mandatory=$True, Position=0, HelpMessage="The Server Instance against which the script is to run.")]
    [string]$SQLServerInstance,
   
    [Parameter(Mandatory=$True, Position=1, HelpMessage="Collection Database name.")]
    [string]$CollectionDatabaseName,
    
    [Parameter(Mandatory=$True, Position=2, HelpMessage="Configuration DB")]
    [string]$ConfigurationDatabaseName,
   
    [Parameter(Mandatory=$True, Position=3, HelpMessage="Enter the Collection Name here.")]
    [string]$CollectionName,
    
    [Parameter(Mandatory=$False, Position=4, HelpMessage="Trigger collection indexing for Code, WorkItem or All")]
    [string]$EntityType = "All"
)

Import-Module .\Common.psm1 -Force

function TriggerCodeIndexing
{
    if(IsExtensionInstalled $SQLServerInstance $CollectionDatabaseName "IsCollectionIndexed")
    {
        $Params = "CollectionId='$CollectionID'"
        $SqlFullPath = Join-Path $PWD -ChildPath 'SqlScripts\CleanUpCollectionCodeIndexingState.sql'
        Invoke-Sqlcmd -InputFile $SqlFullPath -serverInstance $SQLServerInstance -database $CollectionDatabaseName
        Write-Host "Cleaned up the Code Collection Indexing state..." -ForegroundColor Yellow

        $SqlFullPath = Join-Path $PWD -ChildPath 'SqlScripts\QueueCodeExtensionInstallIndexing.sql'
        Invoke-Sqlcmd -InputFile $SqlFullPath -serverInstance $SQLServerInstance -database $ConfigurationDatabaseName  -Verbose -Variable $Params
        Write-Host "Successfully queued the code Indexing job for the collection!!" -ForegroundColor Green
    }
    else
    {
        Write-Host "No jobs queued. Please install the Code Search extension for the collection." -ForegroundColor DarkYellow
    }
}

function TriggerWorkItemIndexing
{
    if(IsExtensionInstalled $SQLServerInstance $CollectionDatabaseName "IsCollectionIndexedForWorkItem")
    {
        $Params = "CollectionId='$CollectionID'"
        $SqlFullPath = Join-Path $PWD -ChildPath 'SqlScripts\CleanUpCollectionWorkItemIndexingState.sql'
        Invoke-Sqlcmd -InputFile $SqlFullPath -serverInstance $SQLServerInstance -database $CollectionDatabaseName
        Write-Host "Cleaned up the WorkItem Collection Indexing state..." -ForegroundColor Yellow

        $SqlFullPath = Join-Path $PWD -ChildPath 'SqlScripts\QueueWorkItemExtensionInstallIndexing.sql'
        Invoke-Sqlcmd -InputFile $SqlFullPath -serverInstance $SQLServerInstance -database $ConfigurationDatabaseName  -Verbose -Variable $Params
        Write-Host "Successfully queued the WorkItem Indexing job for the collection!!" -ForegroundColor Green
    }
    else
    {
        Write-Host "No jobs queued. Please install the WorkItem search extension for the collection." -ForegroundColor DarkYellow
    }
}

function TriggerWikiIndexing
{
    if(IsExtensionInstalled $SQLServerInstance $CollectionDatabaseName "IsCollectionIndexedForWiki")
    {
        $Params = "CollectionId='$CollectionID'"
        $SqlFullPath = Join-Path $PWD -ChildPath 'SqlScripts\CleanUpCollectionWikiIndexingState.sql'
        Invoke-Sqlcmd -InputFile $SqlFullPath -serverInstance $SQLServerInstance -database $CollectionDatabaseName -Verbose -Variable $Params
        Write-Host "Cleaned up the Wiki Collection Indexing state..." -ForegroundColor Yellow

        $SqlFullPath = Join-Path $PWD -ChildPath 'SqlScripts\QueueWikiExtensionInstallIndexing.sql'
        Invoke-Sqlcmd -InputFile $SqlFullPath -serverInstance $SQLServerInstance -database $ConfigurationDatabaseName  -Verbose -Variable $Params
        Write-Host "Successfully queued the Wiki Indexing job for the collection!!" -ForegroundColor Green
    }
    else
    {
        Write-Host "No jobs queued. Please install the Wiki search extension for the collection." -ForegroundColor DarkYellow
    }
}

[System.ENVIRONMENT]::CurrentDirectory = $PWD
Push-Location
ImportSQLModule

$CollectionID = ValidateCollectionName $SQLServerInstance $ConfigurationDatabaseName $CollectionName

switch ($EntityType)
{
    "All" 
        {
            Write-Host "Triggering indexing for Code, WorkItem and Wiki..." -ForegroundColor Green
            TriggerCodeIndexing
            TriggerWorkItemIndexing
            TriggerWikiIndexing
        }
    "WorkItem" 
        {
            Write-Host "Triggering indexing for WorkItem..." -ForegroundColor Green
            TriggerWorkItemIndexing
        }
    "Code"
        {
            Write-Host "Triggering indexing for Code..." -ForegroundColor Green
            TriggerCodeIndexing
        }
    "Wiki"
        {
            Write-Host "Triggering indexing for Wiki..." -ForegroundColor Green
            TriggerWikiIndexing
        }
    default 
        {
            Write-Host "Enter a valid EntityType i.e. Code or WorkItem or Wiki or All" -ForegroundColor Red
        }
}

Pop-Location
