# ABSTRACT: Trace DBIx::Class queries per request
package CatalystX::DBIC::Trace;
BEGIN {
  $CatalystX::DBIC::Trace::VERSION = '0.01';
}
use Moose::Role;
use namespace::autoclean;

use CatalystX::DBIC::Trace::TracerObject;

use CatalystX::InjectComponent;

use DDP;


after 'setup_finalize' => sub {
    my $self = shift;
    #$self->log->debug('Profiling is active');
    #DB::enable_profile();
};
 
#after 'setup_components' => sub {
#    my $class = shift;
#    CatalystX::InjectComponent->inject(
#        into => $class,
#        component => 'CatalystX::Profile::::NYTProf::Controller::ControlProfiling',
#        as => 'Controller::Profile'
#    );
#};

# Start a profile run when a request begins...
# FIXME: is this the best hook?  Want the Catalyst equivalent of a Dancer
# `before` hook.  `prepare_body` looks like a reasonable "we've read the
# request from the network, we're about to handle it" point.
before 'prepare_body' => sub {
    my $c = shift;
    $c->log->debug("plugins prepare_body fires");
    my $uuid = rand 999999;  # FIXME use an actual timestamp

    my $fh = File::Temp->new(UNLINK => 0);
    $c->log->debug("Log DBIC queries to " . $fh->filename);
    # this didn't seem to have any effect...
    $ENV{DBIC_TRACE} = "1=" . $fh->filename;

    my $tracer = CatalystX::DBIC::Trace::TracerObject->new(
        context => $c,
    );

    # FIXME make the model name configurable?  Or find a more robust way
    # to automatically determine?  Maybe call $c->model(qr{.+}) to match
    # all, and filter to results which isa Catalyst::Model::DBIC::Schema
    # and not ResultSets (as I seem to get both)
    my $model = $c->model('DB');
    $c->log->debug("Apply query logging to model ", $model);
    $c->log->debug("model isa " . ref $model);
    # maybe need $model->result_source->schema->storage ?
    # but why are we getting a Drain::Schema::ResultSet at all?!
    $model->storage->debug(1);
    #$model->storage->debugfh($fh);
    $model->storage->debugobj($tracer);

    #$c->stash->{_dbic_trace_fh} = $fh;
    $c->stash->{_dbic_tracer_obj} = $tracer;

};




# And finalise it when the request is finished
after 'finalize_body' => sub {
    my $c = shift;
    $c->log->debug("plugin finalize_body hook fires");
    delete $ENV{DBIC_TRACE};
    if (my $tracer = $c->stash->{_dbic_tracer_obj}) {
        use JSON;
        $c->log->debug("Queries executed are as follows:",
            JSON::to_json($tracer->queries, { pretty => 1 })
        );
    }

};



 
1;
