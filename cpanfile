requires 'Moo', '>= 1.003';
requires 'namespace::autoclean', '>= 0.13';
requires 'Try::Tiny', '>= 0.12';
requires 'IPC::System::Simple', '>= 1.21';
requires 'Path::Class', '>= 0.32';
requires 'LWP::UserAgent, '>= 6.05';

on 'test' => sub {
   requires 'Test::More', '>= 0.96';
};

on 'develop' => sub {
   requires 'Test::Pod', '>= 1.22';
   requires 'Test::Pod::Coverage', '>= 1.08';
   requires 'Pod::Coverage', '>= 0.18';
};
