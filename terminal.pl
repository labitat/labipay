#!/usr/bin/perl -Tw

use strict;
use warnings;

use lib '.';

use Labipay::Funcs;

use CGI;
use JSON;

my $q = new CGI;
my $dbh = db_connect();
my $response = {};





print "Content-Type: application/json\n\n";
my $json = new JSON;
print $json->encode($response);

exit;




sub error {
    my $response = shift || {};
    my $status = shift || 'error';

    


}


sub add_checksum {
    my $response = shift;
    my $fields   = shift;
    my $secret   = shift;

    my $string = $response->{seed} = seed();
    foreach my $field (@$fields) {
	$string .= $response->{$field};
    }
    $string .= $secret;
    
    $response->{checksum} = $string;

    return $string;     

}


sub seed {

    my $length = 10;
    my $seed = '';
    for (my $i = 0; $i < $length; $i++) {
	$seed .= 'g';
    }
    

    return $seed;
}
