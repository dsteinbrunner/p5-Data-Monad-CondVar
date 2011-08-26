use strict;
use warnings;
use Data::Monad::AECV;
use AnyEvent;
use Test::More;

my $m = Data::Monad::AECV->monad;

my $cv213 = do {
	my $cv = AE::cv;
	my $t; $t = AE::timer 0, 0, sub {
		$cv->send(2, 1, 3);
		undef $t;
	};
	$m->new(cv => $cv);
};

sub create_cv($) {
	my $should_skip = shift;
	my $cv1 = $cv213->bind(sub {
		my @v = @_;

		$m->call_cc(sub {
			my $skip = shift;

			my $cv213 = $m->unit(@v);
			my $cv426 = $cv213->bind(sub { $m->unit(map { $_ * 2 } @_) });
			my $cv_skipped = $cv426->bind(sub {
				$should_skip ? $skip->(@_) : $m->unit(@_)
			});

			return $cv_skipped->bind(sub { $m->unit(map { $_ * 2 } @_) });
		});
	});
	return $cv1->bind(sub { $m->unit(map { $_ * 3 } @_) });
}


is_deeply [(create_cv 1)->recv], [12, 6, 18];
is_deeply [(create_cv 0)->recv], [24, 12, 36];

done_testing;