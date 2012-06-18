require File.dirname(__FILE__) + '/spec_helper'

describe "token matcher behaviour" do
  it "should confirm authentication for valid token" do
    email = "random@random.test"

    token = add_user(email)

    app.any_instance.should_receive(:confirm_authentication!).with(email, nil)
    get "/auth/token/#{token}"
    last_response.should be_redirect
    follow_redirect!
    last_request.url.should =~ /\/login?$/
  end

  it "should not confirm authentication for valid expired token" do
    email = "random@random.test"

    token = add_user(email, :expired => true)

    app.any_instance.should_not_receive(:confirm_authentication!)
    get "/auth/token/#{token}"
    last_response.should be_redirect
    follow_redirect!
    last_request.url.should =~ /\/login?$/
  end

  it "should not confirm authentication for invalid token" do
    token = "something_unrelated_seriously"

    app.any_instance.should_not_receive(:confirm_authentication!)
    get "/auth/token/#{token}"
    last_response.should be_redirect
    follow_redirect!
    last_request.url.should =~ /\/login?$/
  end
end
