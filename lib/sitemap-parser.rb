require 'nokogiri'
require 'typhoeus'

class SitemapParser

  def initialize(url, opts = {})
    @url = url
    @options = {:followlocation => true, :recurse => false, url_limited_count: 500}.merge(opts)
    @from_date = Date.parse(@options[:from_date]) rescue nil
  end

  def raw_sitemap
    @raw_sitemap ||= begin
      if @url =~ /\Ahttp/i
        request(@url)
      elsif File.exist?(@url) && @url =~ /[\\\/]sitemap\.xml\Z/i
        open(@url) { |f| f.read }
      end
    end
  end

  # Check for redirection and re-request
  def request(url)
    request = Typhoeus::Request.new(url, followlocation: @options[:followlocation])
    request.options['headers']={}
    request.on_complete do |response|
      if response.success?
        return response.body
      elsif response.redirect_count > 0 && response.effective_url
        return request(response.effective_url)
      else
        raise "HTTP request to #{url} failed"
      end
    end
    request.run
  end

  def sitemap
    @sitemap ||= Nokogiri::XML(raw_sitemap)
  end

  def urls
    if sitemap.at('urlset')
      sitemap.at("urlset").search("url")
    elsif sitemap.at('sitemapindex')
      found_urls = []
      if @options[:recurse]
        if @options[:from_date]
          sitemap.at('sitemapindex').search('sitemap').each do |sitemap|
            child_sitemap_location = sitemap.at('loc').content
            if ll= child_sitemap_location.match('yyyy=(\d{4})&mm=(\d{1,2})&dd=(\d{1,2})')
              is_latest_published_date = begin
                Date.parse("#{$3}-#{$2}-#{$1}") > @from_date
              rescue nil
              end
              if is_latest_published_date
                found_urls << self.class.new(child_sitemap_location, :recurse => false, from_date: @from_date.to_s).urls
              end
            elsif sitemap.at('lastmod').try(:content)
              is_latest_published_date = begin
                Date.parse(sitemap.at('lastmod').content) > @from_date
              rescue nil
              end
              if is_latest_published_date
                found_urls << self.class.new(child_sitemap_location, :recurse => false, from_date: @from_date.to_s).urls
              end
            else
              found_urls << self.class.new(child_sitemap_location, :recurse => false, from_date: @from_date.to_s).urls
            end
            break if @options[:url_limited_count] < found_urls.count
          end
        else
          sitemap.at('sitemapindex').search('sitemap').each do |sitemap|
            child_sitemap_location = sitemap.at('loc').content
            found_urls << self.class.new(child_sitemap_location, :recurse => false).urls
            break if @options[:url_limited_count] < found_urls.count
          end
        end
      end
      return found_urls.flatten
    else
      []
    end
  end

  def to_a
    list = []
    urls.each do |url|
      if @options[:from_date]
        is_latest_published_date = begin
          Date.parse(url.at('lastmod').content) > @from_date
        rescue Exception => e
          nil
        end
        if is_latest_published_date
          list << url.at("loc").content
        end
      else
        list << url.at("loc").content
      end
      break if @options[:url_limited_count] < list.count
    end
    list
  rescue NoMethodError
    list
  end
end
