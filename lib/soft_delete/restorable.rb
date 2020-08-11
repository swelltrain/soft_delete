# frozen_string_literal: true

module SoftDelete
  module Restorable
    extend ActiveSupport::Concern

    included do
      scope :deleted, -> { unscope(where: :deleted_at).where.not(deleted_at: nil) }
    end

    def restore_soft_delete(validate: true)
      restore_soft_delete!(validate: validate)
    rescue ActiveRecord::RecordInvalid
      false
    end

    def restore_soft_delete!(validate: true)
      self.deleted_at = nil
      save!(validate: validate)
    end
  end
end
