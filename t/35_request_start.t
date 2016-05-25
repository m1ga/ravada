use warnings;
use strict;

use Test::More;
use Test::SQL::Data;

use_ok('Ravada');
use_ok('Ravada::Request');

my $test = Test::SQL::Data->new(config => 't/etc/ravada.conf');

my $ravada = Ravada->new(connector => $test->connector);

my ($DOMAIN_NAME) = $0 =~ m{.*/(.*)\.};

sub test_request_start {
}

sub test_remove_domain {
    my $name = shift;

    my $domain = $name if ref($name);
    $domain = $ravada->search_domain($name);

    if ($domain) {
        diag("Removing domain $name");
        eval { $domain->remove() };
        ok(!$@ , "Error removing domain $name : $@") or exit;

        ok(! -e $domain->file_base_img ,"Image file was not removed "
                    . $domain->file_base_img )
                if  $domain->file_base_img;

    }
    $domain = $ravada->search_domain($name);
    ok(!$domain, "I can't remove old domain $name") or exit;

}

sub test_new_domain {
    my $name = shift;

    test_remove_domain($name);

    diag("Creating domain $name");
    my $domain = $ravada->create_domain(name => $name, id_iso => 1, active => 0);

    ok($domain,"Domain not created");

    return $domain;
}


sub test_start {
    my ($name) = $0 =~ m{.*/(.*)\.};
    test_remove_domain($name);

    test_new_domain($name);

    my $domain = $ravada->search_domain($name);
    ok(!$domain->is_active,"Domain $name should be inactive") or return;


    my $req = Ravada::Request->start_domain(
        "does not exists"
    );
    $ravada->process_requests();

    ok($req->status eq 'done', "Expecting status done, got ".$req->status);
    ok($req->error && $req->error =~ /unknown/i
            ,"Expecting unknown domain error , got "
                .($req->error or '<NULL>'));
    $req = undef;

    #####################################################################3
    #
    # start

    my $req2 = Ravada::Request->start_domain($name);
    $ravada->process_requests();

    ok($req2->status eq 'done');

    ok($domain->is_active);

    my $domain2 = $ravada->search_domain($name);
    ok($domain2->is_active);

    $req2 = undef;

    #####################################################################3
    #
    # stop

    my $req3 = Ravada::Request->shutdown_domain($name);
    $ravada->process_requests();
    ok($req3->status eq 'done');

    ok(!$domain->is_active);

    my $domain3 = $ravada->search_domain($name);
    ok(!$domain3->is_active);

}

###############################################################
#
test_start();

done_testing();

