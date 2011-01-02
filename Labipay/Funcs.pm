package Labipay::Funcs;

use Labipay::Setup;
use DBI;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(db_connect apply_template make_auth_fields error); 




# db_connect()
#
# Connect to the database
#
# Arguments:
#     None
#
# Returns:
#     A database handle, undef on error
#
# Notes: None
sub db_connect {

    my $dbh = DBI->connect($Labipay::Setup::db_dsn,
			   $Labipay::Setup::db_user,
			   $Labipay::Setup::db_pw);

    return $dbh;
}


# apply_template()
#
# Applies a template to the data to make a complete HTTP response
#
# Arguments:
#     data      A hashref with the data to fill the template
#               The standard template accepts the following keys:
#                   page    - The content of the body
#                   title   - The title of the page
#                   head    - A text to insert in the HTML HEAD
#                   headers - An arrayref with HTTP headers to add
#
#   [template]  A string with the template to use. (Optional)
#               If the template is a file URL, the file is used.
#               If the template is a string beginning with "template:",
#                 the string after the colon is taken to be the symbolic
#                 name of a template to read.
#
# Returns:
#   A reference a string with the content.
#
# Notes:
#   On error, a default template is used.
sub apply_template {
    my ($data, $template) = @_;

    # If no template has been set, use the default
    $template //= "template:$Labipay::Setup::default_template";

    if ($template =~ m/^template:(.+)$/){
	if ( open TEMP, "<$Labipay::Setup::template_dir/$1" ){
	    $template = join "", <TEMP>;
	}
	else {
	    $template = undef;
	}
    }
    elsif ( $template =~ m/^file:\/\/(.+)$/){
	if ( open TEMP, "<$1" ){
	    $template = join "", <TEMP>;
	}
	else {
	    $template = undef;
	}
    }

    unless (defined $template) {
	# Make an emergency template
	
	$template = join "", <DATA>;
    }

    # Make headers
    my $headers = "Content-Type: " .
                  ($data->{headers}->{"Content-Type"} || "text/html") .
                  "\n";
    
    foreach my $header ( grep { $_ ne 'Content-Type' } keys %{$data->{headers}} ){
	$headers .= "$header: $data->{headers}->{$header}\n";
    }

    
    # Apply template
    foreach my $key ( keys %$data ) {
	next if $key eq 'headers';

	my $uckey = uc $key;

	$template =~ s/<!\-\-${uckey}\-\->/$data->{$key}/g;
    }
    $template =~ s/<!\-\-[A-Z0-9\-_]+\-\->//g;

    $template = "$headers\n$template";

    return \$template;
}


# make_auth_fields()
#
# Create <input type="hidden"> field for authentification
# 
# Arguments:
#    user    - as userinfo hashref as returned by Auth
#    for_get - If true, make fields suitable for a GET string
#              (e.g. "foo=bar&baz=quux"). If false (default), 
#              make fields suitable for a form (e.g. "<input .../>").
#
# Returns:
#    A string with any relevant <input type="hidden"> fields
#
# Notes:
#    None
sub make_auth_fields {
    my ($user, $for_get) = @_;

    my $res = '';

    if (    $user
        and ref $user eq 'HASH'
	and $user->{authfields}
	and ref $user->{authfields} eq 'ARRAY'
	){

	if ($for_get) {
	    $res .= join '&', map { "$_->[0]=$_->[1]" } @{$user->{authfields}};
	}
	else {
	    foreach my $pair (@{$user->{authfields}}) {
		
		$res .= qq|<input type="hidden" name="$pair->[0]" value="$pair->[1]" />\n|
	    }
	}
    }
    return $res;
}


# error()
#
# Make an error page and exit.
#
# Arguments:
#    status    - HTTP status code (e.g. 500)
#    msg       - A string with the error message
#
# Returns:
#    Does not return (exits)
#
# Notes:
#    Exits
sub error {
    my ($status, $msg) = @_;

    print ${apply_template( { title => "Error $status", page => qq|<p class="error">$msg</p>|, } )};

    exit;
}


__DATA__
<html>
  <head>
    <title>Error: <!--TITLE--></title>
    <!--HEAD-->
  </head>
  <body>
    <h1><!--TITLE--></h1>
    <!--PAGE-->
  </body>
</html>
   
