#!/usr/bin/perl -Tw

use strict;
use warnings;

use lib '..';

use Labipay::Funcs;
use CGI;
use OpenThought;


# AJAX backend for looking up a users accounts
#
# The information is public, so no authentification is needed.

my $OT = new OpenThought;
my $q = new CGI;

my $dbh = db_connect();

my $res = undef;

my $username = $q->param('user_to_account_username');

if ($username) {

    my $sth = $dbh->prepare("SELECT DISTINCT a.name, a.number
                             FROM account a, person p
                             WHERE p.username like ?
                               AND a.owner = p.id
                             ORDER BY a.standard DESC, a.name ASC");
    if ($sth and $sth->execute(lc $username)) {
	$res = $sth->fetchall_arrayref;
    }
    else {
	print STDERR "Database error for AJAX username2accounts: " . $dbh->errstr . "\n";
    }

}

print $q->header();


print $OT->parse_and_output( { auto_param => { select_user_to_account => $res },
			       settings   => {selectbox_single_row_mode=>'overwrite'},
			     },
                           );

print "\n";

exit;
