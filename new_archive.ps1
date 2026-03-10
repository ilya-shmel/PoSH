Function New-ZipArchive {
    [cmdletbinding(SupportsShouldProcess)]
    param(
        [Parameter(Position=0, Mandatory, HelpMessage="Enter the folder path to be archived.")]
        [ValidateScript({Test-Path $_})]
        [Alias("PSPath","Source")]
        [String]$Path,

        [Parameter(Position=1, Mandatory, HelpMessage="Enter the path and filename for the zip file")]
        [Alias("zip","Target")]
        [ValidateNotNullorEmpty()]
        [String]$OutputPath,

        [Switch]$Force,
        [switch]$Passthru
    )

    # If file exists and -Force key uses - remove the file
    if ($Force -AND (Test-Path -path $OutputPath)) {
        Remove-Item -Path $OutputPath
    }

    # Create a new empty ZIP file if we need
    if(-NOT (Test-Path $OutputPath)) {
        Try {
            # Create ZIP file (PKZIP signature)
            Set-Content -path $OutputPath -value ("PK" + [char]5 + [char]6 + ("$([char]0)" * 18)) -ErrorAction Stop
            $zipfile = $OutputPath | Get-Item -ErrorAction Stop
            $zipfile.IsReadOnly = $false
        }
        Catch {
            Write-Warning "Не удалось создать $outputpath"
            return
        }
    }
    else {
        Write-Warning "Файл $OutputPath уже существует. Удалите его или используйте -Force."
        return
    }

    # Archive with Shell.Application
    if ($PSCmdlet.ShouldProcess($Path)) {
        $shellApp = New-Object -com shell.application
        $zipPackage = $shellApp.NameSpace($zipfile.fullname)
        $target = Get-Item -Path $Path
        $zipPackage.CopyHere($target.FullName)

        # Return the created zip info
        If ($passthru) {
            Start-Sleep -Milliseconds 200
            Get-Item -Path $Outputpath
        }
    }
}

# Simple running
New-ZipArchive -Path "C:\MyFolder" -OutputPath "C:\MyZip.zip"

# Wordy output and force rewrite
New-ZipArchive -Path "C:\MyFolder" -OutputPath "C:\MyZip.zip" -Verbose -Force -Passthru