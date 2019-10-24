#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use YAML::Tiny;

sub frontmatter {
  my ( $path, $src ) = @_;
  my ( $website ) = ( $path =~ m{src/([^/]+)/} );

  $src =~ s{! '}{'}g;
  $src =~ s{'+}{'}g;

  my $out   = q{};
  my $data  = YAML::Tiny::Load($src);

  if ( $website eq 'bookmarks' ) {
    my $title = $data->{'title'};
    my $link  = $data->{'link'};
    my $date  = $data->{'date'};
    my $tags  = $data->{'tags'};
    my $slug  = $data->{'slug'};

       $title =~ s{"}{\\"}g;

    if ( ! defined $slug || $slug =~ m{^\d{6}$} ) {
      my $hms = ( $date =~ m{(\d{2}:\d{2}:\d{2})} )[0];
         $hms =~ s{:}{}g;

      $slug = $hms;
    }

    $out .= qq{---\n};
    $out .= qq{type: bookmarks\n};
    $out .= qq{title: "${title}"\n};
    $out .= qq{link: '${link}'\n};
    $out .= qq{date: '${date}'\n};
    $out .= qq{slug: '${slug}'\n};
    $out .= qq{tags: \n  - } . join(qq{\n  - }, sort { $a cmp $b } @{ $tags || [] }) . "\n";
    $out .= qq{---\n};
  }
  elsif ( $website eq 'echos' ) {
    my $title = $data->{'title'};
    my $date  = $data->{'date'};
    my $slug  = $data->{'slug'};
    my $fixme = $data->{'fixme'};
    my $ads   = $data->{'ads'};

       $title =~ s{"}{\\"}g;

    if ( ! defined $slug || $slug =~ m{^\d{6}$} ) {
      my $hms = ( $date =~ m{(\d{2}:\d{2}:\d{2})} )[0];
         $hms =~ s{:}{}g;

      $slug = $hms;
    }


    $out .= qq{---\n};
    $out .= qq{type: echos\n};
    $out .= qq{title: "${title}"\n};
    $out .= qq{date: '${date}'\n};
    $out .= qq{slug: '${slug}'\n};
    $out .= qq{ads: @{[ ( $ads eq 'true' ) ? 'true' : 'false' ]}\n};
    $out .= qq{fixme: @{[ ( $fixme eq 'true' ) ? 'true' : 'false' ]}\n};
    $out .= qq{---\n};

  }
  elsif ( $website eq 'notes' ) {
    my $title = $data->{'title'};
    my $slug  = $data->{'slug'};
    my $date  = $data->{'date'};
    my $ads   = $data->{'ads'};
    my $fixme = $data->{'fixme'};

       $title =~ s{"}{\\"}g;
       $slug  =~ s{"}{\\"}g;

    $out .= qq{---\n};
    $out .= qq{type: notes\n};
    $out .= qq{title: "${title}"\n};
    $out .= qq{slug: "${slug}"\n};
    $out .= qq{date: '${date}'\n};
    $out .= qq{ads: @{[ ( $ads eq q{} || $ads eq 'true' ) ? 'true' : 'false' ]}\n};
    $out .= qq{fixme: @{[ ( $fixme ne q{} && $fixme eq 'true' ) ? 'true' : 'false' ]}\n};
    $out .= qq{---\n};
  }
  elsif ( $website eq 'posts' ) {
    my $title = $data->{'title'};
    my $date  = $data->{'date'};
    my $slug  = $data->{'slug'};
    my $tags  = $data->{'tags'};
    my $fixme = $data->{'fixme'};
    my $ads   = $data->{'ads'};

       $title =~ s{"}{\\"}g;

    if ( ! defined $slug || $slug =~ m{^\d{6}$} ) {
      my $hms = ( $date =~ m{(\d{2}:\d{2}:\d{2})} )[0];
         $hms =~ s{:}{}g;

      $slug = $hms;
    }

    $out .= qq{---\n};
    $out .= qq{type: posts\n};
    $out .= qq{title: "${title}"\n};
    $out .= qq{date: '${date}'\n};
    $out .= qq{slug: '${slug}'\n};
    $out .= qq{tags: \n  - } . join(qq{\n  - }, sort { $a cmp $b } @{ $tags || [] }) . "\n";
    $out .= qq{ads: @{[ ( $ads eq 'true' ) ? 'true' : 'false' ]}\n};
    $out .= qq{fixme: @{[ ( $fixme eq 'true' ) ? 'true' : 'false' ]}\n};
    $out .= qq{---\n};
  }

  return $out; 
}

sub content {
  my ( $path, $content ) = @_;

  # TODO

  return $content;
}

sub main {
  my $file = shift;
  my $frontmatter = q{};
  my $content     = q{};

  my $is_frontmatter = 0;

  print "${file}\n";

  open(my $fh, '<', $file);
  while ( my $line = <$fh> ) {
    chomp($line);

    if ( $line eq "---" ) {
      $is_frontmatter++;
      next;
    }

    if ( $is_frontmatter == 1 ) {
      $frontmatter .= qq[${line}\n];
    } else {
      $content .= qq[${line}\n];
    }
  }

  close($fh);

  my $output  = frontmatter($file, $frontmatter);
     $output .= content($file, $content);

  open(my $w, '>', $file);
  print $w $output;
  close($w);
}

main(@ARGV);
