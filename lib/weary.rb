require 'weary/version'
require 'weary/client'
require 'weary/configuration'

module Weary
  extend Configuration

  USER_AGENTS = {
    "Firefox 1.5.0.12 - Mac" => "Mozilla/5.0 (Macintosh; U; PPC Mac OS X Mach-O; en-US; rv:1.8.0.12) Gecko/20070508 Firefox/1.5.0.12",
    "Firefox 1.5.0.12 - Windows" => "Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.8.0.12) Gecko/20070508 Firefox/1.5.0.12",
    "Firefox 2.0.0.12 - Mac" => "Mozilla/5.0 (Macintosh; U; Intel Mac OS X; en-US; rv:1.8.1.12) Gecko/20080201 Firefox/2.0.0.12",
    "Firefox 2.0.0.12 - Windows" => "Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.8.1.12) Gecko/20080201 Firefox/2.0.0.12",
    "Firefox 3.0.4 - Mac" => "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.5; en-US; rv:1.9.0.4) Gecko/2008102920 Firefox/3.0.4",
    "Firefox 3.0.4 - Windows" => "Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.8.1.12) Gecko/2008102920 Firefox/3.0.4",
    "Firefox 3.5.2 - Mac" => "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.5; en-US; rv:1.9.1.2) Gecko/20090729 Firefox/3.5.2",
    "Firefox 3.5.2 - Windows" => "Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.9.1.2) Gecko/20090729 Firefox/3.5.2",
    "Internet Explorer 5.2.3 - Mac" => "Mozilla/4.0 (compatible; MSIE 5.23; Mac_PowerPC)",
    "Internet Explorer 5.5" => "Mozilla/4.0 (compatible; MSIE 5.5; Windows NT 5.1)",
    "Internet Explorer 6.0" => "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; SV1)",
    "Internet Explorer 7.0" => "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 6.0)",
    "Internet Explorer 8.0" => "Mozilla/4.0 (compatible; MSIE 8.0; Windows NT 6.2; Trident/4.0)",
    "Lynx 2.8.4rel.1 on Linux" => "Lynx/2.8.4rel.1 libwww-FM/2.14",
    "MobileSafari 1.1.3 - iPhone" => "Mozilla/5.0 (iPhone; U; CPU like Mac OS X; en) AppleWebKit/420.1 (KHTML, like Gecko) Version/3.0 Mobile/4A93 Safari/419.3",
    "MobileSafari 1.1.3 - iPod touch" => "Mozilla/5.0 (iPod; U; CPU like Mac OS X; en) AppleWebKit/420.1 (KHTML, like Gecko) Version/3.0 Mobile/4A93 Safari/419.3",
    "Opera 9.25 - Mac" => "Opera/9.25 (Macintosh; Intel Mac OS X; U; en)",
    "Opera 9.25 - Windows" => "Opera/9.25 (Windows NT 5.1; U; en)",
    "Safari 1.2.4 - Mac" => "Mozilla/5.0 (Macintosh; U; PPC Mac OS X; en) AppleWebKit/125.5.7 (KHTML, like Gecko) Safari/125.12",
    "Safari 1.3.2 - Mac" => "Mozilla/5.0 (Macintosh; U; PPC Mac OS X; en) AppleWebKit/312.8 (KHTML, like Gecko) Safari/312.6",
    "Safari 2.0.4 - Mac" => "Mozilla/5.0 (Macintosh; U; Intel Mac OS X; en) AppleWebKit/419 (KHTML, like Gecko) Safari/419.3",
    "Safari 3.0.4 - Mac" => "Mozilla/5.0 (Macintosh; U; Intel Mac OS X; en-us) AppleWebKit/523.10.3 (KHTML, like Gecko) Version/3.0.4 Safari/523.10",
    "Safari 3.1.2 - Mac" => "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_5_2; en-us) AppleWebKit/525.13 (KHTML, like Gecko) Version/3.1 Safari/525.13",
    "Safari 3.1.2 - Windows" => "Mozilla/5.0 (Windows; U; Windows NT 5.1; en-us) AppleWebKit/525.13 (KHTML, like Gecko) Version/3.1 Safari/525.13",
    "Safari 3.2.1 - Mac" => "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_5_5; en-us) AppleWebKit/525.27.1 (KHTML, like Gecko) Version/3.2.1 Safari/525.27.1",
    "Safari 3.2.1 - Windows" => "Mozilla/5.0 (Windows; U; Windows NT 5.1; en-us) AppleWebKit/525.27.1 (KHTML, like Gecko) Version/3.2.1 Safari/525.27.1",
    "Safari 4.0.2 - Mac" => "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_5_7; en-us) AppleWebKit/530.19.2 (KHTML, like Gecko) Version/4.0.2 Safari/530.19",
    "Safari 4.0.2 - Windows" => "Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US) AppleWebKit/530.19.2 (KHTML, like Gecko) Version/4.0.2 Safari/530.19.1"
  }
end
