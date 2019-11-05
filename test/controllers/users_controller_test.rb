require "test_helper"

describe UsersController do
  describe "auth_callback" do
    it "logs in the first existing user and redirects them to the root path" do
      expect {
        perform_login
      }.wont_change "User.count"

      must_redirect_to root_path
      expect(session[:user_id].must_equal User.first.id)
    end

    it "logs in a new user and redirects them back to the root path" do
      user = User.new(name: "Tester", provider: "github", uid: 456, email: "tester@test.com", username: "tester123")
      
      expect {
        perform_login(user)
      }.must_change "User.count", 1

      user = User.find_by(uid: user.uid)

      must_redirect_to root_path
      expect(session[:user_id]).must_equal user.id
    end

    it "should redirect back to root for invalid callbacks" do
      expect {
        perform_login(User.new)
      }.wont_change "User.count"

      must_redirect_to root_path
      expect(session[:user_id]).must_be_nil
    end
  end

  describe "destroy/logging out" do
    it "ends the session when the user clicks logout" do
      delete logout_path

      must_respond_with :found
      must_redirect_to root_path
    end
  end
end
