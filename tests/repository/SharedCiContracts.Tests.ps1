# Repository-owned CI wiring; reusable workflow implementation belongs to stiwicourage/powershell-ci.
BeforeAll {
    $script:root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $workflowRoot = Join-Path $script:root '.github/workflows'

    function Get-RepositoryText {
        param([Parameter(Mandatory)][string]$Path)

        if (Test-Path -LiteralPath $Path) {
            return Get-Content -LiteralPath $Path -Raw
        }
        return ''
    }

    $script:testsWorkflow = Get-RepositoryText -Path (Join-Path $workflowRoot 'Tests.yml')
    $script:publishWorkflow = Get-RepositoryText -Path (Join-Path $workflowRoot 'Publish.yml')
    $script:securityWorkflow = Get-RepositoryText -Path (Join-Path $workflowRoot 'Security.yml')
    $script:dependabot = Get-RepositoryText -Path (Join-Path $script:root '.github/dependabot.yml')
    $script:pinnedReference = '@\d+\.\d+\.\d+\s'
}

Describe 'KeepAChangelog shared CI consumer contracts' {
    It 'uses the pinned shared test workflow with the common analyzer version and every severity gated' {
        $script:testsWorkflow | Should -Match "uses: stiwicourage/powershell-ci/\.github/workflows/tests\.yml$script:pinnedReference"
        $script:testsWorkflow | Should -Match "script-analyzer-required-version: '1\.25\.0'"
        $script:testsWorkflow | Should -Not -Match 'script-analyzer-severity' -Because 'every analyzer severity must fail the gate'
        $script:testsWorkflow | Should -Match 'secrets: inherit'
        $script:testsWorkflow | Should -Not -Match 'runs-on:|scripts/build/ci|codecov'
    }

    It 'validates both release documents in CI' {
        $script:testsWorkflow | Should -Match 'changelog-files: ./CHANGELOG.md ./RELEASE_NOTE.md'
    }

    It 'keeps test scheduling and pull requests to both release branches' {
        $script:testsWorkflow | Should -Match '(?s)branches-ignore:\s+- main'
        $script:testsWorkflow | Should -Match '(?s)pull_request:\s+branches:\s+- main\s+- develop'
        $script:testsWorkflow | Should -Match "cron: '0 3 \* \* \*'"
        $script:testsWorkflow | Should -Match 'workflow_dispatch:'
    }

    It 'publishes through the pinned shared publisher' {
        $script:publishWorkflow | Should -Match "uses: stiwicourage/powershell-ci/\.github/workflows/publish\.yml$script:pinnedReference"
        $script:publishWorkflow | Should -Match 'release-continuous-integration: true'
        $script:publishWorkflow | Should -Match 'secrets: inherit'
        $script:publishWorkflow | Should -Not -Match 'runs-on:|Move-UnreleasedChangelog'
    }

    It 'delegates all three security checks and keeps dependency review PR-only' {
        foreach ($workflow in 'codeql', 'powershell-analyzer', 'dependency-review') {
            $script:securityWorkflow | Should -Match "uses: stiwicourage/powershell-ci/\.github/workflows/$workflow\.yml$script:pinnedReference"
        }
        $script:securityWorkflow | Should -Match "github.event_name == 'pull_request'"
        $script:securityWorkflow | Should -Match "cron: '34 3 \* \* 1'"
    }

    It 'keeps no local copies of the shared workflows, actions, or CI scripts' {
        foreach ($path in @(
                '.github/workflows/powershell.yml'
                '.github/workflows/codeql.yml'
                '.github/workflows/dependency-review.yml'
                '.github/actions'
                'scripts/build/ci'
            )) {
            Join-Path $script:root $path | Should -Not -Exist
        }
    }

    It 'lets Dependabot update powershell-ci daily without the release cooldown' {
        $script:dependabot | Should -Match 'package-ecosystem: github-actions'
        $script:dependabot | Should -Match 'interval: daily'
        $script:dependabot | Should -Match '(?s)groups:\s+powershell-ci:\s+patterns:\s+- "stiwicourage/powershell-ci\*"'
        $script:dependabot | Should -Match '(?s)cooldown:\s+exclude:\s+- "stiwicourage/powershell-ci\*"'
    }
}
