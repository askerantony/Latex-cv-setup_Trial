# ============================================
# LaTeX CV Setup
# ============================================

Write-Host "============================================"
Write-Host "       LaTeX CV Setup"
Write-Host "============================================"
Write-Host ""

# --------------------------------------------
# Operating System Detection
# --------------------------------------------

if ($env:OS -eq "Windows_NT") {
    Write-Host "Operating System: Windows"
}
elseif ($IsMacOS) {
    Write-Host "Operating System: macOS"
}
elseif ($IsLinux) {
    Write-Host "Operating System: Linux"
}
else {
    Write-Host "Unsupported operating system."
    exit 1
}

Write-Host ""

# --------------------------------------------
# WinGet Detection
# --------------------------------------------

if ($env:OS -eq "Windows_NT") {

    Write-Host "Checking for WinGet..."

    $winget = Get-Command winget -ErrorAction SilentlyContinue

    if ($null -eq $winget) {
        Write-Host ""
        Write-Host "ERROR: WinGet was not found."
        Write-Host "Please install or enable WinGet and run this setup again."
        exit 1
    }

    Write-Host "WinGet found."
    Write-Host "WinGet path: $($winget.Source)"

    $wingetVersion = winget --version

    Write-Host "WinGet version: $wingetVersion"
}

Write-Host ""

# --------------------------------------------
# Required Software
# --------------------------------------------

$requiredSoftware = @(
    @{
        Name = "Git"
        Id = "Git.Git"
        Command = "git"
    },
    @{
        Name = "Visual Studio Code"
        Id = "Microsoft.VisualStudioCode"
        Command = "code"
    },
    @{
        Name = "MiKTeX"
        Id = "MiKTeX.MiKTeX"
        Command = "pdflatex"
    }
)

# --------------------------------------------
# Ask User For Permission
# --------------------------------------------

function Ask-YesNo {
    param(
        [string]$Question
    )

    while ($true) {

        $answer = Read-Host "$Question [Y/N]"

        if ($answer -match '^[Yy]$') {
            return $true
        }

        if ($answer -match '^[Nn]$') {
            return $false
        }

        Write-Host "Please enter Y or N."
    }
}

# --------------------------------------------
# Installation Function
# --------------------------------------------

function Install-WingetPackage {
    param(
        [string]$Name,
        [string]$Id
    )

    Write-Host ""
    Write-Host "Installing $Name..."
    Write-Host ""

    try {

        winget install `
            --id $Id `
            --exact `
            --source winget `
            --accept-source-agreements `
            --accept-package-agreements

        if ($LASTEXITCODE -eq 0) {

            Write-Host ""
            Write-Host "$Name installation completed successfully."

            return $true
        }
        else {

            Write-Host ""
            Write-Host "$Name installation failed."
            Write-Host "WinGet exit code: $LASTEXITCODE"

            return $false
        }

    }
    catch {

        Write-Host ""
        Write-Host "An error occurred while installing $Name."
        Write-Host $_.Exception.Message

        return $false
    }
}

# --------------------------------------------
# Check And Install Software
# --------------------------------------------

Write-Host "Checking required software..."
Write-Host ""

$installed = @()
$skipped = @()
$failed = @()

foreach ($software in $requiredSoftware) {

    $command = Get-Command $software.Command -ErrorAction SilentlyContinue

    if ($null -ne $command) {

        Write-Host "[INSTALLED] $($software.Name)"
        $installed += $software.Name

    }
    else {

        Write-Host ""
        Write-Host "[MISSING] $($software.Name)"
        Write-Host "WinGet ID: $($software.Id)"

        $permission = Ask-YesNo "Install $($software.Name) using WinGet?"

        if ($permission) {

            $result = Install-WingetPackage `
                -Name $software.Name `
                -Id $software.Id

            if ($result) {
                $installed += $software.Name
            }
            else {
                $failed += $software.Name
            }

        }
        else {

            Write-Host "Skipped $($software.Name)."
            $skipped += $software.Name
        }
    }
}

# --------------------------------------------
# LaTeX Workshop Extension
# --------------------------------------------

Write-Host ""
Write-Host "Checking LaTeX Workshop extension..."

$latexWorkshopId = "james-yu.latex-workshop"

$codeCommand = Get-Command code -ErrorAction SilentlyContinue

if ($null -eq $codeCommand) {

    Write-Host "[SKIPPED] VS Code command was not found."

}
else {

    $extensions = code --list-extensions 2>$null

    if ($extensions -contains $latexWorkshopId) {

        Write-Host "[INSTALLED] LaTeX Workshop"

        $installed += "LaTeX Workshop"

    }
    else {

        Write-Host "[MISSING] LaTeX Workshop"
        Write-Host "Extension ID: $latexWorkshopId"

        $permission = Ask-YesNo "Install LaTeX Workshop extension?"

        if ($permission) {

            Write-Host ""
            Write-Host "Installing LaTeX Workshop..."

            code --install-extension $latexWorkshopId --force

            if ($LASTEXITCODE -eq 0) {

                Write-Host ""
                Write-Host "LaTeX Workshop installed successfully."

                $installed += "LaTeX Workshop"

            }
            else {

                Write-Host ""
                Write-Host "LaTeX Workshop installation failed."

                $failed += "LaTeX Workshop"
            }

        }
        else {

            Write-Host "Skipped LaTeX Workshop."

            $skipped += "LaTeX Workshop"
        }
    }
}

# --------------------------------------------
# Final Summary
# --------------------------------------------

Write-Host ""
Write-Host "============================================"
Write-Host "             Setup Summary"
Write-Host "============================================"

Write-Host ""
Write-Host "Installed / Available:"

foreach ($item in $installed) {
    Write-Host "  [OK]      $item"
}

Write-Host ""
Write-Host "Skipped:"

foreach ($item in $skipped) {
    Write-Host "  [SKIPPED] $item"
}

Write-Host ""
Write-Host "Failed:"

foreach ($item in $failed) {
    Write-Host "  [FAILED]  $item"
}

Write-Host ""
Write-Host "Setup checks completed."
# --------------------------------------------
# Compile LaTeX CV
# --------------------------------------------

Write-Host ""
Write-Host "Checking LaTeX CV..."

if (Test-Path "main.tex") {

    Write-Host "main.tex found."
    Write-Host "Compiling CV..."

    pdflatex -interaction=nonstopmode -halt-on-error main.tex

    if ($LASTEXITCODE -eq 0) {

        Write-Host ""
        Write-Host "CV compiled successfully."

        if (Test-Path "main.pdf") {
            Write-Host "PDF generated successfully: main.pdf"
        }
        else {
            Write-Host "WARNING: Compilation succeeded but main.pdf was not found."
        }

    }
    else {

        Write-Host ""
        Write-Host "ERROR: LaTeX compilation failed."
        Write-Host "Please check the LaTeX output above."
    }

}
else {

    Write-Host ""
    Write-Host "WARNING: main.tex was not found."
    Write-Host "Skipping CV compilation."
}