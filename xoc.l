%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <malloc.h>
#include "xoc.tab.h"

int line=1;
void yyerror(char *);
int yywrap(void);
%}


%%
"main"			   {return(MAINSYM);}
"int"			   {return(INTSYM);}
"char"			   {return(CHARSYM);}
"bool"			   {return(BOOLSYM);}
"if"			   {return(IFSYM);}
"else"			   {return(ELSESYM);}
"then"	 		   {return(THENSYM);}
"while" 		   {return(WHILESYM);}
"repeat"		   {return(REPEATSYM);}
"until"			   {return(UNTILSYM);}
"for"			   {return(FORSYM);}
"continue"	 	   {return(CONTINUESYM);}
"break"			   {return(BREAKSYM);}
"exit"  		   {return(EXITSYM);}
"write"			   {return(WRITESYM);}
"read"			   {return(READSYM);}
"do"		  	   {return(DOSYM);}
"call"			   {return(CALLSYM);}
"const"		  	   {return(CONSTSYM);}
"function"		   {return(PROCSYM);}
"&"			       {return(ANDSYM);}
"|"			       {return(ORSYM);}
"!"			   	   {return(NOTSYM);}
"true"			   {yylval.number=1; return(NUMBER);}
"false"			   {yylval.number=0; return(NUMBER);}
"ODD"			   {return(ODDSYM);}
"XOR"			   {return(XORSYM);}
"var"			   {return(VARSYM);}
">="			   {return(GEQ);}
"<="			   {return(LEQ);}
"=="			   {return(EQL);}
"!="		  	   {return(NEQ);}
[A-Za-z]([A-Za-z]|[0-9])*	{yylval.ident=(char *)malloc(strlen(yytext)+1);
                       	 		strcpy(yylval.ident,yytext);
								return(IDENT);
							}
[0-9]+             {yylval.number=atoi(yytext);return(NUMBER);}
[\n]               {line++;}
[ \t]+             ;
[/][*].*[*][/]	   ;
[/][/].*[\n]	   ;
"++"			   {return SFPLUS;}
"--"			   {return SFMINS;}
"*"				   return *yytext;
"/"				   return *yytext;
"+"				   return *yytext;
","				   return *yytext;
"<"				   return *yytext;
"["				   return *yytext;
"]"				   return *yytext;
">"				   return *yytext;
"-"				   return *yytext;
"="				   return *yytext;
"%"				   return *yytext;
"("				   return *yytext;
")"				   return *yytext;
";"				   return *yytext;
"{"				   return *yytext;
"}"				   return *yytext;
%%



void redirectInput(FILE *input){
	yyin=input;
}

int yygetchar(void){
	int ret;
	ret = getc(yyin);
	printf("%c",ret);
	return ret;
}

int yywrap(void){
	return 1;
}

