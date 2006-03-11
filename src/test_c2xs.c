/* test_c2xs.c */
//Written for testing c2xs.pl
/* some comments


 more comments
end of comments */

#include <header.h>

#ifdef something
#define somethingelse
#endif

void test_0 (int a, double b, SV *c, SV*d, SV* e, SV * f) { // comments -1
    inline_stack_vars
    some irrelevant code {
         more
         again // comments -2
         }
    }

unsigned long test_1 (int a, double b, SV *c, SV*d, SV* e, SV * f) { // comments 1
    some irrelevant code {
         more
         again // comments 2
         }
    }

unsigned long* test_2 (int a, double b, SV *c, SV*d, SV* e, SV * f) { /* comments 3 start here

    comments finish here */
    some irrelevant code {
         more
         again // comments 4
         }
    }

unsigned long *test_3 (int a, double b, SV *c, SV*d, SV* e, SV * f) { // comments 5
    some irrelevant code {
         more
         again // comments 6
         }
    }

unsigned long*test_3 (int a, double b, SV *c, SV*d, SV* e, SV * f) { // comments 6
    some irrelevant code {
         more
         again // comments 7
         }
    }

void test_4 (int a, double b, SV *c, SV*d, SV* e, SV * f) { // comments 7
    inline_stack_vars
    some irrelevant code {
         more
         again // comments 8
         }
    }

SV * test_5 (int a, double b, SV *c, SV*d, SV* e, SV * f) { // comments 9
    inline_stack_vars
    some irrelevant code {
         more
         again // comments 10
         }
    }

SV *test_6 (int a, double b, SV *c, SV*d, SV* e, SV * f) { // comments 11
    inline_stack_vars
    some irrelevant code {
         more
         again // comments 12
         }
    }

SV* test_7 (int a, double b, SV *c, SV*d, SV* e, SV * f) { // comments 13
    inline_stack_vars
    some irrelevant code { /* A comment here
                           comment continues
                           end of comment */
         more
         again // comments 14
         }
    }

SV*test_8 (int a, double b, SV *c, SV*d, SV* e, SV * f) { // comments 15
    inline_stack_vars
    some irrelevant code {
         more
         again // comments 16
         }
    }

// Should be ignored

/*

void * ignore_me(int a, char * x){
    no longer in use {
        finished
        done 
        }
    don't return { }
} */




