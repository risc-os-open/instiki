#!/usr/bin/env ruby

require 'test_helper'

class RoutesTest < ActionController::TestCase

  def test_parse_uri
    assert_routing('', :controller => 'wiki', :action => 'index')
    assert_routing('x', :controller => 'wiki', :action => 'index', :web => 'x')
    assert_routing('x/y', :controller => 'wiki', :web => 'x', :action => 'y')
    assert_routing('x/y/z', :controller => 'wiki', :web => 'x', :action => 'y', :id => 'z')
    assert_recognizes({:web => 'x', :controller => 'wiki', :action => 'y'}, 'x/y/')
    assert_recognizes({:web => 'x', :controller => 'wiki', :action => 'y', :id => 'z'}, 'x/y/z')

    # 2017-02-06 (ADH): Impossible under Rails 3; it simply will never include
    # a trailing "/" in the ID, using globbing, regular expressions or any
    # other routing mechanism. Commenting out this test; there remains the
    # chance that an unescaped trailing slash on a title/ID would break the
    # system (the test below this one checks for the escaped slash case).
    #
    # assert_recognizes({:web => 'x', :controller => 'wiki', :action => 'y', :id => 'z/'}, 'x/y/z/')

    assert_recognizes({:web => 'x', :controller => 'wiki', :action => 'y', :id => 'z/'}, 'x/y/z%2F')
    assert_recognizes({:web => 'x', :controller => 'wiki', :action => 'y', :id => 'z.w'}, 'x/y/z.w')
  end

  def test_parse_uri_interestng_cases
    assert_routing('_veeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeery-long_web_/an_action/HomePage',
      :web => '_veeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeery-long_web_',
      :controller => 'wiki',
      :action => 'an_action', :id => 'HomePage'
    )
#    assert_recognizes({:controller => 'wiki', :action => 'index'}, '///')
  end

  def test_parse_uri_liberal_with_pagenames

    # 2017-02-06 (ADH): Thjis used to say "%24HOME_PAGE" <-> "$HOME_PAGE", but
    # since "$" is entirely valid in a URI path without escaping there is no
    # reason for the router to *generate* a path from that ID with percentage
    # escaping in it; indeed, it does not. Changed to a literal " " character
    # which *does* require escaping to "%20" when the router generates a URL
    # from a parameters Hash.
    #
    assert_routing('web/show/%20HOME_PAGE',
        :controller => 'wiki', :web => 'web', :action => 'show', :id => ' HOME_PAGE')

#    assert_routing('web/show/HomePage%3F',
#        :controller => 'wiki', :web => 'web', :action => 'show',
#        :id => 'HomePage')

#    assert_routing('web/show/HomePage%3Farg1%3Dvalue1%26arg2%3Dvalue2',
#        :controller => 'wiki', :web => 'web', :action => 'show',
#        :id => 'HomePage?arg1=value1&arg2=value2')

    assert_routing('web/files/abc.zip',
        :web => 'web', :controller => 'file', :action => 'file', :id => 'abc.zip')
    assert_routing('web/import', :web => 'web', :controller => 'file', :action => 'import')
    # default option is wiki
    assert_recognizes({:controller => 'wiki', :web => 'unknown_path', :action => 'index', },
      'unknown_path')
  end

  def test_cases_broken_by_routes

    # 2017-02-06 (ADH): This used to say "Page+With+Spaces" and worked under
    # Rails 2, but it seems to me that was a bug and it fails (correctly) in
    # that form on Rails 3. The conversion of "+" to " " should occur only
    # in "application/x-www-form-urlencoded" encoded content, which means the
    # query string - *not* the path component of a URI. Percentage encoding
    # applies there, so this test is updated accordingly.
    #
    assert_routing('web/show/Page%20With%20Spaces',
       :controller => 'wiki', :web => 'web', :action => 'show', :id => 'Page With Spaces')
#    assert_routing('web/show/HomePage%2Fsomething_else',
#        :controller => 'wiki', :web => 'web', :action => 'show', :id => 'HomePage/something_else')
  end

end
