require 'rails_helper'

describe FinancialSummary do

  let(:user) { create :user }
  let(:transaction_10_usd) { create :transaction, user: user, category: :deposit, amount: Money.from_amount(10, :usd) }
  let(:transaction_10_usd2) { create :transaction, user: user, category: :deposit, amount: Money.from_amount(10, :usd) }

  let(:transaction_10_usd_withdraw) { create :transaction, user: user, category: :withdraw, amount: Money.from_amount(10, :usd) }
  let(:transaction_10_usd_withdraw2) { create :transaction, user: user, category: :withdraw, amount: Money.from_amount(10, :usd) }
  let(:transaction_10_cad_withdraw) { create :transaction, user: user, category: :withdraw, amount: Money.from_amount(10, :cad) }
  let(:transaction_10_cad_refund) { create :transaction, user: user, category: :refund, amount: Money.from_amount(10, :cad) }
  let(:transaction_10_usd_refund) { create :transaction, user: user, category: :refund, amount: Money.from_amount(10, :usd) }

  context 'summarizes over one day' do

    it 'deposits in USD' do
      Timecop.freeze(Time.now) do
        create(:transaction, user: user, category: :deposit, amount: Money.from_amount(2.12, :usd))
        transaction_10_usd
      end
      Timecop.freeze(2.days.ago) do
        transaction_10_usd2
      end

      subject = FinancialSummary.one_day(user: user, currency: :usd)
      expect(subject.count(:deposit)).to eq(2)
      expect(subject.amount(:deposit)).to eq(Money.from_amount(12.12, :usd))
    end

    it 'withdraw in usd' do
      Timecop.freeze(Time.now) do
        create(:transaction, user: user, category: :deposit, amount: Money.from_amount(2.12, :usd))
        create(:transaction, user: user, category: :deposit, amount: Money.from_amount(10, :cad))
        transaction_10_usd_withdraw
      end

      Timecop.freeze(2.days.ago) do
        transaction_10_usd2
      end

      subject = FinancialSummary.one_day(user: user, currency: :usd)
      expect(subject.count(:withdraw)).to eq(1)
      expect(subject.amount(:withdraw)).to eq(Money.from_amount(10.00, :usd))
    end

    it 'deposits in CAD' do
      Timecop.freeze(Time.now) do
        create(:transaction, user: user, category: :deposit, amount: Money.from_amount(2.12, :cad))
        create(:transaction, user: user, category: :deposit, amount: Money.from_amount(10, :cad))
        transaction_10_usd
      end

      Timecop.freeze(2.days.ago) do
        transaction_10_usd2
      end

      subject = FinancialSummary.one_day(user: user, currency: :cad)
      expect(subject.count(:deposit)).to eq(2)
      expect(subject.amount(:deposit)).to eq(Money.from_amount(12.12, :cad))
    end

    it 'withdraw in CAD' do
      Timecop.freeze(Time.now) do
        create(:transaction, user: user, category: :deposit, amount: Money.from_amount(2.12, :cad))
        create(:transaction, user: user, category: :deposit, amount: Money.from_amount(10, :cad))
        transaction_10_cad_withdraw
      end

      Timecop.freeze(2.days.ago) do
        transaction_10_usd2
      end

      subject = FinancialSummary.one_day(user: user, currency: :cad)
      expect(subject.count(:withdraw)).to eq(1)
      expect(subject.amount(:withdraw)).to eq(Money.from_amount(10.00, :cad))
    end

    it 'refund in CAD' do
      Timecop.freeze(Time.now) do
        create(:transaction, user: user, category: :deposit, amount: Money.from_amount(2.12, :cad))
        create(:transaction, user: user, category: :deposit, amount: Money.from_amount(10, :cad))
        transaction_10_cad_refund
      end

      Timecop.freeze(2.days.ago) do
        transaction_10_usd2
      end

      subject = FinancialSummary.one_day(user: user, currency: :cad)
      expect(subject.count(:refund)).to eq(1)
      expect(subject.amount(:refund)).to eq(Money.from_amount(10.00, :cad))
    end

    it 'refund in usd' do
      Timecop.freeze(Time.now) do
        create(:transaction, user: user, category: :deposit, amount: Money.from_amount(2.12, :usd))
        create(:transaction, user: user, category: :deposit, amount: Money.from_amount(10, :usd))
        transaction_10_usd_refund
      end

      Timecop.freeze(2.days.ago) do
        transaction_10_usd2
      end
      subject = FinancialSummary.one_day(user: user, currency: :usd)
      expect(subject.count(:refund)).to eq(1)
      expect(subject.amount(:refund)).to eq(Money.from_amount(10.00, :usd))
    end

    it 'no windrawels returns 0' do
      Timecop.freeze(Time.now) do
        create(:transaction, user: user, category: :deposit, amount: Money.from_amount(2.12, :usd))
        create(:transaction, user: user, category: :deposit, amount: Money.from_amount(10, :usd))
        transaction_10_usd_refund
      end

      Timecop.freeze(8.days.ago) do
        transaction_10_usd2
      end
      subject = FinancialSummary.lifetime(user: user, currency: :usd)
      expect(subject.count(:withraw)).to eq(0)
      expect(subject.amount(:withdraw)).to eq(Money.from_amount(0.00, :usd))
    end

    
    it 'no transaction in currency returns 0' do
      Timecop.freeze(Time.now) do
        create(:transaction, user: user, category: :deposit, amount: Money.from_amount(2.12, :usd))
        create(:transaction, user: user, category: :deposit, amount: Money.from_amount(10, :usd))
        transaction_10_usd_refund
      end

      Timecop.freeze(8.days.ago) do
        transaction_10_usd2
      end
      subject = FinancialSummary.seven_days(user: user, currency: :cad)
      expect(subject.count(:deposit)).to eq(0)
      expect(subject.amount(:deposit)).to eq(Money.from_amount(0.00, :cad))
    end
  end

  context 'summarizes over seven days' do

    it 'deposits in USD' do
      Timecop.freeze(5.days.ago) do
        create(:transaction, user: user, category: :deposit, amount: Money.from_amount(2.12, :usd))
        transaction_10_usd
      end
      Timecop.freeze(8.days.ago) do
        transaction_10_usd2
      end

      subject = FinancialSummary.seven_days(user: user, currency: :usd)
      expect(subject.count(:deposit)).to eq(2)
      expect(subject.amount(:deposit)).to eq(Money.from_amount(12.12, :usd))
    end

    it 'withdraw in usd' do
      Timecop.freeze(5.days.ago) do
        create(:transaction, user: user, category: :deposit, amount: Money.from_amount(2.12, :usd))
        create(:transaction, user: user, category: :deposit, amount: Money.from_amount(10, :cad))
        transaction_10_usd_withdraw
      end

      Timecop.freeze(8.days.ago) do
        transaction_10_usd2
      end

      subject = FinancialSummary.seven_days(user: user, currency: :usd)
      expect(subject.count(:withdraw)).to eq(1)
      expect(subject.amount(:withdraw)).to eq(Money.from_amount(10.00, :usd))
    end

    it 'deposits in CAD' do
      Timecop.freeze(5.days.ago) do
        create(:transaction, user: user, category: :deposit, amount: Money.from_amount(2.12, :cad))
        create(:transaction, user: user, category: :deposit, amount: Money.from_amount(10, :cad))
        transaction_10_usd
      end

      Timecop.freeze(8.days.ago) do
        transaction_10_usd2
      end

      subject = FinancialSummary.seven_days(user: user, currency: :cad)
      expect(subject.count(:deposit)).to eq(2)
      expect(subject.amount(:deposit)).to eq(Money.from_amount(12.12, :cad))
    end

    it 'withdraw in CAD' do
      Timecop.freeze(5.days.ago) do
        create(:transaction, user: user, category: :deposit, amount: Money.from_amount(2.12, :cad))
        create(:transaction, user: user, category: :deposit, amount: Money.from_amount(10, :cad))
        transaction_10_cad_withdraw
      end

      Timecop.freeze(8.days.ago) do
        transaction_10_usd2
      end

      subject = FinancialSummary.seven_days(user: user, currency: :cad)
      expect(subject.count(:withdraw)).to eq(1)
      expect(subject.amount(:withdraw)).to eq(Money.from_amount(10.00, :cad))
    end

    it 'refund in CAD' do
      Timecop.freeze(5.days.ago) do
        create(:transaction, user: user, category: :deposit, amount: Money.from_amount(2.12, :cad))
        create(:transaction, user: user, category: :deposit, amount: Money.from_amount(10, :cad))
        transaction_10_cad_refund
      end

      Timecop.freeze(8.days.ago) do
        transaction_10_usd2
      end

      subject = FinancialSummary.seven_days(user: user, currency: :cad)
      expect(subject.count(:refund)).to eq(1)
      expect(subject.amount(:refund)).to eq(Money.from_amount(10.00, :cad))
    end

    it 'refund in usd' do
      Timecop.freeze(5.days.ago) do
        create(:transaction, user: user, category: :deposit, amount: Money.from_amount(2.12, :usd))
        create(:transaction, user: user, category: :deposit, amount: Money.from_amount(10, :usd))
        transaction_10_usd_refund
      end

      Timecop.freeze(8.days.ago) do
        transaction_10_usd2
      end
      subject = FinancialSummary.seven_days(user: user, currency: :usd)
      expect(subject.count(:refund)).to eq(1)
      expect(subject.amount(:refund)).to eq(Money.from_amount(10.00, :usd))
    end

     it 'no withdraw returns 0' do
      Timecop.freeze(5.days.ago) do
        create(:transaction, user: user, category: :deposit, amount: Money.from_amount(2.12, :usd))
        create(:transaction, user: user, category: :deposit, amount: Money.from_amount(10, :usd))
        transaction_10_usd_refund
      end

      Timecop.freeze(8.days.ago) do
        transaction_10_usd2
      end
      subject = FinancialSummary.seven_days(user: user, currency: :usd)
      expect(subject.count(:withdraw)).to eq(0)
      expect(subject.amount(:withdraw)).to eq(Money.from_amount(0.00, :usd))
    end

    it 'no transaction in currency returns 0' do
      Timecop.freeze(5.days.ago) do
        create(:transaction, user: user, category: :deposit, amount: Money.from_amount(2.12, :usd))
        create(:transaction, user: user, category: :deposit, amount: Money.from_amount(10, :usd))
        transaction_10_usd_refund
      end

      Timecop.freeze(8.days.ago) do
        transaction_10_usd2
      end
      subject = FinancialSummary.seven_days(user: user, currency: :cad)
      expect(subject.count(:deposit)).to eq(0)
      expect(subject.amount(:deposit)).to eq(Money.from_amount(0.00, :cad))
    end
  end

  context 'summarizes over lifetime' do

    it 'deposits in USD' do
      Timecop.freeze(5.days.ago) do
        create(:transaction, user: user, category: :deposit, amount: Money.from_amount(2.12, :usd))
        transaction_10_usd
      end
      Timecop.freeze(8.days.ago) do
        transaction_10_usd2
      end

      subject = FinancialSummary.lifetime(user: user, currency: :usd)
      expect(subject.count(:deposit)).to eq(3)
      expect(subject.amount(:deposit)).to eq(Money.from_amount(22.12, :usd))
    end

    it 'withdraw in usd' do
      Timecop.freeze(5.days.ago) do
        create(:transaction, user: user, category: :deposit, amount: Money.from_amount(2.12, :usd))
        create(:transaction, user: user, category: :deposit, amount: Money.from_amount(10, :cad))
        transaction_10_usd_withdraw
      end

      Timecop.freeze(8.days.ago) do
        transaction_10_usd_withdraw2
      end

      subject = FinancialSummary.lifetime(user: user, currency: :usd)
      expect(subject.count(:withdraw)).to eq(2)
      expect(subject.amount(:withdraw)).to eq(Money.from_amount(20.00, :usd))
    end

    it 'deposits in CAD' do
      Timecop.freeze(5.days.ago) do
        create(:transaction, user: user, category: :deposit, amount: Money.from_amount(2.12, :cad))
        create(:transaction, user: user, category: :deposit, amount: Money.from_amount(10, :cad))
        transaction_10_usd
      end

      Timecop.freeze(8.days.ago) do
        transaction_10_usd2
      end

      subject = FinancialSummary.lifetime(user: user, currency: :cad)
      expect(subject.count(:deposit)).to eq(2)
      expect(subject.amount(:deposit)).to eq(Money.from_amount(12.12, :cad))
    end

    it 'withdraw in CAD' do
      Timecop.freeze(5.days.ago) do
        create(:transaction, user: user, category: :deposit, amount: Money.from_amount(2.12, :cad))
        create(:transaction, user: user, category: :deposit, amount: Money.from_amount(10, :cad))
        transaction_10_cad_withdraw
      end

      Timecop.freeze(8.days.ago) do
        transaction_10_usd2
      end

      subject = FinancialSummary.lifetime(user: user, currency: :cad)
      expect(subject.count(:withdraw)).to eq(1)
      expect(subject.amount(:withdraw)).to eq(Money.from_amount(10.00, :cad))
    end

    it 'refund in CAD' do
      Timecop.freeze(5.days.ago) do
        create(:transaction, user: user, category: :deposit, amount: Money.from_amount(2.12, :cad))
        create(:transaction, user: user, category: :deposit, amount: Money.from_amount(10, :cad))
        transaction_10_cad_refund
      end

      Timecop.freeze(8.days.ago) do
        transaction_10_usd2
      end

      subject = FinancialSummary.lifetime(user: user, currency: :cad)
      expect(subject.count(:refund)).to eq(1)
      expect(subject.amount(:refund)).to eq(Money.from_amount(10.00, :cad))
    end

    it 'refund in usd' do
      Timecop.freeze(5.days.ago) do
        create(:transaction, user: user, category: :deposit, amount: Money.from_amount(2.12, :usd))
        create(:transaction, user: user, category: :deposit, amount: Money.from_amount(10, :usd))
        transaction_10_usd_refund
      end

      Timecop.freeze(8.days.ago) do
        transaction_10_usd2
      end
      subject = FinancialSummary.lifetime(user: user, currency: :usd)
      expect(subject.count(:refund)).to eq(1)
      expect(subject.amount(:refund)).to eq(Money.from_amount(10.00, :usd))
    end

    it 'no windrawels returns 0' do
      Timecop.freeze(5.days.ago) do
        create(:transaction, user: user, category: :deposit, amount: Money.from_amount(2.12, :usd))
        create(:transaction, user: user, category: :deposit, amount: Money.from_amount(10, :usd))
        transaction_10_usd_refund
      end

      Timecop.freeze(8.days.ago) do
        transaction_10_usd2
      end
      subject = FinancialSummary.lifetime(user: user, currency: :usd)
      expect(subject.count(:withraw)).to eq(0)
      expect(subject.amount(:withdraw)).to eq(Money.from_amount(0.00, :usd))
    end


    it 'no transaction in currency returns 0' do
      Timecop.freeze(5.days.ago) do
        create(:transaction, user: user, category: :deposit, amount: Money.from_amount(2.12, :usd))
        create(:transaction, user: user, category: :deposit, amount: Money.from_amount(10, :usd))
        transaction_10_usd_refund
      end

      Timecop.freeze(8.days.ago) do
        transaction_10_usd2
      end
      subject = FinancialSummary.seven_days(user: user, currency: :cad)
      expect(subject.count(:deposit)).to eq(0)
      expect(subject.amount(:deposit)).to eq(Money.from_amount(0.00, :cad))
    end
  end

end
