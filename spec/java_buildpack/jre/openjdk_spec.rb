# Encoding: utf-8
# Cloud Foundry Java Buildpack
# Copyright 2013 the original author or authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'spec_helper'
require 'component_helper'
require 'java_buildpack/jre/openjdk'
require 'java_buildpack/jre/memory/weight_balancing_memory_heuristic'

describe JavaBuildpack::Jre::OpenJdk do
  include_context 'component_helper'

  before do
    allow(JavaBuildpack::Jre::WeightBalancingMemoryHeuristic).to receive(:new).and_return(memory_heuristic)
  end

  context do
    let(:memory_heuristic) { double('MemoryHeuristic', resolve: %w(opt-1 opt-2)) }

    it 'should detect with id of openjdk-<version>' do
      expect(component.detect).to eq("openjdk=#{version}")
    end

    it 'should extract Java from a GZipped TAR',
       cache_fixture: 'stub-java.tar.gz' do

      component.compile

      expect(app_dir + '.openjdk/bin/java').to exist
    end

    it 'adds the JAVA_HOME to java_home' do
      component

      expect(java_home).to eq('$PWD/.openjdk')
    end

    it 'adds OnOutOfMemoryError to java_opts' do
      component.release

      expect(java_opts).to include('-XX:OnOutOfMemoryError=$PWD/.openjdk/bin/killjava')
    end

    it 'places the killjava script (with appropriately substituted content) in the diagnostics directory',
       cache_fixture: 'stub-java.tar.gz' do

      component.compile

      expect((app_dir + '.openjdk/bin/killjava').read).to include '}/../../.buildpack-diagnostics/buildpack.log'
    end

    it 'adds java.io.tmpdir to java_opts' do
      component.release

      expect(java_opts).to include('-Djava.io.tmpdir=$TMPDIR')
    end

    it 'adds the memory calculation to java_opts' do
      component.release

      expect(java_opts).to include('`$PWD/.openjdk/bin/memcalc $PWD`')
    end
  end

  context do
    let(:memory_heuristic) { double('MemoryHeuristic', resolve: %w(opt-1 opt-2)) }

    it 'should fail compile if the memory heuristics cannot be resolved' do
      expect(memory_heuristic).to receive(:resolve).and_raise('test')
      expect { component.compile }.to raise_error(/test/)
    end
  end

end
