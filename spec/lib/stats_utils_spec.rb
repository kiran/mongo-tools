require 'spec_helper'
require "stats_utils"

describe "scrub!" do
  it "should scrub out . and $ in first-level keys" do 
    test_bson = BSON::OrderedHash.new
    test_bson[ "a.a.a." ] = "aaa"
    test_bson[ "b$" ] = 9
    test_bson[ "c" ] = 1.033

    assert_bson = BSON::OrderedHash.new
    assert_bson[ "a,a,a," ] = "aaa"
    assert_bson[ "b#" ] = 9
    assert_bson[ "c" ] = 1.033

    scrub!(test_bson)

    test_bson.should eql(assert_bson)
  end

  it "should scrub out . and $ in any level key" do 
    test_bson = BSON::OrderedHash.new
    test_bson[ "a.a.a." ] = "aaa"
    test_bson[ "b$" ] = 9
    test_bson[ "c" ] = 1.033

    inner_bson = BSON::OrderedHash.new
    inner_bson[ "a.a.a.." ] = "aaa"
    inner_bson[ "$$b$" ] = 9

    test_bson['inner.level'] = inner_bson

    assert_bson = BSON::OrderedHash.new
    assert_bson[ "a,a,a," ] = "aaa"
    assert_bson[ "b#" ] = 9
    assert_bson[ "c" ] = 1.033

    inner_bson2 = BSON::OrderedHash.new
    inner_bson2[ "a,a,a,," ] = "aaa"
    inner_bson2[ "##b#" ] = 9

    assert_bson['inner,level'] = inner_bson2

    scrub!(test_bson)

    test_bson.should eql(assert_bson)
  end
end