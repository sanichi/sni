# frozen_string_literal: true

RSpec.describe Sni do
  it "has a version number" do
    expect(Sni::VERSION).not_to be nil
  end

  it "provides system information service" do
    expect(Sni::SysInfo).to respond_to(:call)
  end
end
