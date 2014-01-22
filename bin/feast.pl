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
    EOHTML
END {
    $feast.say: q:to[EOHTML];
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
    method xml ($name : *@content, *%attrs) {
        ("<$name {%attrs.kv.map: {"$^a='$^b'"}}>", "</$name>").join: @content ?? @content.join !! ''
    }
}
sub xml-encode ($_) { .trans(/\</ => '&lt', /\&/ => '&amp;') }

sub table-row (*@d) { <tr>.xml: @d.map({<td>.xml: $_})}
$feast.say: <table>.xml: table-row('', |@impls.map: *.trans('.' => ' ').wordcase);
$feast.say: %dat.sort».kv.map: -> $sect, %tests {
    say "Recording $sect";
    <div>.xml:
        <h3>.xml($sect),
        <table>.xml: join '',
            %tests.sort».kv.map: -> $test, %res {
                for @impls {
                    %res{$_} //= '';
                }
                table-row $test, |%res{@impls};
            }
}
# vim: se ft=perl6
