require "test_helper"

describe WorksController do
  let(:existing_work) { works(:album) }

  describe "root" do
    it "succeeds with all media types" do
      get root_path

      must_respond_with :success
    end

    it "succeeds with one media type absent" do
      only_book = works(:poodr)
      only_book.destroy

      get root_path

      must_respond_with :success
    end

    it "succeeds with no media" do
      Work.all do |work|
        work.destroy
      end

      get root_path

      must_respond_with :success
    end
  end

  CATEGORIES = %w(albums books movies)
  INVALID_CATEGORIES = ["nope", "42", "", "  ", "albumstrailingtext"]

  describe "index" do
    it "succeeds when there are works and logged in" do
      perform_login(User.first)
      get works_path

      must_respond_with :success
    end

    it "does not succeed when there are works and user is not logged in" do
      get works_path

      # must_respond_with :warning
      must_redirect_to root_path
    end

    it "succeeds when there are no works and user logged in" do
      perform_login(User.first)
      Work.all do |work|
        work.destroy
      end

      get works_path

      must_respond_with :success
    end
  end

  describe "new" do
    it "succeeds with a logged in user" do
      perform_login(User.first)
      get new_work_path

      must_respond_with :success
    end

    it "does not succeed with a guest user" do
      get new_work_path

      # must_respond_with :warning
      must_redirect_to root_path
    end
  end

  describe "create" do
    it "creates a work with valid data for a real category with a logged in user" do
      perform_login(User.first)
      new_work = { work: { title: "Dirty Computer", category: "album" } }

      expect {
        post works_path, params: new_work
      }.must_change "Work.count", 1

      new_work_id = Work.find_by(title: "Dirty Computer").id

      must_respond_with :redirect
      must_redirect_to work_path(new_work_id)
    end

    it "does not create a work with valid data becauee no user is logged in" do
      new_work = { work: { title: "Dirty Computer", category: "album" } }

      expect {
        post works_path, params: new_work
      }.wont_change "Work.count"

      must_redirect_to root_path
    end

    it "renders bad_request and does not update the DB for bogus data with a logged in user" do
      perform_login(User.first)
      bad_work = { work: { title: nil, category: "book" } }

      expect {
        post works_path, params: bad_work
      }.wont_change "Work.count"

      must_respond_with :bad_request
    end

    it "redirects to main page if a guest user attempts to update the DB with bogus data" do
      bad_work = { work: { title: nil, category: "book" } }

      expect {
        post works_path, params: bad_work
      }.wont_change "Work.count"

      must_respond_with :redirect
      must_redirect_to root_path
    end

    it "renders 400 bad_request for bogus categories with a logged in user" do
      perform_login(User.first)
      INVALID_CATEGORIES.each do |category|
        invalid_work = { work: { title: "Invalid Work", category: category } }

        proc { post works_path, params: invalid_work }.wont_change "Work.count"

        Work.find_by(title: "Invalid Work", category: category).must_be_nil
        must_respond_with :bad_request
      end
    end
  end

  describe "show" do
    it "succeeds for an extant work ID and logged in user" do
      perform_login(User.first)
      get work_path(existing_work.id)

      must_respond_with :success
    end

    it "does not succeed for an exisiting work and a guest user" do
      get work_path(existing_work.id)

      must_respond_with :redirect
      must_redirect_to root_path
    end

    it "renders 404 not_found for a bogus work ID regardless if user logged in or guest" do
      destroyed_id = existing_work.id
      existing_work.destroy

      get work_path(destroyed_id)

      must_respond_with :not_found
    end
  end

  describe "edit" do
    it "succeeds for an extant work ID and logged in user" do
      perform_login(User.first)
      get edit_work_path(existing_work.id)

      must_respond_with :success
    end

    it "does not succeed for an existing work ID and a guest user" do
      get edit_work_path(existing_work.id)

      must_respond_with :redirect
      must_redirect_to root_path
    end

    it "renders 404 not_found for a bogus work ID regardless if user logged in or guest" do
      bogus_id = existing_work.id
      existing_work.destroy

      get edit_work_path(bogus_id)

      must_respond_with :not_found
    end
  end

  describe "update" do
    it "succeeds for valid data and an extant work ID if user logged in" do
      perform_login(User.first)
      updates = { work: { title: "Dirty Computer" } }

      expect {
        put work_path(existing_work), params: updates
      }.wont_change "Work.count"
      updated_work = Work.find_by(id: existing_work.id)

      updated_work.title.must_equal "Dirty Computer"
      must_respond_with :redirect
      must_redirect_to work_path(existing_work.id)
    end

    it "does not succeed for valid data if user is a guest" do
      updates = { work: { title: "Dirty Computer" } }

      expect {
        put work_path(existing_work), params: updates
      }.wont_change "Work.count"

      must_respond_with :redirect
      must_redirect_to root_path
    end

    it "renders bad_request for bogus data and user logged in" do
      perform_login(User.first)
      updates = { work: { title: nil } }

      expect {
        put work_path(existing_work), params: updates
      }.wont_change "Work.count"

      work = Work.find_by(id: existing_work.id)

      must_respond_with :not_found
    end

    it "redirects to main page for bogus data and guest user" do
      updates = { work: { title: nil } }

      expect {
        put work_path(existing_work), params: updates
      }.wont_change "Work.count"

      must_respond_with :redirect
      must_redirect_to root_path
    end

    it "renders 404 not_found for a bogus work ID regardless is user logged in or guest" do
      bogus_id = existing_work.id
      existing_work.destroy

      put work_path(bogus_id), params: { work: { title: "Test Title" } }

      must_respond_with :not_found
    end
  end

  describe "destroy" do
    it "succeeds for an extant work ID and user logged in" do
      perform_login(User.first)
      expect {
        delete work_path(existing_work.id)
      }.must_change "Work.count", -1

      must_respond_with :redirect
      must_redirect_to root_path
    end

    it "redirects to main page when guest user attempts to delete a valid work" do
      expect {
        delete work_path(existing_work.id)
      }.wont_change "Work.count"

      must_respond_with :redirect
      must_redirect_to root_path
    end

    it "renders 404 not_found and does not update the DB for a bogus work ID regardless if user logged in or guest" do
      bogus_id = existing_work.id
      existing_work.destroy

      expect {
        delete work_path(bogus_id)
      }.wont_change "Work.count"

      must_respond_with :not_found
    end
  end

  describe "upvote" do
    it "redirects to the main page if no user is logged in" do
      @login_user = perform_login(User.first)
      this_work = works(:another_album)
      delete logout_path(@login_user)

      expect {
        post upvote_path(this_work.id)
      }.wont_change "Vote.count"

      must_respond_with :redirect
      must_redirect_to root_path
    end

    it "redirects to the main page after the user has logged out" do
      this_work = works(:another_album)
      this_user = users(:kari)
      perform_login(this_user)

      expect {
        post upvote_path(this_work.id)
      }.must_change "Vote.count", 1

      must_redirect_to work_path(this_work.id)

      delete logout_path(this_user.id)
      must_respond_with :redirect
      must_redirect_to root_path
    end

    it "succeeds for a logged-in user and a fresh user-vote pair" do
      this_work = works(:another_album)
      this_user = users(:kari)
      perform_login(this_user)

      expect {
        post upvote_path(this_work.id)
      }.must_change "Vote.count", 1

      must_redirect_to work_path(this_work.id)
    end

    it "redirects to the work page if the user has already voted for that work" do
      this_work = works(:another_album)
      this_user = users(:kari)
      perform_login(this_user)

      post upvote_path(this_work.id)

      expect {
        post upvote_path(this_work.id)
      }.wont_change "Vote.count"

      must_redirect_to work_path(this_work.id)
    end
  end
end
