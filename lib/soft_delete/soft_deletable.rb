# frozen_string_literal: true

module SoftDelete
  module SoftDeletable
    extend ActiveSupport::Concern
    @@soft_delete_dependency_behavior = nil
    @@include_default_scope = true
    @@skip_dependent_soft_delete = []

    included do
      if @@include_default_scope
        default_scope { where(SoftDelete.configuration.target_column => nil) }
      else
        scope :active, -> { where(SoftDelete.configuration.target_column => nil) }
      end
    end

    def self.not_scoped
      @@include_default_scope = false

      self
    end

    def self.scoped
      @@include_default_scope = true

      self
    end

    # descibes how soft delete should handle dependencies
    # ignore
    # ignore dependencies and do nothing. this is the default behavior
    # default
    # fire off the same action that is described by ar dsl
    # soft_delete
    # if dsl is :destroy, then override with a soft_delete
    def self.dependent(behavior = :ignore, skip_dependent_soft_delete: [])
      raise ArgumentError unless %i[ignore default soft_delete].include? behavior

      @@skip_dependent_soft_delete = skip_dependent_soft_delete
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
        handle_soft_delete_dependency_behavior
        run_callbacks(:destroy) do
          public_send("#{SoftDelete.configuration.target_column}=", Time.now)
          save!(validate: validate)
        end
      end
    end

    private

    def handle_soft_delete_dependency_behavior
      return unless @@soft_delete_dependency_behavior.present?

      case @@soft_delete_dependency_behavior
      when :soft_delete
        handle_overridden_soft_delete_dependencies
      when :default
        handle_normal_dependencies
      end
    end

    # See:
    # https://github.com/rails/rails/blob/a725732b3dee53a102d62cb193c02dc886bbb7ea/activerecord/lib/active_record/associations/has_one_association.rb#L9
    # https://github.com/rails/rails/blob/a725732b3dee53a102d62cb193c02dc886bbb7ea/activerecord/lib/active_record/associations/belongs_to_association.rb#L7
    # https://github.com/rails/rails/blob/a725732b3dee53a102d62cb193c02dc886bbb7ea/activerecord/lib/active_record/associations/has_many_association.rb#L14
    #
    def handle_normal_dependencies
      soft_delete_dependent_associations.each(&:handle_dependency)
    end

    def handle_overridden_soft_delete_dependencies
      soft_delete_dependent_associations.each do |assn|
        next unless assn.options[:dependent] == :destroy

        # TODO: pass in validate
        associated_records = Array(assn.load_target)
        if @@skip_dependent_soft_delete.include?(associated_records.first.class.name)
          # It is skipped so follow through with default destroy
          #
          associated_records.each(&:destroy!)
          next
        end
        associated_records.each(&:soft_delete!)
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
