require 'spec_helper'

module Jiveapps::Command
  describe Help do
    before do
      @cli = prepare_command(Help)
    end

    it "displays a help page" do
      @cli.should_receive(:display).with("=== Summary")
      @cli.should_receive(:display).with("=== General Commands")
      @cli.index
    end
  end
end
