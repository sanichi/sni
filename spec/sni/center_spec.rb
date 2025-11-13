require 'spec_helper'

RSpec.describe Sni::Center do
  describe "valid" do
    it "default with no arguments" do
      result = Sni::Center.call
      expect(result).to eq "col-12"
    end

    it "default with empty hash" do
      result = Sni::Center.call({})
      expect(result).to eq "col-12"
    end

    it "default with all zeros" do
      result = Sni::Center.call(xs: 0, sm: 0, md: 0, lg: 0, xl: 0, xx: 0)
      expect(result).to eq "col-12"
    end

    it "xs only" do
      result = Sni::Center.call(xs: 6)
      expect(result).to eq "offset-3 col-6"
    end

    it "xs with odd width" do
      result = Sni::Center.call(xs: 9)
      expect(result).to eq "offset-1 col-9"
    end

    it "sm only" do
      result = Sni::Center.call(sm: 8)
      expect(result).to eq "offset-sm-2 col-sm-8"
    end

    it "md only" do
      result = Sni::Center.call(md: 10)
      expect(result).to eq "offset-md-1 col-md-10"
    end

    it "lg only" do
      result = Sni::Center.call(lg: 6)
      expect(result).to eq "offset-lg-3 col-lg-6"
    end

    it "xl only" do
      result = Sni::Center.call(xl: 4)
      expect(result).to eq "offset-xl-4 col-xl-4"
    end

    it "xxl only (using xx parameter)" do
      result = Sni::Center.call(xx: 8)
      expect(result).to eq "offset-xxl-2 col-xxl-8"
    end

    it "xs/sm/md combination" do
      result = Sni::Center.call(xs: 9, sm: 7, md: 5)
      expect(result).to eq "offset-1 col-9 offset-sm-2 col-sm-7 offset-md-3 col-md-5"
    end

    it "md/lg/xl combination" do
      result = Sni::Center.call(xs: 0, md: 8, lg: 6, xl: 4)
      expect(result).to eq "offset-md-2 col-md-8 offset-lg-3 col-lg-6 offset-xl-4 col-xl-4"
    end

    it "all breakpoints" do
      result = Sni::Center.call(xs: 10, sm: 8, md: 6, lg: 6, xl: 4, xx: 4)
      expect(result).to eq "offset-1 col-10 offset-sm-2 col-sm-8 offset-md-3 col-md-6 offset-lg-3 col-lg-6 offset-xl-4 col-xl-4 offset-xxl-4 col-xxl-4"
    end

    it "instance method works same as class method" do
      args = { xs: 6, md: 8, xl: 4 }
      class_result = Sni::Center.call(args)
      instance_result = Sni::Center.new(args).call
      expect(class_result).to eq instance_result
    end
  end

  describe "invalid" do
    it "non-hash input" do
      expect { Sni::Center.call(nil) }.to raise_error(StandardError, "invalid input")
      expect { Sni::Center.call("string") }.to raise_error(StandardError, "invalid input")
      expect { Sni::Center.call([1, 2, 3]) }.to raise_error(StandardError, "invalid input")
    end
  end
end
