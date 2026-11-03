require "json"
require "tmpdir"
require "fileutils"
require "minitest/autorun"

# Exercise the initializer's Rails hook without installing Sure or connecting
# to a financial database. The superclass exposes only the intercepted method.
module Rails
  def self.application
    @application ||= Struct.new(:config).new(Class.new do
      attr_reader :prepare
      def to_prepare(&block)
        @prepare = block
      end
    end.new)
  end
end

class TradeRepublicAccount
  class ActivitiesProcessor
    def initialize(account, events)
      @trade_republic_account = account
      @events = events
    end

    private

    def timeline_events
      @events
    end
  end
end

fixture_dir = Dir.mktmpdir("sure-pea-filter-test-")
at_exit { FileUtils.remove_entry(fixture_dir) }
config_path = File.join(fixture_dir, "config.json")
File.write(config_path, JSON.generate(
  version: 1,
  item_id: "00000000-0000-0000-0000-000000000001",
  event_ids: ["00000000-0000-0000-0000-000000000002"]
))
ENV["SURE_PEA_EXCLUSIONS_FILE"] = config_path
require_relative "../initializers/historical_pea_exclusions"
Rails.application.config.prepare.call

class HistoricalPeaExclusionsTest < Minitest::Test
  Account = Struct.new(:trade_republic_item_id, :kind)
  ITEM = "00000000-0000-0000-0000-000000000001"
  OTHER_ITEM = "00000000-0000-0000-0000-000000000003"
  EXCLUDED = "00000000-0000-0000-0000-000000000002"

  def filtered(kind, events, item: ITEM)
    TradeRepublicAccount::ActivitiesProcessor.new(Account.new(item, kind), events).send(:timeline_events)
  end

  def test_target_portfolio_filters_exact_ids_with_either_hash_key_style
    events = [{"id" => EXCLUDED}, {id: EXCLUDED}, {"id" => "keep", "isin" => "same-fund"}, nil]
    assert_equal [{"id" => "keep", "isin" => "same-fund"}, nil], filtered("portfolio", events)
    assert_equal 4, events.length, "Filtering must not mutate the provider's raw snapshot"
  end

  def test_target_cash_filters_the_same_settlement_events
    assert_equal [{id: "keep"}], filtered("cash", [{id: EXCLUDED}, {id: "keep"}])
  end

  def test_another_connection_keeps_the_same_event_id
    events = [{id: EXCLUDED}]
    assert_same events, filtered("portfolio", events, item: OTHER_ITEM)
  end

  def test_crypto_is_unchanged
    events = [{id: EXCLUDED}]
    assert_same events, filtered("crypto", events)
  end

  def test_reload_does_not_prepend_twice_or_expose_the_private_method
    Rails.application.config.prepare.call
    assert_equal 1, TradeRepublicAccount::ActivitiesProcessor.ancestors.count(SureHistoricalPeaExclusions)
    refute TradeRepublicAccount::ActivitiesProcessor.new(Account.new(ITEM, "cash"), []).respond_to?(:timeline_events)
  end
end
