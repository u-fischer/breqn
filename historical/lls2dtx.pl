#!/usr/bin/perl

# lls2dtx.pl
# Copyright 2007 Lars Madsen
#
# This work may be distributed and/or modified under the
# conditions of the LaTeX Project Public License, either version 1.3
# of this license or (at your option) any later version.
# The latest version of this license is in
#   http://www.latex-project.org/lppl.txt
# and version 1.3 or later is part of all distributions of LaTeX
# version 2005/12/01 or later.
#
# This work has the LPPL maintenance status `maintained'.
#
# The Current Maintainer of this work is Lars Madsen, daleif@imf.au.dk
#
# This work consists of the Perl script lls2dtx.pl
#
# usage: lls2dtx.pl file.lls > file.dtx
#
# it will sort of convert the contents of file.lls into the syntax
# used for dtx files, thought the output will need some hand-editing.
#

use warnings;
use strict;
use Getopt::Long;

my $show_unknown = 0;

GetOptions('unkown' => \$show_unknown);

my $file = $ARGV[0];

if ( ! defined $file ) {

warn <<END;

$0, Copyright (C) 2007, Lars Madsen

Usage:

    $0 file.lls > file.dtx
or
    $0 -u file.lls

The first will convert file.lls into the dtx format, though it will
still need some hand editing for punctuation and such.

The -u version does the same as the first version but the output will
be line number and content for lines containing ^E's that have not
been converted (ussefull for debugging).

No file was given, aborting

END
#' for emacs
exit; 
}



my $content;
open my $FH, '<', $file or die "Cannot open '$file': $!";
{
  local $/;
  $content = <$FH>; # slurp all up into mem
}
close $FH;


$content =~ s{\(code}{\%    \\begin{macrocode}}gms; # the magic 4 spaces
$content =~ s{\<code\)}{\%    \\end{macrocode}}gms;

$content =~ s{\(section\(title(.*?)\<title\)}{\\section{\u$1}}gms;
$content =~ s{\<section\)}{\n}gms; # end of section, we just ad a newline

$content =~ s{\(subsection\(title(.*?)\<title\)}{\\section{\u$1}}gms;
$content =~ s{\<subsection\)}{\n}gms; # end of section, we just ad a newline


# something that looks like normal macros or environments
$content =~ s{\(pkg(.*?)\<pkg\)}{\\pkg{$1}}gms;
$content =~ s{\(env(.*?)\<env\)}{\\env{$1}}gms;
$content =~ s{\(cs(.*?)\<cs\)}{\\cs{$1}}gms;
$content =~ s{\(cn(.*?)\<cn\)}{\\cn{$1}}gms; # \cn the same as \cs???
$content =~ s{\(fn(.*?)\<fn\)}{\\fn{$1}}gms;
$content =~ s{\(emph(.*?)\<emph\)}{\\emph{$1}}gms;
$content =~ s{\(frag(.*?)\<frag\)}{$1}gms;
$content =~ s{\(cls(.*?)\<cls\)}{\\cls{$1}}gms;
$content =~ s{\(aside(.*?)\<aside\)}{\\begin{aside}\n$1\n\\end{aside}\n}gms; # looks like an environment
$content =~ s{\(dn(.*?)\<dn\)}{\\begin{dn}\n$1\n\\end{dn}\n}gms;
$content =~ s{\(m(.*?)\<m\)}{\$$1\$}gms; # seems to be math-mode
$content =~ s{\(p(.*?)\<p\)}{\($1\)}gms; 
$content =~ s{\(eqtype(.*?)\<eqtype\)}{\\eqtype{$1}}gms;
$content =~ s{\(opt(.*?)\<opt\)}{\\opt{$1}}gms;

$content =~ s{\(itemize}{\\begin{itemize}}gms;
$content =~ s{\<itemize\)}{\\end{itemize}\n}gms;
$content =~ s{\(enumerate}{\\begin{enumerate}}gms;
$content =~ s{\<enumerate\)}{\\end{enumerate}\n}gms;
$content =~ s{\(item}{\\item }gms;
$content =~ s{\<item\)}{\n }gms;

# literal seems to be the same as verbatim
$content =~ s{\(literal}{\\begin{verbatim}}gms;
$content =~ s{\<literal\)}{\\end{verbatim}}gms;


$content =~ s{\(\.([a-zA-z])}{\u$1}gms; # start of normal sentence
# get the rest
$content =~ s{\(\.}{}gms; # start of normal sentence

$content =~ s{\(\?([a-zA-z])}{\u$1}gms; # start of normal sentence
# and the rest
$content =~ s{\(\?}{}gms; # start of normal sentence

$content =~ s{\(\!([a-zA-z])}{\u$1}gms; # start of normal sentence
# and the rest
$content =~ s{\(\!}{}gms; # start of normal sentence

$content =~ s{\<\.\)}{\.   }gms; # end of normal sentence
$content =~ s{\<\?\)}{\?   }gms; # end of question
$content =~ s{\<\!\)}{\!   }gms; # end of question

# this seems to be a comment as there is nothing in the output
$content =~ s{\(\|(.*?)\<\|\)}{  % $1}gms; 

$content =~ s{\(para}{}gms; # start of a paragraph, dropped
$content =~ s{\<para\)}{}gms; # end of a paragraph, dropped

$content =~ s{\(q(.*?)\<q\)}{\`$1\'}gms; # quotes
$content =~ s{\(qq(.*?)\<qq\)}{\`\`$1\'\'}gms; # quotes
$content =~ s{\(p(.*?)\<p\)}{\($1\)}gms; # ()'s
$content =~ s{\[(.*?)\]}{\\$1 }gms;

# something that looks like \verb
$content =~ s{\(qc(.*?)\<qc\)}{\\verb"$1"}gms; # looks like \verb
$content =~ s{\("(.*?)\<"\)}{\\verb"$1"}gms; # looks like \verb
$content =~ s{\(c(.*?)\<c\)}{\\verb"$1"}gms; # looks like \verb
$content =~ s{\(ttq(.*?)\<ttq\)}{\\verb"$1"}gms; # looks like \verb


$content =~ s{(\((define).*?\<define\))}{behold_the_magic_carpet($1,$2)}gmse;
$content =~ s{(\((macros).*?\<macros\))}{behold_the_magic_carpet($1,$2)}gmse; # apparently a variant of define


$content =~ s{\<document\)}{\\end{document}}gms;

# just a template
$content =~ s{}{}gms;



if ( $show_unknown ) { # will show content and line number of lines containing ^E
  warn "The following lines contains markup not yet accounted for:\n\n";
  my $cnt = 0;
  for ( split/\n/,$content ) {
    $cnt++;
    printf "%05d: %s\n", $cnt,$_ if $_ =~ //;
  }
}
else { # otherwise simply print the contents
  print add_percent_sign($content);
}

exit;




sub behold_the_magic_carpet {
  my $t = shift;
  my $type = shift;
  # we need to know the number of ^E(macro^F...^E<macro) there are
  my $macro_cnt = 0;
  my @N = ('macro','cmd','const','toks','set','def','aux');
  for my $n ( @N ) {
    while  ( $t =~ m{\(\Q$n\E.*?\<\Q$n\E\)}gms ) { $macro_cnt++ }
  }
  # now we know how many \end{macro} to add
  # drop the define part
  $t =~ s{\(\Q$type\E}{}ms;
  for my $n ( @N ) {
    $t =~ s{\(\Q$n\E(.*?)\<\Q$n\E\)}{\\begin{macro}{\\$1}}gms;
  }
  $t =~ s{\<\Q$type\E\)}{"\\end{macro}\n" x $macro_cnt}e;
#  print '-' x 50,"\n\n", $t;
#  print $macro_cnt,"\n";
  return $t;
}


sub add_percent_sign {
  my $t = shift;
  my @lines = split /\n/,$t;
  my $active = 0;
  my @out = (); 
 LINE:
  for my $l ( @lines ) {
    if ( $l =~ m{begin{macrocode}} ) {
      $active = 1;
      push @out, $l;
      next LINE;
    }
    if ( $l =~ m{end{macrocode}} ) {
      $active = 0;
      push @out, $l;
      next LINE;
    }
    $l = '% ' . $l if ! $active && $l !~ /^\s*\%/;
    push @out, $l;
  }
  return join "\n", @out;
}




