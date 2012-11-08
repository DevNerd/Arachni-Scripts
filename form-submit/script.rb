framework = Arachni::Framework.new

# we'll work in blocking mode to make this simpler
# and not follow redirections because the cookies will be set pre-redirection
# (if there actually is a redirection, there may not be...)
opts = { async: false, follow_location: false }

# request the URL with the login form
res = framework.http.get( 'http://testfire.net/bank/login.aspx', opts ).response

login_form_data = { 'uid' => 'jsmith', 'passw' => 'Demo1234' }

# extract forms from the HTTP response and select the login one
login_form = framework.forms_from_response( res ).select do |form|
    (form.auditable.keys & login_form_data.keys).size == 2
end.first

# we can't use merge! because the auditable hash is frozen for internal management reasons
login_form.auditable = login_form.auditable.merge( login_form_data )

# submit the filled in form and instruct the HTTP class to update the framework
# cookies based on the response
login_form.submit( opts.merge( update_cookies: true ) )

# let's check the updated cookies, for curiosity's sake
p framework.http.cookies