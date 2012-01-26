#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper; $Data::Dumper::Useqq = 1;

my $wanted_language = 'Perl 6';

# extract_one_lang_from_rosettacode_tasks_xml.pl
#   by Util of Perlmonks <bruce.gray@acm.org>
# This program reads all the output from get_all_rosettacode_tasks.pl,
# and extracts the decoded entries for one language for all tasks.
# Runs in 5 seconds on my old Mac laptop.

# XXX Change to use a true XML parser?

my @files = glob 'pt_75_*.xml';
die if not @files;

my @pages;
for my $file (@files) {
    open my $fh, '<', $file or die;

    # Skip past XML file header
    while (<$fh>) { last if m{</siteinfo>} }
    die if eof $fh;

    my @page_lines;
    my $in_page;
    while (<$fh>) {
        chomp;
        if ( m{ \A \s* <page> \s* \z }msx ) {
            die if $in_page;
            die if @page_lines;
            $in_page = 1;
            next;
        }
        if ( m{ \A \s* </page> \s* \z }msx ) {
            die if !$in_page;
            undef   $in_page;
            push @pages, [@page_lines];
            undef         @page_lines;
            next;
        }
        if ( $in_page ) {
            push @page_lines, $_;
        }
    }

    close $fh or warn;
}

my $lang_header_re        = qr{ \A \s* =+      \{\{ \s* header \s* \| \s* (  .+?  ) \s* \}\}       }msxi;
my $lang_header_strict_re = qr{ \A    (={2,3}) \{\{     header     \|     (\S.*?\S|\S)     \}\} \1 \z }msx;
my %temp;
for my $page_aref (@pages) {
    my $title_line = shift @{$page_aref};
    my ($title) = ( $title_line =~ m{ \A \s* <title> (.+) </title> \s* \z }msx ) or die;

#    print $title, "\n";
# XXX what about mis-spelled or non-canonical lang names?
    my %lang_lines;
    my $in_lang;
    for ( @{$page_aref} ) {
        if ( /$lang_header_re/ ) {
            $in_lang = $1;

            # Loosen this to be exactly what is OK vs not OK; too many false positives as currently written.
#            warn "Possible bad header in $title: ", Dumper($_) if !/$lang_header_strict_re/;

#            warn "Dup $title => $in_lang" if $lang_lines{$in_lang};
            $lang_lines{$in_lang} = [];
            next;
        }

        if ( $in_lang ) {
            push @{ $lang_lines{$in_lang} }, $_;
            # Note that instead of blindly pushing, you could conditionally
            # push based on a regex over the (XML-encoded) text, which changes
            # this into a per-task version of grep/ack. For example:
#            push @{ $lang_lines{$in_lang} }, $_ if m/multi.+infix/i;
            # or:
#            push @{ $lang_lines{$in_lang} }, $_ if /«|»|&lt;&lt;|&gt;&gt;/;
            
        }
    }
    my $z = $lang_lines{$wanted_language};
    $temp{$title} = $z if $z and @{$z};
#print Dumper \%lang_lines; last;
}

for my $title ( sort keys %temp ) {
    print "$title\n";
    for (@{ $temp{$title} }) {
        s{&lt;}{<}g;
        s{&gt;}{>}g;
        s{&quot;}{"}g;
        s{&amp;}{&}g;
        s{</lang>}{};
        s{<lang perl6>}{};
    }
    print "\t$_\n" for @{ $temp{$title} };
}
#print Dumper \@temp;

__END__
Example output:
100 doors
        '''unoptimized''' {{works with|Rakudo|2010.07"}}
        my @doors = False xx 101;
        
        ($_ = !$_ for @doors[0, * + $_ ...^ * > 100]) for 1..100;
        
        say "Door $_ is ", <closed open>[ @doors[$_] ] for 1..100;
        
        '''optimized'''
        
        say "Door $_ is open" for map {$^n ** 2}, 1..10;
        
        Here's a version using the cross meta-operator instead of a map:
        
         say "Door $_ is open" for 1..10 X** 2;
        
        This one prints both opened and closed doors:
        
        say "Door $_ is ", <closed open>[.sqrt == .sqrt.floor] for 1..100;
        
24 game
        
        {{works with|Rakudo|2010.09.16}}
        grammar Exp24 {
            token TOP { ^ <exp> $ }
            token exp { <term> [ <op> <term> ]* }
            token term { '(' <exp> ')' | \d }
            token op { '+' | '-' | '*' | '/' }
        }
        
        my @digits = roll 4, 1..9;  # to a gamer, that's a "4d9" roll
        say "Here's your digits: {@digits}";
        while my $exp = prompt "\n24-Exp? " {
            unless is-valid($exp, @digits) {
                say "Sorry, your expression is not valid!";
                next;
            }
        
            my $value = eval $exp;
            say "$exp = $value";
            if $value == 24 {
                say "You win!";
                last;
            }
            say "Sorry, your expression doesn't evaluate to 24!";
        }
        
        sub is-valid($exp, @digits) {
            unless ?Exp24.parse($exp) {
                say "Expression doesn't match rules!";
                return False;
            }
        
            unless $exp.comb(/\d/).sort.join == @digits.sort.join {
                say "Expression must contain digits {@digits} only!";
                return False;
            }
        
            return True;
        }
        
99 Bottles of Beer
...