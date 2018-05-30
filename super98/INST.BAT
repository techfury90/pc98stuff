echo off

if not "%1"=="" goto inst

:usage
echo Usage: inst ><dir<>
goto exit

:inst
if not exist %1\nul		md %1

if not exist %1\src\nul		md %1\src
if not exist %1\src\cpu\nul	md %1\src\cpu
if not exist %1\src\text\nul	md %1\src\text
if not exist %1\src\graph\nul	md %1\src\graph
if not exist %1\src\gdc\nul	md %1\src\gdc
if not exist %1\src\grcg\nul	md %1\src\grcg
if not exist %1\src\egc\nul	md %1\src\egc
if not exist %1\src\kbd\nul	md %1\src\kbd
if not exist %1\src\rs232c\nul	md %1\src\rs232c
if not exist %1\src\pic\nul	md %1\src\pic
if not exist %1\src\peri\nul	md %1\src\peri

if not exist %1\lib\nul		md %1\lib
if not exist %1\sample\nul	md %1\sample

copy *.*	%1

copy src\cpu	%1\src\cpu
copy src\text	%1\src\text
copy src\graph	%1\src\graph
copy src\gdc	%1\src\gdc
copy src\grcg	%1\src\grcg
copy src\egc	%1\src\egc
copy src\kbd	%1\src\kbd
copy src\rs232c	%1\src\rs232c
copy src\pic	%1\src\pic
copy src\peri	%1\src\peri

copy lib	%1\lib
copy sample	%1\sample

:exit
