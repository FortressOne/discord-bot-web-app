require "test_helper"

class DeviceCodeTest < ActiveSupport::TestCase
  test "codes are two groups of four from the unambiguous alphabet" do
    20.times do
      code = DeviceCode.generate_code
      assert_match(/\A[#{DeviceCode::ALPHABET.join}]{4}-[#{DeviceCode::ALPHABET.join}]{4}\z/o, code)
    end
  end
end
