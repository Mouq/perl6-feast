use v6;

use MONKEY_TYPING;
augment class Str {
    method xml ($name : *@content, *%attrs) {
        ("<$name {%attrs.kv.map: {"$^a='$^b'"}}>", "</$name>").join: @content ?? @content.join !! ''
    }
}
sub xml-encode ($_) { .trans(/\</ => '&lt', /\&/ => '&amp;') }

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

    my $github-addr = 'https://github.com/coke/perl6-roast-data/blob/master/';

    my sub add-result ($r) {
        %dat{$*section}{$*test-file}{$impl}.push:
            <div>.xml: :class<result>, <a>.xml:
                :class<ref>
                :href("$github-addr$log-path#L$*line"),
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
        <style>
        body {
            padding: 5em;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            border: none;
        }
        td {
            vertical-align: top;
            border-bottom: solid 1px grey;
            width: 20%;
        }
        .section table { display: none; }
        .section input[type=checkbox]:checked ~ table { display: inherit; }
        .section {
            padding-bottom: 3px;
            border-bottom: 2px dotted;
            background-color: #DFF;
            margin: 3px;
        }
        .section .title {
            font-size: 130%;
            font-weight: bold;
        }
        .section td + td {
            font-family: monospace;
        }
        .result {
            color: black;
            margin-bottom: 3px;
            border: 1px dotted grey;
        }
        </style>
    </head>
    <body>
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
$feast.say: %dat.sort».kv.map: -> $sect, %tests {
    say "Recording $sect";
    <div>.xml: :class<section>,
        '<input type="checkbox"/>',
        <span>.xml($sect.tc, :class<title>),
        <table>.xml: join '',
            %tests.sort».kv.map: -> $test, %res {
                for @impls {
                    %res{$_} //= '';
                }
                table-row $test, |%res{@impls};
            }
}
# vim: ft=perl6
