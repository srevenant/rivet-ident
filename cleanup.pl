#!/usr/bin/perl

use strict;

sub scan_folder {
  my $folder = $_[0];

  opendir(DIR, $folder);
  my @files = readdir(DIR);
  closedir(DIR);

  foreach my $fn (@files) {
    if ($fn =~ /^\./) {
      next;
    }
    my $fpath = "$folder/$fn";
    if (-f $fpath && ! -s $fpath && $fn =~ /\.ex(s)?/) {
      &revise_file($fpath);
    } elsif (-d $fpath) {
      &scan_folder($fpath);
    }
  }
}

my $prefix = "Auth";
sub revise_file {
  my $file = $_[0];
  rename($file, "$file.x");
  open(FILE, "$file.x");
  open(OUT, ">$file");
  my $modname = "";
  while (<FILE>) {
    if (/defmodule ([a-z0-9\.]+) do/) {
      $modname = $1;
    }

    # my $before = $_;
    s/(\s)Repo\./ \@repo./g;
    if (s/$prefix([A-Z0-9\.]+)s\./$prefix$1.Db./gi) {
      s/$prefix([A-Z0-9\.]+)\.Db\.(one!?|all!?|build|upsert|change_post|change_prep|changeset|count!?|create|create_post|create_prep|delete|delete_all|delete_all_ids|drop_replace|exists?|full_table_scan|replace|replace_fill|stream|stream_all!?|touch|unload|update!?|update_all|update_fill|preload!?)\(/$prefix$1.$2(/gi;
      # print "- $before";
      # print "+ $_";
    }
    # if (/use .*\.CollectionIntId/) {
    #   print STDERR "WARNING: CollectionIntId found! ($file)";
    # }
    s/use .*\.CollectionUuid,.*$/use Rivet.Ecto.Collection.Context/;

    print OUT;
  }
  close(FILE);
  close(OUT);
  unlink("$file.x");
}

&scan_folder(".");
