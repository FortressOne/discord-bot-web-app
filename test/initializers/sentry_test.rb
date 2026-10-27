require "test_helper"

class SentryInitializerTest < ActiveSupport::TestCase
  test "samples 5% of transactions and never /up" do
    sampler = Sentry.configuration.traces_sampler

    assert_equal 0.0, sampler.call(env: { "PATH_INFO" => "/up" })
    assert_equal 0.05, sampler.call(env: { "PATH_INFO" => "/stats" })
    assert_equal 0.05, sampler.call({})
  end
end
