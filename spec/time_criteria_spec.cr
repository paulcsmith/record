require "./spec_helper"

private class QueryMe < LuckyRecord::Model
  table users do
    column activated_at : Time
  end
end

describe Time::Lucky::Criteria do
  describe "is" do
    it "=" do
      now = Time.now
      activated_at.is(now).to_sql.should eq ["SELECT users.id, users.created_at, users.updated_at, users.activated_at FROM users WHERE activated_at = $1", now.to_s]
    end
  end
end

private def activated_at
  QueryMe::BaseQuery.new.activated_at
end
