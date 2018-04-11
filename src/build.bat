@ECHO OFF

IF "%1"=="" (
	rem I would have loved doing this all in one single step, but for some reason, I can't seem to build using MSBuild
	rem while running from the command line using MSBuild 2017. See https://stackoverflow.com/questions/47002571/.
	rem That's why this build file must be called multiple times.
    echo Please provide a number of the build step. Starting with 1. Example: "%0 1
    goto :EOF
)

set step="%1"

set version=4.1.0
set prereleasePostfix=
set buildNumber=0 
set copyrightYear=2018

set version_Core=%version%
set version_Packaging=%version_Core%
set version_Integration_Web=%version_Core%
set version_Integration_WebForms=%version_Core%
set version_Integration_Mvc=%version_Core%
set version_Integration_Wcf=%version_Core%
set version_Integration_WebApi=%version_Core%
set version_Integration_AspNetCore=%version_Core%
set version_Integration_AspNetCore_Mvc_Core=%version_Core%
set version_Integration_AspNetCore_Mvc=%version_Core%

set vsvars32_bat="%programfiles(x86)%\Microsoft Visual Studio\2017\Community\Common7\Tools\VsMSBuildCmd.bat"
if not exist %vsvars32_bat% goto :vsvars32_bat_missing
@call %vsvars32_bat%

set msbuild="%programfiles(x86)%\Microsoft Visual Studio\2017\Community\MSBuild\15.0\Bin\MSBuild.exe"
if not exist %msbuild% goto :msbuild_exe_missing

set attrib=%systemroot%\System32\attrib.exe
set xcopy=%systemroot%\System32\xcopy.exe
if not exist %xcopy% goto :xcopy_missing


set buildToolsPath=BuildTools
set nugetTemplatePath=%buildToolsPath%\NuGet
set replace=%buildToolsPath%\replace.exe
set compress=%systemroot%\System32\CScript.exe %buildToolsPath%\zip.vbs
set configuration=Release
set defineConstantsNet=PUBLISH
set targetPath=bin
set targetPathNet=%targetPath%\NET
set targetPathPcl=%targetPath%\PCL
set targetPathCoreClr=%targetPath%\DOTNET

set named_version=%version%%prereleasePostfix%

set named_version_Core=%version_Core%%prereleasePostfix%
set named_version_Integration_AspNetCore=%version_Integration_AspNetCore%%prereleasePostfix%
set named_version_Integration_AspNetCore_Mvc_Core=%version_Integration_AspNetCore_Mvc_Core%%prereleasePostfix%
set named_version_Integration_AspNetCore_Mvc=%version_Integration_AspNetCore_Mvc%%prereleasePostfix%
set named_version_Integration_Wcf=%version_Integration_Wcf%%prereleasePostfix%
set named_version_Integration_Web=%version_Integration_Web%%prereleasePostfix%
set named_version_Integration_Mvc=%version_Integration_Mvc%%prereleasePostfix%
set named_version_Integration_WebApi=%version_Integration_WebApi%%prereleasePostfix%
set named_version_Packaging=%version_Packaging%%prereleasePostfix%

set numeric_version_Core=%version_Core%.%buildNumber%
set numeric_version_Integration_AspNetCore=%version_Integration_AspNetCore%.%buildNumber%
set numeric_version_Integration_AspNetCore_Mvc=%version_Integration_AspNetCore_Mvc%.%buildNumber%
set numeric_version_Integration_Wcf=%version_Integration_Wcf%.%buildNumber%
set numeric_version_Integration_Web=%version_Integration_Web%.%buildNumber%
set numeric_version_Integration_Mvc=%version_Integration_Mvc%.%buildNumber%
set numeric_version_Integration_WebApi=%version_Integration_WebApi%.%buildNumber%
set numeric_version_Packaging=%version_Packaging%.%buildNumber%

if not exist SimpleInjector.snk goto :strong_name_key_missing

IF %step%=="1" (
	echo Running step 1
	if exist Releases\v%named_version% goto :release_directory_already_exists

	echo BUILDING
	rmdir %targetPathNet% /s /q
	mkdir %targetPathNet%
	rmdir %targetPathPcl% /s /q
	mkdir %targetPathPcl%
	rmdir %targetPathCoreClr% /s /q
	mkdir %targetPathCoreClr%
	
	echo CLEAN SOLUTION
	%msbuild% /t:Clean /p:Configuration=Release

	echo SET VERSION NUMBERS
	%replace% /line "<VersionPrefix>" "<VersionPrefix>%named_version_Core%</VersionPrefix>" /source:SimpleInjector\SimpleInjector.csproj
	%replace% /line "<VersionPrefix>" "<VersionPrefix>%named_version_Integration_AspNetCore%</VersionPrefix>" /source:SimpleInjector.Integration.AspNetCore\SimpleInjector.Integration.AspNetCore.csproj
	%replace% /line "<VersionPrefix>" "<VersionPrefix>%named_version_Integration_AspNetCore_Mvc_Core%</VersionPrefix>" /source:SimpleInjector.Integration.AspNetCore.Mvc.Core\SimpleInjector.Integration.AspNetCore.Mvc.Core.csproj
	%replace% /line "<VersionPrefix>" "<VersionPrefix>%named_version_Integration_AspNetCore_Mvc%</VersionPrefix>" /source:SimpleInjector.Integration.AspNetCore.Mvc\SimpleInjector.Integration.AspNetCore.Mvc.csproj
	%replace% /line "<VersionPrefix>" "<VersionPrefix>%named_version_Integration_Wcf%</VersionPrefix>" /source:SimpleInjector.Integration.Wcf\SimpleInjector.Integration.Wcf.csproj
	%replace% /line "<VersionPrefix>" "<VersionPrefix>%named_version_Integration_Web%</VersionPrefix>" /source:SimpleInjector.Integration.Web\SimpleInjector.Integration.Web.csproj
	%replace% /line "<VersionPrefix>" "<VersionPrefix>%named_version_Integration_Mvc%</VersionPrefix>" /source:SimpleInjector.Integration.Web.Mvc\SimpleInjector.Integration.Web.Mvc.csproj
	%replace% /line "<VersionPrefix>" "<VersionPrefix>%named_version_Integration_WebApi%</VersionPrefix>" /source:SimpleInjector.Integration.WebApi\SimpleInjector.Integration.WebApi.csproj
	%replace% /line "<VersionPrefix>" "<VersionPrefix>%named_version_Packaging%</VersionPrefix>" /source:SimpleInjector.Packaging\SimpleInjector.Packaging.csproj
	
	rem echo BUILD SOLUTION

	rem %msbuild% "SimpleInjector\SimpleInjector.csproj" /nologo
	rem %msbuild% "SimpleInjector.Integration.AspNetCore\SimpleInjector.Integration.AspNetCore.csproj" /nologo
	rem %msbuild% "SimpleInjector.Integration.AspNetCore.Mvc.Core\SimpleInjector.Integration.AspNetCore.Mvc.Core.csproj" /nologo
	rem %msbuild% "SimpleInjector.Integration.AspNetCore.Mvc\SimpleInjector.Integration.AspNetCore.Mvc.csproj" /nologo
	rem %msbuild% "SimpleInjector.Integration.Wcf\SimpleInjector.Integration.Wcf.csproj" /nologo
	rem %msbuild% "SimpleInjector.Integration.Web\SimpleInjector.Integration.Web.csproj" /nologo
	rem %msbuild% "SimpleInjector.Integration.Web.Mvc\SimpleInjector.Integration.Web.Mvc.csproj" /nologo
	rem %msbuild% "SimpleInjector.Integration.WebApi\SimpleInjector.Integration.WebApi.csproj" /nologo
	rem %msbuild% "SimpleInjector.Packaging\SimpleInjector.Packaging.csproj" /nologo
	
    echo Please compile the solution in RELEASE mode and run step 2
    goto :EOF
)

IF %step%=="2" (
	echo RUNNING TESTS IN PARTIAL TRUST

	set testDll=SimpleInjector.Tests.Unit\bin\Release\net451\SimpleInjector.Tests.Unit.dll
	set testRunner=SimpleInjector.Tests.Unit\bin\Release\net451\PartialTrustTestRunner.exe
	
	echo %testRunner% %testDll%
	%testRunner% %testDll%
	
    echo If tests were green, please run step 3
    goto :EOF	
)

IF %step%=="3" (
	echo BUILD DOCUMENTATION

	%msbuild% "SimpleInjector.Documentation\SimpleInjector.Documentation.shfbproj" /nologo /p:Configuration=%configuration% /p:DefineConstants="%defineConstantsNet%"

	mkdir Releases\v%named_version%
	copy Help\SimpleInjector.chm Releases\v%named_version%\SimpleInjector.chm


	echo CREATING ONLINE DOCUMENTATION

	del Help\SimpleInjector.chm
	del Help\*.aspx
	del Help\*.php
	copy Help\Index.html Help\index.tmp
	del Help\Index.html
	copy Help\index.tmp Help\index.htm
	del Help\index.tmp
	REM For some strange reason, the following call does not compress the complete help directory, while calling it manually does work
	REM %compress% "%CD%\Help" "%CD%\Releases\v%named_version%\SimpleInjector Online Documentation v%named_version%.zip"

    echo Please run step 4
    goto :EOF	
)

IF %step%=="4" (
	echo CREATING NUGET PACKAGES

	mkdir Releases\temp
	%xcopy% %nugetTemplatePath%\.NET\SimpleInjector Releases\temp /E /H
	%attrib% -r "%CD%\Releases\temp\*.*" /s /d
	del Releases\temp\.gitignore /s /q
	copy SimpleInjector\bin\Release\net40\SimpleInjector.dll Releases\temp\lib\net40\SimpleInjector.dll
	copy SimpleInjector\bin\Release\net40\SimpleInjector.xml Releases\temp\lib\net40\SimpleInjector.xml
	copy SimpleInjector\bin\Release\net45\SimpleInjector.dll Releases\temp\lib\net45\SimpleInjector.dll
	copy SimpleInjector\bin\Release\net45\SimpleInjector.xml Releases\temp\lib\net45\SimpleInjector.xml
	copy SimpleInjector\bin\Release\netstandard1.0\SimpleInjector.dll "Releases\temp\lib\netstandard1.0\SimpleInjector.dll"
	copy SimpleInjector\bin\Release\netstandard1.0\SimpleInjector.xml "Releases\temp\lib\netstandard1.0\SimpleInjector.xml"
	copy SimpleInjector\bin\Release\netstandard1.3\SimpleInjector.dll "Releases\temp\lib\netstandard1.3\SimpleInjector.dll"
	copy SimpleInjector\bin\Release\netstandard1.3\SimpleInjector.xml "Releases\temp\lib\netstandard1.3\SimpleInjector.xml"
	%replace% /source:Releases\temp\SimpleInjector.nuspec {version} %named_version_Core%
	%replace% /source:Releases\temp\SimpleInjector.nuspec {year} %copyrightYear%
	%replace% /source:Releases\temp\package\services\metadata\core-properties\c8082e2254fe4defafc3b452026f048d.psmdcp {version} %named_version_Core%
	%compress% "%CD%\Releases\temp" "%CD%\Releases\v%named_version%\SimpleInjector.%named_version_Core%.zip"
	rmdir Releases\temp /s /q

	mkdir Releases\temp
	%xcopy% %nugetTemplatePath%\.NET\SimpleInjector.Packaging Releases\temp /E /H
	%attrib% -r "%CD%\Releases\temp\*.*" /s /d
	del Releases\temp\.gitignore /s /q
	copy SimpleInjector.Packaging\bin\Release\net40\SimpleInjector.Packaging.dll "Releases\temp\lib\net40\SimpleInjector.Packaging.dll"
	copy SimpleInjector.Packaging\bin\Release\net40\SimpleInjector.Packaging.xml "Releases\temp\lib\net40\SimpleInjector.Packaging.xml"
	copy SimpleInjector.Packaging\bin\Release\netstandard1.0\SimpleInjector.Packaging.dll "Releases\temp\lib\netstandard1.0\SimpleInjector.Packaging.dll"
	copy SimpleInjector.Packaging\bin\Release\netstandard1.0\SimpleInjector.Packaging.xml "Releases\temp\lib\netstandard1.0\SimpleInjector.Packaging.xml"
	%replace% /source:Releases\temp\SimpleInjector.Packaging.nuspec {version} %named_version_Packaging%
	%replace% /source:Releases\temp\SimpleInjector.Packaging.nuspec {versionCore} %named_version_Core%
	%replace% /source:Releases\temp\SimpleInjector.Packaging.nuspec {year} %copyrightYear%
	%replace% /source:Releases\temp\package\services\metadata\core-properties\4d447eef3ba54c2da48c4d25f475fcbe.psmdcp {version} %named_version_Packaging%
	%compress% "%CD%\Releases\temp" "%CD%\Releases\v%named_version%\SimpleInjector.Packaging.%named_version_Packaging%.zip"
	rmdir Releases\temp /s /q

	mkdir Releases\temp
	%xcopy% %nugetTemplatePath%\.NET\SimpleInjector.Integration.Web Releases\temp /E /H
	%attrib% -r "%CD%\Releases\temp\*.*" /s /d
	del Releases\temp\.gitignore /s /q
	copy SimpleInjector.Integration.Web\bin\Release\net40\SimpleInjector.Integration.Web.dll Releases\temp\lib\net40\SimpleInjector.Integration.Web.dll
	copy SimpleInjector.Integration.Web\bin\Release\net40\SimpleInjector.Integration.Web.xml Releases\temp\lib\net40\SimpleInjector.Integration.Web.xml
	%replace% /source:Releases\temp\SimpleInjector.Integration.Web.nuspec {version} %named_version_Integration_Web%
	%replace% /source:Releases\temp\SimpleInjector.Integration.Web.nuspec {versionCore} %named_version_Core%
	%replace% /source:Releases\temp\SimpleInjector.Integration.Web.nuspec {year} %copyrightYear%
	%replace% /source:Releases\temp\package\services\metadata\core-properties\fb4dd696b20548afa09bcbbf3ea6c7d0.psmdcp {version} %named_version_Integration_Web%
	%compress% "%CD%\Releases\temp" "%CD%\Releases\v%named_version%\SimpleInjector.Integration.Web.%named_version_Integration_Web%.zip"
	rmdir Releases\temp /s /q

	mkdir Releases\temp
	%xcopy% %nugetTemplatePath%\.NET\SimpleInjector.Integration.Web.Mvc Releases\temp /E /H
	%attrib% -r "%CD%\Releases\temp\*.*" /s /d
	del Releases\temp\.gitignore /s /q
	copy SimpleInjector.Integration.Web.Mvc\bin\Release\net40\SimpleInjector.Integration.Web.Mvc.dll Releases\temp\lib\net40\SimpleInjector.Integration.Web.Mvc.dll
	copy SimpleInjector.Integration.Web.Mvc\bin\Release\net40\SimpleInjector.Integration.Web.Mvc.xml Releases\temp\lib\net40\SimpleInjector.Integration.Web.Mvc.xml
	%replace% /source:Releases\temp\SimpleInjector.Integration.Web.Mvc.nuspec {version} %named_version_Integration_Mvc%
	%replace% /source:Releases\temp\SimpleInjector.Integration.Web.Mvc.nuspec {versionCore} %named_version_Core%
	%replace% /source:Releases\temp\SimpleInjector.Integration.Web.Mvc.nuspec {version_Integration_Web} %named_version_Integration_Web%
	%replace% /source:Releases\temp\SimpleInjector.Integration.Web.Mvc.nuspec {year} %copyrightYear%
	%replace% /source:Releases\temp\package\services\metadata\core-properties\916f6977dc7a462395f59f05d2cc6a76.psmdcp {version} %named_version_Integration_Mvc%
	%compress% "%CD%\Releases\temp" "%CD%\Releases\v%named_version%\SimpleInjector.Integration.Web.Mvc.%named_version_Integration_Mvc%.zip"
	rmdir Releases\temp /s /q

	mkdir Releases\temp
	%xcopy% %nugetTemplatePath%\.NET\SimpleInjector.Integration.Web.Mvc.QuickStart Releases\temp /E /H
	%attrib% -r "%CD%\Releases\temp\*.*" /s /d
	del Releases\temp\.gitignore /s /q
	%replace% /source:Releases\temp\SimpleInjector.MVC3.nuspec {version} %named_version_Integration_Mvc%
	%replace% /source:Releases\temp\SimpleInjector.MVC3.nuspec {versionCore} %named_version_Core%
	%replace% /source:Releases\temp\SimpleInjector.MVC3.nuspec {version_Integration_Mvc} %named_version_Integration_Mvc%
	%replace% /source:Releases\temp\SimpleInjector.MVC3.nuspec {year} %copyrightYear%
	%replace% /source:Releases\temp\package\services\metadata\core-properties\7594fa13b1164869a9b2b67b8b5ad9a3.psmdcp {version} %named_version_Integration_Mvc%
	%compress% "%CD%\Releases\temp" "%CD%\Releases\v%named_version%\SimpleInjector.MVC3.%named_version_Integration_Mvc%.zip"
	rmdir Releases\temp /s /q

	mkdir Releases\temp
	%xcopy% %nugetTemplatePath%\.NET\SimpleInjector.Integration.Wcf Releases\temp /E /H
	%attrib% -r "%CD%\Releases\temp\*.*" /s /d
	del Releases\temp\.gitignore /s /q
	copy SimpleInjector.Integration.Wcf\bin\Release\net45\SimpleInjector.Integration.Wcf.dll Releases\temp\lib\net45\SimpleInjector.Integration.Wcf.dll
	copy SimpleInjector.Integration.Wcf\bin\Release\net45\SimpleInjector.Integration.Wcf.xml Releases\temp\lib\net45\SimpleInjector.Integration.Wcf.xml
	%replace% /source:Releases\temp\SimpleInjector.Integration.Wcf.nuspec {version} %named_version_Integration_Wcf%
	%replace% /source:Releases\temp\SimpleInjector.Integration.Wcf.nuspec {versionCore} %named_version_Core%
	%replace% /source:Releases\temp\SimpleInjector.Integration.Wcf.nuspec {year} %copyrightYear%
	%replace% /source:Releases\temp\package\services\metadata\core-properties\13850374b87d467da12f21ca32dac632.psmdcp {version} %named_version_Integration_Wcf%
	%compress% "%CD%\Releases\temp" "%CD%\Releases\v%named_version%\SimpleInjector.Integration.Wcf.%named_version_Integration_Wcf%.zip"
	rmdir Releases\temp /s /q

	mkdir Releases\temp
	%xcopy% %nugetTemplatePath%\.NET\SimpleInjector.Integration.Wcf.QuickStart Releases\temp /E /H
	%attrib% -r "%CD%\Releases\temp\*.*" /s /d
	del Releases\temp\.gitignore /s /q
	%replace% /source:Releases\temp\SimpleInjector.Integration.Wcf.QuickStart.nuspec {version} %named_version_Integration_Wcf%
	%replace% /source:Releases\temp\SimpleInjector.Integration.Wcf.QuickStart.nuspec {versionCore} %named_version_Core%
	%replace% /source:Releases\temp\SimpleInjector.Integration.Wcf.QuickStart.nuspec {version_Integration_Wcf} %named_version_Integration_Wcf%
	%replace% /source:Releases\temp\SimpleInjector.Integration.Wcf.QuickStart.nuspec {year} %copyrightYear%
	%replace% /source:Releases\temp\package\services\metadata\core-properties\a47c8b1328f541fc8a5cd4c0446d5fe1.psmdcp {version} %named_version_Integration_Wcf%
	%compress% "%CD%\Releases\temp" "%CD%\Releases\v%named_version%\SimpleInjector.Integration.Wcf.QuickStart.%named_version_Integration_Wcf%.zip"
	rmdir Releases\temp /s /q

	mkdir Releases\temp
	%xcopy% %nugetTemplatePath%\.NET\SimpleInjector.Integration.WebApi Releases\temp /E /H
	%attrib% -r "%CD%\Releases\temp\*.*" /s /d
	del Releases\temp\.gitignore /s /q
	copy SimpleInjector.Integration.WebApi\bin\Release\net45\SimpleInjector.Integration.WebApi.dll Releases\temp\lib\net45\SimpleInjector.Integration.WebApi.dll
	copy SimpleInjector.Integration.WebApi\bin\Release\net45\SimpleInjector.Integration.WebApi.xml Releases\temp\lib\net45\SimpleInjector.Integration.WebApi.xml
	%replace% /source:Releases\temp\SimpleInjector.Integration.WebApi.nuspec {version} %named_version_Integration_WebApi%
	%replace% /source:Releases\temp\SimpleInjector.Integration.WebApi.nuspec {versionCore} %named_version_Core%
	%replace% /source:Releases\temp\SimpleInjector.Integration.WebApi.nuspec {year} %copyrightYear%
	%replace% /source:Releases\temp\package\services\metadata\core-properties\a3b1f940a1584e868b3266ff38ba4e08.psmdcp {version} %named_version_Integration_WebApi%
	%compress% "%CD%\Releases\temp" "%CD%\Releases\v%named_version%\SimpleInjector.Integration.WebApi.%named_version_Integration_WebApi%.zip"
	rmdir Releases\temp /s /q

	mkdir Releases\temp
	%xcopy% %nugetTemplatePath%\.NET\SimpleInjector.Integration.WebApi.WebHost.QuickStart Releases\temp /E /H
	%attrib% -r "%CD%\Releases\temp\*.*" /s /d
	del Releases\temp\.gitignore /s /q
	%replace% /source:Releases\temp\SimpleInjector.Integration.WebApi.WebHost.QuickStart.nuspec {version} %named_version_Integration_WebApi%
	%replace% /source:Releases\temp\SimpleInjector.Integration.WebApi.WebHost.QuickStart.nuspec {versionCore} %named_version_Core%
	%replace% /source:Releases\temp\SimpleInjector.Integration.WebApi.WebHost.QuickStart.nuspec {version_Integration_WebApi} %named_version_Integration_WebApi%
	%replace% /source:Releases\temp\SimpleInjector.Integration.WebApi.WebHost.QuickStart.nuspec {year} %copyrightYear%
	%replace% /source:Releases\temp\package\services\metadata\core-properties\28cf0010982e4a44bd982823a7b4b6be.psmdcp {version} %named_version_Integration_WebApi%
	%compress% "%CD%\Releases\temp" "%CD%\Releases\v%named_version%\SimpleInjector.Integration.WebApi.WebHost.QuickStart.%named_version_Integration_WebApi%.zip"
	rmdir Releases\temp /s /q

	ren "%CD%\Releases\v%named_version%\*.zip" "*.nupkg"

	copy "SimpleInjector.Integration.AspNetCore\bin\Release\SimpleInjector.Integration.AspNetCore.%named_version_Integration_AspNetCore%.nupkg" Releases\v%named_version%\
	copy "SimpleInjector.Integration.AspNetCore.Mvc.Core\bin\Release\SimpleInjector.Integration.AspNetCore.Mvc.Core.%named_version_Integration_AspNetCore_Mvc_Core%.nupkg" Releases\v%named_version%\
	copy "SimpleInjector.Integration.AspNetCore.Mvc\bin\Release\SimpleInjector.Integration.AspNetCore.Mvc.%named_version_Integration_AspNetCore_Mvc%.nupkg" Releases\v%named_version%\

    echo Please run step 5
    goto :EOF	
)

IF %step%=="5" (
	set version_restore_line="    <VersionPrefix>4.0.0</VersionPrefix>"

	echo RESTORE VERSION NUMBERS
	%replace% /line "<VersionPrefix>" %version_restore_line% /source:SimpleInjector\SimpleInjector.csproj
	%replace% /line "<VersionPrefix>" %version_restore_line% /source:SimpleInjector.Integration.AspNetCore\SimpleInjector.Integration.AspNetCore.csproj
	%replace% /line "<VersionPrefix>" %version_restore_line% /source:SimpleInjector.Integration.AspNetCore.Mvc.Core\SimpleInjector.Integration.AspNetCore.Mvc.Core.csproj
	%replace% /line "<VersionPrefix>" %version_restore_line% /source:SimpleInjector.Integration.AspNetCore.Mvc\SimpleInjector.Integration.AspNetCore.Mvc.csproj
	%replace% /line "<VersionPrefix>" %version_restore_line% /source:SimpleInjector.Integration.Wcf\SimpleInjector.Integration.Wcf.csproj
	%replace% /line "<VersionPrefix>" %version_restore_line% /source:SimpleInjector.Integration.Web\SimpleInjector.Integration.Web.csproj
	%replace% /line "<VersionPrefix>" %version_restore_line% /source:SimpleInjector.Integration.Web.Mvc\SimpleInjector.Integration.Web.Mvc.csproj
	%replace% /line "<VersionPrefix>" %version_restore_line% /source:SimpleInjector.Integration.WebApi\SimpleInjector.Integration.WebApi.csproj
	%replace% /line "<VersionPrefix>" %version_restore_line% /source:SimpleInjector.Packaging\SimpleInjector.Packaging.csproj
	
	echo Done!
	GOTO :EOF	
)

echo Unknown step number.
GOTO :EOF

:release_directory_already_exists
echo The release directory already exists.
GOTO :EOF

:strong_name_key_missing
echo The strong name key SimpleInjector.snk does not exist. You should generate (a fake) one for this build script to work or copy fake.snk to SimpleInjector.snk to get things running.
GOTO :EOF

:msbuild_exe_missing
echo Couldn't locate MSBuild.exe. Expected  it  to be here: %msbuild%
GOTO :EOF

:vsvars32_bat_missing
echo Couldn't locate vsvars32.bat. Expected it to be here: %vsvars32_bat%
GOTO :EOF

:xcopy_missing
echo Couldn't locate xcopy. Expected it to be here: %xcopy%
GOTO :EOF