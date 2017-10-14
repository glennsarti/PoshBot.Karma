
function Get-KarmaLeaderboard {
    [PoshBot.BotCommand(
        CommandName = 'leaderboard'
    )]
    [cmdletbinding()]
    param(
        [int]$Top = 10
    )

    if ($karmaState = Get-PoshBotStatefulData -Name KarmaState -ValueOnly) {
        $leaderboard = $karmaState |
            Where-Object { $_.Name -ne '' -and $_.Name -ne $null } |
            Sort-Object -Property {[int]$_.CurrentKarma} -Descending |
            Select-Object -First $Top -Wait
        $text = ($leaderboard |
            Where-Object { $_.Name -ne '' -and $_.Name -ne $null } |
            Select-Object -Property Name, CurrentKarma, LastUpdated |
            Format-Table -AutoSize |
            Out-String).Trim()
        New-PoshBotTextResponse -Text $text -AsCode
    } else {
        New-PoshBotTextResponse -Text 'Not cool. No one has any karma :(' -AsCode
    }
}

# ^<@[a-zA-z]+>\+\+$

function Get-KarmaForSubject($Subject) {
    $karmaState = @(Get-PoshBotStatefulData -Name KarmaState -ValueOnly)
    if (-not $karmaState) {
        $karmaState = @()
    }
    if ($karmaState.Count -ge 1 ) {
        $subjectKarma = $KarmaState | Where-Object {$_.Name.ToUpper() -eq $Subject.ToUpper() }
        if ($subjectKarma -eq $null) {
            $subjectKarma = [pscustomobject]@{
                PSTypeName = 'Karma'
                Name = $Subject
                CurrentKarma = 0
                LastUpdated = (Get-Date).ToString('u')
            }
        }
        Write-Output $subjectKarma
    } else {
        $item = [pscustomobject]@{
            PSTypeName = 'Karma'
            Name = $Subject
            CurrentKarma = 0
            LastUpdated = (Get-Date).ToString('u')
        }
        Write-Output $item
    }
}

function Set-KarmaForSubject($Karma) {
    $karmaState = @(Get-PoshBotStatefulData -Name KarmaState -ValueOnly)
    if (-not $karmaState) {
        $karmaState = @()
    }
    $Karma.LastUpdated = (Get-Date).ToString('u')

    if ($karmaState.Count -ge 1 ) {
        $oldKarma = $KarmaState | Where-Object {$_.Name -eq $Karma.Name}
        if ($oldKarma) {
            [int]$oldKarma.CurrentKarma = $Karma.CurrentKarma
        } else {
            $oldKarma = [pscustomobject]@{
                PSTypeName = 'Karma'
                Name = $Karma.Name
                CurrentKarma = $Karma.CurrentKarma
                LastUpdated = $Karma.LastUpdated
            }
            $karmaState += $oldKarma
        }
    } else {
        $item = [pscustomobject]@{
            PSTypeName = 'Karma'
            Name = $Karma.Name
            CurrentKarma = $Karma.CurrentKarma
            LastUpdated = $Karma.LastUpdated
        }
        $karmaState = @($item)
    }

    Set-PoshBotStatefulData -Value $karmaState -Name KarmaState -Depth 10 | Out-Null
}

function Update-Karma {
    <#
    .SYNOPSIS
        Give karma to someone or something e.g.
        Everything--
        @devblackops++
    #>
    [PoshBot.BotCommand(
        CommandName = 'update-karma',
        Command = $false,
        TriggerType = 'Regex',
        Regex = '^(.+)(\+\+|\-\-)$'
    )]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Scope='Function', Target='*')]
    [cmdletbinding()]
    param(
        [parameter(ValueFromRemainingArguments = $true)]
        [object[]]$Arguments
    )

    $Subject = $Arguments[1].Trim()
    $Operation = $Arguments[2]

    # TODO normalize subject names
    # e.g. strip @ for mentions
    $NormalizedSubject = $Subject.Trim()

    # TODO Don't modify your own karma
    # $global:PoshBotContext.From

    $SubjectKarma = Get-KarmaForSubject -Subject $NormalizedSubject
    if ($Operation -eq '++') {
        $SubjectKarma.CurrentKarma += 1
    } else {
        $SubjectKarma.CurrentKarma -= 1
    }

    Set-KarmaForSubject -Karma $SubjectKarma

    if ($SubjectKarma.CurrentKarma -gt 0) {
        Write-Output "$Subject has $($SubjectKarma.CurrentKarma) karma"
    } else {
        Write-Output "$Subject reduced to $($SubjectKarma.CurrentKarma) karma :("
    }
}

# function Set-Karma {
#     <#
#     .SYNOPSIS
#         Give karma to someone
#     #>
#     [PoshBot.BotCommand(
#         CommandName = 'give-karma',
#         Command = $false,
#         TriggerType = 'Regex',
#         Regex = '',
#         Aliases = ('karma')
#     )]
#     [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Scope='Function', Target='*')]
#     [cmdletbinding()]
#     param(
#         [parameter(ValueFromRemainingArguments = $true)]
#         [object[]]$Arguments
#         [parameter(Mandatory, position = 0)]

#         # [string]$User,

#         # [parameter(position = 1)]
#         # [int]$Karma = 1
#     )

#     $now = (Get-Date).ToString('u')

#     # Some people with @mention people and others just use the username. Normalize it
#     $User = $User.TrimStart('@')

#     $karmaState = @(Get-PoshBotStatefulData -Name KarmaState -ValueOnly)
#     if (-not $karmaState) {
#         $karmaState = @()
#     }
#     if ($karmaState.Count -ge 1 ) {
#         $CurrentKarma = 0
#         $userKarma = $KarmaState | Where-Object {$_.Name -eq $User}
#         if ($userKarma) {
#             [int]$userKarma.CurrentKarma += $Karma
#             $CurrentKarma = [int]$userKarma.CurrentKarma
#             $userKarma.LastUpdated = $now
#         } else {
#             $userKarma = [pscustomobject]@{
#                 PSTypeName = 'Karma'
#                 Name = $User
#                 CurrentKarma = $Karma
#                 LastUpdated = $now
#             }
#             $karmaState += $userKarma
#             $CurrentKarma = $userKarma.CurrentKarma
#         }
#     } else {
#         $karmaState = @()
#         $item = [pscustomobject]@{
#             PSTypeName = 'Karma'
#             Name = $User
#             CurrentKarma = $Karma
#             LastUpdated = $now
#         }
#         $karmaState += $item
#         $currentKarma = $Karma
#     }

#     # Prepend '@' so people get mentioned
#     if (-not $User.StartsWith('@')) {
#         $User = "@$User"
#     }

#     if ($Karma -gt 0) {
#         Write-Output "Woot! $User has $CurrentKarma karma"
#     } else {
#         Write-Output "$User reduced to $currentKarma karma :("
#     }

#     Set-PoshBotStatefulData -Value $karmaState -Name KarmaState -Depth 10
# }

function Set-Karma {
    <#
    .SYNOPSIS
        Give karma to someone
    #>
    [PoshBot.BotCommand(
        CommandName = 'set-karma',
        Permissions = 'karma-killer',
        Aliases = ('karma')
    )]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Scope='Function', Target='*')]
    [cmdletbinding()]
    param(
        [parameter(Mandatory, position = 0)]
        [string]$User,

        [parameter(position = 1)]
        [int]$Karma = 1
    )

    $now = (Get-Date).ToString('u')

    # Some people with @mention people and others just use the username. Normalize it
    $User = $User.TrimStart('@')

    $karmaState = @(Get-PoshBotStatefulData -Name KarmaState -ValueOnly)
    if (-not $karmaState) {
        $karmaState = @()
    }
    if ($karmaState.Count -ge 1 ) {
        $CurrentKarma = 0
        $userKarma = $KarmaState | Where-Object {$_.Name -eq $User}
        if ($userKarma) {
            [int]$userKarma.CurrentKarma += $Karma
            $CurrentKarma = [int]$userKarma.CurrentKarma
            $userKarma.LastUpdated = $now
        } else {
            $userKarma = [pscustomobject]@{
                PSTypeName = 'Karma'
                Name = $User
                CurrentKarma = $Karma
                LastUpdated = $now
            }
            $karmaState += $userKarma
            $CurrentKarma = $userKarma.CurrentKarma
        }
    } else {
        $karmaState = @()
        $item = [pscustomobject]@{
            PSTypeName = 'Karma'
            Name = $User
            CurrentKarma = $Karma
            LastUpdated = $now
        }
        $karmaState += $item
        $currentKarma = $Karma
    }

    # Prepend '@' so people get mentioned
    if (-not $User.StartsWith('@')) {
        $User = "@$User"
    }

    if ($Karma -gt 0) {
        Write-Output "Woot! $User has $CurrentKarma karma"
    } else {
        Write-Output "$User reduced to $currentKarma karma :("
    }

    Set-PoshBotStatefulData -Value $karmaState -Name KarmaState -Depth 10
}

function Reset-Karma {
    <#
    .SYNOPSIS
        Resets the karma state
    #>
    [PoshBot.BotCommand(
        Permissions = 'karma-killer'
    )]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Scope='Function', Target='*')]
    [cmdletbinding()]
    param(
        [switch]$Force
    )

    if (-not $Force) {
        New-PoshBotCardResponse -Type Warning -Text 'Are you sure we want to be a karma killer? Use the -Force if you do.'
    } else {
        Remove-PoshBotStatefulData -Name KarmaState
        Write-Output 'Karma state wiped clean'
    }
}
