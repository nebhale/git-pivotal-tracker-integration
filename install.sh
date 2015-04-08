#!/bin/bash
rm -rf *.gem
gem build v2gpti.gemspec
gem install --local *.gem