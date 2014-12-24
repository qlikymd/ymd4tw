require 'net/http'
require 'uri'
require 'json'
require 'open-uri'
require 'openssl'
require 'rubygems'
require 'pp'
require 'nokogiri'
require 'mechanize'
require 'net/http'
require 'net/http/digest_auth'
require 'zlib'

require "mechanize"
require "kconv"

class YmdCrawler

  #
  # 対象HTMLノードツリーの中から、リンク先(href)を抽出する
  #
  def self.get_href(html, base_uri)

    # base_uri が渡されてこなかったら、単なる path のリストにする
    base_uri = "" if !base_uri

    doc = Nokogiri::HTML.parse(html, nil, nil)

    path_list = Array.new

    doc.xpath('//a').each do |node|

      # 親ディレクトリやら再帰的なやつやらは弾く
      if node.attribute('href').value[0,1] != "/"
        path_list.push(base_uri + node.attribute('href').value)
      end
    end
    return path_list
  end

  #
  # digest 認証を行い、レスポンスの html を返却する
  #
  def self.digest_request(params)

    html = nil

      digest_auth = Net::HTTP::DigestAuth.new
      uri = URI.parse params[:uri]
      uri.user = params[:certs][0]
      uri.password = params[:certs][1]
      h = Net::HTTP.new uri.host, 443
      h.use_ssl = true
#      h.set_debug_output $stderr

      req = Net::HTTP::Get.new uri.request_uri
      res = h.request req

      #res is a 401 response with a WWW-Authenticate header
      www_auth_response = res['www-authenticate']
      #www_auth_response["algorithm=\"MD5\""] = "algorithm=MD5"
      auth = digest_auth.auth_header uri, www_auth_response, 'GET'
      
      # create a new request with the Authorization header
      req = Net::HTTP::Get.new uri.request_uri
      req.add_field 'Authorization', auth
      # re-issue request with Authorization
      res = h.request req
      ret = res.body

      case res
      when Net::HTTPRedirection
        # くされあまぞんたいおう
        ret = open(res['Location'], 'rb'){|sio| Zlib::GzipReader.wrap(sio).read }

      end

      return ret

  end

  #
  # HTML を取得する
  #
  def self.get_html(params)

    html = nil
    if params[:auth] == "digest"
      # Digest 認証の場合
      html = self.digest_request(params)
    else
      # それ以外の場合、Basic 認証とみなす
      charset = nil
      begin
        html = open(params[:uri], {:http_basic_authentication => params[:certs]}) do |f|
          charset = f.charset # 文字種別を取得
          f.read # htmlを読み込んで変数htmlに渡す
        end
      rescue
        pp "error caught : #{params[:uri]}"
      end
    end
    return html
  end

  #
  # ファイルかディレクトリかを判断する
  # 今のところ、渡された文字列の末尾がファイルっぽいか否かで判断
  #
  def self.is_file?(str)

    # なんかダサい
    return true if str.end_with?('.csv') 
    return true if str.end_with?('.tsv')
    return true if str.end_with?('.gz')
    return true if str.end_with?('.zip')
    return true if str.end_with?('.tar')

    return false
  end

  #
  # apache とかが出すディレクトリ一覧をクロールする
  #
  def self.crawl_httpd_directory(doc, base_uri, certs)

    file_list = Array.new
    #pp "craaaaaaaaaawl"
    doc.xpath('//a').each do |node|
      # 上位階層をクロールしないようにする
      if node.inner_text == ' Parent Directory'

        # ほんとうは処理対象 uri より上位階層に行ってないかを見たほうがいい

      else
        # いろいろだるそうなので、相対パスだけ見る(ディレクトリ構造は再帰させない)
        child_uri = base_uri + node.attribute('href').value

        if self.is_file?(child_uri) 
          # csvとかtsvでおわってたら、ファイルとみなしてリストに追加する
          file_list.push child_uri
        else
          # ファイルじゃなさそうな場合、さらに下を掘る
          child_html = YmdCrawler.get_html({:certs => certs, :uri => child_uri})
          child_doc = Nokogiri::HTML.parse(child_html, nil, nil)

          # メソッドを再帰的に呼び出し、配列に加えまくる
          file_list += self.crawl(child_doc, child_uri, certs)
        end
      end
    end
    return file_list
  end

  #
  # 一般的な web のフォームを submit してセッションcookieを得る
  #
  def auth_web_form(params)
    # なんかがんばる
    params[:uri]
    params[:form_xpath]
    params[:id_xpath]
    params[:pw_xpath]
    params[:other_form_param]
    
    # au
  end

  def self.get_imobile
    uri = "https://spadvertiser.i-mobile.co.jp/login.aspx"
    id = "ctl00$ContentPlaceHolder2$Login1$UserName"
    pw = "ctl00$ContentPlaceHolder2$Login1$Password"

    agent = Mechanize.new
    agent.verify_mode = OpenSSL::SSL::VERIFY_NONE

    agent.user_agent_alias = "Windows IE 9"
    agent.get(uri)

    login_form = agent.page.forms[0]

    #loginフォーム処理
    agent.page.form_with(:name => 'aspnetForm'){|form|
      form.field_with(:name => id).value = "info@colopl.co.jp"
      form.field_with(:name => pw).value = "colopl"
      form.click_button
      }


    agent.get("https://spadvertiser.i-mobile.co.jp/site.aspx?csv=1")

  end

  def self.get_nend
    uri = "https://www.nend.net/admin/login"
    id = "data[User][mail]"
    pw = "data[User][pass]"

    agent = Mechanize.new
    agent.verify_mode = OpenSSL::SSL::VERIFY_NONE

    agent.user_agent_alias = "Windows IE 9"
    agent.get(uri)

    login_form = agent.page.forms[0]

    #loginフォーム処理
    agent.page.form_with(:name => 'loginform'){|form|
      form.field_with(:name => id).value = "toshinobu-kawaguchi@garage.co.jp"
      form.field_with(:name => pw).value = "0405ab"
      form.click_button
      }


    agent.get("https://www.nend.net/a/advertiser/csv?search_date=2014/12/01%20-%202014/12/19&sort=DESC&skey=6b1d28be6dcb60b55be2c52bd6cb729013a2b61c")

  end




end

