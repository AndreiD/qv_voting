@echo off
if [%1]==[] goto usage

rmdir /Q /S build
truffle.cmd migrate --network %1

:usage
@echo Please add in arguments network name: dev, qa, private
exit 1
