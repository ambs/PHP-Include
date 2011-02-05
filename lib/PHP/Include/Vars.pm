package PHP::Include::Vars;
use warnings;
use strict;
use Filter::Simple;
use Parse::RecDescent;
use Data::Dumper;

our $perl = '';
my $grammar = 


<<'GRAMMAR';

php_vars:	php_start statement(s) php_end

php_start:	/\s*<\?php\s*/

php_end:	/\s*\?>/

statement:      comment | assignment

comment:        /\s*(\#|\/\/).*/

assignment:	( var_assign | hash_assign | array_assign | constant ) /;/
		{
		    $PHP::Include::Vars::perl .= "$item[1];\n";
		}

var_assign:	variable /=/ scalar 
		{
		    $return = "my $item[1]=$item[3]"; 
		}

hash_assign:	variable /=/ /Array\s*\(/i pair(s /,/) /\s*(,\s*)?\)/
		{
		    $item[1] =~ s/^\$/%/;
		    $return = "my $item[1]=(" . join( ',', @{$item[4]} ) . ')';
		}

array_assign:	variable /=/ /Array\s*\(/i element(s /,/) /\s*(,\s*)?\)/
		{
		    $item[1] =~ s/^\$/@/;
		    $return = "my $item[1]=(" . join( ',', @{$item[4]} ) . ')'
		}

scalar:		string | number	

variable:	/\$[a-zA-Z_][0-9a-zA-Z_]*/ 

number:		/-?[0-9.]+/

string:		double_quoted | single_quoted

double_quoted:	/".*?"/

single_quoted:	/'.*?'/

element:	array | scalar | hash | bareword

pair:		scalar /=>/ ( scalar | array | hash | bareword )
		{
		    $return = $item[1] . '=>' . $item[3];
		}

array:          /Array\s*\(/i element(s /,/) /\s*(,\s*)?\)/
                {
                    $return = '['.join(',',@{$item[2]}) . ']';
                }

hash:           /Array\s*\(/i pair(s /,/) /\s*(,\s*)?\)/
                {
                    $return = '{'.join(',',@{$item[2]}) . '}';
                }

bareword:	/[0-9a-zA-Z_]+/
		
constant:	/define\s*\(/ string /,/ scalar /\)/ 
		{
		    $return =  "use constant $item[2] => $item[4]";
		}

whitespace:	/^\s+$/

GRAMMAR

my $parser = Parse::RecDescent->new( $grammar );

FILTER {
    $perl = '';
    #$::RD_TRACE = 1;
    $parser->php_vars( $_ );
    print STDERR "\n\nGENERATED PERL:\n\n", $perl, "\n\n"
	if $PHP::Include::DEBUG; 
    $_ = $perl;
}

=head1 NAME

PHP::Include::Vars

=head1 SYNOPSIS

    use PHP::Include::Vars;
    <?php
    $x = Array( 1,2,3 );
    ?>
    no PHP::Include::Vars;

=head1 DESCRIPTION

Please see PHP::Include for details. PHP::Include::Vars is an implementation 
for the include_php_vars() macro.

=head1 SEE ALSO

=over 4 

=item * PHP::Include

=item * Filter::Simple

=item * Parse::RecDescent

=head1 AUTHORS

=over 4

=item * Ed Summers <ehs@pobox.com>

=cut

