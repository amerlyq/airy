#Register-TemporaryEvent $job StateChanged -Action {
#      [Console]::Beep(100,100)
#      Write-Host "Job #$($sender.Id) ($($sender.Name)) complete."
# }
#############################################################################

$spareNm="Autosave_spare"
$backupNm="Autosave"
$scriptAutobackup = Join-Path (Split-Path $myInvocation.MyCommand.Path) "AutoBackUp.ps1"
Write-Host  $scriptAutobackup
$currjob = "c:\Users\Amer\T-Engine\4.0\tome\save\Amerlyq\"

function FCombine-Path([string]$srcpath,[string]$itempath) 
    { Join-Path (Split-Path $srcpath) ($itempath + "_" + (Split-Path $srcpath -leaf)) }

function FGet-LastSaves([string]$dirpath, [string]$head)
{
    If($dirpath -and (Test-Path $dirpath -Type Container))
    {
        Get-ChildItem $dirpath | Where { $_.PsIsContainer -and ($_.Name -match ("^"+$head+"_"))} |
             Sort-Object LastWriteTime -descending | Foreach-Object { $_.FullName }
    }
}

function FLastSaves([string]$srcpath) 
    { FGet-LastSaves (FCombine-Path $srcpath $backupNm) (Split-Path $srcpath -leaf) }

function FLoad-Autosave([string]$srcpath, [int]$num, [bool]$bMoveOther)
{
    $lastsave = @(FLastSaves $srcpath)[$num]
    if($lastsave)
    {
        $newname = (Split-Path $srcpath -leaf) + (Get-Date -uformat "_Origin_%Y-%m-%d_%H'%M'%S")
        $sparepath = FCombine-Path $srcpath $spareNm
        $dstpath = Join-Path $sparepath $newname
        
        If(-not (Test-Path $sparepath -Type Container)) { [void](New-Item $sparepath -Type Directory) }
        If(Test-Path $dstpath -Type Container) { [void](Remove-Item $dstpath) }
        
        [void](Move-Item $srcpath $dstpath)
        [void](Copy-Item $lastsave $srcpath -recurse)
        Write-Host "'$lastsave' was loaded to '$srcpath'"
        
        If($bMoveOther)
        {
            $lastsave = FLastSaves $srcpath
            For($i=$num-1; $i -ge 0; $i--) { [void](Move-Item @($lastsave)[$i] $sparepath) }
            Write-Host "Moved '$num' verylast saves"
        }
    }
}

function FStart-AutoJob
{
    
}

function FListNumerator($slist)
{
    $strBld = New-Object System.Text.StringBuilder
    for ($i=1; $i -le @($slist).Length; $i++) {
        [void]$strBld.Append("`t"+$i.ToString()+" - "+@($slist)[$i-1]+"`n")
    }
    $strBld.ToString()
}

function FSaveCurrent($srcpath)
{
    [void](&($scriptAutobackup) $srcpath (FCombine-Path $srcpath $backupNm) 0 0)
}

function FMain-Autosave
{ 
    param( $eAction=-1, [string]$currjob)
    
    $dTime=20
    $source1=$currjob
    
    $eAction=$(Read-Host "This is Autosave.`t`tYour current job is 
    '$source1'
        `t`tWhat you want to do?
            1 - Save immediately (s)
            2 - Load Last save
            3 - Load next to Last (r)
            4 - Choose which to load (w)
            5 - Change current Job (x)
            6 - Job's List (g)
            7 - Add new job (v)
            8 - Remove current job
            9 - Clear spare folder
            0 - Remove all jobs")
            
    switch ($eAction) 
    {
        1 { FSaveCurrent($source1) }
        2 { FLoad-Autosave $source1 0 $false }
        3 { FSaveCurrent($source1); FLoad-Autosave $source1 1 $true }
        4 {
            $whichload= -1 + $(Read-Host "Please, enter number, which save you want to load
            "(FListNumerator (FLastSaves $source1 | Select-Object -First 10)))
            FLoad-Autosave $source1 $whichload $false
          }
        5 {
            $currid = $(Read-Host "Enter wished Id
            "(Get-Job | Format-Table -property Id,Name,State,HasMoreData -AutoSize | Out-String))
            $source1=(Get-Job -id $currid).Name.Substring(4)
          }
        6 { Read-Host "There are list of jobs
            "(Get-Job | Format-Table -property Id,Name,State,HasMoreData -AutoSize | Out-String)
          }
        7 {
            $source1 = $(Read-Host "Enter file path")
            if($(Read-Host "Are you sure wish to start '$source1'? (y/n)") -eq "y") {
            [void](Start-Job -FilePath $scriptAutobackup `
                -ArgumentList $source1,(FCombine-Path $source1 $backupNm),$dTime,5 `
                -Name ("FAS=$source1"))}
          }
        8 {
            if($(Read-Host "Are you sure wish to remove '$source1' job from queue? (y/n)") -eq "y") {
            [void](Get-Job | Where { $_.Name -eq "FAS=$source1"} | Stop-Job -PassThru | Remove-Job) }
          }
        9 {
            if($(Read-Host "Are you sure wish to clear '$source1' spare folder? (y/n)") -eq "y") {
                $sparedir = FCombine-Path $source1 $spareNm
                if(Test-Path $sparedir) { [void]( Remove-Item $sparedir -Confirm) }}
          }
        0 { [void](Get-Job | Where { $_.Name -match "^FAS=.*"} | Stop-Job -PassThru | Remove-Job) }
        default { $source1 = "exit" }
    }
    $source1
}

$bRunMenu = $true

#(Start-Job -FilePath $scriptAutobackup `
#                -ArgumentList $currjob,(FCombine-Path $currjob $backupNm),$dTime,5 `
#                -Name ("FAS=$currjob"))

while($bRunMenu) { $bRunMenu = (#$currjob = 
    (FMain-Autosave -1 $currjob)) -ne "exit" }