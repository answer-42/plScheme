#!/usr/bin/perl
use feature qw/switch/;
use List::MoreUtils qw/zip/;

use Data::Dumper;

$env = {
    '+' => sub { $_[0]+$_[1] },
    '-' => sub { $_[0]-$_[1] },
    '*' => sub { $_[0]*$_[1] },
    '/' => sub { $_[0]/$_[1] },
    '=' => sub { $_[0]==$_[1] },
    '<' => sub { $_[0]<$_[1] },
    '>' => sub { $_[0]>$_[1] },
    '<=' => sub { $_[0]<=$_[0] },
    '>=' => sub { $_[0]>=$_[1] },
    'car' => sub { $_[0]->[0] },
    'cdr' => sub { [@{$_[0]}[1..@{$_[0]}-1]] },
    'apply' => sub { $_[0]->(@{$_[1]}) },
    'length' => sub { +@{$_[0]} }, # scalar @{$_[0]} would be clearer
    'append' => sub { [@{$_[0]}, @{$_[1]}] },
    'list' => sub { [@_[0..@_-1]] },
    OUTER => 0,
};

sub set {
    my ($env, $key, $val) = @_;
    (defined $$env{$key}
	? $$env{$key} : $$env{OUTER}{$key}) = $val
}

sub find {
    my ($key, $env) = @_;
    return $$env{$key} if defined $$env{$key};
    return 0 unless $$env{OUTER};
    return find($key, $$env{OUTER});
}

sub scm_parse {
    $_ = join ' ', map {s/([^\[\]]+)/'$1'/;
			s/([^\[]+)/$1,/r} split /\s/, $_[0] =~ y/()/[]/r;
    s/("[^"]*?)',(\s+)'([^"]*?"')/$1$2$3/g;
    eval
}

sub scm_eval {
    my ($in, $env) = @_;
    return find($in, $env) if find($in, $env);
    return $in if ref $in ne 'ARRAY';

    given ($$in[0]) {
	when ('lambda') { sub { scm_eval($$in[2], {zip(@{$$in[1]},@_), OUTER=>$env}) } }
	when ('define') { $$env{$$in[1]} = scm_eval($$in[2], $env) }
	when ('if') { scm_eval(scm_eval($$in[1], $env) ? $$in[2] : $$in[3], $env) }
	when ('set!') { set($env, $$in[1], scm_eval($$in[2], $env)) }
	when ('quote') { [@$in[1..@$in-1]] }
	when ('begin') { [map { scm_eval($_, $env) } @$in[1..@$in-1]]->[-1] }
	when ('defmacro')
	     { ... }
	default {
	    @exp = map {scm_eval($_, $env)} @$in;
	    $exp[0]->(@exp[1..$#exp])
	}
    }
}


sub scm_write {
    $_ = shift;
    return '(' . (join ' ', @$_) . ')' if ref $_ eq 'ARRAY';
    return $_ if /^\d+(\.\d+)?$/;
    s/^"(.*)"$/$1/, return $_ if /^".*?"$/;
    return "function $_" if ref $_ eq 'CODE';

    warn "Didn't recognize type -- $_";
}


sub pe {
    scm_eval scm_parse($_[0]), $env
}

sub scm_repl {
    print '==> ';
    while (<STDIN>) {
	print scm_write(scm_eval(scm_parse($_), $env));
	print "\n==> ";
    }
}

scm_repl();
