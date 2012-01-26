#!/usr/bin/perl
use strict;
use warnings;
use File::Slurp;
use Data::Dumper;

# get_all_rosettacode_tasks.pl
#   by Util of Perlmonks <bruce.gray@acm.org>
# This program gets all the programming tasks in large batches.
# Runs in about 1 minute.
# Note that it is currently caching, so `rm pt_75_*.{xml,json}` to update.

my $batch_size = 75;
my $base_url_json = "http://rosettacode.org/mw/api.php?action=query&list=categorymembers&cmtitle=Category:Programming_Tasks&format=json&cmlimit=$batch_size";
my $base_url_xml  = "http://rosettacode.org/mw/api.php?action=query&generator=categorymembers&gcmtitle=Category:Programming_Tasks&gcmlimit=$batch_size&export&exportnowrap";

sub run {
    my @args = @_;
#print "Running @args\n";
    my $rc = system(@args);
    die "Ack! rc=$rc cmd=@args" if $rc != 0;
}

# Cached, for now.
sub get {
    my ( $file, $url ) = @_;
#    unlink $file or die "cannot unlink '$file': $!" if -e $file;
    return if -e $file;
print "getting $file\n";
    run("curl -sS --compressed -o $file '$url'");    
}

# Kludge to remove the need for JSON::XS module.
my $continue_re = qr{
        ,"query-continue":\{
            "categorymembers":\{
                "cmcontinue":"(page\|[a-fA-F0-9]+\|\d+)"
            \}
        \}
    \}
    \s*
    \z
}msx;

my $n = 0;
my @continuation_points;
# Must get continuation points from a run that only list page titles, to
# use for a huge "give me all task pages with full contents" run later.
while (1) {
    my $file = sprintf 'pt_75_%02d.json', ++$n;

    my $url = $base_url_json;
    if ( @continuation_points ) {
        $url .= "&cmcontinue=$continuation_points[-1]|";
    }

    get( $file, $url );

    my $json = read_file($file);
    $json =~ /$continue_re/
        or last;

    push @continuation_points, $1;
}
print Dumper \@continuation_points;

# Now get the big listings, using Generator.
$n = 0;
for my $cp ( '', @continuation_points ) {
    my $file = sprintf 'pt_75_%02d.xml', ++$n;
    my $url = $base_url_xml;
    if ( $cp ) {
        $url .= "&gcmcontinue=$cp|";
    }

    get( $file, $url );
}

__END__

References:
http://rosettacode.org/mw/api.php
    See section: action=query
http://www.mediawiki.org/wiki/API_Query
