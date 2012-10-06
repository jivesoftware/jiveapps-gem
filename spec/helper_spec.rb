require 'spec_helper'

describe Jiveapps::Helpers do

  class Temp
    include Jiveapps::Helpers
  end

  describe "user git version" do
    it "handles normal git version string" do
      @obj = Temp.new
      @obj.stub(:git_version).and_return("git version 1.7.9.6 (Apple Git-31.1)")
      @obj.user_git_version.should == Gem::Version.new("1.7")
    end

    it "handles apple-specific git version string" do
      @obj = Temp.new
      @obj.stub(:git_version).and_return("git version 1.7.11.3")
      @obj.user_git_version.should == Gem::Version.new("1.7")
    end
  end

end
