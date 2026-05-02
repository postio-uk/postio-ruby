# frozen_string_literal: true

module Postio
  module Models
    # Performance — per-request timing breakdown.
    Performance = Data.define(:worker_ms, :lookup_ms) do
      def self.from_hash(h)
        new(worker_ms: h["workerMs"].to_i, lookup_ms: h["lookupMs"].to_i)
      end
    end

    # Meta — response envelope metadata for every endpoint except /connect.
    Meta = Data.define(:count_results, :request_id, :performance) do
      def self.from_hash(h)
        new(
          count_results: h["countResults"].to_i,
          request_id:    h["requestId"].to_s,
          performance:   Performance.from_hash(h["performance"])
        )
      end
    end

    # MetaConnect — meta block for /connect (no count).
    MetaConnect = Data.define(:request_id, :performance) do
      def self.from_hash(h)
        new(
          request_id:  h["requestId"].to_s,
          performance: Performance.from_hash(h["performance"])
        )
      end
    end

    # AddressSearchResult — a single typeahead hit.
    AddressSearchResult = Data.define(:udprn, :suggestion) do
      def self.from_hash(h)
        new(udprn: h["udprn"].to_i, suggestion: h["suggestion"].to_s)
      end
    end

    # Address — full PAF + OS record. Many fields are optional.
    Address = Data.define(
      :udprn, :postcode, :postcode_outward, :postcode_inward, :postcode_type,
      :address_line_1, :address_line_2, :address_line_3, :post_town,
      :organisation_name, :department_name, :building_name, :building_number,
      :sub_building_name, :po_box, :thoroughfare, :dependent_thoroughfare,
      :dependent_locality, :double_dependent_locality, :delivery_point_suffix,
      :country, :county, :district, :ward,
      :latitude, :longitude, :eastings, :northings
    ) do
      def self.from_hash(h)
        new(
          udprn:                       h["udprn"].to_i,
          postcode:                    h["postcode"].to_s,
          postcode_outward:            h["postcode_outward"],
          postcode_inward:             h["postcode_inward"],
          postcode_type:               h["postcode_type"],
          address_line_1:              h["address_line_1"],
          address_line_2:              h["address_line_2"],
          address_line_3:              h["address_line_3"],
          post_town:                   h["post_town"],
          organisation_name:           h["organisation_name"],
          department_name:             h["department_name"],
          building_name:               h["building_name"],
          building_number:             h["building_number"],
          sub_building_name:           h["sub_building_name"],
          po_box:                      h["po_box"],
          thoroughfare:                h["thoroughfare"],
          dependent_thoroughfare:      h["dependent_thoroughfare"],
          dependent_locality:          h["dependent_locality"],
          double_dependent_locality:   h["double_dependent_locality"],
          delivery_point_suffix:       h["delivery_point_suffix"],
          country:                     h["country"],
          county:                      h["county"],
          district:                    h["district"],
          ward:                        h["ward"],
          latitude:                    h["latitude"]&.to_f,
          longitude:                   h["longitude"]&.to_f,
          eastings:                    h["eastings"]&.to_i,
          northings:                   h["northings"]&.to_i
        )
      end
    end

    # EmailResult — validation verdict for one email address.
    EmailResult = Data.define(
      :email, :is_valid_syntax, :did_you_mean, :is_disposable, :is_free_provider,
      :is_role_account, :mx_found, :smtp_check, :is_catch_all, :deliverability
    ) do
      DELIVERABILITY_DELIVERABLE   = "deliverable"
      DELIVERABILITY_UNDELIVERABLE = "undeliverable"
      DELIVERABILITY_RISKY         = "risky"
      DELIVERABILITY_UNKNOWN       = "unknown"
      DELIVERABILITY_INVALID       = "invalid"

      def self.from_hash(h)
        new(
          email:            h["email"].to_s,
          is_valid_syntax:  h["isValidSyntax"] == true,
          did_you_mean:     h["didYouMean"],
          is_disposable:    h["isDisposable"] == true,
          is_free_provider: h["isFreeProvider"] == true,
          is_role_account:  h["isRoleAccount"] == true,
          mx_found:         h["mxFound"] == true,
          smtp_check:       h["smtpCheck"],
          is_catch_all:     h["isCatchAll"],
          deliverability:   h["deliverability"].to_s
        )
      end
    end

    # PhoneResult — validation verdict for one phone number.
    PhoneResult = Data.define(
      :number, :is_valid, :is_possible, :type, :country_code, :country_name,
      :national_format, :international_format, :e164_format, :original_carrier,
      :current_carrier, :is_ported, :is_reachable, :mcc, :mnc, :level, :lookup_error
    ) do
      def self.from_hash(h)
        new(
          number:               h["number"].to_s,
          is_valid:             h["isValid"] == true,
          is_possible:          h["isPossible"] == true,
          type:                 h["type"],
          country_code:         h["countryCode"],
          country_name:         h["countryName"],
          national_format:      h["nationalFormat"],
          international_format: h["internationalFormat"],
          e164_format:          h["e164Format"],
          original_carrier:     h["originalCarrier"],
          current_carrier:      h["currentCarrier"],
          is_ported:            h["isPorted"],
          is_reachable:         h["isReachable"],
          mcc:                  h["mcc"],
          mnc:                  h["mnc"],
          level:                h["level"],
          lookup_error:         h["lookupError"]
        )
      end
    end

    # Envelopes — one per endpoint.
    AddressSearchEnvelope = Data.define(:success, :results, :meta) do
      def self.from_hash(h)
        new(
          success: h["success"] == true,
          results: (h["results"] || []).map { |r| AddressSearchResult.from_hash(r) },
          meta:    Meta.from_hash(h["meta"])
        )
      end
    end

    AddressPostcodeEnvelope = Data.define(:success, :results, :meta) do
      def self.from_hash(h)
        new(
          success: h["success"] == true,
          results: (h["results"] || []).map { |r| Address.from_hash(r) },
          meta:    Meta.from_hash(h["meta"])
        )
      end
    end

    AddressUdprnEnvelope = Data.define(:success, :results, :meta) do
      def self.from_hash(h)
        new(
          success: h["success"] == true,
          results: (h["results"] || []).map { |r| Address.from_hash(r) },
          meta:    Meta.from_hash(h["meta"])
        )
      end
    end

    EmailEnvelope = Data.define(:success, :results, :meta) do
      def self.from_hash(h)
        new(
          success: h["success"] == true,
          results: (h["results"] || []).map { |r| EmailResult.from_hash(r) },
          meta:    Meta.from_hash(h["meta"])
        )
      end
    end

    PhoneEnvelope = Data.define(:success, :results, :meta) do
      def self.from_hash(h)
        new(
          success: h["success"] == true,
          results: (h["results"] || []).map { |r| PhoneResult.from_hash(r) },
          meta:    Meta.from_hash(h["meta"])
        )
      end
    end

    ConnectSuccess = Data.define(:success, :meta) do
      def self.from_hash(h)
        new(success: h["success"] == true, meta: MetaConnect.from_hash(h["meta"]))
      end
    end
  end
end
