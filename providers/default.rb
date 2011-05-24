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

require 'chef/data_bag'
include WebsterClay::Dominodes

action :release do
  setup_data_bag_item(new_resource.data_bag, new_resource.lock_name)
  release_lock(new_resource.data_bag, new_resource.lock_name)
  new_resource.updated_by_last_action(true)
end

action :execute do
  setup_data_bag_item(new_resource.data_bag, new_resource.lock_name)

  # we want to handle retries ourselves here
  old_http_retry_count = Chef::Config[:http_retry_count]
  Chef::Config[:http_retry_count] = 0

  begin
    acquire_lock(new_resource.data_bag, new_resource.lock_name, new_resource.timeout, run_context)
    recipe_eval(&new_resource.recipe)
  rescue Timeout::Error
    Chef::Application.fatal! "Timed out after #{new_resource.timeout} seconds waiting for lock #{new_resource.lock_name}"
  else
    release_lock(new_resource.data_bag, new_resource.lock_name)
  ensure
    # clean up our change to the http_retry_count
    Chef::Config[:http_retry_count] = old_http_retry_count
  end
end