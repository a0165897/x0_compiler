%{
    #include <stdio.h>
    #include <stdlib.h>
    #include <string.h>

    #define true 1
    #define false 0
    #define bool int

    #define txmax 100 //符号表容量
    #define al 10   //标识符最长长度
    #define amax 2048 //地址上界
    #define levmax 3  //嵌套深度
    #define cxmax 200  //最多的pcode条数
    #define stacksize 5000 //栈元素上界
    #define arraysize 10000

    enum object{
      constant,
      variable,
      procedure,
      array,
    };
    enum vartype{
      intype,
      chartype,
      booltype,
    };
  /*符号表结构*/
    struct tablestruct{
      char name[al];    /* 名字 */
      enum object kind; /* 类型：const，var，array或procedure */
      enum vartype idtype;
      int val;      /* 数值，仅const使用 */
      int level;
      int adr;      /* 地址，仅const不使用 */
      int size;
      bool isarray;
      // int arraylist[arraysize];
      /* 存储数组的值 arraysize */
      int arraylen;/* 记录数组长度 */
      int dim;
      int lay[5];
    };

    struct tablestruct table[txmax]; //符号表
    /*pcode指令*/
    enum fct{
      lit,  opr,  lod,
      sto,  cal,  ini,
      jmp,  jpc,  loa,
      sta,  hod,  cpy,
      jpe,  ext,  cla,
      tss,  tsl
    };

    struct instruction
    {
      enum fct f;
      int l;
      int a;
    };

    struct instruction code[cxmax];//存放pcode的数组


    int tx;   //符号表当前尾指针
    int cx;   //pcode代码指针
    int px;   

    int lev;  //层次记录
    int proctable[3]; //嵌套过程索引表
    char id[al];
    int num;
    bool listswitch;   /* 显示虚拟机代码与否 */
    bool tableswitch;  /* 显示符号表与否 */

    FILE* fin;      /* 输入源文件 */
    FILE* ftable;   /* 输出符号表 */
    FILE* fcode;    /* 输出虚拟机代码 */
    FILE* foutput;  /* 输出出错示意（如有错） */
    FILE* fresult;  /* 输出执行结果 */
    FILE* fstack;   /* 输出每一步栈的结果 */
    char fname[al];
    int err;

    void init();
    void enter(enum vartype T, enum object k, int arraylen, int dim, int lay[]);
    int position(char* s);
    void setdx(int n);
    void gen(enum fct x, int y, int z);
    void listall();
    void displaytable();
    int base(int l, int* s, int b);
    void enterbreak(int exit);//填写break出口
    void entercond(int exit);//填写continue出口
    char symbol[20];//当前的ident的类型 是数组还是单个变量
    int nowlen;//如果是数组的话 访问的事第几个单元
    char category[10];//判断当前id是否是整形还是字符类型还是布尔类型
    int dx;//记录符号表的个数 而不是地址空间的个数即数组为1个变量
    int extralen;//记录由于存在数组而多出来的需要分配的个数

    bool loopstate = 0;//记录是否进入loop状态
    int contnum;
    int breaknum;
    int breaklist[al];//需要填写的break出口列表
    int contlist[al];


%}

%union{
  char* ident;
  int number;
}

%token BEGINSYM CALLSYM CONSTSYM DOSYM ENDSYM IFSYM ODDSYM PROCSYM EXITSYM
%token READSYM THENSYM VARSYM WHILESYM WRITESYM ELSESYM DOSYM UNTILSYM

%token MAINSYM INTSYM CHARSYM NUM NEQ EQL LEQ GEQ XORSYM REPEATSYM BOOLSYM
%token ANDSYM ORSYM NOTSYM SELFMIUNS SELFADD FORSYM CONTINUESYM BREAKSYM
%token DIM2 

%left '+''-'
%left '*''/' 
%token <ident> IDENT
%token <number> NUMBER

%type <number> ident var forexpr
%type <number> vardecl varlist vardef declaration_list
%type <number> get_table_addr get_code_addr
%%
/*  分程序 */
program:
  MAINSYM
  '{'
    block
  '}'
  ;
block:         {               
                table[tx].adr = cx;         /* 记录当前层代码的开始位置 */  
                $<number>$ = cx;
                gen(jmp, 0 , 0);            /* 产生跳转指令，跳转位置未知暂时填0 */
               }
               get_table_addr               /* 记录本层标识符的初始位置 */
               constdecl declaration_list
               {
                 printf("变量声明完成%d\n",$4 - extralen);
                 setdx($4 - extralen);
                 extralen=0;/* 分配变量相对地址 */
               }  
               procdecls
               {
                code[$<number>1].a = cx;    /* 把前面生成的跳转语句的跳转位置改成当前位置 */
                table[$2].adr = cx;         /* 记录当前过程代码地址 */
                table[$2].size = $4 + 3;    /* 记录当前过程分配数据大小 */
                gen(ini, 0, $4 + 3);
                displaytable();
               }
                statements
               {
                gen(opr, 0 , 0);                
                tx = proctable[px];
               }
          ;
/*  过程声明 */
procdecls: | {puts("---");}
          procdecls procdecl procbody '}'
           
          ;
/*  过程声明头部 */
procdecl: inc_px PROCSYM IDENT  '{'
               {                 
                 strcpy(id, $3);
                 enter(-1, procedure, 0, 0, NULL); 
                 proctable[px] = tx;                
               }
          ;

/*  过程声明主体 */
procbody: inc_level block dec_level_px  
          ;
/*  常量声明 */
constdecl: CONSTSYM constlist ';' 
          |
          ;

/* 常量声明列表 */
constlist: constdef 
          | constlist ',' constdef 
          ;

/* 单个常量 */
constdef: IDENT '=' NUMBER
               {
                strcpy(id,$1);   
                num = $3;
                enter(intype, constant, 0, 0, NULL);
              }
          ;
declaration_list:
  declaration_list  vardecl{
    $$ = $1 + $2;
  }
  |vardecl{
    $$ = $1;
  }
  ;
/*  变量声明 */
vardecl: type varlist ';'
               {
                $$ = $2;         /* 传递变量声明的个数 */

               }
          |
              {
                $$ = 0;          /* 没有变量声明 */
              } 
          ;
type:
  INTSYM{
    strcpy(category, "int");
  }
  |CHARSYM{
    strcpy(category, "char");
  }
  |BOOLSYM{
    strcpy(category, "bool");
  }
/* 变量声明列表 */
varlist: vardef 
               {
                $$ = $1;
               }
          | varlist ',' vardef 
               {
                $$ = $1 + $3;  /* 变量声明的个数相加 */
               }
          ;
         
/* 单个变量 */
vardef: IDENT 
               {
                strcpy(id, $1);
                if(category[0] == 'c')
                  enter(chartype, variable, 0, 0, NULL); 
                else if(category[0] == 'i')
                  enter(intype, variable, 0, 0, NULL); 
                else
                  enter(booltype, variable, 0, 0, NULL);
                $$ = 1;
               }
         | IDENT '[' NUMBER ']'
         {
                strcpy(id, $1);
                int temp[] = {$3};
                if(category[0] == 'c')
                  enter(chartype, array, $3, 1, temp); 
                else if(category[0] == 'i')
                  enter(intype, array, $3, 1, temp); 
                else
                  enter(booltype, array, $3, 1, temp); 
                $$ = $3;
                extralen += $3 - 1;
                printf("我是数组定义%d over\n", $3);
               }
         | IDENT '[' NUMBER DIM2 NUMBER ']'
         {
                strcpy(id, $1);
                int temp[] = {$3, $5};
                if(category[0] == 'c')
                  enter(chartype, array, $3 * $5, 2, temp); 
                else if(category[0] == 'i')
                  enter(intype, array, $3 * $5, 2, temp); 
                else
                  enter(booltype, array, $3 * $5, 2, temp); 
                $$ = $3 * $5;
                extralen += $3 * $5 - 1;
                printf("我是数组定义%d over\n", $3);
               }
          ;



/*  语句 */
statement: assignmentstm 
          | callstm 
          | compoundstm 
          | ifstm 
          | whilestm 
          | readstm 
          | writestm 
          | selfplusminus
          | repeatstm
          | dowhilestm
          | forloopstm
          | continuestm
          | breakstm
          | exitstm

          ;
exitstm:  EXITSYM ';'
        {
          gen(ext, 0, 0);
        }
continuestm:
        CONTINUESYM get_code_addr ';'{
          gen(jmp, 0, 0);
          contlist[contnum++] = $2;
        }
breakstm:
        BREAKSYM get_code_addr ';'{
          gen(jmp, 0, 0);
          breaklist[breaknum++] = $2;
        }
/*  for loop 循环语句 */   
forloopstm:
         FORSYM '(' forexpr ';' get_code_addr
         forexpr 
         {
          /*用于判断是否是无条件限制循环 仅在for的语句2中会使用*/
          if($6 == 1)
            gen(lit, 0, 1);
        }
         ';' get_code_addr
         {
          loopstate = 1;
          gen(jpe, 0, 0);
          gen(jmp, 0, 0);
         } get_code_addr forexpr ')'
         {
          gen(jmp, 0, $5);
         } 
         get_code_addr
         statement{
          gen(jmp, 0, $11);
          code[$9].a = $15;
          code[$9 + 1].a = cx;
          enterbreak(cx);
          entercond($11);
          loopstate = 0;
         }
         ;

forexpr:
        {$$ = 1;/*用于判断是否是无条件限制循环 仅在for的语句2中会使用*/}|expression{
  {$$ = 0;/*用于判断是否是无条件限制循环 仅在for的语句2中会使用*/}
}
      ;
/*  do while 循环语句 */   
dowhilestm:
      DOSYM get_code_addr statement get_code_addr
      WHILESYM '(' condition get_code_addr
      {
        gen(jpe, 0, $2);
        entercond($4);
        enterbreak($8);
      }
      ')' ';'
      ;      
/*  repeat until 循环语句 */   
repeatstm:
      REPEATSYM get_code_addr statement get_code_addr
      UNTILSYM '(' condition get_code_addr
      {
        gen(jpc, 0, $2);
        entercond($4);
        enterbreak($8);
      }
      ')' ';'
      ;
/*  自增自减语句 */
selfplusminus: var SELFADD ';'
        {
          if (table[$1].kind == variable)
          {
            gen(lod, lev - table[$1].level, table[$1].adr);
            gen(lit, 0, 1);
            gen(opr, 0, 2);
            gen(sto, lev - table[$1].level, table[$1].adr);
          }
          else if(table[$1].kind == array)
          {
            gen(cpy, 0, 0);
            gen(tsl, 0, table[$1].arraylen);
            gen(loa, lev - table[$1].level, table[$1].adr);
            gen(lit, 0, 1);
            gen(opr, 0, 2);
            gen(tss, 0, table[$1].arraylen);
            gen(sta, lev - table[$1].level, table[$1].adr);
          }
        }
      | var SELFMIUNS ';'
        {
          if (table[$1].kind == variable)
          {
            gen(lod, lev - table[$1].level, table[$1].adr);
            gen(lit, 0, 1);
            gen(opr, 0, 3);
            gen(sto, lev - table[$1].level, table[$1].adr);
          }
          else if(table[$1].kind == array)
          {
            gen(cpy, 0, 0);
            gen(tsl, 0, table[$1].arraylen);
            gen(loa, lev - table[$1].level, table[$1].adr);
            gen(lit, 0, 1);
            gen(opr, 0, 3);
            gen(tss, 0, table[$1].arraylen);
            gen(sta, lev - table[$1].level, table[$1].adr);
          }
        }
  
/*  赋值语句 */
assignmentstm: var '=' expression ';'
               {
                 printf("我%s赋值语句也被执行到了!! \n", table[$1].name);
                 if ($1 == 0)
                       yyerror("Symbol does not exist");
                 else
                    {
                       if (table[$1].kind == array)
                        {
                          gen(tss, 0, table[$1].arraylen);
                          gen(sta, lev - table[$1].level, table[$1].adr);
                        }
                       else if (table[$1].kind == variable)
                           gen(sto, lev - table[$1].level, table[$1].adr);
                       else{
                           yyerror("Symbol should be a variable");
                       }
                    }
               }
          ;

/*  调用语句 */
callstm: CALLSYM ident ';'
             {
                 if ($2 == 0)
                       yyerror("call Symbol does not exist");
                 else
                    {
                       if (table[$2].kind != procedure)
                           yyerror("Symbol should be a procedure");
                       else
                           gen (cal, lev - table[$2].level, table[$2].adr);    
                    }
              }
          ;

/* 复合语句 */
compoundstm: '{' statements '}' 
          ;

/* 一条或多条语句 */
statements: statement 
          | statements statement 
          ;

/* 条件语句 */
ifstm: IFSYM '(' condition ')' get_code_addr 
               {
                gen(jpc, 0, 0);
               }
        statement 
               {
                code[$5].a = cx + 1;//如果没有满足if条件 跳转到else处
                gen(jmp, 0, 0);
               }
        get_code_addr
        elsestm
        {
          code[$9 - 1].a = cx;//回填if的无条件跳转
        }
          ;
   
elsestm:
  |ELSESYM statement
  ;
/* 循环语句 */
whilestm: WHILESYM get_code_addr '(' condition ')' get_code_addr 
               {
                gen(jpc, 0 , 0);
               }
          statement
               {
                gen(jmp, 0, $2);
                code[$6].a = cx;
                enterbreak(cx);
                entercond($2);
               }
          ;

/* 读语句 */
readstm: READSYM  readvarlist  ';'
          ;

/* 一个或多个读语句的变量 */
readvarlist: readvar | readvarlist ',' readvar 
          ;
/* 读语句变量 */
readvar: var 
               {
                gen(opr, 0, 16);
                if(table[$1].kind == variable) 
                  gen(sto, lev - table[$1].level, table[$1].adr);
                else
                  {gen(tss, 0, table[$1].arraylen);
                  gen(sta, lev - table[$1].level, table[$1].adr);
                }
               }
          ;

var: ident 
               {
                printf("看到我%s了吗~~ 我从ident变成var了\n",table[$$].name);
                $$ = $1;
                symbol[0] = 'v';//当前符号是单个变量
                // gen(opr, 0, 16);
                // gen(sto, lev - table[$1].level, table[$1].adr);
               } 
    | ident '[' expression ']'
               {
                  printf("看到我%s了吗~~ 我从ident[]变成var了\n",table[$$].name);
                  $$ = $1;
                  symbol[0] = 'a';//当前符号是一个array
                  // gen(opr, 0, 16);
                  // gen(sto, lev - table[$1].level, table[$1].adr);
               }
    | ident '[' expression DIM2 expression ']'
               {
                  // printf("?????\n");
                  $$ = $1;
                  gen(lit, 0, table[$1].lay[1]);
                  // printf("!!!\n");
                  gen(cla, 0, 0);
               } 
    ;
          ;

/* 写语句 */
writestm: WRITESYM var                
          { if ($2 == 0)
                       yyerror("Symbol does not exist");
                 else
                    {
                       if (table[$2].kind == procedure)
                           yyerror("Symbol should not be a procedure");
                       else if(table[$2].kind == variable)
                          {
                            gen(lod, lev - table[$2].level, table[$2].adr);
                            if(table[$2].idtype != chartype)
                              gen(opr, 0, 14);
                              else
                                gen(opr, 0, 17);
                                gen(opr, 0, 15);    
                          }
                        else if (table[$2].kind == constant){//或者是常数
                               gen(lit, 0, table[$2].val);
                               gen(opr, 0, 14);
                               gen(opr, 0, 15);    
                        }
                        else{
                            gen(tsl, 0, table[$2].arraylen);
                            gen(loa, lev - table[$2].level, table[$2].adr);
                            if(table[$2].idtype != chartype)
                              gen(opr, 0, 14);
                            else
                              gen(opr, 0, 17);
                            gen(opr, 0, 15);    
                        }
                    }
                } ';'
                |WRITESYM expression{
                gen(opr, 0, 14);
                gen(opr, 0, 15);
               }';'
          ;


/* 条件表达式 */
condition: 
          |factor
          |ODDSYM expression 
               {
                gen(opr, 0, 6);
               }
          | NOTSYM expression
               {
                gen(opr, 0, 20);
               }
          | expression EQL expression 
               {
                gen(opr, 0, 8);
               }
          | expression NEQ expression 
               {
                gen(opr, 0, 9);
               }
          | expression '<' expression 
               {
                gen(opr, 0, 10);
               }
          | expression LEQ expression 
               {
                gen(opr, 0, 13);
               }
          | expression '>' expression 
               {
                gen(opr, 0, 12);
               }
          | expression GEQ expression 
               {
                gen(opr, 0, 11);
               }
          | expression ANDSYM expression
               {
                gen(opr, 0, 21);//取and操作
               }
          | expression ORSYM expression
               {
                gen(opr, 0, 22);//取and操作
               }
          ;
/* 表达式 */
expression: '+' term
          | '-' term
               {
                gen(opr, 0, 1);
               }
          | term             
          | expression '+' term
               {
                gen(opr, 0, 2);
               }
          | expression '-' term
               {
                gen(opr, 0, 3);
               }
          | var '=' expression
          {

                if(table[$1].kind == variable)
                {            
                  gen(sto, lev - table[$1].level, table[$1].adr);
                  gen(lod, lev - table[$1].level, table[$1].adr);
                  printf("我variable %s表达式赋值 被执行到了!! \n",table[$1].name);
                }
                else if(table[$1].kind == array)
                {
                  gen(tss, 0, table[$1].arraylen);
                  gen(sta, lev - table[$1].level, table[$1].adr);
                  gen(hod, 0, 0);
                  // gen(loa, lev - table[$1].level, table[$1].adr);
                  printf("我array %s表达式赋值 被执行到了!! \n",table[$1].name);
                }

          }
          | condition{puts("看我!! 我是伪装成表达式的条件语句");};
          
          ;

/* 项 */
term: factor
          | term '*' factor
               {
                gen(opr, 0, 4);
               }
          | term '/' factor
               {
                gen(opr, 0, 5);
               }  
          | term '%' factor
                {
             gen(opr, 0, 18);
            }
        | term XORSYM factor
                {
             gen(opr, 0, 19);
            }      
          ;

/* 因子 */
factor: var
               { if ($1 == 0)
                       yyerror("Symbol does not exist");
                 else
                    {
                       if (table[$1].kind == procedure)
                           yyerror("Symbol should not be a procedure");
                       else
                          {
                            if(table[$1].kind == constant)
                               gen(lit, 0, table[$1].val);
                            else if(table[$1].kind == variable)
                               gen(lod, lev - table[$1].level, table[$1].adr);
                            else if(table[$1].kind == array)
                               {gen(tsl, 0, table[$1].arraylen);
                               gen(loa, lev - table[$1].level, table[$1].adr);
                             }
                          }
                    }
                }   
          | NUMBER 
               {
                gen(lit, 0, $1);
               }
          | '(' expression ')';
          | var SELFADD {
          if (table[$1].kind == variable)
          {
            gen(lod, lev - table[$1].level, table[$1].adr);
            gen(lit, 0, 1);
            gen(opr, 0, 2);
            gen(sto, lev - table[$1].level, table[$1].adr);
            gen(hod, 0, 0);
          }
          else if(table[$1].kind == array)
          {
            gen(cpy, 0, 0);
            gen(tsl, 0, table[$1].arraylen);
            gen(loa, lev - table[$1].level, table[$1].adr);
            gen(lit, 0, 1);
            gen(opr, 0, 2);
            gen(tss, 0, table[$1].arraylen);
            gen(sta, lev - table[$1].level, table[$1].adr);
            gen(hod, 0, 0);
          }
          }
          | var SELFMIUNS{
          if (table[$1].kind == variable)
          {
            gen(lod, lev - table[$1].level, table[$1].adr);
            gen(lit, 0, 1);
            gen(opr, 0, 3);
            gen(sto, lev - table[$1].level, table[$1].adr);
            gen(hod, 0, 0);
          }
          else if(table[$1].kind == array)
          {
            gen(cpy, 0, 0);
            gen(tsl, 0, table[$1].arraylen);
            gen(loa, lev - table[$1].level, table[$1].adr);
            gen(lit, 0, 1);
            gen(opr, 0, 3);
            gen(tss, 0, table[$1].arraylen);
            gen(sta, lev - table[$1].level, table[$1].adr);
            gen(hod, 0, 0);
          }
          }

ident: IDENT 
               {
                $$ = position ($1); 
               }
          ;
get_table_addr:
               {
                $$ = tx;
               } 
          ;
get_code_addr:
               {
                $$ = cx;
               }
          ;

inc_level:
               {
                lev++;               
                if (lev > levmax)   /* 嵌套层数过多 */
                     yyerror("Lev is too big");    
               }
          ;
inc_px:
              {
               px++;              
              }     
          ;
dec_level_px:
              {
                lev--;
                px--;              
              }    
          ;

////////////////////////////////////////////////////////
//程序部分
%%
extern int line;
int yyerror(char *s)
{
  err = err + 1;
  printf("%s in line %d\n", s, line);
  fprintf(foutput, "%s in line %d\n", s, line);
  return 0;
}

/* 初始化 */
void init()
{
    tx = 0;
    cx = 0;
    px = 0;  
    lev = 0;   
    proctable[0] = 0;
    num = 0;
    err = 0;
}

/* 填写所有的break出口 */
void enterbreak(int exit)
{
  int i = 0;
  for(i = 0; i < breaknum; i++)
    code[breaklist[i]].a = exit;
  breaknum = 0;
}

/* 填写所有的continue出口 */
void entercond(int exit)
{
  int i = 0;
  for(i = 0; i < contnum; i++)
    code[contlist[i]].a = exit;
  contnum = 0;
}


/* 在符号表中加入一项 */
void enter(enum vartype T, enum object k, int arraylen, int dim, int lay[])
{
    int i;
  tx = tx + 1;
  strcpy(table[tx].name, id);
  table[tx].kind = k;
  switch (k)
  {
    case array: /* 数组 */  
      table[tx].level = lev;
      table[tx].idtype = T;
      table[tx].arraylen = arraylen;
      for(i = 0; i < dim; i++)
          {
              table[tx].lay[i] = lay[i];
              // printf("%d ", lay[i]);
          }
      table[tx].dim = dim;
      break;
    case constant:  /* 常量 */      
      table[tx].val = num; /* 登记常数的值 */
      break;
    case variable:  /* 变量 */
      table[tx].level = lev;
      table[tx].idtype = T;
      break;
    case procedure: /* 过程 */
      table[tx].level = lev;
      break;
  }
}

/* 查找标识符在符号表中的位置 */
int position(char *s)
{
  int i;
  strcpy(table[0].name, s);
  i = tx;
  while(strcmp(table[i].name, s) != 0)
    i--;
  return i;
}

/* 为本层变量分配相对地址，从3开始分配 */
void setdx(int n)
{
  int i;
  int extra = 0;
  for(i = n; i >= 1; i--)
  {
    table[tx - i + 1].adr = extra + n - i + 3;
    printf("%s: %d\n",table[tx - i + 1].name, extra + n - i + 3);
    if(table[tx - i + 1].kind == array)
    {
      extra += table[tx - i + 1].arraylen - 1;
    }
  }
}

/* 生成虚拟机代码 */
void gen(enum fct x, int y, int z)
{
  if (cx >= cxmax)
  {
    printf("Program is too long!\n"); /* 生成的虚拟机代码程序过长 */
    exit(1);
  }
  if ( z >= amax)
  {
    printf("Displacement address is too big!\n"); /* 地址偏移越界 */
    exit(1);
  }
  code[cx].f = x;
  code[cx].l = y;
  code[cx].a = z;
  cx++;
}

/* 输出所有目标代码  */
void listall()
{
  int i;
  char name[][5]=
  {
    {"lit"},{"opr"},{"lod"},{"sto"},{"cal"},{"int"},{"jmp"},{"jpc"},{"loa"},{"sta"},{"hod"},
    {"cpy"},{"jpe"},{"ext"},{"cla"},{"tss"},{"tsl"}
  };
  if (listswitch)
  {
    for (i = 0; i < cx; i++)
    {
      printf("%d %s %d %d\n", i, name[code[i].f], code[i].l, code[i].a);
      fprintf(fcode,"%d %s %d %d\n", i, name[code[i].f], code[i].l, code[i].a);
      
    }
  }
}

/* 输出符号表 */
void displaytable()
{
  int i;
if (tableswitch)    /* 输出符号表 */
  {
  
  for (i = 1; i <= tx; i++)
    {
      switch (table[i].kind)
      {
        case array:
          printf("    %d array %s ", i, table[i].name);
          printf("lev=%d addr=%d type=%d len=%d\n", table[i].level, table[i].adr, table[i].idtype, table[i].arraylen);
          fprintf(ftable, "    %d var   %s ", i, table[i].name);
          fprintf(ftable, "lev=%d addr=%d\n", table[i].level, table[i].adr);
          break;
        case constant:
          printf("    %d const %s ", i, table[i].name);
          printf("val=%d\n", table[i].val);
          fprintf(ftable, "    %d const %s ", i, table[i].name);
          fprintf(ftable, "val=%d\n", table[i].val);
          break;
        case variable:
          printf("    %d var   %s ", i, table[i].name);
          printf("lev=%d addr=%d type=%d \n", table[i].level, table[i].adr,  table[i].idtype);
          fprintf(ftable, "    %d var   %s ", i, table[i].name);
          fprintf(ftable, "lev=%d addr=%d\n", table[i].level, table[i].adr);
          break;
        case procedure:
          printf("    %d proc  %s ", i, table[i].name);
          printf("lev=%d addr=%d size=%d\n", table[i].level, table[i].adr, table[i].size);
          fprintf(ftable,"    %d proc  %s ", i, table[i].name);
          fprintf(ftable,"lev=%d addr=%d size=%d\n", table[i].level, table[i].adr, table[i].size);
          break;
      }
    }
    printf("\n");
    fprintf(ftable, "\n");
  }

}
void showstack(int t, int p, int *s)
{
  int i;
  fprintf(fstack, "pcode %2d: |", p);
  for(i = 1; i <= t; i++)
    fprintf(fstack, " %2d |", s[i]);
  for(; t < 80; t++)
    fprintf(fstack, "%s", " ");
  fprintf(fstack, "%s", "\n");
}
/* 解释程序 */
void interpret()
{
  int p = 0; /* 指令指针 */
  int b = 1; /* 指令基址 */
  int t = 0; /* 栈顶指针 */
  struct instruction i; /* 存放当前指令 */
  int s[stacksize]; /* 栈 */

  printf("Start x0\n");
  fprintf(fresult,"Start x0\n");
  s[0] = 0; /* s[0]不用 */
  s[1] = 0; /* 主程序的三个联系单元均置为0 */
  s[2] = 0;
  s[3] = 0;
  do {
      i = code[p];  /* 读当前指令 */
    p = p + 1;
    switch (i.f)
    {
      case lit: /* 将常量a的值取到栈顶 */
        t = t + 1;
        s[t] = i.a;
        showstack(t, p, s);       
        break;
      case opr: /* 数学、逻辑运算 */
        switch (i.a)
        {
          case 0:  /* 函数调用结束后返回 */
            t = b - 1;
            p = s[t + 3];
            b = s[t + 2];
            break;
          case 1: /* 栈顶元素取反 */
            s[t] = - s[t];
            break;
          case 2: /* 次栈顶项加上栈顶项，退两个栈元素，相加值进栈 */
            t = t - 1;
            s[t] = s[t] + s[t + 1];
            break;
          case 3:/* 次栈顶项减去栈顶项 */
            t = t - 1;
            s[t] = s[t] - s[t + 1];
            break;
          case 4:/* 次栈顶项乘以栈顶项 */
            t = t - 1;
            s[t] = s[t] * s[t + 1];
            break;
          case 5:/* 次栈顶项除以栈顶项 */
            t = t - 1;
            s[t] = s[t] / s[t + 1];
            break;
          case 6:/* 栈顶元素的奇偶判断 */
            s[t] = s[t] % 2;
            break;
          case 8:/* 次栈顶项与栈顶项是否相等 */
            t = t - 1;
            s[t] = (s[t] == s[t + 1]);
            break;
          case 9:/* 次栈顶项与栈顶项是否不等 */
            t = t - 1;
            s[t] = (s[t] != s[t + 1]);
            break;
          case 10:/* 次栈顶项是否小于栈顶项 */
            t = t - 1;
            s[t] = (s[t] < s[t + 1]);
            break;
          case 11:/* 次栈顶项是否大于等于栈顶项 */
            t = t - 1;
            s[t] = (s[t] >= s[t + 1]);
            break;
          case 12:/* 次栈顶项是否大于栈顶项 */
            t = t - 1;
            s[t] = (s[t] > s[t + 1]);
            break;
          case 13: /* 次栈顶项是否小于等于栈顶项 */
            t = t - 1;
            s[t] = (s[t] <= s[t + 1]);
            break;
          case 14:/* 栈顶值输出 */
            printf("%d", s[t]);
            fprintf(fresult, "%d", s[t]);
            t = t - 1;
            break;
          case 15:/* 输出换行符 */
            printf("\n");
            fprintf(fresult,"\n");
            break;
          case 16:/* 读入一个输入置于栈顶 */
            t = t + 1;
            printf("?");
            fprintf(fresult, "?");
            scanf("%d", &(s[t]));
            fprintf(fresult, "%d\n", s[t]);           
            break;
          case 17:/* 栈顶值输出字符 */
            printf("%c", s[t]);
            fprintf(fresult, "%c", s[t]);
            t = t - 1;
            break;
          case 18:/* 次栈顶项除以栈顶项 */
            t = t - 1;
            s[t] = s[t] % s[t + 1];
            break;
          case 19:/* 次栈顶项异或栈顶项 */
            t = t - 1;
            s[t] = s[t] ^ s[t + 1];
            break;
          case 20:/* 栈顶的值取not */
            s[t] = !s[t];
            break;
          case 21:/* 次栈顶项and栈顶项 */
            t = t - 1;
            s[t] = s[t] && s[t + 1];
            break;
          case 22:/* 次栈顶项or栈顶项 */
            t = t - 1;
            s[t] = s[t] || s[t + 1];
            break;
        }
        showstack(t, p, s);
        break;

      case lod: /* 取相对当前过程的数据基地址为a的内存的值到栈顶 */
        t = t + 1;
        s[t] = s[base(i.l,s,b) + i.a];
        showstack(t, p, s);        
        break;
      case sto: /* 栈顶的值存到相对当前过程的数据基地址为a的内存 */
        s[base(i.l, s, b) + i.a] = s[t];
        showstack(t, p, s);
        t = t - 1;
        break;
      case cal: /* 调用子过程 */
        s[t + 1] = base(i.l, s, b); /* 将父过程基地址入栈，即建立静态链 */
        s[t + 2] = b; /* 将本过程基地址入栈，即建立动态链 */
        s[t + 3] = p; /* 将当前指令指针入栈，即保存返回地址 */
        b = t + 1;  /* 改变基地址指针值为新过程的基地址 */
        p = i.a;  /* 跳转 */
        showstack(t, p, s);
        break;
      case ini: /* 在数据栈中为被调用的过程开辟a个单元的数据区 */
        t = t + i.a;  
        showstack(t, p, s);
        break;
      case jmp: /* 直接跳转 */
        p = i.a;
        showstack(t, p, s);
        break;
      case jpc: /* 如果栈顶等于0条件跳转 */
        if (s[t] == 0) 
          p = i.a;
        t = t - 1;
        showstack(t, p, s);
        break;
      case jpe: /* 如果栈顶等于1条件跳转 */
        if (s[t]) 
          p = i.a;
        t = t - 1;
        showstack(t, p, s);
        break;
      case loa: /* 专门用于lod数组变量 */
        // printf("lod: s[%d] = %d\n", t, s[base(i.l, s, b) + i.a + s[t]]);
        s[t] = s[base(i.l, s, b) + i.a + s[t]];
        showstack(t, p, s);
        break;
      case sta: /* 专门用于sto数组变量 */
        // int top = s[t - 1];//取出expression(次栈顶)的值
        // s[t] = s[t + 1];//原栈顶的值
        // s[base(i.l, s, b) + i.a + top] = s[t];
        s[base(i.l, s, b) + i.a + s[t - 1]] = s[t];
        // printf("sto:s[%d] = %d\n", base(i.l, s, b) + i.a + s[t - 1], s[t]);
        // printf("%d\n", base(i.l, s, b) + i.a + s[t - 1]);
        s[t - 1] = s[t];
        t = t - 2;
        showstack(t, p, s);
        break;

      case hod:
        t = t + 1;//将上次的值滞留在栈顶
        showstack(t, p, s);
        break;
      case cpy://将栈顶的值复制一份
        s[t + 1] = s[t];
        t = t + 1;
        showstack(t, p, s);
        break;
      case ext:
        p = 0;
        showstack(t, p, s);
        break;
      case cla:
        t -= 2;
        s[t] = s[t] * s[t + 2] + s[t + 1];
        showstack(t, p, s);
        break;
      case tss:
        if(s[t - 1] >= i.a)
          {
            p = 0;
            printf("数组越界!\n");
          }
        break;
      case tsl:
        if(s[t] >= i.a)
          {
            p = 0;
            printf("数组越界!\n");
          }
        break;
    }
  } while (p != 0);
  printf("End pl0\n");
  fprintf(fresult,"End pl0\n");
}

/* 通过过程基址求上l层过程的基址 */
int base(int l, int* s, int b)
{
  int b1;
  b1 = b;
  while (l > 0)
  {
    b1 = s[b1];
    l--;
  }
  return b1;
}

int main(void)
{
  printf("Input x0 file?   ");
  scanf("%s", fname);   /* 输入文件名 */

  if ((fin = fopen(fname, "r")) == NULL)
  {
    printf("Can't open the input file!\n");
    exit(1);
  } 
  if ((foutput = fopen("foutput.txt", "w")) == NULL)
  {
    printf("Can't open the output file!\n");
    exit(1);
  }
  if ((ftable = fopen("ftable.txt", "w")) == NULL)
  {
    printf("Can't open ftable.txt file!\n");
    exit(1);
  }
  
  printf("List object codes?(Y/N)");  /* 是否输出虚拟机代码 */
  scanf("%s", fname);
  listswitch = (fname[0]=='y' || fname[0]=='Y');

  printf("List symbol table?(Y/N)");  /* 是否输出符号表 */
  scanf("%s", fname);
  tableswitch = (fname[0]=='y' || fname[0]=='Y');
  
  redirectInput(fin);   
  init();
    yyparse();

  if(err == 0)
  {
    printf("\n===Parsing success!===\n");
    fprintf(foutput, "\n===Parsing success!===\n");
    if ((fcode = fopen("fcode.txt", "w")) == NULL)
    {
      printf("Can't open fcode.txt file!\n");
      exit(1);
    }   

    if ((fresult = fopen("fresult.txt", "w")) == NULL)
    {
      printf("Can't open fresult.txt file!\n");
      exit(1);
    }
    if ((fstack = fopen("fstack.txt", "w")) == NULL)
    {
      printf("Can't open fresult.txt file!\n");
      exit(1);
    }
    
    listall();  /* 输出所有代码 */
    fclose(fcode);
    
    interpret();  /* 调用解释执行程序 */          
    fclose(fresult);
    fclose(fstack);
  }
  else
  {
    printf("%d errors in PL/0 program\n", err);
    fprintf(foutput, "%d errors in PL/0 program\n", err);
    
  }
  
  fclose(ftable);
  fclose(foutput);
  fclose(fin);
  return 0;
}



