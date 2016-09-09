require_relative "helper"

class NothingToDoTest < ::Test::Unit::TestCase
  sub_test_case 'nothing to do' do
    test 'yay' do
      assert true
    end
  end
end
