require "mechanize"
require "mail"

# config your info
ACCOUNT = "V2EX_ACCOUTN"
PASSWORD = "YOUR_PASSWORD"
Mail.defaults do
  delivery_method :smtp, {
    :address => "smtp.qq.com",
    :port => "587",
    :user_name => "send_from@qq.com",
    :password => "send_from_mail_password",
    :authentication => :plain,
    :openssl_verify_mode => 'none',
    :enable_starttls_auto => true
  }
end

mail_text = ""
success = true

agent = Mechanize.new
agent.user_agent_alias = "Mac Safari"

page = agent.get("http://www.v2ex.com/signin")
login_form = page.form_with(:action => "/signin")
login_form.u = ACCOUNT
login_form.p = PASSWORD
login_rsp = agent.submit(login_form)

if login_rsp.uri.path == "/"
  puts "登陆成功"
  mission_page = agent.get("/mission/daily")
  input_tag = mission_page.at('//input[@class="super normal button"]/@onclick')
  href = input_tag.to_s.split("'")[1]
  if href == "/balance"
    puts "今日已经领取"
  else
    finish_page = href.click
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

unless success
  mail = Mail.new do
    from "send_from@qq.com"
    to  "send_to@foxmail.com"
    subject "用户: #{ACCOUNT}V2EX签到失败"
    body  mail_text
  end
  mail.charset = "utf-8"
  mail.deliver
end
