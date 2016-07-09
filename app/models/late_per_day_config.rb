class LatePerDayConfig < LatenessConfig
  def allow_submission?(assn, sub)
    days_allowed = self.days_per_assignment
    if days_allowed.nil? && !assn.lateness_config.nil?
      days_allowed = assn.lateness_config.days_per_assignment
    end
    return true if days_allowed.nil?
    days_late(assn, sub) <= days_allowed
  end

  def late_penalty(assn, sub)
    [100, [self.max_penalty || 0, (self.percent_off || 0).to_f * (days_late(assn, sub).to_f / self.frequency)].max].min
  end
end
