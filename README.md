# Sitemap Parser

*Ruby Gem to parse sitemaps.org compliant sitemaps*

[![Build Status](https://travis-ci.org/benbalter/sitemap-parser.svg?branch=master)](https://travis-ci.org/benbalter/sitemap-parser) [![Gem Version](https://badge.fury.io/rb/sitemap-parser.svg)](http://badge.fury.io/rb/sitemap-parser)

## Usage

```ruby
sitemap = SitemapParser.new "http://ben.balter.com/sitemap.xml"
sitemap.urls # => Array of Nokigiri XML::Node objects
sitemap.to_a # => Array of url strings
```

## Options

### Recurse nested sitemaps

```
sitemap = SitemapParser.new('http://ben.balter.com/sitemap.xml', {recurse: true})
```

## Roadmap

* `sitemap_index` support

## Modified original with following
* Modified original fork https://github.com/benbalter/sitemap-parser
* Added last modified sitemap url support
* Took care of redirection
* added limited url count support