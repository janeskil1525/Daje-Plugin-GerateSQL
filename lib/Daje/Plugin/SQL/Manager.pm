package Daje::Plugin::SQL::Manager;
use Mojo::Base 'Daje::Plugin::Sql::Base::Common', -signatures;

use Daje::Plugin::SQL::Script::Fields;
use Daje::Plugin::SQL::Script::Index;
use Daje::Plugin::SQL::Script::ForeignKey;
use Daje::Plugin::SQL::Script::Sql;

sub generate_table($self) {
    my $sections = "";
    my $json_arr = $self->json;
    my $length = scalar @{$json_arr};
    for (my $i = 0; $i < $length; $i++) {
        my $json = @{$json_arr}[$i];
        if (exists($json->{version})) {
            $sections .= $self->_version($json->{version});
        }
    }
    $self->set_sql($self->create_file($sections));
    return ;
}

sub _version($self, $version) {
    my $sql = "";
    my $sections = "";
    my $length = scalar @{$version};
    for (my $i = 0; $i < $length; $i++) {
        if(exists(@{$version}[$i]->{tables})) {
            my $tables = @{$version}[$i]->{tables};
            my $len = scalar @{$tables};
            for(my $j = 0; $j < $len; $j++){
                my $table = $self->shift_section($tables);
                $sql .= $self->create_table_sql($table);
            }
            $sections .= $self->create_section($sql, @{$version}[$i]->{number});
        }
    }
    return $sections
}

sub create_file($self, $sections) {
    my $file = $self->template->get_data_section('file');
    my $date = localtime();
    $file =~ s/<<date>>/$date/ig;
    $file =~ s/<<sections>>/$sections/ig;

    return $file;
}

sub create_section($self, $sql, $number) {
    my $section = $self->template->get_data_section('section');
    $section =~ s/<<version>>/$number/ig;
    $section =~ s/<<table>>/$sql/ig;
    return $section;
}

sub create_table_sql($self, $table) {
    my $result = "";
    my $fields = '';
    my $indexes = '';
    my $foreignkeys = "";
    my $sql = "";

    my $name = $table->{table}->{name};
    if (exists($table->{table}->{fields})) {
        $fields = $self->create_fields($table->{table});
        $foreignkeys = $self->create_fkeys($table->{table}, $name);
    }
    my $test = $table->{table}->{index};
    if (exists($table->{table}->{index})) {
        $indexes = $self->create_index($table->{table})
    }

    if (exists($table->{table}->{sql})) {
        $sql = $self->create_sql($table->{table}, $name)
    }

    my $template = $self->fill_template($name, $fields, $foreignkeys, $indexes, $sql);

    return $template;

}

sub create_sql($self, $json, $tablename) {
    my $sql_stmt = Daje::Plugin::SQL::SqlManager::Sql->new(
        json      => $json,
        template  => $self->template,
        tablename => $tablename,
    );
    my $result = $sql_stmt->create_sql();
    return $result;
}

sub fill_template($self, $name, $fields, $foreignkeys, $indexes, $sql) {
    my $template = $self->template->get_data_section('table');
    $template =~ s/<<fields>>/$fields/ig;
    $template =~ s/<<tablename>>/$name/ig;
    if(exists($foreignkeys->{template_fkey})) {
        $template =~ s/<<foregin_keys>>/$foreignkeys->{template_fkey}/ig;
    } else {
        $template =~ s/<<foregin_keys>>//ig;
    }
    if(exists($foreignkeys->{template_ind})) {
        $indexes .= "" . $foreignkeys->{template_ind};
    }

    $template =~ s/<<indexes>>/$indexes/ig;
    $template =~ s/<<sql>>/$sql/ig;

    return $template;
}

sub create_fields($self, $json) {
    my $fields = Daje::Plugin::SQL::Script::Fields->new(
        json     => $json,
        template => $self->template,
    );

    $fields->create_fields();
    my $sql = $fields->sql;

    return $sql;
}

sub create_index($self, $json) {
    my $test = 1;
    my $template = $self->template;
    my $index = Daje::Plugin::SQL:Script::Index->new(
        json      => $json,
        template  => $template,
        tablename => $json->{name},
    );

    $index->create_index();
    my $sql = $index->sql;
    return $sql;
}

sub create_fkeys($self, $json, $table_name) {
    my $foreignkeys = {};
    my $foreign_key = Daje::Plugin::SQL::Script::ForeignKey->new(
        json      => $json,
        template  => $self->template,
        tablename => $table_name,
    );
    $foreign_key->create_foreign_keys();
    if ($foreign_key->created() == 1) {
        $foreignkeys = $foreign_key->templates();
    }
    return $foreignkeys;
}

1;