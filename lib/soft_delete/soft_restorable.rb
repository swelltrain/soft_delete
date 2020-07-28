def restore_soft_delete(validate: true)
  restore_soft_delete!(validate: validate)
rescue ActiveRecord::RecordInvalid
  false
end

def restore_soft_delete!(validate: true)
  self.deleted_at = nil
  save!(validate: validate)
end
