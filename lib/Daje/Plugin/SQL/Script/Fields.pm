package Daje::Plugin::SQL::Script::Fields;
use Mojo::Base 'Daje::Plugin::SQL::Base::Common', -signatures;

use Syntax::Keyword::Match qw(match);

our $VERSION = "0.01";

sub create_fields($self){
    my $field = '';
    eval {
        my $fields = $self->json->{fields};
        foreach my $key (sort keys %{$fields}) {
            $field .= $key . ' ' . $fields->{$key} . $self->get_defaults($fields->{$key}) . ',';
        }
    };
    die "Fields could not be generated '$@'" if $@;

    $self->set_sql($field);

    return ;
}

sub get_defaults($self, $datatype) {
    my $result = "";
    if (index($datatype,'(') > -1) {
        $datatype = substr($datatype,0,index($datatype,'('))
    }
    match(lc($datatype) : eq) {
        case ('bigint') { $result = " not null default 0 \n"}
        case ('smallint') { $result = " not null default 0 \n"}
        case ('integer') { $result = " not null default 0 \n"}
        case ('decimal') { $result = " not null default 0.0 \n"}
        case ('numeric') { $result = " not null default 0.0 \n"}
        case ('varchar') { $result = " not null default '' \n"}
        case ('char') { $result = " not null default '' \n"}
        case ('text') { $result = " not null default '' \n"}
        default { $result = '' }
    }
    return $result;
}

1;
#################### pod generated by Pod::Autopod - keep this line to make pod updates possible ####################

=head1 NAME

Daje::Plugin::SQL::Script::Fields


=head1 REQUIRES

L<Syntax::Keyword::Match> 

L<Mojo::Base> 


=head1 METHODS

=head2 create_fields($self)

 create_fields($self)();

=head2 get_defaults($self,

 get_defaults($self,();


=cut

