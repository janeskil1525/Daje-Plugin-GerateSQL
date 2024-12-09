package Daje::Plugin::Input::ConfigManager;
use Mojo::Base -signatures;


our $VERSION = "0.01";

use Daje::Generate::Database::SqlLite;
use Daje::Generate::Database::Operations;
use Daje::Tools::Filechanged;

use Mojo::File;
use Mojo::JSON qw{from_json};

has 'source_path';
has 'files';
has 'filetype' ;
has 'changed_files' ;
has 'change';

sub save_new_hash($file) {
    my $path = Mojo::File->new($file);
    my $new_hash = $change->load_new_hash($path);
    my $dbh = Daje::Generate::Database::SqlLite->new(path => $path)->get_dbh();
    my $operations = Daje::Generate::Database::Operations->new(dbh => $dbh);
    $operations->save_hash($path->dirname . '/' . $path->basename, $new_hash);

    return 1;
}

sub load_json($file) {
    my $context;
    try {
        $context =  Mojo::File->new($file)->slurp;
    } catch ($e) {
        die "load_json failed '$e";
    };

    return from_json($context);
}

sub load_changed_files () {
    my ($dbh, $operations, $path) = $self->_load_objects();
    try {
        $files = $path->list();
    } catch ($e) {
        die "Files could not be loaded: $e";
    };

    my $length = scalar @{$files};
    for (my $i = 0; $i < $length; $i++) {
        my $old_hash = $operations->load_hash(@{$files}[$i]->dirname . '/' . @{$files}[$i]->basename);
        if ($change->is_file_changed( @{$files}[$i], $old_hash)) {
            push @{$changed_files}, @{$files}[$i]->dirname . '/' . @{$files}[$i]->basename;
        }
    }
    return;
}

sub _load_objects() {
    my $path = Mojo::File->new($source_path);
    $change = Daje::Tools::Filechanged->new();
    my $dbh = Daje::Generate::Database::SqlLite->new(path => $path)->get_dbh();
    my $operations = Daje::Generate::Database::Operations->new(dbh => $dbh);

    return ($dbh, $operations, $path);
}

1;