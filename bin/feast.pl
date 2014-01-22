use v6;

my $feast = open "feast.html", :w;
$feast.say: q:to[EOHTML];
    <!doctype html>
    <html>
    <head>
        <meta charset="utf-8">
        <style>
        </style>
    </head>
    <body>
    <table>
        <tr>
    EOHTML
END {
    $feast.say: q:to[EOHTML];
            </tr>
        </table>
        </body>
        </html>
        EOHTML
    $feast.close;
}

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
    my (Str $section, Str $test-file);
    my $log-fh = $log-path.open;
    for $log-fh.lines {
        when m[
            ^
            (
              [ S\d\d\- | integration | rosettacode ]
              [ \S ]+?
            )
            '.' [ $impl | t ]
            \.* [\s+ \d+]**5
            $
        ] {
            $test-file = $0 ~ '.t';
            $section   = $0.comb: /^<ident>+/;
            say "Processing {$impl}'s $section at $test-file";
        }
        # Currently very simple, might improve later
        when m[ ^ (\s+ $<num>=\d+) { $0.comb == 6 } ' skipped: ' (.*) $ ] {
            %dat{$section}{$test-file}{$impl}.push: '<br/>' R~ xml-encode $_;
        }
        when m[ ^ (\s+ $<num>=\d+) { $0.comb == 6 } ' todo   : ' (.*) $ ] {
            %dat{$section}{$test-file}{$impl}.push: '<br/>' R~ xml-encode $_;
        }
        when m[ ^ (\s+ $<num>=\d+) { $0.comb == 6 } ' tests aborted (missing ok/not ok)' $ ] {
            %dat{$section}{$test-file}{$impl}.push: '<br/>' R~ xml-encode $_;
        }
    }
    $log-fh.close
}

say "Writing";

use MONKEY_TYPING;
augment class Str {
    method xml ($name : *@content) { qqw[<$name> </$name>].join: @content ?? @content.join !! '' }
}
sub xml-encode ($_) { .trans(/\</ => '&lt', /\&/ => '&amp;') }

sub table-row (*@d) { $feast.say: <tr>.xml: @d.map({<td>.xml: $_})}
table-row('', |@impls.map: *.trans('.' => ' ').wordcase);
for %dat.sort».kv -> $sect, %tests {
    say "Recording $sect";
    table-row <h3>.xml: $sect;
    for %tests.sort».kv -> $test, %res {
        for @impls {
            %res{$_} //= '';
        }
        table-row $test, |%res{@impls};
    }
}
# vim: se ft=perl6
