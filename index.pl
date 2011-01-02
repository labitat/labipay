#!/usr/bin/perl -Tw

use strict;
use warnings;

use lib '.';

use Labipay::Funcs;
use Labipay::Auth;
use Labipay::ActionHandler;
use CGI;


my $q = new CGI;
my $dbh = db_connect();


my $user = authenticate($q, $dbh, '.');


my $title = 'Overview';
$title   .= " - $user->{name}" if $user->{name};

my $rightbox = '';
my $page     = '';
my $head     = qq|<script src="ajax/util.js"></script>\n|;;

# Handle actions
my $handler_response = handle($q, $dbh, $user, {'transfer' => undef,
						create_shop => undef,
						create_account => undef,
			                       }
                              );  


# Find account info
my $total_balance = 0;

my $auth_fields = make_auth_fields($user);
my $auth_get_fields  = make_auth_fields($user, 1);
my $my_accounts_options = '';

my $sth = $dbh->prepare("SELECT * FROM account WHERE owner = ? order by standard DESC, number ASC");
error(500, "No contact to database: " . $dbh->errstr) unless $sth;
$sth->execute($user->{id}) or error(500, $dbh->errstr);

# If no account has been defined for this user, create one
unless ($sth->rows) {
    $dbh->do("INSERT INTO account (owner, name, standard) values (?, 'Primary', 1)", undef, $user->{id}) or error(500, "Could not create account: " . $dbh->errstr);

    # Re-get
    $sth->execute($user->{id});
}

$rightbox .= qq|<table border="0" class="infotable">
                   <tr><td><b>Accounts</b></td><td></td></tr>\n|;

while (my $account = $sth->fetchrow_hashref){
    my $sel = ord($account->{standard})==0 ? '' : 'selected="selected"';
    $my_accounts_options .= qq|<option value="$account->{number}" $sel>$account->{name}</option>\n|;


    my $balanceclass = ($account->{balance} < 0) ? ' class="negative"' : '';
    $rightbox .= sprintf(qq|<tr><td><a href="account.pl?account=%d&%s">%s</a></td><td style="text-align: right" $balanceclass>%01.2f</td></tr>\n|,
			 $account->{number},
			 $auth_get_fields,
			 $account->{name},
			 $account->{balance}
	                );
    $total_balance += $account->{balance};
}
my $balanceclass = ($total_balance < 0) ? ' class="negative"' : '';
$rightbox .= sprintf( qq|<tr><td><b>Total:</b></td><td style="text-align:right" $balanceclass><b>%01.2f</b></td></tr>\n|,
		      $total_balance);


# "Create account" button
$rightbox .= qq|<tr><td colspan="2"><form action="#" method="post">|;
$rightbox .= $auth_fields;
$rightbox .= qq|<input type="hidden" name="action" value="create_account" />|;
$rightbox .= qq|<input type="hidden" name="account_name" value="" id="new_account_name" />|;
$rightbox .= qq|<input type="submit" value="Create new account" onclick="return confirm('Really create new account?')"/></form></td></tr>|;
$rightbox .= qq|</table><hr class="rightboxspacer" />\n|;

# TODO: Add javascript to ask for account name


# Shop info
$sth = $dbh->prepare("SELECT shop.* FROM shop, shop_admin WHERE shop_admin.shop = shop.id and shop_admin.person = ? order by name ASC");
error(500, "No contact to database: " . $dbh->errstr) unless $sth;

$sth->execute($user->{id});

$rightbox .= qq|<b>Shops</b><br/>\n|;

while (my $shop = $sth->fetchrow_hashref){
    $rightbox .= sprintf(qq|<a href="shop.pl?shop=%d&%s">%s</a><br/>\n|,
			 $shop->{id},
			 $auth_get_fields,
			 $shop->{name},
	                );
}

# "Create shop" button
$rightbox .= qq|<form action="#" method="post">|;
$rightbox .= make_auth_fields($user);
$rightbox .= qq|<input type="hidden" name="action" value="create_shop" />|;
$rightbox .= qq|<input type="hidden" name="shop_name" value="" id="new_shop_name"/>|;
$rightbox .= qq|<input type="hidden" name="shop_name" value="" id="new_shop_account"/>|;

# TODO: Add javascript to ask for shop name and account
$rightbox .= qq|<input type="submit" value="Create shop" onclick="return confirm('Really create new shop?')" /></form>|;


if ($total_balance < 0) {
    $page .= sprintf( qq|<p class="error"><b>You owe money!</b><br/>Please insert at least <b>%01.2f</b> on your account.</p>|,
		      0 - $total_balance
	            );
}


# Buy button
$page .= qq|<h3>Go shopping</h3><form action="buy.pl" method="post">
            $auth_fields
            <input type="submit" value="Buy something!" /></form>|;


# Transfer
$head .= qq|<script src="ajax/OpenThought.js"></script>\n|;
$page .= '<a name="transfer"></a><h3>Transfer</h3>';
$page .= $handler_response->{transfer}->{text} || '';
$page .= qq|<form action="#transfer" method="post">
            Transfer a sum of
            <input type="text" name="amount" size="6"/>
            from my <select name="from_account">
            $my_accounts_options
            </select> account
            <br/>
            to<br/>

            <input type="radio" name="to_type" value="my" checked="checked" id="to_type_my" onclick="document.getElementById('select_my_to_account').disabled=false; document.getElementById('user_to_account_username').value=''; document.getElementById('user_to_account_username').disabled=true; document.getElementById('select_user_to_account').disabled=true;  document.getElementById('select_user_to_account').disabled=true;"/>
            my <select name="to_account" id="select_my_to_account">$my_accounts_options</select> account<br/>

            <input type="radio" name="to_type" value="user" id="to_type_user" onclick="document.getElementById('select_my_to_account').disabled=true; document.getElementById('user_to_account_username').disabled=false;" />
            user
            <input type="text" size="15" id="user_to_account_username" name="user_to_account_username" disabled="disabled" onkeyup="getElementById('select_user_to_account').disabled=false; clearselect('select_user_to_account', false); delay_ajax( 'user_to_account_username', 'username2accounts', 300)" />'s account
            <select name="to_account" id="select_user_to_account" disabled="disabled"></select>
            $auth_fields
            <br/>
            <input type="hidden" name="action" value="transfer" />
            <input type="submit" value="Transfer" onclick="return confirm('Are you sure that you want to transfer the money?')" />
            </form>
            
            |;



print ${apply_template( { title => $title,
			  page => qq|<div class="rightbox">$rightbox</div>$page|,
			  head => $head,
                        }
                       )
        };


exit;
