@echo off
setlocal
set path=%path%;lex-yacc\bin
flex xoc.l
bison -d xoc.y 
gcc -g -o xoc  lex.yy.c xoc.tab.c -lm
pause