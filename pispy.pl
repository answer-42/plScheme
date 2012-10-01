#!/usr/bin/perl
use feature qw/switch/;
use List::MoreUtils qw/zip/;

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

sub parse {
    # BUG: Doesn't parse strings properly!
    eval join ' ', map {s/([^\[\]]+)/'$1'/;
			s/([^\[]+)/$1,/r} split /\s/, $_[0] =~ y/()/[]/r;
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
	when ('call/cc') { ... # TODO }
	default {
	    @exp = map {scm_eval($_, $env)} @$in;
	    $exp[0]->(@exp[1..$#exp])
	}
    }
}

sub pe {
    scm_eval parse($_[0]), $env
}

sub scm_write {
    $_ = shift;
    return '(' . (join ' ', @$_) . ')' if ref $_ eq 'ARRAY';
    return $_ if /^\d+(\.\d+)?$/;
    return s/^"(.*)"$/$1/ if /^".*"$/;

    warn "Didn't recognize type -- $_";
}
