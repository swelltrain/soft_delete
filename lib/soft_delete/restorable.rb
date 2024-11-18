# frozen_string_literal: true

module SoftDelete
  module Restorable
    extend ActiveSupport::Concern

    included do
      scope :deleted, lambda {
        unscope(where: SoftDelete.configuration.target_column).where.not(SoftDelete.configuration.target_column => nil)
      }
    end

    def restore_soft_delete(validate: true)
      restore_soft_delete!(validate: validate)
    rescue ActiveRecord::RecordInvalid
      false
    end

    def restore_soft_delete!(validate: true)
      public_send("#{SoftDelete.configuration.target_column}=", nil)
      save!(validate: validate)
    end
  end
end
