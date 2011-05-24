#
# Author:: Jesse Newland (<jesse@websterclay.com>)
# Copyright:: Copyright (c) 2011 Webster Clay, LLC.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

actions :execute, :clear

attribute :lock_name,             :kind_of => String,  :name_attribute => true
attribute :data_bag,              :kind_of => String,  :default => 'dominodes'
attribute :timeout,               :kind_of => Integer, :default => 3600

# no LWRP way to do this
def initialize(*args)
  super
  @action = :execute
end

# no LWRP way to do this either
def recipe(arg=nil, &block)
  arg ||= block
  set_or_return(
    :recipe,
    arg,
    :kind_of => [ Proc ]
  )
end