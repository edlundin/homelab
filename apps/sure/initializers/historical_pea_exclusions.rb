require "json"
require "set"

# Sure 0.7.6 does not retain PEA ownership when routing Trade Republic timeline
# events. Exclude only export-verified historical IDs for one connection; an
# instrument-name/ISIN filter would also discard legitimate ordinary trades.
module SureHistoricalPeaExclusions
  path = ENV.fetch("SURE_PEA_EXCLUSIONS_FILE", "/etc/sure/pea-exclusions/config.json")
  config = JSON.parse(File.read(path))
  uuid = /\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/i
  valid = config.is_a?(Hash) && config["version"] == 1 &&
    config["item_id"].is_a?(String) && uuid.match?(config["item_id"]) &&
    config["event_ids"].is_a?(Array) && !config["event_ids"].empty? &&
    config["event_ids"].all? { |id| id.is_a?(String) && uuid.match?(id) }
  raise ArgumentError, "Invalid historical PEA exclusion configuration" unless valid

  ITEM_ID = config.fetch("item_id").freeze
  EVENT_IDS = config.fetch("event_ids").map(&:freeze).to_set.freeze

  private

  def timeline_events
    events = super
    return events unless @trade_republic_account.trade_republic_item_id.to_s == ITEM_ID
    return events unless %w[portfolio cash].include?(@trade_republic_account.kind)

    events.reject do |event|
      event.is_a?(Hash) && EVENT_IDS.include?((event["id"] || event[:id]).to_s)
    end
  end
end

Rails.application.config.to_prepare do
  processor = TradeRepublicAccount::ActivitiesProcessor
  unless processor.private_method_defined?(:timeline_events) && processor.instance_method(:timeline_events).arity.zero?
    raise "Sure's Trade Republic processor changed; review the historical PEA filter before upgrading"
  end
  processor.prepend(SureHistoricalPeaExclusions) unless processor.ancestors.include?(SureHistoricalPeaExclusions)
end
