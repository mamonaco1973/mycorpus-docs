param(
    [int]$MaxPasses = 2
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Disable Node.js SSL verification — workaround for SSL inspection proxies/AV
$env:NODE_TLS_REJECT_UNAUTHORIZED = "0"

$runtimeDir = "c:\cloudenv\mycorpus\mycorpus-runtime"
$docsDir    = "c:\cloudenv\mycorpus\mycorpus-docs"
$tempDir    = [System.IO.Path]::GetTempPath()

# Writing standards injected into every prompt — keeps all agents consistent
$standards = @"
Writing standards for this corpus (mandatory):
- Self-contained sections: each section must answer fully in isolation, no cross-references
- Q&A format: FAQ especially — each question is a retrieval target with a complete answer
- Full answers, not references: repeat key facts rather than saying "see above"
- Plain prose: short bullet lists are fine, avoid heavy nesting or large tables
- No relative links between sections
- Branding: always write the product name as "MyCorpus.ai" — never "mycorpus", "MyCorpus", or any other casing

Exclusions — read $docsDir\NODOC.md and do not document anything listed there.
Do not add, mention, or allude to excluded features even if they appear in the source code.
"@

# Source files — globbed so new ingestors and frontend modules are picked up automatically
$corePy        = (Get-ChildItem "$runtimeDir\03-core\code\*.py").FullName
$ingestPy      = (Get-ChildItem "$runtimeDir\02-ingest\ingestors\*.py").FullName
$webappJs      = (Get-ChildItem "$runtimeDir\04-webapp\js\*.js" -Recurse).FullName
$webappHtml    = @("$runtimeDir\04-webapp\index.html")
$adminTf       = @("$runtimeDir\03-core\cognito.tf", "$runtimeDir\03-core\variables.tf")
$runtimeReadme = @("$runtimeDir\README.md")

$userSources  = @($corePy) + @($webappJs) + $webappHtml + $runtimeReadme
$adminSources = @($corePy) + @($ingestPy) + @($webappJs) + $webappHtml + $adminTf + $runtimeReadme

# FAQ draws from both sets
$faqSources = ($userSources + $adminSources) | Select-Object -Unique

$docs = @(
    @{
        Name    = "user-guide.md"
        Path    = "$docsDir\user-guide.md"
        Sources = $userSources
        Desc    = "end-user guide covering: getting started, chat interface, conversations, token budgets, corpus building, all source types, troubleshooting. Audience: end users (non-admin)."
    },
    @{
        Name    = "admin-guide.md"
        Path    = "$docsDir\admin-guide.md"
        Sources = $adminSources
        Desc    = "administrator guide covering: corpora management, source type configuration, user management, identity provider setup (Google/SAML/OIDC), MCP connector, plans, branding, data security. Audience: administrators. Must include a complete reference guide to .corpora files: format, all supported fields, examples, and how the runtime resolves and applies them."
    },
    @{
        Name    = "faq.md"
        Path    = "$docsDir\faq.md"
        Sources = $faqSources
        Desc    = "comprehensive FAQ covering all features, concepts, RAG internals, data privacy, plans, troubleshooting. Audience: all users."
    }
)

function Invoke-Claude([string]$Prompt, [string]$OutFile) {
    $start = Get-Date

    # Run claude in a background job so we can print elapsed time while waiting
    $job = Start-Job -ScriptBlock {
        param($prompt, $out)
        $env:NODE_TLS_REJECT_UNAUTHORIZED = "0"
        # Let Claude write the file directly; discard stdout so it doesn't
        # pollute the job output stream alongside the exit code
        & claude --dangerously-skip-permissions --print $prompt | Out-Null
        return $LASTEXITCODE
    } -ArgumentList $Prompt, $OutFile

    while ($job.State -eq "Running") {
        Start-Sleep 10
        $secs = [int]((Get-Date) - $start).TotalSeconds
        Write-Host "    ... ${secs}s" -ForegroundColor DarkGray
    }

    $exitCode = Receive-Job $job -ErrorAction SilentlyContinue
    Remove-Job $job -Force

    $total = [int]((Get-Date) - $start).TotalSeconds
    Write-Host "    ... done in ${total}s"

    if ($exitCode -ne 0) { throw "claude exited with code $exitCode" }

    $result = Get-Content $OutFile -Raw -ErrorAction SilentlyContinue
    if (-not $result) { throw "No output written to $OutFile" }
    return $result
}

function Format-SourceList([string[]]$Sources) {
    return ($Sources | ForEach-Object { "  - $_" }) -join "`n"
}

foreach ($doc in $docs) {
    Write-Host ""
    Write-Host "=== $($doc.Name) ==="

    $errorsFile = Join-Path $tempDir "mcorpus_errors_$($doc.Name)"

    # ---- Phase 1: Writer ----
    # Fresh context: reads source files + existing doc, outputs updated version
    Write-Host "  [writer] updating from source..."
    $sourceList = Format-SourceList $doc.Sources
    $writerPrompt = @"
You are updating product documentation from source code.

Read these source files (ground truth):
$sourceList

Read the existing documentation file:
  $($doc.Path)

This document is: $($doc.Desc)

$standards

Update the documentation to accurately reflect the current source code. Preserve the existing structure and format. Fix any inaccuracies, add missing features, remove features that no longer exist. Write the complete updated markdown directly to the documentation file path shown above.
"@
    Invoke-Claude $writerPrompt $doc.Path | Out-Null
    Write-Host "  [writer] done"

    # ---- Phase 2+3: Reviewer → Fixer loop ----
    for ($pass = 1; $pass -le $MaxPasses; $pass++) {

        # Reviewer: fresh context — reads source + doc, zero memory of the writer phase
        Write-Host "  [reviewer] pass $pass..."
        $reviewerPrompt = @"
You are a strict technical reviewer.

Read these source files (ground truth):
$sourceList

Read the documentation file to review:
  $($doc.Path)

Compare them carefully. List every factual error in the documentation:
- Features described that do not exist in the source
- Features that exist in the source but are missing from the docs
- Incorrect behavior, wrong names, wrong descriptions
- Anything contradicted by the source code

Report ONLY real discrepancies. No style feedback. Be specific — name the section and the error.
If the documentation accurately reflects the source, write exactly: NO ERRORS FOUND
Write your error list to: $errorsFile
"@
        $errors = Invoke-Claude $reviewerPrompt $errorsFile

        if ($errors -match "NO ERRORS FOUND") {
            Write-Host "  [done] clean after $pass review pass(es)"
            break
        }

        $errorLines = ($errors -split "`n").Count
        Write-Host "  [fixer] applying $errorLines lines of corrections..."

        # Fixer: fresh context — reads source + doc + error list, outputs corrected doc
        $fixerPrompt = @"
You are a documentation editor.

Read these source files (ground truth):
$sourceList

Read the current documentation:
  $($doc.Path)

Read the error list:
  $errorsFile

$standards

Fix every error listed. The source files are the ground truth — when in doubt, match the code. Write the complete corrected markdown directly to the documentation file path shown above.
"@
        Invoke-Claude $fixerPrompt $doc.Path | Out-Null

        if ($pass -eq $MaxPasses) {
            Write-Host "  [done] reached max passes ($MaxPasses)"
        }
    }

    Remove-Item $errorsFile -ErrorAction SilentlyContinue
    Write-Host "  [saved] $($doc.Path)"
}

Write-Host ""
Write-Host "All docs updated."

# ---- Sample .corpora files ----
Write-Host ""
Write-Host "=== samples ==="
$samplesDir     = "$docsDir\samples"
$corporaSource  = "$runtimeDir\04-webapp\js\sources\corporaSamples.js"
$samplesSentinel = "$tempDir\mcorpus_samples_sentinel"
$samplesPrompt  = @"
Read the file: $corporaSource

It contains sample .corpora definitions embedded in JavaScript. Extract every sample and write each one as an individual file into the directory: $samplesDir

Rules:
- One file per sample
- Use a descriptive kebab-case filename with a .corpora extension (e.g. github-repo.corpora)
- File content must be only the raw .corpora content — no JavaScript, no markdown fences
- Do not create any index or summary file

When all sample files have been written, write a one-line summary of what was created (e.g. "Created 5 sample files") to: $samplesSentinel
"@
Write-Host "  [samples] extracting from corporaSamples.js..."
Invoke-Claude $samplesPrompt $samplesSentinel | Out-Null
Write-Host "  [samples] done — written to $samplesDir"
