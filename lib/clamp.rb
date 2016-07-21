class Numeric
  def clamp(lo, hi)
    [lo, [self, hi].min].max
  end
end
