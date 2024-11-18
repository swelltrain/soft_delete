# frozen_string_literal: true

module SoftDelete
  # This is configuration class for the gem
  class Configuration
    attr_accessor :target_column

    def initialize
      @target_column = :deleted_at
    end
  end
end
