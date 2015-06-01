Set P=%~dp0
Set P=%P:~0,-1%
Set cd=%P%

set PATH=%PATH%;%cd%\VirtualDub

for %%A in (*.avi) do set from=%%A & set to=%%~nA_clean

vdub.exe /i "%cd%\vdb_sets.vdscript" "%cd%\%from%" "%cd%\%to%.avi" 

rem cd VirtualDub
rem vdub.exe /i %cd%\vdb_sets.vdscript %cd%\epub_d1.avi %cd%\epub_d1.clean.avi

rem "%%~dpnA.avs" 

pause

rem ---Notes---
rem code requires: Avisynth, virtualdub, pre-existing (.vcf) config file
rem most people prefer to use virtualdub with jobs in queue; run them in sequence. This runs jobs in parallel by searching the directory of the script, finding all listed wildcard masked files below, generating a simple avisynth script file for each file, then opening virtualdub and autosaving the video to .avi
rem caution, this will stress your system. you may only be able to handle 1 file at a time. I can input 30 blueray .m2ts files just fine, so long as i set vdub process to idle or low. Modify the code to your hearts content ~ TigerWild

rem create a unique .vcf that you will use with this batch file only. Do this by running Virtualdub, opening a video file, configuring all your settings as you want them, then selecting File->save processing settings->.vcf
rem use a text editor to open the vcf file you made, and add these 2 lines: VirtualDub.Open(VirtualDub.params[0]); VirtualDub.SaveAVI(VirtualDub.params[1]);

rem ---References---
rem http://stackoverflow.com/questions/87496..
rem http://forum.doom9.org/archive/index.php.. with a nod to stax76