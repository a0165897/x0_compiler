%{
#include <stdio.h>
#include "my.tab.h"
int line=1;
void yyerror(char *);
void comment();
int yywrap(void);
%}
ID             [a-zA-Z_]([a-zA-Z_]|[0-9])*
mainsym        "main"
intsym         "int"
charsym        "char"
boolsym		   "bool"
NUM 		   [0-9]+
ifsym		   "if"
elsesym		   "else"
thensym		   "then"
whilesym	   "while"
writesym	   "write"
readsym		   "read"
dosym		   "do"
callsym 	   "call"
constsym	   "const"
procsym		   "proc"
repeatsym	   "repeat"
untilsym	   "until"
forsym	       "for"
continuesym    "continue"
returnsym	   "return"
breaksym	   "break"
exitsym	       "exit"
%%
"]["			   {return(DIM2);}
"++"			   {return SELFADD;}
"--"			   {return SELFMIUNS;}
"/*"			   {comment(); }
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
"begin"			   return BEGINSYM;
"end"			   return ENDSYM;
"("				   return *yytext;
")"				   return *yytext;
";"				   return *yytext;
"{"				   return *yytext;
"}"				   return *yytext;
{NUM}              {yylval.number=atoi(yytext);return(NUMBER);}
{mainsym}		   {return(MAINSYM);}
{intsym}		   {return(INTSYM);}
{charsym}		   {return(CHARSYM);}
{boolsym}		   {return(BOOLSYM);}
{ifsym}			   {return(IFSYM);}
{elsesym}		   {return(ELSESYM);}
{thensym} 		   {return(THENSYM);}
{whilesym} 		   {return(WHILESYM);}
{repeatsym}		   {return(REPEATSYM);}
{untilsym}		   {return(UNTILSYM);}
{forsym}		   {return(FORSYM);}
{continuesym}	   {return(CONTINUESYM);}
{breaksym}		   {return(BREAKSYM);}
{exitsym}  		   {return(EXITSYM);}
{writesym}		   {return(WRITESYM);}
{readsym}		   {return(READSYM);}
{dosym}		  	   {return(DOSYM);}
{callsym}		   {return(CALLSYM);}
{constsym}		   {return(CONSTSYM);}
{procsym}		   {return(PROCSYM);}
"and"			   {return(ANDSYM);}
"or"			   {return(ORSYM);}
"not"			   {return(NOTSYM);}
"true"			   {yylval.number=1;return(NUMBER);}
"false"			   {yylval.number=0;return(NUMBER);}
"ODD"			   {return(ODDSYM);}
"XOR"			   {return(XORSYM);}
"var"			   {return(VARSYM);}
">="			   {return(GEQ);}
"<="			   {return(LEQ);}
"=="			   {return(EQL);}
"!="		  	   {return(NEQ);}
{ID}   		   	   {yylval.ident=(char *)malloc(strlen(yytext)+1);
                                 strcpy(yylval.ident,yytext);return(IDENT);}
\n                 {/* ignore end of line */line++;}
[ \t]+             /* ignore whitespace */;
%%
void redirectInput(FILE *input)
{
	yyin=input;
}
int yygetchar(void)
{
	int ret;
	ret = getc(yyin);
	printf("%c",ret);
	return ret;
}

int yywrap(void)
{
	return 1;
}
void comment()
{
	char c, d;
loop:
	while ((c = input()) != '*' && c != 0);
		putchar(c);

	putchar(c);

	if ((d = input()) != '/' && c != 0)
	{
		unput(d);
		goto loop;
	}

	if (c != 0)
		putchar(d);

}
