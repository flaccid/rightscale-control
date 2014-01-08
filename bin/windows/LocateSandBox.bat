@echo off
rem # Copyright (c) 2010-2012 RightScale Inc
rem #
rem # Permission is hereby granted, free of charge, to any person obtaining
rem # a copy of this software and associated documentation files (the
rem # "Software"), to deal in the Software without restriction, including
rem # without limitation the rights to use, copy, modify, merge, publish,
rem # distribute, sublicense, and/or sell copies of the Software, and to
rem # permit persons to whom the Software is furnished to do so, subject to
rem # the following conditions:
rem #
rem # The above copyright notice and this permission notice shall be
rem # included in all copies or substantial portions of the Software.
rem #
rem # THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
rem # EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
rem # MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
rem # NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
rem # LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
rem # OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
rem # WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


rem # test the installed sandbox by default instead of running from dev. this
rem # is meant to aid in testing on the cloud. if this is a dev directory test,
rem # then either uninstall the sandbox or else set the env vars prior to
rem # calling this batch file.

if "" equ "%RS_RIGHT_LINK_INSTALL_HOME%" (
  if "" equ "%ProgramFiles(x86)%" (
    call :ConvertToFullPath RS_RIGHT_LINK_INSTALL_FULL_HOME "%ProgramFiles%\RightScale\RightLink"
  ) else (
    call :ConvertToFullPath RS_RIGHT_LINK_INSTALL_FULL_HOME "%ProgramFiles(x86)%\RightScale\RightLink"
  )
) else (
  call :ConvertToFullPath RS_RIGHT_LINK_INSTALL_FULL_HOME "%RS_RIGHT_LINK_INSTALL_HOME%"
)
call :ConvertToShortPath RS_RIGHT_LINK_INSTALL_HOME "%RS_RIGHT_LINK_INSTALL_FULL_HOME%"

if "" equ "%RS_RIGHT_LINK_HOME%" (
  if exist "%RS_RIGHT_LINK_INSTALL_FULL_HOME%" (
    call :ConvertToFullPath RS_RIGHT_LINK_FULL_HOME "%RS_RIGHT_LINK_INSTALL_FULL_HOME%"
  ) else (
    call :ConvertToFullPath RS_RIGHT_LINK_FULL_HOME "%~dp0.."
  )
) else (
  if "" equ "%RS_RIGHT_LINK_FULL_HOME%" (
    call :ConvertToFullPath RS_RIGHT_LINK_FULL_HOME "%RS_RIGHT_LINK_HOME%"
  )
)
call :ConvertToShortPath RS_RIGHT_LINK_HOME "%RS_RIGHT_LINK_FULL_HOME%"

if "" equ "%RS_SANDBOX_HOME%" (
  set RS_SANDBOX_HOME=%RS_RIGHT_LINK_HOME%\sandbox
)


rem # attempt to resolve ruby home. note that the redundancy of the following
rem # if statements is due in part to not being able to both set and read
rem # environment variables within the scope of an if block; lame but true.
if "" equ "%RS_RUBY_HOME%" (
  if exist "%RS_SANDBOX_HOME%\ruby" (
    set RS_RUBY_HOME=%RS_SANDBOX_HOME%\ruby
    set RS_RUBY_EXE=%RS_RUBY_HOME%\bin\ruby.exe
  )
)
if "" equ "%RS_RUBY_EXE%" (
  if exist "%RS_RIGHT_LINK_INSTALL_HOME%\sandbox\Ruby\bin\ruby.exe" (
    set RS_RUBY_HOME=%RS_RIGHT_LINK_INSTALL_HOME%\sandbox\ruby
    set RS_RUBY_EXE=%RS_RIGHT_LINK_INSTALL_HOME%\sandbox\ruby\bin\ruby.exe
  )
)
if "" equ "%RS_RUBY_EXE%" (
  rem # try to find ruby on the path using our "which.cmd" as a last attempt
  rem # due to running a little slow on vm's, etc.
  call %~dps0which.cmd ruby RS_RUBY_EXE
)
if "" equ "%RS_RUBY_HOME%" (
  if "" neq "%RS_RUBY_EXE%" (
    set RS_RUBY_HOME=%RS_RUBY_EXE%.\..\..
  )
)
if "" equ "%RS_RUBY_HOME%" (
  echo RS_RUBY_HOME could not be resolved.
  exit /B 110
)
if not exist %RS_RUBY_HOME% (
  echo %RS_RUBY_HOME% does not exist.
  exit /B 111
)
call :ConvertToShortPath RS_RUBY_HOME %RS_RUBY_HOME%
set RS_RUBY_EXE=%RS_RUBY_HOME%\bin\ruby.exe
if not exist %RS_RUBY_EXE% (
  echo %RS_RUBY_EXE% does not exist.
  exit /B 112
)


rem # set gem shortcut for convenience and because ruby\bin\gem.bat will run
rem # any ruby.exe which appears first on the path.
set RS_GEM=%RS_RUBY_EXE% %RS_RUBY_HOME%\bin\gem


rem # done
exit /B 0


rem # subroutine hack to convert a long path to a short path

:ConvertToShortPath
  set %1=%~fs2
  goto :EOF

rem # subroutine hack to convert a partial path to a full path

:ConvertToFullPath
  set %1=%~f2
  goto :EOF
