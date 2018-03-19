class FinancialSummary

  def initialize(transactions, currency)
    @transactions = transactions
    @currency = currency
  end

  def self.one_day(user: user, currency: currency)
    self.n_days_ago(user.id, currency, 1)
  end
  
  def self.seven_days(user: user, currency: currency)
    self.n_days_ago(user.id, currency, 7)
  end

  def self.lifetime(user: user, currency: currency)
    self.new(Transaction.where('user_id = ? AND lower(amount_currency) = ?', user.id, currency.downcase),currency.downcase)
  end

  def count(category)
     @transactions.where(category: category).count
  end

  def amount(category)
    total_in_cents = @transactions.where(category: category).sum(:amount_cents)
    Money.new(total_in_cents, @currency)
  end

  private

  def self.n_days_ago(user_id, currency, days_ago) # allows for dynamic generation if we want to different time frames
    self.new(Transaction.where('user_id = ? AND created_at >= ? AND lower(amount_currency) = ?', user_id, days_ago.days.ago, currency.downcase), currency.downcase)
  end

end