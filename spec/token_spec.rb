require File.dirname(__FILE__) + '/spec_helper'

describe "token matcher behaviour" do
  describe "valid token" do
    before :each do
      email = "random@random.test"
      @user = add_user(email)
      @old_user = user_by_id(@user[:id])

      app.any_instance.should_receive(:confirm_authentication!).with(email, nil)
      get "/auth/token/#{@user[:token]}"
      last_response.should be_redirect
      follow_redirect!
    end

    it "should confirm authentication" do
      last_request.url.should =~ /\/login?$/
    end

    it "should wipe token" do
      user_by_token(@user[:token]).should be_empty
    end

    it "while preserving user" do
      user = user_by_id(@user[:id])
      user[:access_token] = @user[:token]
      user.should eq(@old_user)
    end
  end

  it "should not confirm authentication for valid expired token" do
    email = "random@random.test"
    @user = add_user(email, :expired => true)

    app.any_instance.should_not_receive(:confirm_authentication!)
    get "/auth/token/#{@user[:token]}"
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
