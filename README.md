Dominodes
=========

A Chef resource for mutual exclusion of blocks of recipe code. Useful for
cross-cluster rolling restarts.

Installation
------------

The easiest way to install this is to use [knife-github-cookbooks](https://github.com/websterclay/knife-github-cookbooks):

    gem install knife-github-cookbooks
    knife cookbook github install websterclay/chef-dominodes

Usage
-----

This cookbook implements a LWRP that exposes a new `dominodes` resource with
two actions: `execute` and `release`.

The `dominodes` resources expects a name and a `recipe` attribute, which is
expected to be a block of recipe code. **The provided recipe block will never
be applied on more than one node in your cluster simultaneously**.

### Example

    dominodes 'rolling_apache_restarts'
      recipe do
        execute 'service apache2 restart'
      end
      action :nothing
    end

    template "/etc/www/configures-apache.conf" do
      notifies :execute, "dominodes[rolling_apache_restarts]"
    end

You can also notify the `release` action to release the lock used for mutual
exclusion if you need to for some reason:

    notifies :release, "dominodes[rolling_apache_restarts]"

How it works
------------

### Abusing Data Bags for Fun and Profit

To facilitate the mutual execution of the embedded recipe, a data bag item is
created and used as a lock. The execution of the resource loops while
attempting to obtain the lock when it is in a free state. By default, the
recipe will give up on obtaining the lock after 1 hour. You can adjust this
behavior by setting the `timeout` directive to the desired number of seconds.

### Scope

The `recipe` block inside a `dominodes` resources is essentially an in-line
Chef run. This means that the resources within this block cannot interact with
resources outside, e.g., manipulating notifies.

### Another Example

Here's my test recipe:

    dominodes 'test_with_uptime' do
      recipe do
        execute 'hostname'
        execute 'date'
        execute 'sleep 10'
        execute 'hostname'
        execute 'date'
      end
    end

And here's how it looks while executing

    ec2-174-129-167-180.compute-1.amazonaws.com [Tue, 24 May 2011 14:34:59 +0000] INFO: execute[hostname] sh(hostname)
    ec2-174-129-167-180.compute-1.amazonaws.com ip-10-117-33-108
    ec2-174-129-167-180.compute-1.amazonaws.com [Tue, 24 May 2011 14:34:59 +0000] INFO: execute[hostname] ran successfully
    ec2-174-129-167-180.compute-1.amazonaws.com [Tue, 24 May 2011 14:34:59 +0000] INFO: execute[date] sh(date)
    ec2-174-129-167-180.compute-1.amazonaws.com Tue May 24 14:34:59 UTC 2011
    ec2-174-129-167-180.compute-1.amazonaws.com [Tue, 24 May 2011 14:34:59 +0000] INFO: execute[date] ran successfully
    ec2-174-129-167-180.compute-1.amazonaws.com [Tue, 24 May 2011 14:34:59 +0000] INFO: execute[sleep 10] sh(sleep 10)
    ec2-174-129-167-180.compute-1.amazonaws.com [Tue, 24 May 2011 14:35:09 +0000] INFO: execute[sleep 10] ran successfully
    ec2-174-129-167-180.compute-1.amazonaws.com [Tue, 24 May 2011 14:35:09 +0000] INFO: execute[hostname] sh(hostname)
    ec2-174-129-167-180.compute-1.amazonaws.com ip-10-117-33-108
    ec2-174-129-167-180.compute-1.amazonaws.com [Tue, 24 May 2011 14:35:09 +0000] INFO: execute[hostname] ran successfully
    ec2-174-129-167-180.compute-1.amazonaws.com [Tue, 24 May 2011 14:35:09 +0000] INFO: execute[date] sh(date)
    ec2-174-129-167-180.compute-1.amazonaws.com Tue May 24 14:35:09 UTC 2011
    ec2-174-129-167-180.compute-1.amazonaws.com [Tue, 24 May 2011 14:35:09 +0000] INFO: execute[date] ran successfully
    ec2-174-129-167-180.compute-1.amazonaws.com [Tue, 24 May 2011 14:35:10 +0000] INFO: Chef Run complete in 15.108392 seconds
    ec2-174-129-167-180.compute-1.amazonaws.com [Tue, 24 May 2011 14:35:10 +0000] INFO: Running report handlers
    ec2-174-129-167-180.compute-1.amazonaws.com [Tue, 24 May 2011 14:35:10 +0000] INFO: Report handlers complete
    ec2-50-19-47-63.compute-1.amazonaws.com     [Tue, 24 May 2011 14:35:11 +0000] INFO: execute[hostname] sh(hostname)
    ec2-50-19-47-63.compute-1.amazonaws.com     domU-12-31-39-02-6E-F2
    ec2-50-19-47-63.compute-1.amazonaws.com     [Tue, 24 May 2011 14:35:11 +0000] INFO: execute[hostname] ran successfully
    ec2-50-19-47-63.compute-1.amazonaws.com     [Tue, 24 May 2011 14:35:11 +0000] INFO: execute[date] sh(date)
    ec2-50-19-47-63.compute-1.amazonaws.com     Tue May 24 14:35:11 UTC 2011
    ec2-50-19-47-63.compute-1.amazonaws.com     [Tue, 24 May 2011 14:35:11 +0000] INFO: execute[date] ran successfully
    ec2-50-19-47-63.compute-1.amazonaws.com     [Tue, 24 May 2011 14:35:11 +0000] INFO: execute[sleep 10] sh(sleep 10)
    ec2-50-19-47-63.compute-1.amazonaws.com     [Tue, 24 May 2011 14:35:21 +0000] INFO: execute[sleep 10] ran successfully
    ec2-50-19-47-63.compute-1.amazonaws.com     [Tue, 24 May 2011 14:35:21 +0000] INFO: execute[hostname] sh(hostname)
    ec2-50-19-47-63.compute-1.amazonaws.com     domU-12-31-39-02-6E-F2
    ec2-50-19-47-63.compute-1.amazonaws.com     [Tue, 24 May 2011 14:35:21 +0000] INFO: execute[hostname] ran successfully
    ec2-50-19-47-63.compute-1.amazonaws.com     [Tue, 24 May 2011 14:35:21 +0000] INFO: execute[date] sh(date)
    ec2-50-19-47-63.compute-1.amazonaws.com     Tue May 24 14:35:21 UTC 2011
    ec2-50-19-47-63.compute-1.amazonaws.com     [Tue, 24 May 2011 14:35:21 +0000] INFO: execute[date] ran successfully
    ec2-50-19-47-63.compute-1.amazonaws.com     [Tue, 24 May 2011 14:35:23 +0000] INFO: Chef Run complete in 28.427305 seconds
    ec2-50-19-47-63.compute-1.amazonaws.com     [Tue, 24 May 2011 14:35:23 +0000] INFO: Running report handlers
    ec2-50-19-47-63.compute-1.amazonaws.com     [Tue, 24 May 2011 14:35:23 +0000] INFO: Report handlers complete

Caveats
-------

### Manually cleaning up stale locks

Locks should be cleaned up even if exceptions are raised in the critical
section. However, if you somehow work yourself into a situation that requires
clearing a lock manually, you can do so with knife:

    knife data bag edit dominodes test_with_uptime

Author
------

Jesse Newland  
jesse@websterclay.com  
@jnewland  
jnewland on freenode  

License
-------

    Author:: Jesse Newland (<jesse@websterclay.com>)
    Copyright:: Copyright (c) 2011 Webster Clay, LLC
    License:: Apache License, Version 2.0

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.