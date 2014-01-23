use v6;

use MONKEY_TYPING;
augment class Str {
    method xml ($name : *@content, *%attrs) {
        ~ "<$name"~%attrs.kv.map({" $^a='$^b'"}).join~">\n"
        ~ @content.map(*~"\n").join.indent(4)
        ~ "</$name>"
    }
}
sub xml-encode ($_) { .trans(/\</ => '&lt', /\&/ => '&amp;') }
my %github =
    roast-data => 'https://github.com/coke/perl6-roast-data/blob/master/',
    roast => 'https://github.com/perl6/roast/blob/master/';

say "Preparing roasted implementations";

my %dat;
my Str @impls;
# Grab each file in log dir, extract
# the skips and todos for each file,
# and sort? them???? and display.
for dir("log")[2,4..*] -> $log-path {
    my $impl = $log-path.parts<basename>.trans: /'_summary.out' $/ => '';
    say "Collecting the charred remains of $impl";
    @impls.push: $impl;

    my $log-fh = $log-path.open;
    my $*line = 0; # Rakudo's IO.ins tends to display total line count

    my (Str $*section, Str $*test-file);
    my Bool $failure-summary; # (have we reached the failure summary yet?)

    my sub add-result ($r) {
        %dat{$*section}{$*test-file}{$impl}.push:
            <div>.xml: :class<result>, <a>.xml:
                :class<ref>
                :href("%github<roast-data>$log-path#L$*line"),
                xml-encode $r;
    }

    for $log-fh.lines {
        $*line++;
        when m[
            ^
            (
              [ S\d\d\- | integration | rosettacode ]
              \S+?
            )
            '.' [ $impl | t ]
            (.*)
        ] {
            $*test-file = $0 ~ '.t';
            $*section   = $0.comb: /^<ident>+/;
            say "Processing {$impl}'s $*section at $*test-file";
            if $failure-summary {
                add-result 'Failed test #'~$1;
            }
        }
        # Currently very simple, might improve later
        when m[ ^ (\s+ $<num>=\d+) { $0.comb == 6 } ' skipped: ' (.*) $ ] {
            add-result $_;
        }
        when m[ ^ (\s+ $<num>=\d+) { $0.comb == 6 } ' todo   : ' (.*) $ ] {
            add-result $_;
        }
        when m[ ^ (\s+ $<num>=\d+) { $0.comb == 6 } ' tests aborted (missing ok/not ok)' $ ] {
            add-result $_;
        }
    }
    $log-fh.close
}

say "Writing";
my $feast = open 'feast.html', :w;

$feast.say: q:to[EOHTML];
    <!doctype html>
    <html>
    <head>
        <meta charset="utf-8">
        <link href='http://fonts.googleapis.com/css?family=Marcellus' rel='stylesheet' type='text/css'>
        <link href='http://fonts.googleapis.com/css?family=Marcellus+SC' rel='stylesheet' type='text/css'>
        <link href='http://fonts.googleapis.com/css?family=Anonymous+Pro:400,400italic&subset=latin,latin-ext' rel='stylesheet' type='text/css'>
        <link href='feast.css' rel='stylesheet' type='text/css'>
        <title>Feast: Roasted Perl 6</title>
    </head>
    <body>
    <h1 class='title'>Feast: Roasted Perl 6</h1>
    EOHTML

END {
    $feast.say: q:to[EOHTML];
        </body>
        </html>
        EOHTML
    $feast.close;
}


sub table-row (*@d) { <tr>.xml: @d.map({<td>.xml: $_})}
$feast.say: <table>.xml: :class<header>, table-row('', |@impls.map: *.trans('.' => ' ').wordcase);
%dat.sort».kv.map: -> $sect, %tests {
    say "Recording $sect";
    $feast.say: <div>.xml: :class<section>,
        '<input type="checkbox"/>',
        <div>.xml($sect.tc, :class<title>),
        <table>.xml: :class<section-body>,
            %tests.sort».kv.map: -> $test, %res {
                state $last-dir = '';
                my ($dir, $t) = $test.split: '/';
                %res{$_} //= '' for @impls;
                my $r = '';
                if $last-dir ne $dir {
                    $r = <td>.xml: :class<test-dir>, $dir.split('-')[1..*].Str.wordcase;
                    $last-dir = $dir;
                }
                $r, table-row <a>.xml($t,:href(%github<roast>~$test)), |%res{@impls}
            }
}
# vim: ft=perl6
