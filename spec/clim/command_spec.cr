require "./../spec_helper"

describe Clim::Command do
  describe "#initialize" do
    it "sets default usage when initialized with name." do
      cmd = Command.new("spec_command")
      cmd.usage.should eq("spec_command [options] [arguments]")
    end
    it "sets default parser when initialized with name." do
      cmd = Command.new("spec_command")
      cmd.parser.to_s.should eq("    -h, --help                       Show this help.")
    end
  end
  describe "#check_required" do
    it "returns self when there is no required options." do
      cmd = Command.new("spec_command")
      opts = Options.new

      opt1 = Option(String).new("-a", "", "", false, "", "")
      opt1.set_value = "foo"
      opts.add opt1

      opt2 = Option(String).new("-b", "", "", false, "", "")
      opt2.set_value = "bar"
      opts.add opt2

      cmd.opts = opts
      cmd.check_required.should eq(nil)
    end
    it "raises an Exception when there is required option." do
      cmd = Command.new("spec_command")
      opts = Options.new

      opt1 = Option(String).new("-a", "", "", false, "", "")
      opt1.set_value = "foo"
      opts.add opt1

      opt2 = Option(String).new("-b", "", "", true, "", "")
      opts.add opt2

      cmd.opts = opts
      expect_raises(Exception, "Required options. \"-b\"") { cmd.check_required }
    end
    it "raises an Exception when there are required options." do
      cmd = Command.new("spec_command")
      opts = Options.new

      opt1 = Option(String).new("-a", "", "", true, "", "")
      opts.add opt1

      opt2 = Option(String).new("-b", "", "", true, "", "")
      opts.add opt2

      cmd.opts = opts
      expect_raises(Exception, "Required options. \"-a\", \"-b\"") { cmd.check_required }
    end
  end
  describe "#help" do
    it "returns help message when there is no sub_commands." do
      cmd = Command.new("spec_command")
      cmd.desc = "spec_command description."
      cmd.usage = "spec_command [your options] [your arguments]"
      cmd.help.should eq(
        <<-HELP_MESSAGE

          spec_command description.

          Usage:

            spec_command [your options] [your arguments]

          Options:

            -h, --help                       Show this help.


        HELP_MESSAGE
      )
    end
    it "returns help message when there is sub_commands." do
      main_cmd = Command.new("main_command")
      main_cmd.desc = "main_command description."
      main_cmd.usage = "main_command [your options] [your arguments]"

      sub_cmd1 = Command.new("sub_command1")
      sub_cmd1.desc = "sub_command1 description."
      sub_cmd1.usage = "sub_command1 [your options] [your arguments]"
      main_cmd.sub_cmds << sub_cmd1

      sub_cmd2 = Command.new("sub_command2_long_name")
      sub_cmd2.desc = "sub_command2 description."
      sub_cmd2.usage = "sub_command2 [your options] [your arguments]"
      main_cmd.sub_cmds << sub_cmd2

      main_cmd.help.should eq(
        <<-HELP_MESSAGE

          main_command description.

          Usage:

            main_command [your options] [your arguments]

          Options:

            -h, --help                       Show this help.

          Sub Commands:

            sub_command1             sub_command1 description.
            sub_command2_long_name   sub_command2 description.


        HELP_MESSAGE
      )
    end
  end
  describe "#max_name_length" do
    it "returns max name length when commands are set." do
      main_cmd = Command.new("main_command")
      main_cmd.sub_cmds << Command.new("foo")
      main_cmd.sub_cmds << Command.new("fooo")
      main_cmd.sub_cmds << Command.new("fo")
      main_cmd.max_name_length.should eq(4)
    end
    it "returns 0 when commands are not set." do
      cmd = Command.new("foo")
      cmd.max_name_length.should eq(0)
    end
  end
  describe "#parse" do
    main_cmd = Command.new("init")
    Spec.before_each do
      main_cmd = Command.new("main_cmd")

      sub_cmd1 = Command.new("sub_cmd1")
      sub_cmd2 = Command.new("sub_cmd2")
      main_cmd.sub_cmds << sub_cmd1
      main_cmd.sub_cmds << sub_cmd2

      sub_sub_cmd1 = Command.new("sub_sub_cmd1")
      sub_sub_cmd2 = Command.new("sub_sub_cmd2")
      sub_cmd1.sub_cmds << sub_sub_cmd1
      sub_cmd1.sub_cmds << sub_sub_cmd2
    end
    it "returns main_cmd when argv is empry." do
      argv = %w()
      cmd = main_cmd.parse(argv)
      cmd.name.should eq("main_cmd")
    end
    context "returns specified command when there is argv." do
      it "argv is empty." do
        argv = %w()
        cmd = main_cmd.parse(argv)
        cmd.name.should eq("main_cmd")
      end
      it "sub_cmd1" do
        argv = %w(sub_cmd1)
        cmd = main_cmd.parse(argv)
        cmd.name.should eq("sub_cmd1")
      end
      it "sub_cmd2" do
        argv = %w(sub_cmd2)
        cmd = main_cmd.parse(argv)
        cmd.name.should eq("sub_cmd2")
      end
      it "sub_cmd1 sub_sub_cmd1" do
        argv = %w(sub_cmd1 sub_sub_cmd1)
        cmd = main_cmd.parse(argv)
        cmd.name.should eq("sub_sub_cmd1")
      end
      it "sub_cmd1 sub_sub_cmd2" do
        argv = %w(sub_cmd1 sub_sub_cmd2)
        cmd = main_cmd.parse(argv)
        cmd.name.should eq("sub_sub_cmd2")
      end
      it "missing_cmd" do
        argv = %w(missing_cmd)
        cmd = main_cmd.parse(argv)
        cmd.name.should eq("main_cmd")
      end
      it "sub_cmd1 missing_cmd" do
        argv = %w(sub_cmd1 missing_cmd)
        cmd = main_cmd.parse(argv)
        cmd.name.should eq("sub_cmd1")
      end
      it "sub_cmd1 sub_sub_cmd1 other_args" do
        argv = %w(sub_cmd1 sub_sub_cmd1 other_args)
        cmd = main_cmd.parse(argv)
        cmd.name.should eq("sub_sub_cmd1")
      end
    end
    it "raises Exception when command names are duplicated." do
      main_cmd = Command.new("main_cmd")

      sub_cmd1 = Command.new("sub_cmd1")
      main_cmd.sub_cmds << sub_cmd1

      duplicate_cmd1 = Command.new("duplicate_cmd_name")
      duplicate_cmd2 = Command.new("duplicate_cmd_name")
      sub_cmd1.sub_cmds << duplicate_cmd1
      sub_cmd1.sub_cmds << duplicate_cmd2

      argv = %w(sub_cmd1 duplicate_cmd_name)
      expect_raises(Exception, "There are duplicate registered commands. [duplicate_cmd_name]") { main_cmd.parse(argv) }
    end
  end
end
