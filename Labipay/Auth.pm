package Labipay::Auth;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(authenticate permission); 

use Labipay::Funcs;

# authenticate()
#
# Handles authentification of the web user.
# This can be done by login, cookies, or other means
#
# Arguments:
#      cgi      a CGI object
#      dbh      a database handle
#     [return]  URL of the page to return to after login (optional)
#
# Returns:
#      A hashref with the following keys:
#        id     - User id
#        name   - User's real name
#        handle - User handle (user name)
#        email  - User email (if known)
#        authfields - an arrayref of [name, value] pairs to insert in all forms
#
#      undef on error and when the user could not be autheticated.
#                    
# Notes:
#      If the "return" argument is given, this function will _not_ return.
#      Instead, it will refer the user to a login page and exit.
#      The login page will be given the "return" argument as the URL to
#      send the user back to after giving his credentials.
sub authenticate {
    my ($cgi, $dbh, $return) = @_;

    return undef unless $cgi && $dbh;

    # For now, just check whether I am me
    if (     (    $cgi->param("auth_user") || '' eq 'Elhaaard'
	      and $cgi->param("auth_password") || '' eq 'letmein')
        or   (    $cgi->param("auth_userid") || '' eq '2'
	      and $cgi->param("auth_session") || '' eq '8khjdwq8y32e')
        ) {
	return {    id     => 2,
		    name   => "Jørgen Elgaard Larsen",
		    handle => "Elhaard",
		    email  => 'jel@elgaard.net',
		    authfields => [  [ auth_session, '8khjdwq8y32e' ], [auth_userid, 2] ],
	};
    }

    # If we get here, the user could not be authenticated
    return undef unless $return;
    my $args = "return=$return";
    $args .= "&auth_user=" . $cgi->param("auth_user") if $cgi->param("auth_user");
    print ${apply_template( { title => "Please login",
			      page => qq|<p class="error"><a href="login.pl?$args">Please login here</a></p>|,
			      headers => { Location => qq|login.pl?$args| },
			    }
                           )
	   };
    exit;

}


# permission()
#
# Find out whether a given user has a given permission
# 
# Arguments:
#      userid      a user id (integer)
#      permission  the permission to check (string, e.g. "admin")
#      dbh         a database handle
#
# Returns:
#      True or false
#                    
# Notes:
#      None
sub permission {
    my ($userid, $permission, $dbh) = @_;

    return ($userid < 1);
}

