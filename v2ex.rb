#!/usr/bin/env ruby
require "mechanize"
require "mail"

ACCOUNTS= [
  ["your-v2-account", "your-password-for-v2-account"],
]
MAIL = "your-qq-mail@qq.com"
MAIL_PWD = "password-of-your-qq-mail@qq.com"
TO_MAIL = "your-mail-for-receive-notification@gmail.com"

Mail.defaults do
  delivery_method :smtp, {
    :address => "smtp.qq.com",
    :port => "587",
    :user_name => "#{MAIL}",
    :password => "#{MAIL_PWD}",
    :authentication => :plain,
    :openssl_verify_mode => 'none',
    :enable_starttls_auto => true
  }
end

agent = Mechanize.new
agent.user_agent_alias = "Mac Safari"

for account in ACCOUNTS

  user_name = account.first
  user_pwd = acount.last

  begin
    mail_text = ""
    success = true
    page = agent.get("http://www.v2ex.com/signin")
    login_form = page.form_with(:action => "/signin")
    login_form.field_with(:type => "text").value = user_name
    login_form.field_with(:type => "password").value = user_pwd
    login_rsp = agent.submit(login_form)

    if login_rsp.uri.path == "/"
      puts "登陆成功"
      mission_page = agent.get("/mission/daily")
      input_element = mission_page.search("input").select do |node|
        !node.attributes["class"].nil? && node.attributes["class"].value == "super normal button"
      end
      href = input_element.first.attributes["onclick"].value.split("'")[1]
      if href == "/balance"
        puts "今日已经领取"
      else
        finish_page = agent.get(href)
        message = finish_page.at("//div[@class='message']/text()").to_s
        success = message.include?("已成功领取每日登录奖励") ? true : false
        if success
          puts "领取成功"
        else
          mail_text = "领取失败"
          puts mail_text
        end
      end
    else
      success = false
      mail_text = "V2EX登录失败"
      puts mail_text
    end
  rescue => e
    success = false
    mail_text = "未知错误: #{e}"
    puts mail_text
  end

  unless success
    mail = Mail.new do
      from "#{MAIL}"
      to  "#{TO_MAIL}"
      subject "天啦噜！V2EX没能自动签到"
      body  (mail_text << "\n用户: #{user_name}")
    end
    mail.charset = "utf-8"
    mail.deliver
  end
end
