#!/usr/bin/perl

use v5.16;
use warnings;
use autodie qw( :all );
use utf8::all;

use CHI;
use WWW::Mechanize::Cached::GZip;

my $url = 'http://mail.opensolaris.org/mailman/listinfo';

my $cache = CHI->new(
    'driver'             => 'File',
    'root_dir'           => '/tmp/perl-cache/',
    'default_expires_in' => '20d',
    'namespace'          => 'mail-opensolaris',
);

my $mech = WWW::Mechanize::Cached::GZip->new( 'cache' => $cache );

#$mech->cache_undef_content_length('warn');
$mech->cache_undef_content_length(1);
$mech->cache_zero_content_length('warn');

$mech->get($url);

foreach my $list ( $mech->links() ) {
    next if ( $list->url() !~ m/^listinfo/xms );
    $mech->get( 'http://mail.opensolaris.org/mailman/' . $list->url() );
    my @archive = $mech->find_all_links(
        'tag'        => 'a',
        'text_regex' => qr/Archives/xms
    );
    foreach my $gz_list (@archive) {
        next if ( $gz_list->url() =~ m{mailman/}xms );

        $mech->get( $gz_list->url() );
        if ( $mech->success ) {
            my @gzs = $mech->find_all_links(
                'tag'       => 'a',
                'url_regex' => qr/[.]gz$/xms
            );
            foreach my $file (@gzs) {
                $mech->get( $file->base() . $file->url() );

                my @s = split '/', $file->base()->as_string;
                mkdir 'mail/' . $s[-1] if ( !-e 'mail/' . $s[-1] );
                $mech->save_content( 'mail/' . $s[-1] . '/' . $file->url() );
            }
        }
    }

}
