requires 'LWP::UserAgent', '>= 6.05';
requires 'IPC::System::Simple', '>= 1.21';
requires 'App::Cmd', '>= 0.323';
requires 'IO::Uncompress::Gunzip';
requires 'File::Copy';
requires 'Capture::Tiny';

on 'test' => sub {
   requires 'Test::More', '>= 0.96';
};

on 'develop' => sub {
   requires 'Test::Pod', '>= 1.22';
   requires 'Test::Pod::Coverage', '>= 1.08';
   requires 'Pod::Coverage', '>= 0.18';
};
