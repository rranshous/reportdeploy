require 'sinatra'
require 'twilio-ruby'

MESSAGE = """
.
This is a message for %{recipient} concerning a deployment.
Team %{team_name} is about to deploy %{app_name}.
If you find this news concerning please press 1 and stay on the line and you will be connected with the team.
This message will repeat.
"""

TWILIO_NUMBER = "+17708093748"

account_sid = ENV['TWILIO_ACCOUNT_SID']
auth_token = ENV['TWILIO_AUTH_TOKEN']
$client = Twilio::REST::Client.new account_sid, auth_token

get '/' do
  return '''<form method="POST" action="/">
      <label>What\'s the phone # this message should go to? <input type="text" name="target_phone"/></label>
      <label>Who is going to receive this message? "This is a message for <input type="text" name="recipient"/>"</label>
      <label>What is your (recignizable) team name? "This is a message from <input type="text" name="team_name"/>"</label>
      <label>What app are you deploying? "The app is named <input type="text" name="app_name"/>"</label>
      <label>What phone number should the recipient call if they need to follow up? "To reach me call <input type="text" name="callback_num"/>"</label>
      <label>
      <input type="submit"/>
    </form>
  '''.gsub("\n","<br/>")
end

post '/' do
  @call = $client.calls.create(
    from: TWILIO_NUMBER,
    to: params["target_phone"],
    url: callback_url(params)
  )
  "Call initiated
  #{curl_command(request, params)}".gsub("\n","<br/>")
end

helpers do
  def callback_url params
    url = "http://twimlets.com/menu?" + URI.encode_www_form({
      Message: MESSAGE % Hash[params.to_a.map{|k,v|[k.to_sym,v]}],
      "Options[1]": bridge_url(params)
    })
    url
  end
  def bridge_url params
    "http://twimlets.com/forward?" + URI.encode_www_form({
      PhoneNumber: params["callback_num"],
      CallerId: TWILIO_NUMBER,
      Timeout: 60
    })
  end
  def curl_command request, params
    """
    curl -X POST http://#{request.host}/ \\
    #{params.to_a.map{|(k,v)| "--data-urlencode \"#{k}=#{v}\""}.join(" \\\n")}
    """
  end
end
