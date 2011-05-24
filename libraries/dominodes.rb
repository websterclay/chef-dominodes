require 'chef/data_bag'

module WebsterClay
  module Dominodes

    def release_lock(data_bag, lock_name)
      lock = Chef::DataBagItem.load(data_bag, lock_name)
      lock.raw_data = {'id' => lock_name}
      lock.save
    end

    def setup_data_bag_item(data_bag, lock_name)
      begin
        Chef::DataBag.load(data_bag)
      rescue Net::HTTPServerException
        Chef::Log.debug("Creating data bag: #{data_bag}")
        d = Chef::DataBag.new
        d.name(data_bag)
        d.save
        begin
          Chef::DataBagItem.load(data_bag, lock_name)
        rescue Net::HTTPServerException
          Chef::Log.debug("Creating data bag item: #{lock_name}")
          i = Chef::DataBagItem.new
          i.data_bag(data_bag)
          i.raw_data = {'id' => lock_name}
          i.save
        end
      end
    end

    def acquire_lock(data_bag, lock_name, timeout, context)
      Timeout.timeout(timeout) do
        lock_data = {}

        # loop until we have the lock
        while lock_data['node'] != context.node.name do
          begin
            lock = Chef::DataBagItem.load(data_bag, lock_name)
            lock_data = lock.raw_data
            # if noone has the lock, try to grab it
            if lock_data['node'].nil?
              Chef::Log.debug("No resource using lock #{lock_name}: #{lock_data.inspect}")
              lock.raw_data = {'node' => context.node.name, 'id' => lock_name}
              lock.save
              # now reload the data to confirm no one else has clobbered it
              lock_data = Chef::DataBagItem.load(data_bag, lock_name).raw_data
            else
              Chef::Log.debug("Waiting for lock #{lock_name}: #{lock_data.inspect}")
              sleep rand(5)
            end
          rescue Net::HTTPFatalError
            Chef::Log.debug("Conflict acquiring lock. Reloading")
            sleep rand(5)
          end
        end
        Chef::Log.debug("Lock acquired! #{lock_name}: #{lock_data.inspect}")
      end
    end

  end
end