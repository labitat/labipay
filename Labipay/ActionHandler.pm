package Labipay::ActionHandler;

use Labipay::Funcs;
use Labipay::Auth;
use DBI;
use Lingua::EN::Numbers qw(num2en_ordinal);

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(handle); 

use strict;
use warnings;



# handle()
#
# Perform any actions from input forms
#
# Arguments:
#    cgi     - a CGI object
#    dbh     - a database handle
#    user    - a hashref that represents the current user (undef if
#              no user is logged in)
#    actions - a hashref - keys:   the names of actions to handle
#                          values: the page to send to on input errors
#                                  (undef means just return)
#
# Returns:
#    A hashref - keys:   the names of the handled actions
#                values: a hashref with
#                        status   - true on ok, false on fail
#                        text     - a string with any response to
#                                   the user (e.g. ok/error)
#
# Notes:
#    On database errors, the error() function is called
sub handle {
    my ($cgi, $dbh, $user, $actions) = @_;

    my $res = {};
    my $action = $cgi->param("action");

    unless ($cgi and $dbh and $actions){
	error(500, "Wrong arguments to handle()");
    }

    # See whether we have anything to do
    return $res unless ( $action and exists $actions->{$action} );

    if ($action eq 'transfer') {
	_handle_transfer($res, @_);
    }
    elsif ($action eq 'create_account') {
	_create_account($res, @_);
    }
    elsif ($action eq 'create_shop') {
	_create_shop($res, @_);
    }

    return $res;

}


####
#
# TRANSFER
#
####
sub _handle_transfer {
    my ($res, $cgi, $dbh, $user, $actions) = @_;


    # Check that we have a logged in user
    unless ($user->{id}) {
	return _fail( 'transfer', 
		      $actions,
		      $res,
		      $cgi,
		      '<p class="error">Could not transfer: No user is logged in</p>');
    }

    # Check permission
    unless (permission($user->{id}, 'admin', $dbh)) {
	my $sth = $dbh->prepare("SELECT * FROM account WHERE number=?")
	    or error(500, "Database error: " . $dbh->errstr);
	$sth->execute( $cgi->param("from_account") )
	    or error(500, "Database error: " . $dbh->errstr);
	
	my $row = $sth->fetchrow_hashref;
	
	unless ($row->{owner} == $user->{id}) {
	    return _fail( 'transfer', 
			  $actions,
			  $res,
			  $cgi,
			  '<p class="error">You are now allowed to transfer from that account!</p>');
	}	    
    }
	
    # Clean up amount
    my $amount = $cgi->param("amount") || '';
    $amount =~ s/[^0-9\,\.\-]//g;
    
    # Handle different commas
    if ($amount =~ m/\d\,\d\d\d(\.\d\d)$/){
	$amount =~ s/\,//g;
    }
    elsif (   $amount =~ m/\d\.\d\d\d(\,\d\d)$/
	      or $amount =~ m/^\d*\,\d\d?$/){
	$amount =~ s/\./=/;
	$amount =~ s/\,/./;
	$amount =~ s/=/,/;	    
    }
    
    # Force to be a valid number
    {
	no strict;
	no warnings;
	$amount += 0;
    }
    
    # Is the amount zero (or 0.00 etc)?
    if ( $amount == 0) {
	return _fail( 'transfer', 
		      $actions,
		      $res,
		      $cgi,
		      qq|<p class="error">Please fill out the amount field with a valid number</p>|);
    }
    elsif ( $amount < 0 ) {
	return _fail( 'transfer', 
		      $actions,
		      $res,
		      $cgi,
		      '<p class="error">No, you cannot transfer a negative amount. How stupid do you think we are?</p>');
    }
    elsif ( $cgi->param("from_account")  == $cgi->param("to_account") ) {
	    return _fail( 'transfer', 
			  $actions,
			  $res,
			  $cgi,
			  '<p class="error">It does not make sense to transfer from an account to itself. Please choose another account.</p>');
    }
    
    
    # Make the transfer as a transaction
    $dbh->do("start transaction")
	or error(500, "Database error: " . $dbh->errstr);
    
    $dbh->do("update account set balance = balance - ? where number = ?",
	     undef,
	     $amount,
	     $cgi->param("from_account"))
	or _rollback_and_die($dbh);
    
    
    $dbh->do("update account set balance = balance + ? where number = ?",
	     undef,
	     $amount,
	     $cgi->param("to_account"))
	or _rollback_and_die($dbh);
    
    $dbh->do("insert into transfer (from_account, to_account, amount) values (?, ?, ?)",
	     undef,
	     $cgi->param("from_account"),
	     $cgi->param("to_account"),
	     $amount
	)
	or _rollback_and_die($dbh);
    
    $dbh->do("commit")
	or error(500, "Database error - could not commit: " . $dbh->errstr);
    
    $res->{transfer} = {  status => 1,
			  text   => qq|<p class="good">$amount was transferred</p>|,
    };
    
}


####
#
# CREATE ACCOUNT
#
####
sub _create_account {
    my ($res, $cgi, $dbh, $user, $actions) = @_;


    # Check that we have a logged in user
    unless ($user->{id}) {
	return _fail( 'create_account', 
		      $actions,
		      $res,
		      $cgi,
		      '<p class="error">Could not create account: No user is logged in</p>');
    }

    my $name = $cgi->param("new_account_name");
    
    unless ($name) {
	my $sth = $dbh->prepare("SELECT COUNT(number) FROM account WHERE owner = ?");
	if ($sth and $sth->execute("$user->{id}")) {
	    my $count = $sth->fetchrow_arrayref->[0];
	    $name = ucfirst(num2en_ordinal($count+1));
	}
    }
    $name ||= 'New';

    $dbh->do("insert into account (name, owner) VALUES (?, ?)",
	     undef,
	     $name,
	     $user->{id}
	    )
	or error(500, "Database error - could not create account: " . $dbh->errstr);
    
    $res->{create_shop} = {  status => 1,
				text   => qq|<p class="good">Account &quot;$name&quot; was created</p>|,
    };
}



####
#
# CREATE SHOP
#
####
sub _create_shop {
    my ($res, $cgi, $dbh, $user, $actions) = @_;

    my $add_id_to_name = 0;

    # Check that we have a logged in user
    unless ($user->{id}) {
	return _fail( 'create_shop', 
		      $actions,
		      $res,
		      $cgi,
		      '<p class="error">Could not create shop: No user is logged in</p>');
    }

    my $name = $cgi->param("new_shop_name");
    my $account = $cgi->param("new_shop_account");

    # Default name
    unless ($name) {
	$name = '' . ($user->{handle}//'Labitat') . "'s new shop";
	$add_id_to_name = 1;
    }

    # Account number check
    if ($account) {
	# Check that the account exists
	$account =~ s/\D//g;
	my $sth = $dbh->prepare("SELECT * FROM account WHERE number = ?");
	unless ( $sth and $sth->execute($account) ) {
	    error(500, "Could not verify account number '$account'");
	}
    }
    else {
	# Select the user's standard account
	my $sth = $dbh->prepare("SELECT * FROM account WHERE owner = ? ORDER BY standard DESC, number ASC");
	unless ($sth and $sth->execute($user->{id})){
	    error( 500, "Could not find an account to use with the shop: " . $dbh->errstr);
	}
	my $row = $sth->fetchrow_hashref;
	unless ($row) {
	    return _fail( 'create_shop', 
			  $actions,
			  $res,
			  $cgi,
			  '<p class="error">You do not have any accounts!</p>'
		         );
	}
	$account = $row->{number};
    }
    
    
    $dbh->do("start transaction")
	or error(500, "Database error: " . $dbh->errstr);
    
    $dbh->do("insert into shop (name, account) values (?, ?)",
	     undef,
	     $name,
	     $account
	)
	or _rollback_and_die($dbh);
    
    my $sth = $dbh->prepare("SELECT LAST_INSERT_ID()");
    unless ($sth and $sth->execute()){
	_rollback_and_die($dbh);
    }
    my $shop_id = $sth->fetchrow_arrayref->[0];

    unless ($shop_id){
	_rollback_and_die($dbh, "Could not get shop ID");
    }

    if ($add_id_to_name) {
	$dbh->do("UPDATE shop SET name = CONCAT(name, ' (', ?, ')') WHERE id = ?",
	     undef,
	     $shop_id,
	     $shop_id
	    )
	    or _rollback_and_die($dbh, "Could not change name for shop $shop_id");
    }

    $dbh->do("INSERT INTO shop_admin (shop, person) VALUES (?,?)",
	     undef,
	     $shop_id,
	     $user->{id}
	)
	or _rollback_and_die($dbh, "Could not add admin to shop. Giving up");
    
    $dbh->do("commit")
	or error(500, "Database error - could not commit: " . $dbh->errstr);
    

    $res->{create_account} = {  status => 1,
				text   => qq|<p class="good">Account &quot;$name&quot; was created</p>|,
                             };
    
}




# _fail()
#
# Internal function, handles failure
#
# Arguments:
#    action   - string with the current action
#    actions  - incoming hash with actions
#    res      - a hashref to the result hashref
#    cgi      - the cgi object
#    text     - an error message (string)
#    
#  Returns:
#    The result hashref
#
# Notes:
#    If an error page is given, calls that error page and exits!
#
sub _fail {
    my ($action, $actions, $res, $cgi, $text) = @_;

    $res->{$action}->{status} = 0;
    $res->{$action}->{text} = $text;

    unless ($actions->{$action}) {
	return $res;
    }

    # TODO: Return to proper page
    

    error(401, $text);
}


# _rollback_and_die()
#
# Makes a transaction rollback and calls error()
#
# Arguments:
#     dbh   - a database handle
#    [msg]  - a message string (optional, default 'Database error')
#     
# Returns:
#     Never returns, exits
#
# Notes:
#     None
sub _rollback_and_die {
    my ($dbh, $msg) = @_;

    $msg //= 'Database error';

    my $errstr = $dbh->errstr;

    $dbh->do("rollback")
	or error(500, 
		 sprintf("Database error - could not even rollback: %s (original error was: %s - %s)",
			 $dbh->errstr,
			 $msg,
			 $errstr)
	);

    error(500, "$msg: $errstr<br/>Rolled back");
}
