class NendWebController < ApplicationController

require "pp"
require 'kconv'

  def index

    auth_uri = "https://spadvertiser.i-mobile.co.jp/login.aspx"
    form_xpath = "aspnetForm"
#    id_xpath = "//*[@id="ctl00_ContentPlaceHolder2_Login1_UserName"]"
#    pw_xpath = "//*[@id="ctl00_ContentPlaceHolder2_Login1_Password"]"

    csv = YmdCrawler.get_nend
    @val = csv.body.toutf8
    pp @val
  end

end
