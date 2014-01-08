@echo off
rem # Copyright (c) 2009-2011 RightScale Inc
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

if "" equ "%1" (
  echo Usage: which {executable file name}[.{extension}] [environment var to set]
  goto :EOF
)

setlocal

rem # the trivial PATH lookup works only if the caller is kind enough to provide
rem # the correct file extension. we don't want to find any directories which
rem # have the same name as the executable and are on the PATH, so don't try the
rem # case without an extension.

set FIRST_MATCH_WINNER=
if "" neq "%~x1" (

  call :TryExtension %1

) else (

  rem # the user is not providing a file extension so, iterate over known
  rem # executable file extensions and attempt to match one of these on
  rem # the PATH.

  FOR /F "tokens=1-26 delims=;" %%a in ("%PATHEXT%") do (
    if "" neq "%%a" call :TryExtension %1%%a
    if "" neq "%%b" call :TryExtension %1%%b
    if "" neq "%%c" call :TryExtension %1%%c
    if "" neq "%%d" call :TryExtension %1%%d
    if "" neq "%%e" call :TryExtension %1%%e
    if "" neq "%%f" call :TryExtension %1%%f
    if "" neq "%%g" call :TryExtension %1%%g
    if "" neq "%%h" call :TryExtension %1%%h
    if "" neq "%%i" call :TryExtension %1%%i
    if "" neq "%%j" call :TryExtension %1%%j
    if "" neq "%%k" call :TryExtension %1%%k
    if "" neq "%%l" call :TryExtension %1%%l
    if "" neq "%%m" call :TryExtension %1%%m
    if "" neq "%%n" call :TryExtension %1%%n
    if "" neq "%%o" call :TryExtension %1%%o
    if "" neq "%%p" call :TryExtension %1%%p
    if "" neq "%%q" call :TryExtension %1%%q
    if "" neq "%%r" call :TryExtension %1%%r
    if "" neq "%%s" call :TryExtension %1%%s
    if "" neq "%%t" call :TryExtension %1%%t
    if "" neq "%%u" call :TryExtension %1%%u
    if "" neq "%%v" call :TryExtension %1%%v
    if "" neq "%%w" call :TryExtension %1%%w
    if "" neq "%%x" call :TryExtension %1%%x
    if "" neq "%%y" call :TryExtension %1%%y
    if "" neq "%%z" call :TryExtension %1%%z
  )
)

if "" neq "%FIRST_MATCH_WINNER%" (
  if "" equ "%2" (
    echo %FIRST_MATCH_WINNER%
  ) else (
    endlocal
    set %2=%FIRST_MATCH_WINNER%
  )
  goto :EOF
)

:NoMatch
  if "" neq "%2" (
    endlocal
    set %2=
  )
  goto :EOF


rem # tries to find the file with name and extension provided on the PATH,
rem # giving precedence to the current working directory. this behavior
rem # differs from linux, which ignores the CWD, and is specific to windows.
rem # if successful, then FIRST_MATCH_WINNER is set to the short directory
rem # path because echo cannot output a string containing space
rem # characters without surrounding quotes (which we don't want here).
:TryExtension
  if "" neq "%FIRST_MATCH_WINNER%" goto :EOF
  if exist "%CD%\%~nx1" (
    call :ConvertToShortPath FIRST_MATCH_WINNER "%CD%\%~nx1"
  ) else (
    set FIRST_MATCH_WINNER=%~dpsnx$PATH:1
  )
  goto :EOF


rem # subroutine hack to convert a long path to a short path
:ConvertToShortPath
  set %1=%~fs2
  goto :EOF
