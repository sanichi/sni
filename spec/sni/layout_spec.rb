require 'spec_helper'

RSpec.describe Sni::Layout do
  describe "valid" do
    it "one row, two breakpoints" do
      lo = Sni::Layout.call(sm: [2, 3, 3], xx: [1, 2, 3])
      expect(lo[0]).to eq "col-sm-2 offset-sm-2 col-xxl-1 offset-xxl-3"
      expect(lo[1]).to eq "col-sm-3 offset-sm-0 col-xxl-2 offset-xxl-0"
      expect(lo[2]).to eq "col-sm-3 offset-sm-0 col-xxl-3 offset-xxl-0"
    end

    it "mixed rows, three breakpoints" do
      lo = Sni::Layout.call(lg: [[2, 1, 2], [1, 2, 3]], md: [[3, 2, 3], [2, 3, 4]], xs: [[3, 3], [3, 3], [3, 3]])
      expect(lo[0]).to eq "col-3 offset-3 col-md-3 offset-md-2 col-lg-2 offset-lg-4"
      expect(lo[1]).to eq "col-3 offset-0 col-md-2 offset-md-0 col-lg-1 offset-lg-0"
      expect(lo[2]).to eq "col-3 offset-3 col-md-3 offset-md-0 col-lg-2 offset-lg-0"
      expect(lo[3]).to eq "col-3 offset-0 col-md-2 offset-md-2 col-lg-1 offset-lg-3"
      expect(lo[4]).to eq "col-3 offset-3 col-md-3 offset-md-0 col-lg-2 offset-lg-0"
      expect(lo[5]).to eq "col-3 offset-0 col-md-4 offset-md-0 col-lg-3 offset-lg-0"
    end

    it "mixed rows, no padding" do
      lo = Sni::Layout.call(xl: [3, 3, 3, 3], sm: [[6, 6], [6, 6]])
      expect(lo[0]).to eq "col-sm-6 offset-sm-0 col-xl-3 offset-xl-0"
      expect(lo[1]).to eq "col-sm-6 offset-sm-0 col-xl-3 offset-xl-0"
      expect(lo[2]).to eq "col-sm-6 offset-sm-0 col-xl-3 offset-xl-0"
      expect(lo[3]).to eq "col-sm-6 offset-sm-0 col-xl-3 offset-xl-0"
    end

    it "xxl and xx are equivalent" do
      lo1 = Sni::Layout.call(xx: [3, 3, 3, 3])
      lo2 = Sni::Layout.call(xxl: [3, 3, 3, 3])
      expect(lo1[0]).to eq lo2[0]
      expect(lo1[1]).to eq lo2[1]
      expect(lo1[2]).to eq lo2[2]
      expect(lo1[3]).to eq lo2[3]
    end

    it "instance method works same as class method" do
      args = { sm: [2, 3, 3], xx: [1, 2, 3] }
      class_result = Sni::Layout.call(args)
      instance_result = Sni::Layout.new(args).call
      expect(class_result).to eq instance_result
    end
  end

  describe "invalid" do
    it "input" do
      expect{Sni::Layout.call(nil)}.to raise_error(StandardError, "invalid input")
    end

    it "keys" do
      expect{Sni::Layout.call(yy: [1, 2, 3])}.to raise_error(StandardError, "no valid breakpoint keys")
    end

    it "empty" do
      expect{Sni::Layout.call(md: [])}.to raise_error(StandardError, "no items")
    end

    it "width" do
      expect{Sni::Layout.call(md: [0, 4])}.to raise_error(StandardError, "invalid width")
      expect{Sni::Layout.call(md: [4, 13])}.to raise_error(StandardError, "invalid width")
    end

    it "total" do
      expect{Sni::Layout.call(md: [5, 5, 5])}.to raise_error(StandardError, "excessive sum of widths")
    end

    it "rows" do
      expect{Sni::Layout.call(md: [1, 2, [3, 4]])}.to raise_error(StandardError, "invalid row")
      expect{Sni::Layout.call(md: [[1, 2], "a"])}.to raise_error(StandardError, "invalid row")
    end

    it "number" do
      expect{Sni::Layout.call(md: [1, 2, 3], lg: [1, 2, 3, 4])}.to raise_error(StandardError, "inconsistent number of items")
    end
  end
end