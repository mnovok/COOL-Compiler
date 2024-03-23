/*
 *  The scanner definition for COOL.
 */

/*
 *  Stuff enclosed in %{ %} in the first section is copied verbatim to the
 *  output, so headers and global definitions are placed here to be visible
 * to the code in the file.  Don't remove anything that was here initially
 */
%option noyywrap 
%{
#include <cool-parse.h>
#include <stringtab.h>
#include <utilities.h>

/* The compiler assumes these identifiers. */
#define yylval cool_yylval
#define yylex  cool_yylex

/* Max size of string constants */
#define MAX_STR_CONST 1025
#define YY_NO_UNPUT   /* keep g++ happy */

extern FILE *fin; /* we read from this file */

/* define YY_INPUT so we read from the FILE fin:
 * This change makes it possible to use this scanner in
 * the Cool compiler.
 */
#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
	if ( (result = fread( (char*)buf, sizeof(char), max_size, fin)) < 0) \
		YY_FATAL_ERROR( "read() in flex scanner failed");

char string_buf[MAX_STR_CONST]; /* to assemble string constants */
char *string_buf_ptr;

extern int curr_lineno;
extern int verbose_flag;

extern YYSTYPE cool_yylval;

/*
 *  Add Your own definitions here
 */

/* varijabla za duljinu stringa i varijabla brojaca komentara*/
int str_len = 0;
int comment_counter = 0;

void empty_buffer();

%}

/*
 * Define names for regular expressions here.
 */

%x COMMENT
%x LINECOMMENT
%x STRING 

DIGIT          [0-9]
CHARACTER      [a-zA-Z0-9_]
LOWERCASE      [a-z]
UPPERCASE      [A-Z]
TYPEID         {UPPERCASE}{CHARACTER}*
OBJECTID       {LOWERCASE}{CHARACTER}*
WHITESPACE     [ \b\t\n\f]
INVALID        "!"|"^"|"?"|"$"|"#"|"%"|"["|"]"|"_"|">"|"&"|"`"|"\\"
DASH           --
COMMENTSTART   \(\*
COMMENTEND     \*\)
STRINGSTART    \"
SELF           self
SELFTYPE       SELF_TYPE

/*
  *  The multiple-character operators.
  */

DARROW          =>
ASSIGN          <-
LE              <=

/* kljucne rijeci */

CLASS           [cC][lL][aA][sS][sS]
ELSE            [eE][lL][sS][eE]
FI              [fF][iI]
IF              [iI][fF]
IN              [iI][nN]
INHERITS        [iI][nN][hH][eE][rR][iI][tT][sS]
LET             [lL][eE][tT]
LOOP            [lL][oO][oO][pP]
POOL            [pP][oO][oO][lL]
THEN            [tT][hH][eE][nN]
WHILE           [wW][hH][iI][lL][eE]
CASE            [cC][aA][sS][eE]
ESAC            [eE][sS][aA][cC]
OF              [oO][fF]
NEW             [nN][eE][wW]
ISVOID          [iI][sS][vV][oO][iI][dD]
NOT             [nN][oO][tT]

TRUE            t[rR][uU][eE]
FALSE           f[aA][lL][sS][eE]

INTCONST       {DIGIT}+



%%

 /*
  *  Nested comments
  */
   

  /* 
  * operatori poredani po prioritetu 
  */

"."         { return '.'; }
"@"         { return '@'; }
"~"         { return '~'; }
"*"         { return '*'; }
"/"         { return '/'; }
"+"         { return '+'; }
"-"         { return '-'; }
{LE}        { return (LE); }
"<"         { return '<'; }
"="         { return '='; }
{ASSIGN}    { return (ASSIGN); }
"("         { return '('; }
")"         { return ')'; }
"{"         { return '{'; }
"}"         { return '}'; }
","         { return ','; }
":"         { return ':'; }
";"         { return ';'; }
{DARROW}		{ return (DARROW); }

 /*dodatni znakovi iz mape*/

           { cool_yylval.error_msg = "\001"; return (ERROR); }      
           { cool_yylval.error_msg = "\002"; return (ERROR); } 
           { cool_yylval.error_msg = "\003"; return (ERROR); } 
           { cool_yylval.error_msg = "\004"; return (ERROR); } 

 /*
  * Keywords are case-insensitive except for the values true and false,
  * which must begin with a lower-case letter.
  */
  

{CLASS}     { return (CLASS); }
{ELSE}      { return (ELSE); }
{FI}        { return (FI); }
{IF}        { return (IF); }
{IN}        { return (IN); }
{INHERITS}  { return (INHERITS); }
{LET}       { return (LET); }
{LOOP}      { return (LOOP); }
{POOL}      { return (POOL); }
{THEN}      { return (THEN); }
{WHILE}     { return (WHILE); }
{CASE}      { return (CASE); }
{ESAC}      { return (ESAC); }
{OF}        { return (OF); }
{NEW}       { return (NEW); }
{ISVOID}    { return (ISVOID); }
{NOT}       { return (NOT); }

{TRUE}      {
              cool_yylval.boolean = 1;
              return (BOOL_CONST);
            }
{FALSE}     {
              cool_yylval.boolean = 0;
              return (BOOL_CONST);
            }
{OBJECTID}  {
              cool_yylval.symbol = idtable.add_string(yytext);
              return (OBJECTID);
            }
{TYPEID}    {
              cool_yylval.symbol = stringtable.add_string(yytext);
              return (TYPEID);
            }            
{SELFTYPE}  {
              cool_yylval.symbol = stringtable.add_string(yytext);
              return (TYPEID);
            }
{SELF}      {
              cool_yylval.symbol = stringtable.add_string(yytext);
              return (TYPEID);
            }
{INTCONST}  {
              cool_yylval.symbol = inttable.add_string(yytext);
              return (INT_CONST);
            }
{INVALID}   {
              cool_yylval.error_msg = yytext;  
              return (ERROR); 
            }                        
"|"         {  
              cool_yylval.error_msg = "|";  
              return (ERROR); 
            } 
 /*
  *  String constants (C syntax)
  *  Escape sequence \c is accepted for all characters c. Except for 
  *  \n \t \b \f, the result is c.
  *
  */

[\n]            { curr_lineno++; }

{WHITESPACE}    {;}
               
{STRINGSTART}   {
                  str_len = 0;
                  BEGIN (STRING);
                }
                
<LINECOMMENT>{
"\n"              {BEGIN (INITIAL);}             
.                 { ; }             
}

<COMMENT>{
{COMMENTSTART}    { comment_counter++; }
"\n"              { curr_lineno++; }
{COMMENTEND}      {
                    comment_counter--;
                    if(comment_counter == 0)
                      BEGIN (INITIAL); /*vrati skener u prvobitno stanje*/
                  }
<<EOF>>           {
                    cool_yylval.error_msg = "EOF in comment";
                    BEGIN (INITIAL);
                    return (ERROR);
                  }                  
.                 { ; }
         }

<INITIAL>{
{COMMENTEND}    {
                    cool_yylval.error_msg = "Unmatched *)";
                    return (ERROR);
                } 
}

<INITIAL>{
{COMMENTSTART}  {
                  comment_counter++;
                  BEGIN (COMMENT);
                } 
}

<INITIAL>{
{DASH}  {
                  BEGIN (LINECOMMENT);
        } 
}

<STRING>{
{STRINGSTART}   {
                  if(str_len >= MAX_STR_CONST)
                  {
                    cool_yylval.error_msg = "String constant too long";
                    empty_buffer();
                    BEGIN (INITIAL); 
                    return (ERROR); 
                  }
                  else
                  {
                    cool_yylval.symbol = stringtable.add_string(string_buf); 
                    empty_buffer();
                    BEGIN (INITIAL); 
                    return (STR_CONST); 
                  }
                }
<<EOF>>         {
                    cool_yylval.error_msg = "EOF in string constant";
                    empty_buffer();
                    BEGIN (INITIAL);
                    return (ERROR);
                }
\0              {
                    cool_yylval.error_msg = "String contains null character";
                    empty_buffer();
                    BEGIN (INITIAL);
                    return (ERROR);
                }
                /*string nije zatvoren*/
\n              {
                    cool_yylval.error_msg = "Unterminated string constant";
                    empty_buffer();
                    curr_lineno++;
                    BEGIN (INITIAL);
                    return (ERROR);
                }
\\n             {
                    if(str_len > MAX_STR_CONST)
                  {
                    cool_yylval.error_msg = "String constant too long";
                    empty_buffer();
                    BEGIN (INITIAL); 
                    return (ERROR); 
                  }
                  else
                    string_buf[str_len++]= '\n';
                }
\\t             {
                    if(str_len > MAX_STR_CONST)
                  {
                    cool_yylval.error_msg = "String constant too long";
                    empty_buffer();
                    BEGIN (INITIAL); 
                    return (ERROR); 
                  }
                  else
                    string_buf[str_len++]= '\t';
                }
\\b             {
                    if(str_len > MAX_STR_CONST)
                  {
                    cool_yylval.error_msg = "String constant too long";
                    empty_buffer();
                    BEGIN (INITIAL); 
                    return (ERROR); 
                  }
                  else
                    string_buf[str_len++]= '\b';
                }
\\f             {
                    if(str_len > MAX_STR_CONST)
                  {
                    cool_yylval.error_msg = "String constant too long";
                    empty_buffer();
                    BEGIN (INITIAL); 
                    return (ERROR); 
                  }
                  else
                    string_buf[str_len++]= '\f';
                }                                                      
\\\0            {
                  cool_yylval.error_msg = "String has an escaped null character";
	                empty_buffer();
                  BEGIN (INITIAL);
                  return (ERROR);
                }
\\[^btnf]       {
                  string_buf[str_len++]= yytext[1];
                }
\\\"            {
                  string_buf[str_len++]= '"';
                }                                                                                                  
.               {
                  string_buf[str_len++]= *yytext;
                }                              
}
%%

void empty_buffer(){
  memset(string_buf, 0, sizeof(string_buf));
}