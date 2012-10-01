### Testing
use Test::More 'no_plan';

require('pispy.pl');

subtest 'Parser' => sub {
    ok(print scm_parse('(string-join "abc def" " ghi")') eq
       "['string-join', '\"abc def\"', '\" ghi\"']");
    ok(print scm_parse('"test string"') eq "'\"test string\"'")
};

subtest 'Operators' => sub {
    is( pe("(- 4 5)"), '-1');
    is( pe("(* 5 5)"), '25' );
};

subtest 'Stuff' => sub {
    is( pe("(if (< 1  2) 3 4)"), '3');
    pe("(define x 0)");
    is( pe("(begin (set! x 5) (+ x 1))"), '6');
    is(pe("(set! x 9) x"), '9');
};

subtest 'Define functions' => sub {
    pe("(define fact (lambda (n) (if (= n 0) 1 (* n (fact (- n 1))))))");
    pe("(define fib (lambda (n) (if (< n 2) n (+ (fib (- n 1)) (fib (- n 2))))))");

    is( pe("(fact 3)"), '6', 'factorial 3');
    is( pe("(fib 1)"), '1', 'fibonacci 1');
    is( pe("(fib 3)"), '2', 'fibonacci 3');
    is( pe("(fib 10)"), '55', 'fibonacci 10');
};

subtest 'Operators 2' => sub {
    is(pe('(apply + (quote 1 2))'), '3','apply');
    is(pe('(car (quote 1 2 3 4))'),'1','car');
    is(pe('(apply + (cdr (quote 1 2 3)))'), '5', 'apply-cdr');
    is(pe('(length (quote 1 2 3 4))'), '4', 'length');
    
    ok( print pe('(list 1 2 3 4)') eq '1234', 'list');
    ok( print pe('(append (quote 1 2) (quote 3 4))') eq '1234', 'append');
    ok( print pe('(cdr (quote 1 2 3 4))') eq '234', 'cdr');
};

subtest 'Writer' => sub {
    is(scm_write(pe('(quote 1 2 3 4)')), '(1 2 3 4)', 'quote');
    is(scm_write(pe('78')), 78, 'integer');
    is(scm_write(pe('123.89')), 123.89, 'floating point');
    is(scm_write(pe('"test string"')), 'test string', 'string');
    is(scm_write(pe('(list 1 2 3 4)')), '(1 2 3 4)', 'list');
    is(scm_write(pe('(list)')), '()', 'empty list 1');
    is(scm_write(pe('(quote)')), '()', 'empty list 2');
    # is(scm_write(pe()));
    # is(scm_write(pe()));
};


#print Dumper parse('(append "abc" "avc sd")');
