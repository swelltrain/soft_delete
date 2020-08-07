# frozen_string_literal: true

module SoftDelete
  # TODO: wrap in a transaction
  module SoftDeletable
    extend ActiveSupport::Concern
    @@soft_delete_dependency_behavior = nil

    included do
      default_scope { where(deleted_at: nil) }
    end

    # descibes how soft delete should handle dependencies
    # ignore
    # ignore dependencies and do nothing. this is the default behavior
    # default
    # fire off the same action that is described by ar dsl
    # soft_delete
    # if dsl is :destroy, then override with a soft_delete
    def self.dependent(behavior = :ignore)
      raise ArgumentError unless %i[ignore default soft_delete].include? behavior

      @@soft_delete_dependency_behavior = behavior
      self
    end

    def soft_delete(validate: true)
      soft_delete!(validate: validate)
    rescue ActiveRecord::RecordInvalid
      false
    end

    def soft_delete!(validate: true)
      ActiveRecord::Base.transaction do
        handle_soft_delete_dependencies
        run_callbacks(:destroy)

        self.deleted_at = Time.now
        save!(validate: validate)
      end
    end

    private

    def handle_soft_delete_dependencies
      return unless @@soft_delete_dependency_behavior.present?

      case @@soft_delete_dependency_behavior
      when :soft_delete
        handle_overridden_soft_delete_dependencies
      when :default
        handle_normal_dependencies
      end
    end

    def handle_normal_dependencies
      soft_delete_dependent_associations.each(&:handle_dependency)
    end

    def handle_overridden_soft_delete_dependencies
      soft_delete_dependent_associations.each do |assn|
        next unless assn.options[:dependent] == :destroy

        # TODO: pass in validate
        assn.load_target.each(&:soft_delete!)

        # see:
        # https://github.com/rails/rails/blob/master/activerecord/lib/active_record/associations/collection_association.rb#L174
        assn.reset
        assn.loaded!
      end
      handle_normal_dependencies
    end

    def soft_delete_dependent_associations
      @soft_delete_dependent_associations ||=
        _reflections.select { |_k, v| v.options[:dependent].present? }.map { |_k, v| association(v.name) }
    end
  end
end
