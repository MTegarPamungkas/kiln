@echo off
cd /d "%~dp0..\packages\kiln_cli"
dart compile exe bin\kiln.dart -o "%~dp0kiln.exe"
