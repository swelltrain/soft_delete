# frozen_string_literal: true

require 'active_record'
require 'soft_delete/version'
require 'soft_delete/soft_deletable'
require 'soft_delete/restorable'
require_relative 'soft_delete/configuration'

# This is gem main module
module SoftDelete
  @configuration = Configuration.new

  def self.configuration
    @configuration
  end

  def self.configuration=(config)
    @configuration = config
  end

  def self.configure
    yield(configuration)
  end
end
