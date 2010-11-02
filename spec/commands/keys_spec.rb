require 'spec_helper'

module Jiveapps::Command
  describe Keys do
    before do
      @keys = prepare_command(Keys)
      @keys.jiveapps.stub!(:user).and_return('joe')

      @key_list_response = [
        {
          "name"       => "foobar",
          "created_at" => "2010-11-01T18:31:04Z",
          "updated_at" => "2010-11-01T18:31:04Z",
          "username"   => "testuser",
          "id"         => 3,
          "key"        => "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAp9AJD5QABmOcrkHm6SINuQkDefaR0MUrfgZ1Pxir3a4fM1fwa00dsUwbUaRuR7FEFD8n1E9WwDf8SwQTHtyZsJg09G9myNqUzkYXCmydN7oGr5IdVhRyv5ixcdiE0hj7dRnOJg2poSQ3Qi+Ka8SVJzF7nIw1YhuicHPSbNIFKi5s0D5a+nZb/E6MNGvhxoFCQX2IcNxaJMqhzy1ESwlixz45aT72mXYq0LIxTTpoTqma1HuKdRY8HxoREiivjmMQulYP+CxXFcMyV9kxTKIUZ/FXqlC6G5vSm3J4YScSatPOj9ID5HowpdlIx8F6y4p1/28r2tTl4CY40FFyoke4MQ== pablo@jive\n"
        }
      ]
    end

    it "adds a key from the default locations if no key filename is supplied" do
      @keys.should_receive(:find_key).and_return('/home/joe/.ssh/id_rsa.pub')
      File.should_receive(:read).with('/home/joe/.ssh/id_rsa.pub').and_return('ssh-rsa xyz')
      @keys.jiveapps.should_receive(:add_key).with('ssh-rsa xyz')
      @keys.should_receive(:display).with("Uploading ssh public key /home/joe/.ssh/id_rsa.pub")
      @keys.add
    end

    it "adds a key from a specified keyfile path" do
      @keys.stub!(:args).and_return(['/my/key.pub'])
      @keys.should_receive(:find_key).with('/my/key.pub').and_return('/my/key.pub')
      File.should_receive(:read).with('/my/key.pub').and_return('ssh-rsa xyz')
      @keys.jiveapps.should_receive(:add_key).with('ssh-rsa xyz')
      @keys.add
    end

    it "list keys, trimming the hex code for better display" do
      @keys.jiveapps.should_receive(:keys).and_return(@key_list_response)
      @keys.should_receive(:display).with('ssh-rsa AAAAB3NzaC...Fyoke4MQ== pablo@jive')
      @keys.list
    end

    it "list keys showing the whole key hex with --long" do
      @keys.stub!(:args).and_return(['--long'])
      @keys.jiveapps.should_receive(:keys).and_return(@key_list_response)
      @keys.should_receive(:display).with("ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAp9AJD5QABmOcrkHm6SINuQkDefaR0MUrfgZ1Pxir3a4fM1fwa00dsUwbUaRuR7FEFD8n1E9WwDf8SwQTHtyZsJg09G9myNqUzkYXCmydN7oGr5IdVhRyv5ixcdiE0hj7dRnOJg2poSQ3Qi+Ka8SVJzF7nIw1YhuicHPSbNIFKi5s0D5a+nZb/E6MNGvhxoFCQX2IcNxaJMqhzy1ESwlixz45aT72mXYq0LIxTTpoTqma1HuKdRY8HxoREiivjmMQulYP+CxXFcMyV9kxTKIUZ/FXqlC6G5vSm3J4YScSatPOj9ID5HowpdlIx8F6y4p1/28r2tTl4CY40FFyoke4MQ== pablo@jive")
      @keys.list
    end

    it "removes the key matching the specified name" do
      @keys.stub!(:args).and_return(['pablo@jive'])
      @keys.jiveapps.should_receive(:remove_key).with('pablo@jive')
      @keys.remove
    end

    context "key locating" do
      before do
        @keys.stub!(:home_directory).and_return('/home/joe')
      end

      it "finds the user's ssh key in ~/ssh/id_rsa.pub" do
        File.should_receive(:exists?).with('/home/joe/.ssh/id_rsa.pub').and_return(true)
        @keys.send(:find_key).should == '/home/joe/.ssh/id_rsa.pub'
      end

      it "finds the user's ssh key in ~/ssh/id_dsa.pub" do
        File.should_receive(:exists?).with('/home/joe/.ssh/id_rsa.pub').and_return(false)
        File.should_receive(:exists?).with('/home/joe/.ssh/id_dsa.pub').and_return(true)
        @keys.send(:find_key).should == '/home/joe/.ssh/id_dsa.pub'
      end

      it "finds the user's ssh key in the specified path, /my/path/id_rsa.pub" do
        File.should_receive(:exists?).with('/my/path/id_rsa.pub').and_return(true)
        @keys.send(:find_key, '/my/path/id_rsa.pub').should == '/my/path/id_rsa.pub'
      end

      it "raises an exception if neither id_rsa or id_dsa were found" do
        File.stub!(:exists?).and_return(false)
        lambda { @keys.send(:find_key) }.should raise_error(Jiveapps::Command::CommandFailed)
      end

      it "raises an exception if specified path not found" do
        File.stub!(:exists?).and_return(false)
        lambda { @keys.send(:find_key, '/my/path/id_rsa.pub') }.should raise_error(Jiveapps::Command::CommandFailed)
      end
    end

  end
end