#!/usr/bin/perl -Tw

use strict;
use warnings;

use lib '.';

use Labipay::Funcs;
use Labipay::Auth;
use CGI;


my $q = new CGI;
my $dbh = db_connect();


my $user   = authenticate($q, $dbh);
my $return = $q->param("return");
my $title  = "Login";

my $page = qq|<form method="post" action="$return">\n|;
if ($user) {
    foreach my $pair ( @{$user->{authfields}} ) {
	$page .= qq|<input type="hidden" name="$pair->[0]" value="$pair->[1]" />\n|;
    }
    $page .= qq|<input type="submit" value="Continue" />|;
    $title = '';
}
else {
    my $name = $q->param("auth_user") || '';
    if ($name){
	$page .= qq|<p class="error">Login incorrect</p>\n|;
    }
	
    $page .= qq|Username: <input type="text" name="auth_user" value="$name" /><br/>
                Password: <input type="password" name="auth_password" />
                <input type="submit" value="Login" />
               |;
}
$page .= qq|</form>|;



print ${apply_template( { title => $title, page => $page } )};


exit;
