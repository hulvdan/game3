@echo off
cd /d "%~dp0/.."
call "c:\Users\user\dev\home\emsdk\emsdk.bat" activate latest
call "c:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvarsall.bat" x64
set EMSCRIPTEN=c:\Users\user\dev\home\emsdk\upstream\emscripten
codium .
