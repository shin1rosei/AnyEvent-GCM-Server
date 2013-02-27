use inc::Module::Install;
name 'AnyEvent-GCM-Server';
all_from 'lib/AnyEvent/GCM/Server.pm';

# requires '';
requires 'Cache::LRU';
requires 'Log::Minimal';
requires 'Mouse';
requires 'AnyEvent::HTTP';
requires 'AnyEvent::MPRPC';
requires 'Data::Validator';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
auto_set_repository;
auto_include;
WriteAll;
