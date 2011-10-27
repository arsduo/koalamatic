=begin
(This is currently a placeholder taken from an uncommitted Koala file.)

These tests are only executed when running live against test users; they're intended to cover as many aspects of the Facebook API as we can.  

Instead of making sure Koala works, these are to ensure that _Facebook itself_ is working.  

The main test suite makes sure Koala can talk to Facebook properly, but not to be comprehensive. An example may help:
* The main test suite ensures that you can post to a generic object's wall.
* These tests ensure that you can post to walls for every type of object (Pages, Groups, Events, etc.)

By building out a comprehensive set of API calls and running these tests frequently, we can quickly detect errors in the Facebook API.

Please add or update tests to help us get close to complete coverage!
=end

require 'spec_helper'

if KoalaTest.test_user?
  # because of how much these tests do, they only run against test users, not real users
  # and not against the mocks, since that would defeat the purpose
  describe "Facebook API coverage tests" do
  end
end