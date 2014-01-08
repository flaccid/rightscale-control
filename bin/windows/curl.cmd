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

setlocal

call LocateSandBox.bat
if %ERRORLEVEL% neq 0 (
  exit /B %ERRORLEVEL%
)

rem # use installed location if curl.exe is not relative to RightLink home.
if "" equ "%RS_CURL_EXE%" (
  set RS_CURL_EXE=%RS_SANDBOX_HOME%\shell\bin\curl.exe
)
if not exist "%RS_CURL_EXE%" (
  set RS_CURL_EXE=%RS_RIGHT_LINK_INSTALL_HOME%\sandbox\shell\bin\curl.exe
)

rem # accept any curl.exe on the path if still not found.
if not exist "%RS_CURL_EXE%" (
  set RS_CURL_EXE=curl.exe
)

%RS_CURL_EXE% %*

exit /B %ERRORLEVEL%
