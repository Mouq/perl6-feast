use v6;

use MONKEY_TYPING;
augment class Str {
    method xml ($name : *@content, *%attrs) {
        [~] "<$name"~%attrs.kv.map({" $^a='$^b'"}).join~">",
            @content.flat.map(*~"\n"),
            "</$name>"
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
for dir("log")[2..*] -> $log-path {
    my $impl = $log-path.parts<basename>.trans: /'_summary.out' $/ => '';
    say "Collecting the charred remains of $impl";
    @impls.push: $impl;
    my $impl-num = @impls.end;

    my $log-fh = $log-path.open;
    my $line = 0; # Rakudo's IO.ins tends to display total line count

    my (Str $section, Str $test-file);
    my Bool $failure-summary; # (have we reached the failure summary yet?)

    my sub add-result ($r) {
        %dat{$section}{$test-file}.push:
            $impl-num => <a>.xml: :class<ref>:href("%github<roast-data>$log-path#L$line"),
                <div>.xml: :class<result>,
                    xml-encode $r;
    }

    for $log-fh.lines {
        $line++;
        when m[
            ^
            (
              [ S\d\d\- | integration | rosettacode ]
              \S+?
            )
            '.' [ $impl | t ]
            (.*)
        ] {
            ($test-file) = split '/', ~$0;
            $test-file ~= '.t';
            $section   = $0.comb: /^<ident>+/;
            say "Processing $impl\'s $section at $test-file";
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
        when m[^ 'Failure summary:' $] {
            $failure-summary = True;
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
        <script type='text/javascript' src='https://ajax.googleapis.com/ajax/libs/jquery/1.11.0/jquery.min.js'></script>
        <script type='text/javascript' src='feast.js'></script>
        <title>Feast: Roasted Perl 6</title>
    </head>
    <body>
    <h1 class='title'>Feast</h1>
    <h3 class='subtitle'>Roasted Perl 6</h3>
    EOHTML

END {
    $feast.say: q:to[EOHTML];
        </body>
        </html>
        EOHTML
    $feast.close;
}


$feast.say: <div>.xml: :class<impls>,
    @impls.map: {
        <div>.xml: :class<impl>, $_.trans('.' => ' ').wordcase
    }

for %dat.sort».kv -> $sect, %testfiles {
    # Split the tests by major section (S01, S02, etc.):
    say "Recording $sect";
    $feast.say: <div>.xml: :class<synopsis off>,
        <div>.xml($sect.tc, :class<desc>),
        |%testfiles.sort».kv.map: -> $testfile, @res {
            <div>.xml: :class<file off>,
                <div>.xml(:class<desc>, $testfile.split('-')[1..*].Str.wordcase),
                # Each test file has its own set of results
                # which we classify by implementation:
                #<a>.xml(
                #    :href("%github<roast>$testfile"),
                #    <div>.xml: :class<cell>, $testfile
                #),
                @res».kv.map: -> $impl, $fudge {
                    <div>.xml: :class«fudge impl{$impl}»,
                    $fudge
                }
        }
}
# vim: ft=perl6
